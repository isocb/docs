# Virtual Columns UI/UX Enhancements Plan

**Created:** 2025-11-13  
**Status:** Planning  
**Priority:** Post-Concatenation Implementation

---

## Overview

This document outlines UI/UX enhancements for Virtual Columns display control. These features provide granular control over how virtual column data appears in tables while keeping the default UI simple for regular columns.

**Philosophy:** Regular columns maintain simplicity. Virtual columns offer advanced display controls for power users who need precise formatting.

---

## Enhancement 1: Column Data Alignment

### Purpose
Control text alignment (left, center, right) for virtual column values in table displays, similar to spreadsheet alignment options.

### Use Cases
- **Numbers/Currency:** Right-align for easy visual comparison of magnitudes
- **Text/Names:** Left-align (default) for readability
- **Status Indicators:** Center-align for visual balance
- **Dates:** Right or center-align for consistency

### Examples

```
DEFAULT (Left-aligned):
| Team Name       | Score | Status    |
|-----------------|-------|-----------|
| Manchester Utd  | 125   | Active    |
| Chelsea FC      | 98    | Active    |

WITH ALIGNMENT:
| Team Name       | Score | Status    |
|-----------------|-------|-----------|
| Manchester Utd  |   125 |  Active   |
| Chelsea FC      |    98 |  Active   |
  (left)           (right) (center)
```

---

### Configuration

**Database Field:**
```sql
ALTER TABLE virtual_columns 
ADD COLUMN text_align VARCHAR(10) DEFAULT 'left' 
CHECK (text_align IN ('left', 'center', 'right'));
```

**Form UI Addition:**
- Location: VirtualColumnForm, after Data Type selector
- Control: Dropdown/Select
- Options:
  - Left (default)
  - Center
  - Right
- Label: "Text Alignment"
- Help Text: "How values should align in the table"

**Default Behavior:**
- Text/Concat types → Left
- Number/Currency types → Right (automatic)
- Date types → Left
- Boolean types → Center

---

### Implementation Complexity: **MEDIUM (2-3 hours)**

**Files to Modify:**
1. **Database Migration** (5 min)
   - Add `text_align` column with constraint
   
2. **Schema Update** (5 min)
   - `helpers/schema.tsx` - Add `textAlign: string | null;`
   
3. **Form UI** (15 min)
   - `components/VirtualColumnForm.tsx` - Add alignment selector
   - Add state variable
   - Add to form submission
   - Add to edit mode loading
   
4. **POST Endpoint** (10 min)
   - `endpoints/project/virtual-columns/_POST.schema.ts` - Add validation
   - `endpoints/project/virtual-columns/_POST.ts` - Add to INSERT/UPDATE
   
5. **Display Logic** (60-90 min) - **COMPLEX PART**
   - Identify where virtual column data is rendered
   - Pass alignment metadata through data pipeline
   - Apply CSS classes based on alignment
   - Files likely affected:
     - `components/MasterDetailView.tsx`
     - `components/MasterDetailTable.tsx` (if exists)
     - `components/DataTable.tsx` (or equivalent)
   - Create CSS classes for alignment
   
6. **Testing** (30 min)
   - Test in master-detail view
   - Test with grouped data
   - Test with different data types
   - Verify CSV export (alignment may not apply)

---

### Technical Approach

**Data Flow:**
```
1. Virtual Column Config (text_align: 'right')
   ↓
2. Virtual Column Calculator (adds value to row)
   ↓
3. Data Row (needs alignment metadata)
   ↓
4. Table Renderer (applies CSS class)
   ↓
5. Display (text visually aligned)
```

**Challenge:** Virtual columns currently just add values to rows. Need to pass metadata too.

**Solution Options:**

**Option A: Column Metadata Map**
```typescript
// Pass alongside data
const columnMetadata = {
  [virtualColumn.displayName]: {
    align: 'right',
    width: 'auto'
  }
};
```

**Option B: CSS Class on Table Cells**
```typescript
// In table rendering
<td className={getAlignmentClass(columnName)}>
  {value}
</td>
```

**Recommended:** Option B (simpler, less refactoring)

---

## Enhancement 2: Column Width Override

### Purpose
Allow virtual columns to expand to full width of their content, preventing truncation of important data.

### Use Cases
- **Long Text Concatenations:** "Team: Manchester United Youth Academy U10 Division A"
- **Full Addresses:** "123 Very Long Street Name, Suburb, City, Postcode"
- **Descriptions:** Multi-word generated descriptions
- **IDs/Codes:** Long reference numbers that shouldn't wrap

### Examples

```
DEFAULT (Truncated):
| Team Label          | Score |
|---------------------|-------|
| Team: Manchester... | 125   |
| Team: Chelsea FC... | 98    |

WITH WIDTH OVERRIDE (Full Width):
| Team Label                                    | Score |
|-----------------------------------------------|-------|
| Team: Manchester United Youth Academy U10 Div | 125   |
| Team: Chelsea FC Under 10s Premier League     | 98    |
```

---

### Configuration

**Database Field:**
```sql
ALTER TABLE virtual_columns 
ADD COLUMN column_width VARCHAR(20) DEFAULT 'auto' 
CHECK (column_width IN ('auto', 'fit-content', 'full'));
```

**Form UI Addition:**
- Location: VirtualColumnForm, near alignment setting
- Control: Dropdown/Select
- Options:
  - Auto (default) - Standard column width
  - Fit Content - Expand to widest content
  - Full - Take all available space
- Label: "Column Width"
- Help Text: "How much horizontal space this column should take"

**Behavior:**
- **Auto:** Standard table column width (default)
- **Fit Content:** Column expands to accommodate longest value (no truncation)
- **Full:** Column takes maximum available width (rare use case)

---

### Implementation Complexity: **MEDIUM (2-3 hours)**

**Files to Modify:**
1. **Database Migration** (5 min)
   - Add `column_width` column with constraint
   
2. **Schema Update** (5 min)
   - `helpers/schema.tsx` - Add `columnWidth: string | null;`
   
3. **Form UI** (15 min)
   - `components/VirtualColumnForm.tsx` - Add width selector
   
4. **POST Endpoint** (10 min)
   - Update schema and handler
   
5. **Display Logic** (60-90 min)
   - Apply width styles to table columns
   - CSS classes for width behaviors
   - Handle responsive behavior (mobile)
   - Prevent table breaking on very wide content
   
6. **CSS Styling** (30 min)
   - Define width classes
   - Handle text overflow
   - Ensure table remains usable
   
7. **Testing** (30 min)
   - Test with various content lengths
   - Test responsive behavior
   - Verify table doesn't break layout

---

### Technical Approach

**CSS Classes:**
```css
.column-width-auto {
  width: auto;
  max-width: 200px; /* Prevent excessive width */
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.column-width-fit-content {
  width: fit-content;
  min-width: 150px;
  max-width: none;
  white-space: normal;
  word-break: break-word;
}

.column-width-full {
  width: 100%;
}
```

**Considerations:**
- Very long content can break table layouts
- Need max-width safeguards
- Mobile responsiveness crucial
- Horizontal scroll may be needed for fit-content

---

## Enhancement 3: Show/Hide Column Headers Toggle

### Purpose
Give users control over whether column headers are displayed in table views, allowing for cleaner, more compact displays when headers are obvious or unnecessary.

### Use Cases
- **Embedded Views:** When table is embedded and context is clear
- **Single-Column Displays:** Header is redundant
- **Print/Export:** Cleaner output without headers
- **Dashboard Cards:** Compact data display
- **Mobile Views:** Save vertical space

### Examples

```
WITH HEADERS (Default):
┌─────────────┬───────┬────────┐
│ Team Name   │ Score │ Status │
├─────────────┼───────┼────────┤
│ Manchester  │ 125   │ Active │
│ Chelsea FC  │ 98    │ Active │
└─────────────┴───────┴────────┘

WITHOUT HEADERS:
┌─────────────┬───────┬────────┐
│ Manchester  │ 125   │ Active │
│ Chelsea FC  │ 98    │ Active │
└─────────────┴───────┴────────┘
```

---

### Configuration

**Scope:** This is a **view-level setting**, not a per-virtual-column setting.

**Storage Location Options:**

**Option A: Relationship Configuration**
```typescript
// In sheet_relationships table
{
  fieldDisplayConfig: {
    showColumnHeaders: boolean; // Default: true
  }
}
```

**Option B: User Preference**
```typescript
// In user preferences or view state
{
  tableView: {
    showHeaders: boolean;
  }
}
```

**Option C: Project Analysis Config**
```typescript
// In project_analysis_config table
{
  configuration: {
    tableDisplayConfig: {
      showHeaders: boolean;
    }
  }
}
```

**Recommended:** Option A (Relationship Configuration)
- Makes sense with other field display settings
- Per-relationship control
- Persisted across sessions
- Clear data model

---

### UI Location

**Primary Location:** Relationship Configuration Panel
- Tab: Field Display or Configuration
- Control: Checkbox/Toggle
- Label: "Show Column Headers"
- Default: Checked (true)
- Help Text: "Display column names at the top of the table"

**Secondary Location (Optional):** View Controls
- Inline toggle in master-detail view
- Quick show/hide without opening config
- Saves to relationship config on change

---

### Implementation Complexity: **LOW-MEDIUM (1-2 hours)**

**Files to Modify:**

1. **Database/Schema** (10 min)
   - Update `fieldDisplayConfig` type definition
   - No migration needed (JSON field)
   
2. **Relationship Config UI** (20 min)
   - Add toggle to `RelationshipAccordionItem` or config panel
   - Add state management
   - Include in save payload
   
3. **Display Logic** (30-60 min)
   - Conditionally render `<thead>` in table components
   - Pass `showHeaders` prop through component tree
   - Handle grouped vs ungrouped displays
   - Ensure data still renders correctly without headers
   
4. **CSS Adjustments** (15 min)
   - Ensure table styling works with/without headers
   - Border adjustments if needed
   
5. **Testing** (20 min)
   - Test with headers on
   - Test with headers off
   - Test in different view modes (grouped/ungrouped)
   - Verify export behavior (may need headers even if hidden)

---

### Technical Approach

**Data Flow:**
```
1. User toggles "Show Column Headers" in relationship config
   ↓
2. Setting saved in sheet_relationships.fieldDisplayConfig
   ↓
3. Frontend loads relationship configuration
   ↓
4. Table component receives showHeaders prop
   ↓
5. Conditionally renders <thead> section
```

**Component Pattern:**
```typescript
// In MasterDetailTable or equivalent
<table>
  {showHeaders && (
    <thead>
      <tr>
        {columns.map(col => <th key={col.id}>{col.name}</th>)}
      </tr>
    </thead>
  )}
  <tbody>
    {/* data rows */}
  </tbody>
</table>
```

**Considerations:**
- Accessibility: Screen readers may need headers even if visually hidden
- Exports: CSV/Excel exports should probably always include headers
- Sorting: Column sorting UI typically in headers - need alternative if hidden
- Responsive: Mobile views may benefit from hidden headers

---

## Implementation Priority

### Recommended Order

**Phase 1: Core Virtual Column Types (Current)**
1. ✅ Formula (Completed)
2. ✅ Regex (Completed)
3. ✅ Concatenation (Completed)
4. ⏳ Currency Formatter (Next)
5. ⏳ Date Formatter (After Currency)

**Phase 2: Display Control (This Plan)**
6. **Alignment** - Most impactful, needed for numbers/currency
7. **Column Width Override** - Important for concatenation results
8. **Show/Hide Headers** - Nice-to-have, enhances flexibility

**Rationale:**
- Complete core data transformation features first
- Then add display controls to make outputs look professional
- Headers toggle is least critical (can be last)

---

## Combined Implementation Estimate

| Feature | Complexity | Time Estimate |
|---------|------------|---------------|
| Text Alignment | Medium | 2-3 hours |
| Column Width Override | Medium | 2-3 hours |
| Show/Hide Headers | Low-Medium | 1-2 hours |
| **Total** | - | **5-8 hours** |

**If done together:** ~7 hours (some shared work)

---

## User Experience Design

### VirtualColumnForm - New Section

**Location:** After "Data Type" field

```
┌─────────────────────────────────────────────┐
│ Data Type *                                 │
│ [Number ▼]                                  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Display Options                              │
├─────────────────────────────────────────────┤
│ Text Alignment                              │
│ [Left ▼]                                    │
│ ℹ How values should align in the table      │
│                                             │
│ Column Width                                │
│ [Auto ▼]                                    │
│ ℹ How much horizontal space to take         │
└─────────────────────────────────────────────┘
```

**Collapsible Section (Optional):**
Could make "Display Options" an expandable section to reduce form clutter for users who don't need these controls.

---

### Relationship Config - Headers Toggle

**Location:** In Field Display configuration panel

```
┌─────────────────────────────────────────────┐
│ Table Display Options                        │
├─────────────────────────────────────────────┤
│ ☑ Show Column Headers                       │
│ ℹ Display column names at the top of table  │
└─────────────────────────────────────────────┘
```

---

## Testing Checklist

### Alignment Testing
- [ ] Left-aligned text displays correctly
- [ ] Right-aligned numbers display correctly
- [ ] Center-aligned status displays correctly
- [ ] Alignment persists after save
- [ ] Alignment works in grouped data
- [ ] Alignment works in ungrouped data
- [ ] Alignment setting loads correctly when editing
- [ ] Multiple virtual columns with different alignments work together

### Width Override Testing
- [ ] Auto width behaves like standard columns
- [ ] Fit-content expands for long text
- [ ] Fit-content doesn't break table layout
- [ ] Full width takes available space
- [ ] Responsive behavior on mobile works
- [ ] Long text wraps appropriately
- [ ] Table remains horizontally scrollable if needed
- [ ] Width setting persists after save

### Headers Toggle Testing
- [ ] Headers show by default
- [ ] Headers hide when toggled off
- [ ] Data still displays correctly without headers
- [ ] Setting persists after save
- [ ] Works with grouped data
- [ ] Works with ungrouped data
- [ ] Sorting still works (if applicable)
- [ ] CSV export includes headers regardless of toggle

### Integration Testing
- [ ] All three features work together
- [ ] Performance is acceptable with multiple virtual columns
- [ ] No conflicts with regular columns
- [ ] Export functionality still works
- [ ] Print view looks correct
- [ ] Mobile view is usable

---

## Database Schema Summary

**All new fields in `virtual_columns` table:**

```sql
-- Alignment (Enhancement 1)
ALTER TABLE virtual_columns 
ADD COLUMN text_align VARCHAR(10) DEFAULT 'left' 
CHECK (text_align IN ('left', 'center', 'right'));

-- Width Override (Enhancement 2)
ALTER TABLE virtual_columns 
ADD COLUMN column_width VARCHAR(20) DEFAULT 'auto' 
CHECK (column_width IN ('auto', 'fit-content', 'full'));

-- Comments for documentation
COMMENT ON COLUMN virtual_columns.text_align IS 'Text alignment in table display: left, center, or right';
COMMENT ON COLUMN virtual_columns.column_width IS 'Column width behavior: auto, fit-content, or full';
```

**Headers toggle:** Stored in existing `sheet_relationships.fieldDisplayConfig` JSON field (no migration needed)

---

## TypeScript Schema Updates

**File:** `helpers/schema.tsx`

```typescript
export interface VirtualColumns {
  id: string;
  projectId: string;
  sheetId: string;
  displayName: string;
  expression: string | null;
  dataType: string;
  columnType: string;
  displayOrder: number;
  visible: boolean;
  isActive: boolean;
  errorMessage: string | null;
  sourceColumnId: string | null;
  regexPattern: string | null;
  regexReplacement: string | null;
  regexFlags: string | null;
  concatColumnIds: string[] | null;
  concatPrefix: string | null;
  concatSeparator: string | null;
  concatSuffix: string | null;
  // NEW DISPLAY CONTROL FIELDS
  textAlign: 'left' | 'center' | 'right' | null;
  columnWidth: 'auto' | 'fit-content' | 'full' | null;
  createdAt: Generated<Timestamp | null>;
  updatedAt: Generated<Timestamp | null>;
}
```

---

## Known Limitations & Considerations

### Alignment
- CSV/Excel exports may not preserve alignment (export formats handle this differently)
- Screen readers use text content, not visual alignment
- Very short columns may not show alignment difference clearly

### Column Width
- Fit-content can cause horizontal scroll on narrow screens
- Very long content (>500 characters) may still need truncation
- Performance impact minimal unless hundreds of columns

### Headers Toggle
- Sorting UI typically lives in headers - may need alternative control
- Accessibility tools may need hidden headers for context
- Print view may need headers even when hidden in UI

---

## Future Enhancements (Not in Scope)

**Out of scope for this plan, but possible future work:**

1. **Per-User Display Preferences**
   - Let each user customize alignment/width for themselves
   - Requires user preferences table
   
2. **Column Reordering**
   - Drag-and-drop column order
   - Separate from display order
   
3. **Conditional Formatting**
   - Color-code values based on rules
   - Icons/badges for status
   
4. **Column Grouping**
   - Group related columns under headers
   - Nested headers
   
5. **Freeze Columns**
   - Keep first N columns visible while scrolling
   - Excel-style freeze panes

---

## Success Criteria

**Alignment:**
- ✅ User can set alignment per virtual column
- ✅ Alignment displays correctly in all table views
- ✅ Setting persists across sessions
- ✅ Default alignment makes sense for data type

**Column Width:**
- ✅ User can control column width behavior
- ✅ Fit-content prevents truncation of long text
- ✅ Table remains usable on all screen sizes
- ✅ No performance degradation

**Headers Toggle:**
- ✅ User can show/hide headers per relationship
- ✅ Data remains readable without headers
- ✅ Setting persists across sessions
- ✅ Exports still include headers

---

## Documentation Updates Needed

After implementation:

1. Update `context/specific_instructions.md` with display control features
2. Add examples to `virtual-columns-enhancement-plan.md`
3. Update user documentation (if exists) with new options
4. Add screenshots showing alignment/width examples

---

## Rollback Plan

If issues arise after deployment:

**Alignment:**
```sql
-- Disable by resetting to default
UPDATE virtual_columns SET text_align = 'left';
```

**Width:**
```sql
-- Disable by resetting to default
UPDATE virtual_columns SET column_width = 'auto';
```

**Headers:**
```sql
-- Re-enable headers in all relationships
UPDATE sheet_relationships 
SET field_display_config = jsonb_set(
  COALESCE(field_display_config, '{}'::jsonb),
  '{showColumnHeaders}',
  'true'::jsonb
);
```

**Code Rollback:**
- Git revert commits
- Redeploy previous version
- Database fields remain but unused (harmless)

---

**Last Updated:** 2025-11-13  
**Status:** Ready for Implementation  
**Prerequisites:** Concatenation must be complete (✅)
