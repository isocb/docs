# Project-Specific Technical Reference

This document provides technical details, patterns, and reference information specific to the Bedrock Enhanced project.

## Project Overview

**Project Name:** Bedrock Enhanced

**Project Purpose:**  
Multi-tier database application for managing Google Sheets data with relationships, analysis, and virtual columns (calculated fields and regex transformations). Enables clients to organize, analyze, and filter spreadsheet data for their users.  as the project matures other data connectors will be added for example Knack Database, airtable and Uploaded CSV files. 

**Business Model:**
- Bedrock (owner company) manages multiple clients
- Each client has multiple users
- Clients configure access to Google Sheets (or newer data sources connected )
- Data is grouped, analyzed, and filtered per user's email
- Master-detail relationships enable complex data views

## Current Architecture

### Database (Neon PostgreSQL)

**Key Tables:**
- `projects`: Main project configurations
- `project_sheets`: Google Sheets linked to projects
- `sheet_columns`: Column definitions and metadata
- `sheet_relationships`: Master-detail relationships between sheets
- `virtual_columns`: Calculated fields and regex transformations
- `clients`: Client organizations
- `users`: User accounts and permissions
- `owners`: Platform owner accounts

**Data Type Enum:**
```sql
CREATE TYPE data_type AS ENUM ('text', 'number', 'date', 'boolean', 'currency');
```

**ID Strategy:**
- All tables use text-based UUIDs with entity-specific prefixes
- Generated via `generateId(entityType)` helper
- Example: `prj_abc123...`, `psh_xyz789...`, `vcl_def456...`
- IMPORTANT ARCHITECTURE NOTE:  See file /context/column-identification.md for explanation of why column idetification does not use internal ID's.
  
**Foreign Key Strategy:**
- Use CASCADE deletes for dependent data
- Maintain referential integrity
- Example: Deleting a project deletes all its sheets, columns, and relationships

### Backend (Node.js + Hono)

**Framework:** Hono web framework
- Fast, lightweight routing
- Native Request/Response objects
- Dynamic imports for endpoints

**Query Builder:** Kysely
- Type-safe SQL query builder
- TypeScript integration
- Defined in `helpers/db.ts`

**API Pattern Structure:**
```
endpoints/
  [feature]/
    [entity]/
      ├── _GET.schema.ts     # Input/output types + fetch function
      ├── _GET.ts            # HTTP handler
      ├── _POST.schema.ts    # Input/output types + post function
      ├── _POST.ts           # HTTP handler
      ├── delete_POST.schema.ts
      └── delete_POST.ts     # DELETE via POST pattern
```

**Schema Files (.schema.ts):**
- Define Zod validation schemas
- Export TypeScript types
- Export async fetch/post functions
- Used by frontend React Query hooks

**Handler Files (.ts):**
- Export `handle(request: Request): Promise<Response>`
- Validate session/authentication
- Parse and validate input
- Execute Kysely queries
- Return superjson responses

**Route Registration (server.ts):**
```typescript
app.get('_api/[route]', async c => {
  try {
    const { handle } = await import("./endpoints/[path]/_GET.js");
    const response = await handle(c.req.raw);
    return response;
  } catch (e) {
    console.error(e);
    return c.text("Error loading endpoint code " + e.message, 500);
  }
});
```

**Key Backend Patterns:**
- Schema validation: Zod
- Serialization: superjson (handles Date, Map, Set, etc.)
- Authentication: Custom session-based via `getServerUserSession`
- Error handling: Try/catch with detailed logging

### Frontend (React + TypeScript)

**State Management:**
- React Query (@tanstack/react-query) for server state
- React hooks for local state
- Custom hooks pattern for data fetching

**Custom Hooks Pattern:**
```typescript
// In helpers/
export function useVirtualColumns(sheetId: string) {
  return useQuery({
    queryKey: ['virtualColumns', sheetId],
    queryFn: () => fetchVirtualColumns({ sheetId }),
    enabled: !!sheetId
  });
}
```

**UI Components:**
- Custom component library (not shadcn/ui)
- Import pattern: `import { Button } from './Button'`
- NO `/ui/` subfolder in imports
- CSS Modules for styling (`.module.css` files)
- Icons from lucide-react

**Component Structure:**
```
components/
  ├── Button.tsx
  ├── Button.module.css
  ├── Dialog.tsx
  ├── Dialog.module.css
  └── [ComponentName].tsx + .module.css
```

**Typical Component Pattern:**
```typescript
import { useState } from 'react';
import { useVirtualColumns } from '../helpers/useVirtualColumns';
import { Button } from './Button';
import { Dialog } from './Dialog';
import styles from './VirtualColumnsTab.module.css';

export function VirtualColumnsTab({ sheetId }: Props) {
  const { data, isLoading } = useVirtualColumns(sheetId);
  // Component logic
  return (
    <div className={styles.container}>
      {/* JSX */}
    </div>
  );
}
```

**Key Frontend Libraries:**
- React 18.3
- React Router DOM 6.26
- React Query 5.76
- lucide-react (icons)
- date-fns (date formatting)
- recharts (charts)

## Key Development Patterns

### 1. Adding a New Database Table

**Steps:**
1. Create table in Neon SQL Editor
   ```sql
   CREATE TABLE my_new_table (
     id TEXT PRIMARY KEY,
     name TEXT NOT NULL,
     created_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```

2. Update `helpers/schema.tsx`:
   ```typescript
   export interface MyNewTable {
     id: string;
     name: string;
     createdAt: Generated<Timestamp | null>;
   }
   
   export interface DB {
     // ... existing tables
     my_new_table: MyNewTable;
   }
   ```

3. Commit schema changes
4. Deploy to Render
5. Verify in deployed environment

### 2. Creating CRUD Endpoints

**File Structure:**
```
endpoints/
  [feature]/
    [entity]/
      ├── _GET.schema.ts     # List/fetch operations
      ├── _GET.ts
      ├── _POST.schema.ts    # Create/update operations
      ├── _POST.ts
      ├── delete_POST.schema.ts
      └── delete_POST.ts
```

**Schema File Example (_GET.schema.ts):**
```typescript
import { z } from 'zod';
import superjson from 'superjson';

// Input validation schema
export const InputSchema = z.object({
  sheetId: z.string()
});

export type Input = z.infer<typeof InputSchema>;

// Output type
export type Output = {
  id: string;
  name: string;
  // ... other fields
}[];

// Fetch function for React Query
export async function fetchMyData(input: Input): Promise<Output> {
  const response = await fetch(`/_api/my-endpoint?sheetId=${input.sheetId}`);
  if (!response.ok) throw new Error('Failed to fetch');
  const text = await response.text();
  return superjson.parse(text);
}
```

**Handler File Example (_GET.ts):**
```typescript
import superjson from 'superjson';
import { db } from '../../helpers/db.js';
import { getServerUserSession } from '../../helpers/getServerUserSession.js';
import { InputSchema } from './_GET.schema.js';

export async function handle(request: Request): Promise<Response> {
  const session = await getServerUserSession(request);
  if (!session) {
    return new Response('Unauthorized', { status: 401 });
  }

  const url = new URL(request.url);
  const rawInput = {
    sheetId: url.searchParams.get('sheetId')
  };

  const input = InputSchema.parse(rawInput);

  const results = await db
    .selectFrom('my_table')
    .where('sheet_id', '=', input.sheetId)
    .selectAll()
    .execute();

  return new Response(
    superjson.stringify(results),
    { headers: { 'Content-Type': 'application/json' } }
  );
}
```

**Register in server.ts:**
```typescript
app.get('_api/my-endpoint', async c => {
  try {
    const { handle } = await import("./endpoints/my-feature/_GET.js");
    const response = await handle(c.req.raw);
    return response;
  } catch (e) {
    console.error(e);
    return c.text("Error loading endpoint code " + e.message, 500);
  }
});
```

### 3. Creating React Components

**Component File Structure:**
```
components/
  ├── MyComponent.tsx
  └── MyComponent.module.css
```

**Component Example:**
```typescript
import { useState } from 'react';
import { useMyData } from '../helpers/useMyData';
import { Button } from './Button';
import { Input } from './Input';
import { Plus, Trash2 } from 'lucide-react';
import styles from './MyComponent.module.css';

interface MyComponentProps {
  sheetId: string;
}

export function MyComponent({ sheetId }: MyComponentProps) {
  const [isOpen, setIsOpen] = useState(false);
  const { data, isLoading, error } = useMyData(sheetId);

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div className={styles.container}>
      <Button onClick={() => setIsOpen(true)}>
        <Plus className={styles.icon} />
        Add New
      </Button>
      {/* Component JSX */}
    </div>
  );
}
```

**CSS Module Example:**
```css
.container {
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.icon {
  width: 16px;
  height: 16px;
}
```

**React Query Hook Example:**
```typescript
// helpers/useMyData.tsx
import { useQuery } from '@tanstack/react-query';
import { fetchMyData } from '../endpoints/my-feature/_GET.schema';

export function useMyData(sheetId: string) {
  return useQuery({
    queryKey: ['myData', sheetId],
    queryFn: () => fetchMyData({ sheetId }),
    enabled: !!sheetId
  });
}
```

### 4. ID Generation Pattern

**Import and Usage:**
```typescript
import { generateId } from '../helpers/generateId';

// Generate IDs with entity-specific prefixes
const ownerId = generateId('owner');                 // own_...
const clientId = generateId('client');               // clt_...
const userId = generateId('user');                   // usr_...
const projectId = generateId('project');             // prj_...
const sheetId = generateId('projectSheet');          // psh_...
const columnId = generateId('sheetColumn');          // scl_...
const analysisId = generateId('projectAnalysisConfig'); // pac_...
const virtualColumnId = generateId('virtualColumn'); // vcl_...
```

**Entity Type Mapping:**
```typescript
export type EntityType =
  | "owner"               // own_
  | "client"              // clt_
  | "user"                // usr_
  | "project"             // prj_
  | "projectSheet"        // psh_
  | "sheetColumn"         // scl_
  | "projectAnalysisConfig" // pac_
  | "virtualColumn";      // vcl_
```

**Adding New Entity Types:**
1. Add to `EntityType` union in `helpers/generateId.tsx`
2. Add prefix to `prefixes` object
3. Use consistent naming (camelCase for type, snake_case for prefix)

## Virtual Columns Feature

### Overview
Virtual columns are calculated fields that don't exist in the source Google Sheets but are computed on-the-fly. Two types supported:
1. **Formula**: Mathematical calculations using operators (+, -, *, /, %)
2. **Regex**: Text transformations using regular expressions

### Database Table
```sql
CREATE TABLE virtual_columns (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  sheet_id TEXT NOT NULL REFERENCES project_sheets(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  expression TEXT,
  data_type data_type NOT NULL,
  column_type TEXT DEFAULT 'formula' CHECK (column_type IN ('formula', 'regex')),
  display_order INTEGER DEFAULT 0,
  visible BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  error_message TEXT,
  source_column_id TEXT,
  regex_pattern TEXT,
  regex_replacement TEXT,
  regex_flags TEXT DEFAULT 'g',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Expression Field:**
- For formula type: JSON with parts array
  ```json
  {
    "type": "formula",
    "parts": [
      { "partType": "column", "columnId": "scl_abc..." },
      { "partType": "operator", "value": "+" },
      { "partType": "number", "value": 10 }
    ]
  }
  ```
- For regex type: JSON with pattern, replacement, flags
  ```json
  {
    "type": "regex",
    "sourceColumnId": "scl_xyz...",
    "pattern": "^(\\d{3})-(\\d{4})$",
    "replacement": "($1) $2",
    "flags": "g"
  }
  ```

### Endpoints

**GET `/api/project/virtual-columns?sheetId=xxx`**
- Fetch all virtual columns for a sheet
- Returns array of virtual column definitions

**POST `/api/project/virtual-columns`**
- Create or update virtual column
- Body: `{ json: { id?, sheetId, name, dataType, expression }, meta: {} }`
- Returns created/updated virtual column

**POST `/api/project/virtual-columns/delete`**
- Delete virtual column
- Body: `{ json: { id }, meta: {} }`
- Returns success response

### Components

**`VirtualColumnsTab.tsx`**
- Main management UI for virtual columns
- Lists all virtual columns for a sheet
- Buttons to create, edit, delete
- Located in: `components/VirtualColumnsTab.tsx`

**`VirtualColumnForm.tsx`**
- Modal form for creating/editing virtual columns
- Supports both formula and regex types
- Includes expression builder UI
- Located in: `components/VirtualColumnForm.tsx`

**Integration:**
- Added as tab in project pages
- Accessed via: `pages/projects.$projectId.tsx`
- Tab component renders when "Virtual Columns" tab selected

### Calculator

**`helpers/virtualColumnCalculator.tsx`**

**Key Functions:**

```typescript
// Calculate single virtual column for one row
export function calculateVirtualColumn(
  virtualColumn: Selectable<VirtualColumns>,
  rowData: Record<string, any>,
  columnIdToNameMap: Map<string, string>
): any

// Add virtual columns to array of rows
export function addVirtualColumnsToRows(
  rows: Record<string, any>[],
  virtualColumns: Selectable<VirtualColumns>[],
  columnIdToNameMap: Map<string, string>
): Record<string, any>[]
```

**Formula Evaluation:**
- Supports operator precedence (*, / before +, -)
- Handles parentheses for grouping
- Returns numeric results
- Throws errors for invalid expressions

**Regex Processing:**
- Applies pattern matching and replacement
- Supports flags (g, i, m, etc.)
- Returns transformed text
- Handles missing source columns gracefully

### Integration Points

**Primary Integration: `endpoints/project/related-data_GET.ts`**
- Critical 719-line file handling master-detail relationships
- Fetches data from Google Sheets
- Applies grouping and analysis
- Returns data for `MasterDetailView` component
- **Needs virtual column integration** (current work)

**Other Integration Points:**
- CSV exports (future)
- Chart data (future)
- Analysis operations (future)

### Current Status
- **Phase 4B**: Integrating virtual column calculator into related-data endpoint
- **Next Steps**: Add 5 specific code changes to apply calculations
- **After**: Test thoroughly, then Phase 5 (CSV exports, additional integrations)

## File Locations Reference

### Core Helpers
- `helpers/schema.tsx` - TypeScript database types (auto-generated base + manual edits)
- `helpers/db.ts` - Kysely database instance and connection
- `helpers/generateId.tsx` - Entity ID generation with prefixes
- `helpers/getServerUserSession.ts` - Authentication and session management
- `helpers/virtualColumnCalculator.tsx` - Virtual column calculation logic

### Key Endpoints
- `endpoints/project/related-data_GET.ts` - **CRITICAL** Master-detail data endpoint (719 lines)
- `endpoints/project/virtual-columns/_GET.ts` - Fetch virtual columns
- `endpoints/project/virtual-columns/_POST.ts` - Create/update virtual columns
- `endpoints/project/virtual-columns/delete_POST.ts` - Delete virtual columns
- `endpoints/project/columns_GET.ts` - Fetch sheet columns
- `endpoints/project/sheets_GET.ts` - Fetch project sheets

### Key Components
- `pages/projects.$projectId.tsx` - Main project page with tabs
- `components/MasterDetailView.tsx` - Display master-detail data
- `components/ProjectColumnsTab.tsx` - Manage sheet columns
- `components/VirtualColumnsTab.tsx` - Manage virtual columns
- `components/VirtualColumnForm.tsx` - Create/edit virtual column modal
- `components/RelatedDataTab.tsx` - Tab showing related data view

### Configuration Files
- `server.ts` - Hono server with route registrations
- `package.json` - Dependencies and scripts
- `vite.config.ts` - Vite build configuration
- `render.yaml` - Render deployment configuration

### Testing Locations
- **Live Application**: Render deployment URL (production)
- **Database**: Neon console SQL editor
- **Logs**: Render dashboard → Logs tab
- **Browser Console**: DevTools for frontend errors

## Common Issues & Solutions

### Import Path Errors

**Problem:** Component imports fail with "module not found"

❌ **Wrong:**
```typescript
import { Button } from './ui/button';
import { Dialog } from './ui/Dialog';
```

✅ **Correct:**
```typescript
import { Button } from './Button';
import { Dialog } from './Dialog';
```

**Solution:** Never use `/ui/` subfolder in component imports. Always use capitalized component name directly.

### SuperJSON Format Errors

**Problem:** POST requests fail with "invalid JSON" or data not deserializing correctly

❌ **Wrong:**
```typescript
const body = { sheetId: 'psh_123', name: 'Test' };
```

✅ **Correct:**
```typescript
const body = {
  json: { sheetId: 'psh_123', name: 'Test' },
  meta: {}
};
```

**Solution:** Always wrap POST body data in `json` property with empty `meta` object for superjson format.

### Missing Icon Imports

**Problem:** Icons don't render, console shows "X is not defined"

❌ **Wrong:**
```typescript
import { Zap } from 'lucide-react';
// Using Edit, Trash2 in JSX without importing
```

✅ **Correct:**
```typescript
import { Zap, Edit, Trash2, Plus } from 'lucide-react';
// Import all icons used in component
```

**Solution:** Always check that all lucide-react icons used in JSX are imported at the top of the file.

### Entity Type Errors

**Problem:** `generateId()` fails with "Invalid entity type"

**Solution:** Add new entity type to two places in `helpers/generateId.tsx`:
1. Add to `EntityType` union type
2. Add prefix to `prefixes` object

Example:
```typescript
export type EntityType =
  | "owner"
  | "myNewEntity";  // Add here

const prefixes: Record<EntityType, string> = {
  owner: "own_",
  myNewEntity: "mne_"  // And here
};
```

### Kysely Query Errors

**Problem:** Database queries fail with type errors

**Common Causes:**
- Table name doesn't match schema (use snake_case: `project_sheets` not `projectSheets`)
- Column names don't match schema (check `helpers/schema.tsx`)
- Missing `await` on query execution
- Forgot to call `.execute()` on query

✅ **Correct Pattern:**
```typescript
const results = await db
  .selectFrom('project_sheets')  // snake_case table name
  .where('project_id', '=', projectId)  // snake_case column
  .selectAll()
  .execute();  // Don't forget execute()!
```

### Authentication Errors

**Problem:** Endpoint returns 401 Unauthorized

**Check:**
1. Is `getServerUserSession()` called at start of handler?
2. Is session null check present?
3. Are cookies being sent with request?

```typescript
const session = await getServerUserSession(request);
if (!session) {
  return new Response('Unauthorized', { status: 401 });
}
```

### Deployment Issues

**Problem:** Changes not reflecting in deployed app

**Solutions:**
1. Check Render dashboard for deployment status
2. Wait 2-3 minutes for full deployment
3. Hard refresh browser (Ctrl+Shift+R)
4. Check Render logs for build/startup errors
5. Verify correct branch is deployed

### React Query Stale Data

**Problem:** UI shows old data after mutation

**Solution:** Invalidate queries after mutations

```typescript
import { useQueryClient } from '@tanstack/react-query';

const queryClient = useQueryClient();

// After successful mutation
await postVirtualColumn(data);
queryClient.invalidateQueries({ queryKey: ['virtualColumns', sheetId] });
```

## Commit Message Conventions

### Format
Use clear, descriptive messages that explain what changed:

✅ **Good Examples:**
- "Add virtual columns POST schema and handler"
- "Fix VirtualColumnForm import paths"
- "Update related-data endpoint to include virtual columns"
- "Create VirtualColumnsTab component with CRUD operations"

❌ **Poor Examples:**
- "Update files"
- "Fix bug"
- "Changes"
- "WIP"

### Pattern
```
[Action] [What] [Context if needed]

Examples:
Add virtual column calculator helper
Fix import paths in VirtualColumnsTab
Update schema to include virtual_columns table
Refactor related-data endpoint for performance
```

### When to Commit
- After completing a logical unit of work
- After each phase in a multi-phase feature
- Before switching to a different task
- When tests pass and feature works

## Branch Strategy

**Current Approach:**
- Working directly on `main` branch
- Regular commits as features are completed
- Render auto-deploys from `main`
- Test after each deploy

**Alternative for Large Features:**
- Create feature branch if requested
- Develop and test in feature branch
- Merge to `main` when complete
- **Default to main branch unless specified otherwise**

## Testing Strategy

### Database Testing
1. Open Neon console
2. Run SQL queries to verify data
3. Check table structure matches schema
4. Verify foreign key relationships work

### Backend Testing
1. Check Render logs for startup errors
2. Test endpoints with actual requests
3. Verify response format (superjson)
4. Check error handling with invalid input

### Frontend Testing
1. Open deployed app in browser
2. Test user interactions
3. Check browser console for errors
4. Verify UI updates correctly
5. Test edge cases (empty data, errors, etc.)

### Integration Testing
1. Test complete user workflows
2. Verify data flows from database to UI
3. Check that mutations update state correctly
4. Test with realistic data volumes

## Development Tips

### Before Starting
1. Review current code to understand context
2. Check existing patterns in similar files
3. Verify database schema in Neon
4. Review Render logs for baseline errors

### During Development
1. Make small, focused changes
2. Test incrementally
3. Commit after each working phase
4. Keep changes minimal and surgical
5. Follow existing code style

### After Changes
1. Deploy to Render
2. Wait for deployment to complete
3. Test in production environment
4. Check Render logs for errors
5. Verify requirements are met

### When Stuck
1. Check Render logs for error messages
2. Verify database state in Neon
3. Review similar working code
4. Test API endpoints independently
5. Check browser console for frontend errors

## Quick Reference

### Common Commands (if CLI requested)
```bash
# Install dependencies
npm install

# Build frontend
npm run build

# Start server
npm start

# Development mode
npm run dev
```

### Common File Patterns
```
Endpoint:     endpoints/[feature]/[entity]/_[METHOD].ts
Schema:       endpoints/[feature]/[entity]/_[METHOD].schema.ts
Component:    components/[ComponentName].tsx
Style:        components/[ComponentName].module.css
Helper:       helpers/[helperName].tsx
Hook:         helpers/use[HookName].tsx
Type:         helpers/schema.tsx
```

### Common Imports
```typescript
// Database
import { db } from '../helpers/db';
import type { DB, VirtualColumns } from '../helpers/schema';

// Validation
import { z } from 'zod';

// Serialization
import superjson from 'superjson';

// React Query
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Icons
import { Plus, Edit, Trash2, Zap } from 'lucide-react';

// Components
import { Button } from './Button';
import { Dialog } from './Dialog';
import { Input } from './Input';
```

## Project Status

### Recently Completed
- Virtual columns database table
- Virtual column CRUD endpoints
- Virtual column management UI (VirtualColumnsTab)
- Virtual column form with formula and regex support
- Virtual column calculator helper
- Virtual column concatonator
- Virtual Column Alignment

### Current Work
- CSV / PDF to work with virtual columns as per the column spec.
- 

### Next Steps
- CSV export with virtual columns


### Known Limitations
- Virtual columns calculated on-the-fly (not stored)
- Formula type supports basic operators only
- Regex type requires valid patterns
- Performance impact with large datasets (to be monitored)

## Summary

Bedrock Enhanced is a production application built with modern tools (React, Hono, Kysely, PostgreSQL) following consistent patterns. Development focuses on:
- Browser-based workflow (GitHub, Neon, Render)
- Type-safe code (TypeScript, Kysely, Zod)
- Modular architecture (components, endpoints, helpers)
- Iterative testing and deployment
- Clear documentation and communication

Key to success: Follow established patterns, test incrementally, and maintain clear communication about changes and their purpose.

Correct at 12/11/2025 10:12  (dd/mm/yyyy)
