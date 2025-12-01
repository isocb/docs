# Column Identification Architecture

**Date:** 2025-11-17  
**Context:** Virtual column alignment implementation  
**Author:** System architecture documentation

---

## Table of Contents
1. [Core Constraint: Google Sheets API](#core-constraint-google-sheets-api)
2. [The Naming Collision Problem](#the-naming-collision-problem)
3. [Key Implementation Points](#key-implementation-points)
4. [Solutions & Best Practices](#solutions--best-practices)
5. [Code Examples](#code-examples)
6. [Future Considerations](#future-considerations)

---

## Core Constraint: Google Sheets API

### Why Column Names Are Data Keys

The Bedrock application uses the Google Sheets API to fetch data from spreadsheets. The API returns data in a structure where **column names (headers) are the keys** in the data objects. This is a fundamental constraint imposed by how Google Sheets represents tabular data.

### Google Sheets Data Structure Example

When fetching data from Google Sheets, the API returns:

```javascript
// Raw Google Sheets API response
{
  headers: ["Name", "Email", "Age", "Department"],
  rows: [
    ["John Smith", "john@example.com", 30, "Engineering"],
    ["Jane Doe", "jane@example.com", 28, "Marketing"]
  ]
}
```

Our application transforms this into record objects using **column names as keys**:

```javascript
// Transformed into record objects (see helpers/syncSheetData.tsx)
const rowData: { [key: string]: any } = {};
headers.forEach((header, colIndex) => {
  if (visibleColumnNames.has(header)) {
    const value = row[colIndex];
    rowData[header] = typeof value === 'string' ? value.trim() : value ?? null;
  }
});

// Resulting in:
{
  "Name": "John Smith",
  "Email": "john@example.com", 
  "Age": 30,
  "Department": "Engineering"
}
```

### Architectural Impact

This means that throughout our application:

1. **Data access uses column names**: `record[columnName]` not `record[columnId]`
2. **Virtual columns must use the same pattern**: They add computed values to records using their display name as the key
3. **Column metadata has IDs**: Our database stores `SheetColumns` and `VirtualColumns` with IDs, but the actual data records use names
4. **The two worlds must be bridged**: We maintain mappings between column IDs (metadata) and column names (data access)

```typescript
// Column metadata in database - has IDs
interface SheetColumns {
  id: string;              // e.g., "col_abc123"
  columnName: string;      // e.g., "Email" - used for data access
  displayName: string | null;
  dataType: DataType;
  // ... other metadata
}

interface VirtualColumns {
  id: string;              // e.g., "vcl_xyz789"  
  displayName: string;     // e.g., "Full Name" - used as columnName for data access
  expression: string | null;
  // ... other metadata
}

// But actual data records use names as keys
const record: Record<string, any> = {
  "Email": "john@example.com",
  "Full Name": "John Smith"  // Virtual column added by calculator
};
```

---

## The Naming Collision Problem

### The Scenario

A critical issue arises when a virtual column has the same display name as an existing (potentially hidden) source column:

1. **Source Column**: A real column in Google Sheets named "Department" that is marked as `visible: false`
2. **Virtual Column**: A computed column also named "Department" (e.g., concatenating division and team)

### Why This Causes Problems

When both columns exist with the same name:

```typescript
// Both columns exist in metadata
const columns = [
  { id: "col_123", columnName: "Department", visible: false },  // Hidden source
  { id: "vcl_456", columnName: "Department", visible: true }    // Virtual column
];

// But records use the name as the key - only ONE value can exist!
const record = {
  "Department": "Engineering"  // Which column does this represent?
};
```

### Impact on Lookups and Metadata Retrieval

When rendering data or applying formatting, we look up column metadata:

```typescript
// PROBLEM: Multiple columns match!
const columnInfo = columns.find(col => col.columnName === header);
// Returns the FIRST match, which might be the wrong one

// If we get the hidden source column instead of the virtual column:
// - Wrong data type applied
// - Wrong formatting (e.g., textAlign)
// - Wrong visibility status
```

### Real-World Example

Consider this scenario from virtual column alignment implementation (2025-11-17):

```typescript
// Source columns
[
  { id: "col_001", columnName: "Team", visible: true },
  { id: "col_002", columnName: "Division", visible: false }  // Hidden
]

// User creates virtual column to replace Division
{ 
  id: "vcl_003", 
  columnName: "Division",  // Same name as hidden column!
  expression: "concat(Team, ' - ', Region)",
  textAlign: "center"
}

// Lookup for alignment in MasterDetailRecordsList.tsx
const columnInfo = columns?.find(col => col.columnName === "Division");
// Returns col_002 (hidden source) instead of vcl_003 (virtual)
// textAlign: null instead of textAlign: "center" 
// Visual alignment breaks!
```

---

## Key Implementation Points

### 1. Column Metadata Has IDs, Record Data Uses Names

**Critical Understanding**: There are two parallel systems:

```typescript
// METADATA LAYER (has IDs)
// Stored in database, retrieved via endpoints
interface ColumnMetadata {
  id: string;           // Unique identifier for database operations
  columnName: string;   // Key for data access
  displayName: string;  // Label for UI (can be null, defaults to columnName)
  dataType: string;
  visible: boolean;
  textAlign?: string;
  // ... other metadata
}

// DATA LAYER (uses names as keys)
// Retrieved from Google Sheets, stored as JSON in sheetData.rowData
type RecordData = {
  [columnName: string]: any;  // Column name is the key!
};
```

### 2. Labels vs Column Names

**Important Distinction**:

- **`displayName`** (or label): What the user sees in the UI, can be customized
- **`columnName`**: The actual key used to access data in records, must match Google Sheets header

```typescript
// A column can have different display and technical names
{
  id: "col_001",
  columnName: "email_address",      // Data access key
  displayName: "Email Address",     // UI label (prettier)
  // ...
}

// Access data:
const email = record["email_address"];  // NOT record["Email Address"]

// Display in UI:
<th>{column.displayName || column.columnName}</th>
```

For virtual columns, `displayName` IS the `columnName` (they're the same value).

### 3. Multiple Column Arrays to Track

The application maintains several arrays that must be coordinated:

```typescript
// 1. Sheet columns (real Google Sheets columns)
const sheetColumns: SheetColumn[] = await db
  .selectFrom("sheetColumns")
  .selectAll()
  .where("sheetId", "=", sheetId)
  .execute();

// 2. Virtual columns (computed columns)
const virtualColumns: VirtualColumn[] = await db
  .selectFrom("virtualColumns")
  .selectAll()
  .where("sheetId", "=", sheetId)
  .execute();

// 3. Merged columns (both types combined)
const columns = [
  ...sheetColumns.map(col => ({
    id: col.id,
    columnName: col.columnName,
    dataType: col.dataType,
    // ... other fields
  })),
  ...virtualColumns.map(vcol => ({
    id: vcol.id,
    columnName: vcol.displayName,  // Virtual columns use displayName as columnName
    dataType: vcol.dataType,
    textAlign: vcol.textAlign,
    // ... other fields
  }))
];
```

### 4. Data Flow Overview

```
Google Sheets API
      ↓
  headers: ["Name", "Email", "Age"]
  rows: [["John", "john@example.com", 30]]
      ↓
syncSheetData (helpers/syncSheetData.tsx)
      ↓
  rowData: { "Name": "John", "Email": "john@example.com", "Age": 30 }
      ↓
Stored in database (sheetData.rowData as JSON)
      ↓
Retrieved by endpoints (e.g., related-data_GET.ts)
      ↓
Virtual Column Calculator adds computed fields
      ↓
  { "Name": "John", "Email": "john@example.com", "Age": 30, "Full Name": "John Smith" }
      ↓
Components render using columnName to look up metadata
      ↓
  const columnInfo = columns.find(col => col.columnName === header)
```

---

## Solutions & Best Practices

### ✅ DO: Validate Column Name Uniqueness

**Prevent collisions at creation time:**

```typescript
// When creating/updating a virtual column
async function validateVirtualColumnName(
  projectId: string, 
  sheetId: string, 
  displayName: string,
  excludeId?: string
): Promise<boolean> {
  // Check against other virtual columns
  const existingVirtual = await db
    .selectFrom("virtualColumns")
    .select("id")
    .where("sheetId", "=", sheetId)
    .where("displayName", "=", displayName)
    .where("isActive", "=", true)
    .$if(!!excludeId, (qb) => qb.where("id", "!=", excludeId!))
    .executeTakeFirst();
  
  if (existingVirtual) {
    return false;  // Collision with virtual column
  }
  
  // Check against real sheet columns
  const existingSheet = await db
    .selectFrom("sheetColumns")
    .select("id")
    .where("sheetId", "=", sheetId)
    .where("columnName", "=", displayName)
    .where("isActive", "=", true)
    .executeTakeFirst();
    
  if (existingSheet) {
    return false;  // Collision with real column
  }
  
  return true;  // Name is unique
}
```

### ✅ DO: Warn Users of Collisions

**Provide clear UI feedback:**

```typescript
// In VirtualColumnForm component
if (!await validateVirtualColumnName(projectId, sheetId, displayName)) {
  showError(
    "Column name collision detected. " +
    "A column with this name already exists. " +
    "Please choose a different name."
  );
  return;
}
```

### ✅ DO: Prioritize Virtual Columns in Lookups

**When lookups occur, prefer virtual columns over hidden source columns:**

```typescript
// RIGHT - Safe lookup that handles duplicates
const columnInfo = columns
  ?.filter(col => col.columnName === header)
  .sort((a, b) => {
    // Virtual columns (starting with vcl_) come first
    if (a.id.startsWith('vcl_') && !b.id.startsWith('vcl_')) return -1;
    if (!a.id.startsWith('vcl_') && b.id.startsWith('vcl_')) return 1;
    return 0;
  })[0];
```

### ❌ DON'T: Try to Refactor to IDs Everywhere

**This is architecturally impossible due to Google Sheets API:**

```typescript
// IMPOSSIBLE - Google Sheets API doesn't provide IDs
const record = {
  "col_123": "john@example.com",  // ❌ Can't do this
  "vcl_456": "John Smith"         // ❌ Can't do this
};

// We MUST use names
const record = {
  "Email": "john@example.com",    // ✅ Required by Google Sheets
  "Full Name": "John Smith"       // ✅ Required by Google Sheets
};
```

### ❌ DON'T: Assume Single Matches in Lookups

**Always handle potential duplicates:**

```typescript
// WRONG - Fails with duplicate names
const columnInfo = columns?.find(col => col.columnName === header);
// Returns first match, which might be wrong column

// RIGHT - Handle duplicates explicitly  
const matchingColumns = columns?.filter(col => col.columnName === header);
if (matchingColumns.length > 1) {
  console.warn(`Multiple columns named "${header}" found`);
  // Apply prioritization logic
}
const columnInfo = prioritizeVirtualColumn(matchingColumns);
```

### ❌ DON'T: Mix Column Names with Display Names

**Be clear about which field you're using:**

```typescript
// WRONG - Confusing which name to use
const value = record[column.displayName];  // Might not exist in record

// RIGHT - Explicit about data access key
const value = record[column.columnName];   // Correct data access
const label = column.displayName || column.columnName;  // Correct display
```

---

## Code Examples

### Safe Column Lookup Pattern

Use this pattern whenever looking up column metadata from a column name:

```typescript
/**
 * Safely lookup column metadata by name, prioritizing virtual columns.
 * Handles the case where multiple columns might have the same name.
 */
function getColumnInfo(
  columns: ColumnMetadata[], 
  columnName: string
): ColumnMetadata | undefined {
  const matches = columns.filter(col => col.columnName === columnName);
  
  if (matches.length === 0) {
    return undefined;
  }
  
  if (matches.length === 1) {
    return matches[0];
  }
  
  // Multiple matches - prioritize virtual columns
  return matches.sort((a, b) => {
    if (a.id.startsWith('vcl_') && !b.id.startsWith('vcl_')) return -1;
    if (!a.id.startsWith('vcl_') && b.id.startsWith('vcl_')) return 1;
    return 0;
  })[0];
}

// Usage in component
const columnInfo = getColumnInfo(columns, header);
const alignment = columnInfo?.textAlign || 'left';
```

### Example: MasterDetailRecordsList Component

```typescript
// In components/MasterDetailRecordsList.tsx
{headers.map(header => {
  const cellValue = record[header];  // Data access uses column name
  
  // Safe lookup with duplicate handling
  const columnInfo = columns
    ?.filter(col => col.columnName === header)
    .sort((a, b) => {
      if (a.id.startsWith('vcl_') && !b.id.startsWith('vcl_')) return -1;
      if (!a.id.startsWith('vcl_') && b.id.startsWith('vcl_')) return 1;
      return 0;
    })[0];
  
  const alignment = columnInfo?.textAlign || 'left';
  
  return (
    <td key={header} className={getAlignmentClass(alignment)}>
      {formatCellValue(cellValue, header, analysisConfig, columns)}
    </td>
  );
})}
```

### Example: Virtual Column Calculator

```typescript
// In helpers/virtualColumnCalculator.tsx
export function calculateVirtualColumns(
  records: Record<string, any>[],
  virtualColumns: VirtualColumn[]
): Record<string, any>[] {
  return records.map(record => {
    const enrichedRecord = { ...record };
    
    virtualColumns.forEach(vcol => {
      if (!vcol.isActive || !vcol.visible) return;
      
      // Compute value based on virtual column type
      const computedValue = computeVirtualColumnValue(vcol, record);
      
      // Add to record using displayName as the key
      enrichedRecord[vcol.displayName] = computedValue;
    });
    
    return enrichedRecord;
  });
}
```

### Example: Column Validation Endpoint

```typescript
// In endpoints/project/virtual-columns/validate-name_POST.ts
export async function handle(request: Request): Promise<Response> {
  const { sheetId, displayName, excludeId } = await parseRequest(request);
  
  // Check for collisions with virtual columns
  const virtualConflict = await db
    .selectFrom("virtualColumns")
    .select("id")
    .where("sheetId", "=", sheetId)
    .where("displayName", "=", displayName)
    .where("isActive", "=", true)
    .$if(!!excludeId, qb => qb.where("id", "!=", excludeId!))
    .executeTakeFirst();
  
  // Check for collisions with real columns
  const sheetConflict = await db
    .selectFrom("sheetColumns")
    .select("id")
    .where("sheetId", "=", sheetId)
    .where("columnName", "=", displayName)
    .where("isActive", "=", true)
    .executeTakeFirst();
  
  return Response.json({
    isValid: !virtualConflict && !sheetConflict,
    conflict: virtualConflict ? "virtual" : sheetConflict ? "sheet" : null
  });
}
```

---

## Future Considerations

### Why Full Refactor to IDs Is Not Recommended

**Architectural Reality**: The Google Sheets API is the source of truth for our data, and it provides data with column names as keys. Any attempt to use IDs instead would require:

1. **Transforming every record**: Converting all data to use IDs, which is computationally expensive
2. **Breaking Google Sheets integration**: We'd lose the direct mapping between Google Sheets and our data
3. **Complex synchronization**: Every sync would need bidirectional mapping between names and IDs
4. **Query complexity**: SQL queries on `rowData` JSON would need to resolve IDs to names
5. **No real benefit**: The collision problem still exists—we'd just move it to a different layer

### The Chosen Solution: Validation Over Refactoring

**Decision**: Rather than fight the architectural constraint, we embrace it and prevent collisions through validation.

**Rationale**:
- ✅ Simpler implementation
- ✅ Maintains Google Sheets compatibility
- ✅ Better performance (no transformation overhead)
- ✅ Clearer code (names are self-documenting)
- ✅ Prevents user confusion (names match what they see in Google Sheets)

### Ongoing Maintenance

**When creating new features involving columns:**

1. **Always validate column name uniqueness** before saving
2. **Always use safe lookup patterns** that handle duplicates
3. **Always prioritize virtual columns** in conflict resolution
4. **Document any new column-related code** with references to this document

### Preventing Future Bugs

**This documentation should be referenced when:**

- ✅ Creating or editing virtual columns
- ✅ Implementing new column-related features
- ✅ Debugging column lookup issues
- ✅ Onboarding new developers to the codebase
- ✅ Reviewing PRs that touch column logic
- ✅ Investigating data rendering inconsistencies

### Related Files and Locations

**Key files that implement these patterns:**

- `helpers/syncSheetData.tsx` - Converts Google Sheets data to records
- `helpers/virtualColumnCalculator.tsx` - Adds virtual columns to records
- `helpers/GoogleSheetsAPI.tsx` - Fetches data from Google Sheets
- `helpers/schema.tsx` - Type definitions for SheetColumns and VirtualColumns
- `components/MasterDetailRecordsList.tsx` - Example of safe column lookup
- `components/MasterDetailGroupedRecords.tsx` - Example of safe column lookup
- `endpoints/project/related-data_GET.ts` - Combines real and virtual columns

---

## Summary

**The Golden Rule**: Column names (not IDs) are the keys for data access because Google Sheets API requires it. Accept this constraint, validate to prevent collisions, and use safe lookup patterns that prioritize virtual columns.

This architectural decision is **permanent and unchangeable** without abandoning Google Sheets integration. All development must work within this constraint.
