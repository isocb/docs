# Concatenation Virtual Column - Detailed Implementation Plan

**Type:** Concatenation  
**Priority:** 1 of 3 (First Implementation)  
**Status:** Ready to Implement  
**Date:** 2025-11-13

---

## Overview

Implement a new virtual column type that concatenates (joins) multiple column values with optional prefix, separator, and suffix text.

---

## Requirements

### Functional Requirements
1. Select multiple source columns (minimum 1, no maximum)
2. Add optional prefix text before all columns
3. Add separator text between columns
4. Add optional suffix text after all columns
5. Handle null/empty values gracefully
6. Output as text data type

### Non-Functional Requirements
- Performance: No significant impact on data loading
- UI: Intuitive multi-select and text input interface
- Validation: Prevent saving without at least one column selected
- Error Handling: Gracefully handle missing columns or invalid data

---

## User Stories

**Story 1: Full Name Creation**
> As a user, I want to combine FirstName and LastName columns with a space separator, so I can display full names in reports.

**Configuration:**
- Columns: [FirstName, LastName]
- Separator: " "
- Result: "John Smith"

---

**Story 2: Team Label with Division**
> As a user, I want to create a label showing "Team: Eagles (U10)" by combining TeamName and Division with specific text around them.

**Configuration:**
- Prefix: "Team: "
- Columns: [TeamName, Division]
- Separator: " ("
- Suffix: ")"
- Result: "Team: Eagles (U10)"

---

**Story 3: Full Address**
> As a user, I want to build a complete address from Address1, City, and Postcode separated by commas.

**Configuration:**
- Columns: [Address1, City, Postcode]
- Separator: ", "
- Result: "123 High St, London, SW1A 1AA"

---

## Database Schema Changes

### SQL Migration

**Run in Neon SQL Editor:**

```sql
-- Add columns for concatenation configuration
ALTER TABLE virtual_columns 
ADD COLUMN IF NOT EXISTS concat_column_ids TEXT[],
ADD COLUMN IF NOT EXISTS concat_prefix TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS concat_separator TEXT DEFAULT ' ',
ADD COLUMN IF NOT EXISTS concat_suffix TEXT DEFAULT '';

-- Add comment for documentation
COMMENT ON COLUMN virtual_columns.concat_column_ids IS 'Array of column IDs to concatenate';
COMMENT ON COLUMN virtual_columns.concat_prefix IS 'Text to add before concatenated values';
COMMENT ON COLUMN virtual_columns.concat_separator IS 'Text to add between concatenated values';
COMMENT ON COLUMN virtual_columns.concat_suffix IS 'Text to add after concatenated values';
```

### Schema Type Updates

**File:** `helpers/schema.tsx`

**Find the VirtualColumns interface and add these fields:**

```typescript
export interface VirtualColumns {
  id: string;
  projectId: string;
  sheetId: string;
  displayName: string;
  expression: string | null;
  dataType: string;
  columnType: string; // 'formula' | 'regex' | 'concat'
  displayOrder: number;
  visible: boolean;
  isActive: boolean;
  errorMessage: string | null;
  sourceColumnId: string | null;
  regexPattern: string | null;
  regexReplacement: string | null;
  regexFlags: string | null;
  // NEW FIELDS for concatenation
  concatColumnIds: string[] | null;
  concatPrefix: string | null;
  concatSeparator: string | null;
  concatSuffix: string | null;
  createdAt: Generated<Timestamp | null>;
  updatedAt: Generated<Timestamp | null>;
}
```

---

## Backend Implementation

### Step 1: Update Virtual Column Calculator

**File:** `helpers/virtualColumnCalculator.tsx`

**Add concatenation function after the `applyRegex` function:**

```typescript
/**
 * Concatenate multiple column values with prefix, separator, and suffix
 */
function concatenateColumns(
  virtualColumn: Selectable<VirtualColumns>,
  rowData: Record<string, any>,
  columnIdToNameMap: Map<string, { name: string; dataType: string }>
): string {
  try {
    // Get configuration
    const columnIds = virtualColumn.concatColumnIds || [];
    const prefix = virtualColumn.concatPrefix || '';
    const separator = virtualColumn.concatSeparator || ' ';
    const suffix = virtualColumn.concatSuffix || '';

    if (columnIds.length === 0) {
      throw new Error('No columns selected for concatenation');
    }

    // Get values for each column
    const values: string[] = [];
    for (const columnId of columnIds) {
      try {
        const value = getColumnValue(columnId, rowData, columnIdToNameMap);
        
        // Convert to string, skip null/undefined/empty
        if (value !== null && value !== undefined && value !== '') {
          values.push(String(value));
        }
      } catch (error) {
        // Column not found or no value - skip it
        console.warn(`Column ${columnId} not found or empty, skipping in concatenation`);
      }
    }

    // If no values collected, return empty string
    if (values.length === 0) {
      return '';
    }

    // Build result: prefix + values.join(separator) + suffix
    const joined = values.join(separator);
    return prefix + joined + suffix;

  } catch (error) {
    throw new Error(`Concatenation error: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
```

**Update the main calculateVirtualColumn function:**

**Find this section (around line 178):**

```typescript
export function calculateVirtualColumn(
  virtualColumn: Selectable<VirtualColumns>,
  rowData: Record<string, any>,
  columnIdToNameMap: Map<string, { name: string; dataType: string }>
): any {
  try {
    if (virtualColumn.columnType === 'formula') {
      // ... existing formula code
    } else if (virtualColumn.columnType === 'regex') {
      // ... existing regex code
    }
    
    // ADD THIS NEW BLOCK:
    else if (virtualColumn.columnType === 'concat') {
      return concatenateColumns(virtualColumn, rowData, columnIdToNameMap);
    }
    
    // Unknown type
    return null;
```

---

### Step 2: Update POST Endpoint Schema

**File:** `endpoints/project/virtual-columns/_POST.schema.ts`

**Update the schema to include concat fields:**

```typescript
export const schema = z.object({
  id: z.string().optional(),
  projectId: z.string().min(1),
  sheetId: z.string().min(1),
  displayName: z.string().min(1),
  dataType: z.enum(['text', 'number', 'date', 'boolean', 'currency']),
  columnType: z.enum(['formula', 'regex', 'concat']), // Add 'concat'
  visible: z.boolean().default(true),
  isActive: z.boolean().default(true),
  
  // Formula fields
  expression: z.string().optional(),
  
  // Regex fields
  sourceColumnId: z.string().optional(),
  regexPattern: z.string().optional(),
  regexReplacement: z.string().optional(),
  regexFlags: z.string().optional(),
  
  // Concatenation fields - NEW
  concatColumnIds: z.array(z.string()).optional(),
  concatPrefix: z.string().optional(),
  concatSeparator: z.string().optional(),
  concatSuffix: z.string().optional(),
}).refine(
  (data) => {
    // Validate formula type has expression
    if (data.columnType === 'formula' && !data.expression) {
      return false;
    }
    // Validate regex type has required fields
    if (data.columnType === 'regex' && (!data.sourceColumnId || !data.regexPattern)) {
      return false;
    }
    // Validate concat type has at least one column - NEW
    if (data.columnType === 'concat' && (!data.concatColumnIds || data.concatColumnIds.length === 0)) {
      return false;
    }
    return true;
  },
  {
    message: "Formula requires expression. Regex requires sourceColumnId and regexPattern. Concat requires at least one column.",
  }
);
```

---

### Step 3: Update POST Endpoint Handler

**File:** `endpoints/project/virtual-columns/_POST.ts`

**Update the insert/update queries to include concat fields:**

**Find the insert query (around line 40-60) and add concat fields:**

```typescript
const newVirtualColumn = await db
  .insertInto('virtualColumns')
  .values({
    id: virtualColumnId,
    projectId: input.projectId,
    sheetId: input.sheetId,
    displayName: input.displayName,
    dataType: input.dataType,
    columnType: input.columnType,
    visible: input.visible,
    isActive: input.isActive,
    expression: input.expression || null,
    sourceColumnId: input.sourceColumnId || null,
    regexPattern: input.regexPattern || null,
    regexReplacement: input.regexReplacement || null,
    regexFlags: input.regexFlags || null,
    // ADD THESE:
    concatColumnIds: input.concatColumnIds || null,
    concatPrefix: input.concatPrefix || null,
    concatSeparator: input.concatSeparator || null,
    concatSuffix: input.concatSuffix || null,
  })
  .returningAll()
  .executeTakeFirstOrThrow();
```

**Find the update query and add the same fields:**

```typescript
const updatedVirtualColumn = await db
  .updateTable('virtualColumns')
  .set({
    displayName: input.displayName,
    dataType: input.dataType,
    columnType: input.columnType,
    visible: input.visible,
    isActive: input.isActive,
    expression: input.expression || null,
    sourceColumnId: input.sourceColumnId || null,
    regexPattern: input.regexPattern || null,
    regexReplacement: input.regexReplacement || null,
    regexFlags: input.regexFlags || null,
    // ADD THESE:
    concatColumnIds: input.concatColumnIds || null,
    concatPrefix: input.concatPrefix || null,
    concatSeparator: input.concatSeparator || null,
    concatSuffix: input.concatSuffix || null,
    updatedAt: sql`NOW()`,
  })
  .where('id', '=', input.id)
  .returningAll()
  .executeTakeFirstOrThrow();
```

---

## Frontend Implementation

### Step 4: Update VirtualColumnForm Component

**File:** `components/VirtualColumnForm.tsx`

**Add state for concatenation fields (around line 40):**

```typescript
// Existing state...
const [columnType, setColumnType] = useState<'formula' | 'regex' | 'concat'>('formula');

// Concatenation-specific state - NEW
const [concatColumnIds, setConcatColumnIds] = useState<string[]>([]);
const [concatPrefix, setConcatPrefix] = useState('');
const [concatSeparator, setConcatSeparator] = useState(' ');
const [concatSuffix, setConcatSuffix] = useState('');
```

**Update the useEffect that populates form when editing (around line 52-80):**

```typescript
useEffect(() => {
  if (virtualColumn) {
    setDisplayName(virtualColumn.displayName);
    setDataType(virtualColumn.dataType);
    setVisible(virtualColumn.visible);
    setIsActive(virtualColumn.isActive);
    setColumnType(virtualColumn.columnType as 'formula' | 'regex' | 'concat');

    if (virtualColumn.columnType === 'regex') {
      // ... existing regex logic
    } else if (virtualColumn.columnType === 'concat') {
      // NEW - populate concat fields
      setConcatColumnIds(virtualColumn.concatColumnIds || []);
      setConcatPrefix(virtualColumn.concatPrefix || '');
      setConcatSeparator(virtualColumn.concatSeparator || ' ');
      setConcatSuffix(virtualColumn.concatSuffix || '');
    } else if (virtualColumn.expression) {
      // ... existing formula logic
    }
  } else {
    // Reset form for new virtual column
    setColumnType('formula');
    setDisplayName('');
    setDataType('text'); // Concat defaults to text
    setVisible(true);
    setIsActive(true);
    setFormulaParts([]);
    setSourceColumnId('');
    setRegexPattern('');
    setRegexReplacement('');
    setRegexFlags('g');
    // NEW - reset concat fields
    setConcatColumnIds([]);
    setConcatPrefix('');
    setConcatSeparator(' ');
    setConcatSuffix('');
  }
}, [virtualColumn, isOpen]);
```

**Update the handleSubmit function (around line 100-150):**

```typescript
const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault();

  let expression: string | undefined = undefined;

  if (columnType === 'formula') {
    // ... existing formula logic
  }

  saveVirtualColumn(
    {
      id: virtualColumn?.id,
      projectId,
      sheetId,
      displayName,
      columnType,
      expression: columnType === 'formula' ? expression : undefined,
      dataType,
      visible,
      isActive,
      // Regex fields
      sourceColumnId: columnType === 'regex' ? sourceColumnId : undefined,
      regexPattern: columnType === 'regex' ? regexPattern : undefined,
      regexReplacement: columnType === 'regex' ? regexReplacement : undefined,
      regexFlags: columnType === 'regex' ? regexFlags : undefined,
      // NEW - Concat fields
      concatColumnIds: columnType === 'concat' ? concatColumnIds : undefined,
      concatPrefix: columnType === 'concat' ? concatPrefix : undefined,
      concatSeparator: columnType === 'concat' ? concatSeparator : undefined,
      concatSuffix: columnType === 'concat' ? concatSuffix : undefined,
    },
    {
      onSuccess: () => {
        onSuccess();
      },
    }
  );
};
```

**Add concat UI section in the form JSX (around line 250):**

```typescript
{/* Column Type Selector */}
<div className={styles.formField}>
  <label htmlFor="columnType" className={styles.label}>Column Type *</label>
  <Select value={columnType} onValueChange={(value) => setColumnType(value as 'formula' | 'regex' | 'concat')}>
    <SelectTrigger id="columnType">
      <SelectValue />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="formula">Formula (Math)</SelectItem>
      <SelectItem value="regex">Regex (Text Transform)</SelectItem>
      <SelectItem value="concat">Concatenation (Join Columns)</SelectItem>
    </SelectContent>
  </Select>
</div>

{/* ... existing formula and regex sections ... */}

{/* NEW - Concatenation Section */}
{columnType === 'concat' && (
  <>
    <div className={styles.formField}>
      <label className={styles.label}>Columns to Concatenate *</label>
      <p className={styles.helpText}>Select columns to join together</p>
      <div className={styles.multiSelect}>
        {availableColumns.map(col => (
          <label key={col.id} className={styles.checkboxLabel}>
            <input
              type="checkbox"
              checked={concatColumnIds.includes(col.id)}
              onChange={(e) => {
                if (e.target.checked) {
                  setConcatColumnIds([...concatColumnIds, col.id]);
                } else {
                  setConcatColumnIds(concatColumnIds.filter(id => id !== col.id));
                }
              }}
            />
            <span>{col.displayName || col.columnName}</span>
          </label>
        ))}
      </div>
      {concatColumnIds.length === 0 && (
        <p className={styles.errorText}>Please select at least one column</p>
      )}
    </div>

    <div className={styles.formField}>
      <label htmlFor="concatPrefix" className={styles.label}>Prefix Text (Optional)</label>
      <Input
        id="concatPrefix"
        value={concatPrefix}
        onChange={(e) => setConcatPrefix(e.target.value)}
        placeholder='e.g., "Team: "'
      />
      <p className={styles.helpText}>Text to add before all columns</p>
    </div>

    <div className={styles.formField}>
      <label htmlFor="concatSeparator" className={styles.label}>Separator *</label>
      <Input
        id="concatSeparator"
        value={concatSeparator}
        onChange={(e) => setConcatSeparator(e.target.value)}
        placeholder='e.g., " " or ", "'
        required
      />
      <p className={styles.helpText}>Text between each column (use " " for space)</p>
    </div>

    <div className={styles.formField}>
      <label htmlFor="concatSuffix" className={styles.label}>Suffix Text (Optional)</label>
      <Input
        id="concatSuffix"
        value={concatSuffix}
        onChange={(e) => setConcatSuffix(e.target.value)}
        placeholder='e.g., ")"'
      />
      <p className={styles.helpText}>Text to add after all columns</p>
    </div>

    <div className={styles.previewBox}>
      <strong>Preview Pattern:</strong>
      <div className={styles.previewText}>
        {concatPrefix}
        {concatColumnIds.map((id, index) => {
          const col = availableColumns.find(c => c.id === id);
          return (
            <span key={id}>
              {index > 0 && concatSeparator}
              <em>[{col?.displayName || col?.columnName || 'Column'}]</em>
            </span>
          );
        })}
        {concatSuffix}
      </div>
    </div>
  </>
)}
```

---

### Step 5: Add CSS Styles

**File:** `components/VirtualColumnForm.module.css`

**Add these styles at the end:**

```css
.multiSelect {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-2);
  max-height: 200px;
  overflow-y: auto;
  padding: var(--spacing-2);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  background-color: var(--surface-elevated);
}

.checkboxLabel {
  display: flex;
  align-items: center;
  gap: var(--spacing-2);
  cursor: pointer;
  padding: var(--spacing-1);
  border-radius: var(--radius-sm);
  transition: background-color var(--animation-duration-fast);
}

.checkboxLabel:hover {
  background-color: var(--muted);
}

.checkboxLabel input[type="checkbox"] {
  width: 16px;
  height: 16px;
  cursor: pointer;
}

.previewBox {
  padding: var(--spacing-3);
  background-color: var(--surface-elevated);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  margin-top: var(--spacing-2);
}

.previewText {
  font-family: monospace;
  font-size: 0.875rem;
  color: var(--muted-foreground);
  margin-top: var(--spacing-1);
}

.previewText em {
  color: var(--primary);
  font-style: normal;
  font-weight: 600;
}

.errorText {
  color: var(--destructive);
  font-size: 0.875rem;
  margin-top: var(--spacing-1);
}
```

---

## Testing Plan

### Test Case 1: Basic Two-Column Concatenation
**Input:**
- Columns: [FirstName, LastName]
- Prefix: ""
- Separator: " "
- Suffix: ""
- Sample Data: FirstName="John", LastName="Smith"

**Expected Output:** "John Smith"

---

### Test Case 2: Team Label with Prefix and Suffix
**Input:**
- Columns: [TeamName, Division]
- Prefix: "Team: "
- Separator: " ("
- Suffix: ")"
- Sample Data: TeamName="Eagles", Division="U10"

**Expected Output:** "Team: Eagles (U10)"

---

### Test Case 3: Address with Multiple Columns
**Input:**
- Columns: [Address1, City, Postcode]
- Prefix: ""
- Separator: ", "
- Suffix: ""
- Sample Data: Address1="123 High St", City="London", Postcode="SW1A 1AA"

**Expected Output:** "123 High St, London, SW1A 1AA"

---

### Test Case 4: Null/Empty Value Handling
**Input:**
- Columns: [FirstName, MiddleName, LastName]
- Separator: " "
- Sample Data: FirstName="John", MiddleName=null, LastName="Smith"

**Expected Output:** "John Smith" (skips null MiddleName)

---

### Test Case 5: All Null Values
**Input:**
- Columns: [Column1, Column2]
- Sample Data: Column1=null, Column2=null

**Expected Output:** "" (empty string)

---

### Test Case 6: Single Column
**Input:**
- Columns: [TeamName]
- Prefix: "Team: "
- Suffix: " Squad"
- Sample Data: TeamName="Eagles"

**Expected Output:** "Team: Eagles Squad"

---

## Deployment Steps

### Step-by-Step Deployment

1. **Database Migration**
   - Open Neon SQL Editor
   - Run the ALTER TABLE commands
   - Verify columns added: `SELECT * FROM virtual_columns LIMIT 1;`

2. **Update Schema Types**
   - Edit `helpers/schema.tsx`
   - Add concat fields to VirtualColumns interface
   - Commit: "Add concat fields to VirtualColumns schema"

3. **Backend Calculator**
   - Edit `helpers/virtualColumnCalculator.tsx`
   - Add concatenateColumns function
   - Update calculateVirtualColumn switch
   - Commit: "Add concatenation calculator logic"

4. **Backend Endpoint**
   - Edit `endpoints/project/virtual-columns/_POST.schema.ts`
   - Update validation schema
   - Edit `endpoints/project/virtual-columns/_POST.ts`
   - Update insert/update queries
   - Commit: "Add concat fields to virtual column POST endpoint"

5. **Frontend Form**
   - Edit `components/VirtualColumnForm.tsx`
   - Add state, UI, and submit handling
   - Edit `components/VirtualColumnForm.module.css`
   - Add styles
   - Commit: "Add concatenation UI to virtual column form"

6. **Deploy to Render**
   - Push to GitHub main branch
   - Wait for Render auto-deploy (2-3 minutes)
   - Check Render logs for errors

7. **Test in Production**
   - Navigate to project page
   - Go to Virtual Columns tab
   - Create new concat virtual column
   - Test with each test case above
   - Preview in master-detail view
   - Verify results

---

## Validation & Error Handling

### Form Validation
- At least one column must be selected
- Display name is required
- Separator defaults to space if empty

### Calculator Error Handling
- Missing column IDs → Skip gracefully
- Null/empty values → Skip in concatenation
- No valid values → Return empty string
- Column not found → Log warning, continue

### Edge Cases
- All columns null/empty → Return ""
- Single column selected → Works as expected
- Columns in different order → Respects order of selection
- Very long concatenated result → No truncation (full value returned)

---

## Rollback Plan

If issues are discovered after deployment:

1. **Disable all concat virtual columns:**
   ```sql
   UPDATE virtual_columns 
   SET is_active = false 
   WHERE column_type = 'concat';
   ```

2. **Revert code changes:**
   - Git revert the commits
   - Redeploy to Render

3. **Database cleanup (if needed):**
   ```sql
   -- Remove concat columns if rolling back entirely
   ALTER TABLE virtual_columns 
   DROP COLUMN IF EXISTS concat_column_ids,
   DROP COLUMN IF EXISTS concat_prefix,
   DROP COLUMN IF EXISTS concat_separator,
   DROP COLUMN IF EXISTS concat_suffix;
   ```

---

## Success Criteria

- ✅ User can create concat virtual column via UI
- ✅ Can select 1+ columns
- ✅ Can add prefix, separator, suffix text
- ✅ Preview shows expected pattern
- ✅ Virtual column appears in column list
- ✅ Calculated value shows in master-detail view
- ✅ Works with grouped data
- ✅ Works with ungrouped data
- ✅ Handles null values correctly
- ✅ No errors in browser console
- ✅ No errors in Render logs
- ✅ All 6 test cases pass

---

## Next Steps After Completion

1. Mark concatenation as ✅ Complete
2. Deploy to production
3. Test thoroughly with real data
4. Document any issues/learnings
5. Move to Currency Formatter implementation
6. Update main enhancement plan with status

---

**Implementation Start Date:** 2025-11-13  
**Estimated Completion:** 2-3 hours  
**Actual Completion:** _[To be filled]_
