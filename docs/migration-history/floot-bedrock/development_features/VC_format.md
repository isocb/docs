# Virtual Columns Enhancement Plan

**Created:** 2025-11-13  
**Status:** In Progress  
**Phase:** Concatenation Implementation

---

## Overview

This document outlines the plan to enhance the Virtual Columns feature with additional calculator types beyond the existing Formula and Regex types.

---

## Current Implementation

### Existing Virtual Column Types
1. **Formula** - Mathematical calculations using operators (+, -, *, /, %)
2. **Regex** - Text pattern matching and extraction/replacement

### Existing Data Types
- `text`
- `number`
- `date`
- `boolean`
- `currency`

### Architecture
- **Database:** `virtual_columns` table in PostgreSQL
- **Calculator:** `helpers/virtualColumnCalculator.tsx`
- **UI:** `components/VirtualColumnForm.tsx`
- **Integration:** Applied in `endpoints/project/related-data_GET.ts`

---

## Enhancement Scope

### Priority 1: Core Three Types (Immediate Implementation)

#### 1. CONCATENATION - Completed tested and deployed.
**Purpose:** Join multiple column values with custom text separators

**Configuration:**
- Multiple source columns (multi-select)
- Prefix text (optional) - text before all columns
- Separator text - text between each column
- Suffix text (optional) - text after all columns

**Use Cases:**
- Combine first and last names: `FirstName + " " + LastName` → "John Smith"
- Build team labels: `"Team: " + TeamName + " (" + Division + ")"` → "Team: Eagles (U10)"
- Create full addresses: `Address1 + ", " + City + ", " + Postcode`

**Output Data Type:** `text`

---
#### 1A. COLUMN WIDTH FORMATTER (Current next step)

#### 2. CURRENCY FORMATTER
**Purpose:** Format numbers as currency or extract numbers from currency strings

**Configuration:**
- Source column (number or currency type)
- Operation mode:
  - **To Currency**: Format number → currency display
  - **From Currency**: Extract number from currency string
- Currency symbol selector (£, $, €, ¥, etc.)
- Currency symbol position (before/after)
- Decimal places (0-4, default 2)
- Thousands separator (, or .)

**Use Cases:**
- Display prices: `1234.56` → "£1,234.56"
- Extract amounts: "£1,234.56" → 1234.56
- Convert between formats: "$1,234.56" → "£1,234.56"

**Output Data Type:** 
- `currency` (when formatting to currency)
- `number` (when extracting from currency)

---

#### 3. DATE FORMATTER
**Purpose:** Reformat date columns to different display formats

**Configuration:**
- Source date column
- Output format selector:
  - `DD/MM/YYYY` → 13/11/2025 (UK default)
  - `MM/DD/YYYY` → 11/13/2025 (US format)
  - `YYYY-MM-DD` → 2025-11-13 (ISO/UTC)
  - `DD MMM YYYY` → 13 Nov 2025
  - `D MMMM YYYY` → 13 November 2025
  - `ddd, DD MMM YYYY` → Wed, 13 Nov 2025
  - `Relative` → "2 days ago"
  - `ISO 8601` → 2025-11-13T14:14:44Z
  - Custom format string (for advanced users)

**Use Cases:**
- UK display: `2025-11-13` → "13/11/2025"
- Friendly dates: `2025-11-13` → "13 November 2025"
- Relative time: `2025-11-11` → "2 days ago"

**Output Data Type:** `text` or `date`

**Library:** Use `date-fns` (already in dependencies)

---

### Priority 2: Future Enhancement Types (Deferred)

#### 4. CONDITIONAL
**Purpose:** Return different values based on conditions (IF/THEN/ELSE logic)

**Complexity:** **Medium-High**
- Requires condition parser and evaluator
- Needs UI for building conditions (comparison operators, values)
- Must handle multiple data types in conditions
- May need nested conditions (AND/OR logic)

**Estimated Effort:** 3-4 hours

**Configuration:**
- Source column to evaluate
- Condition operator (equals, not equals, greater than, less than, contains, starts with, etc.)
- Comparison value
- Value if condition is true
- Value if condition is false

**Use Cases:**
- Age categories: IF Age > 10 THEN "Over 10" ELSE "Under 10"
- Status indicators: IF Status = "Active" THEN "✓" ELSE "✗"
- Grade calculation: IF Score >= 80 THEN "Pass" ELSE "Fail"

**Output Data Type:** Varies based on return values (text, number, boolean)

**Implementation Notes:**
- Start with simple equality/comparison operators
- Support single condition first, extend to AND/OR later
- Consider using expression evaluator library or build custom parser
- UI complexity: condition builder with dropdowns and value inputs

---

#### 5. LOOKUP
**Purpose:** Look up values from another column based on matching criteria

**Complexity:** **High**
- Requires access to other row data (cross-row operations)
- May have performance implications with large datasets
- Needs clear match strategy (first match, exact match, etc.)
- UI complexity for selecting lookup/return columns

**Estimated Effort:** 4-5 hours

**Configuration:**
- Source column (value to match)
- Lookup column (where to search)
- Return column (what value to return)
- Match type (exact, contains, starts with)
- Default value if no match found

**Use Cases:**
- Team lookup: TeamID → TeamName
- Contact lookup: UserID → Email
- Category lookup: Code → Description

**Output Data Type:** Varies based on return column type

**Implementation Notes:**
- Current virtual column calculator works row-by-row
- Lookup requires access to other rows in dataset
- May need to pass full dataset to calculator, not just single row
- Consider performance with large datasets (thousands of rows)
- Possible alternative: Use relationship features instead

**Recommendation:** Evaluate if existing relationship/join features can solve the use case before implementing lookup virtual columns.

---

## Implementation Strategy

### Approach
**Sequential Implementation:** Complete one type fully before starting the next

1. **Concatenation** → Complete, test, deploy
2. **Currency Formatter** → Complete, test, deploy  
3. **Date Formatter** → Complete, test, deploy
4. **Conditional** → Future (as needed)
5. **Lookup** → Future (evaluate necessity)

### Testing Strategy
After each type implementation:
1. Create test virtual column in UI
2. Apply to sample data
3. Preview in master-detail view
4. Test edge cases (null values, empty strings, invalid data)
5. Verify data type handling
6. Check performance with realistic data volume

---

## Technical Architecture

### Database Schema Extensions

**New columns needed in `virtual_columns` table:**

```sql
-- For concatenation type
ALTER TABLE virtual_columns 
ADD COLUMN concat_column_ids TEXT[],    -- Array of column IDs to concatenate
ADD COLUMN concat_prefix TEXT,          -- Text before all columns
ADD COLUMN concat_separator TEXT,       -- Text between columns
ADD COLUMN concat_suffix TEXT;          -- Text after all columns

-- For currency type
ALTER TABLE virtual_columns
ADD COLUMN currency_symbol VARCHAR(10),  -- £, $, €, etc.
ADD COLUMN currency_position VARCHAR(10), -- 'before' or 'after'
ADD COLUMN currency_decimals INTEGER,    -- 0-4
ADD COLUMN currency_thousands_sep VARCHAR(5); -- ',' or '.'

-- For date formatter type
ALTER TABLE virtual_columns
ADD COLUMN date_format TEXT;             -- Format string or preset name
```

### Calculator Pattern

```typescript
// In helpers/virtualColumnCalculator.tsx
export function calculateVirtualColumn(
  virtualColumn: Selectable<VirtualColumns>,
  rowData: Record<string, any>,
  columnIdToNameMap: Map<string, { name: string; dataType: string }>
): any {
  try {
    if (virtualColumn.columnType === 'formula') {
      return evaluateFormula(/*...*/);
    } else if (virtualColumn.columnType === 'regex') {
      return applyRegex(/*...*/);
    } else if (virtualColumn.columnType === 'concat') {
      return concatenateColumns(virtualColumn, rowData, columnIdToNameMap);
    } else if (virtualColumn.columnType === 'currency') {
      return formatCurrency(virtualColumn, rowData, columnIdToNameMap);
    } else if (virtualColumn.columnType === 'dateFormat') {
      return formatDate(virtualColumn, rowData, columnIdToNameMap);
    }
    return null;
  } catch (error) {
    console.error('Virtual column calculation error:', error);
    return null;
  }
}
```

### Form UI Pattern

```typescript
// In components/VirtualColumnForm.tsx
const [columnType, setColumnType] = useState<'formula' | 'regex' | 'concat' | 'currency' | 'dateFormat'>('formula');

// Type-specific state
const [concatColumnIds, setConcatColumnIds] = useState<string[]>([]);
const [concatPrefix, setConcatPrefix] = useState('');
const [concatSeparator, setConcatSeparator] = useState(' ');
const [concatSuffix, setConcatSuffix] = useState('');

// Render type-specific form sections
{columnType === 'concat' && (
  <div className={styles.concatSection}>
    {/* Multi-select for columns */}
    {/* Text inputs for prefix, separator, suffix */}
  </div>
)}
```

---

## Data Type Enhancements

### Number Type Enhancement
**Add decimal place configuration:**
- Allow users to specify decimal places for number display
- Default: 2 decimal places
- Range: 0-10 decimal places

**Fields needed:**
```sql
ALTER TABLE virtual_columns
ADD COLUMN number_decimals INTEGER DEFAULT 2;
```

**Example:**
- Value: 123.456789
- Decimals: 2 → "123.46"
- Decimals: 0 → "123"
- Decimals: 4 → "123.4568"

---

## Known Issues & Fixes

### Regex Extraction Bug (FIXED)
**Problem:** Pattern `U(\d+)` with replacement `$1` returned full source text instead of captured group.

**Root Cause:** The `applyRegex` function used `replace()` which affected the whole string, not just the match.

**Solution:** Detect "pure extraction" patterns (like `$1`, `$2`) and return only captured groups.

**Status:** Fix provided in previous response, needs deployment.

---

## Dependencies

### Required npm Packages
- ✅ `date-fns` - Already installed (v2.30.0+)
- ✅ `lucide-react` - Already installed (icons)
- ✅ `zod` - Already installed (validation)

### No New Dependencies Needed
All functionality can be implemented with existing libraries.

---

## Deployment Checklist

For each new type implementation:
- [ ] Database migration applied (Neon SQL Editor)
- [ ] Schema types updated (`helpers/schema.tsx`)
- [ ] Calculator logic implemented (`helpers/virtualColumnCalculator.tsx`)
- [ ] Form UI updated (`components/VirtualColumnForm.tsx`)
- [ ] Endpoint schema updated if needed
- [ ] Committed to Git with clear message
- [ ] Deployed to Render
- [ ] Tested in production with real data
- [ ] Edge cases verified
- [ ] Documentation updated

---

## Success Criteria

### Concatenation
- ✅ Can select multiple columns
- ✅ Can add prefix, separator, suffix text
- ✅ Handles null/empty values gracefully
- ✅ Outputs correct concatenated text
- ✅ Works with both grouped and ungrouped data

### Currency Formatter
- ✅ Can format numbers to currency with symbol
- ✅ Symbol position configurable (before/after)
- ✅ Decimal places configurable (0-4)
- ✅ Thousands separator works correctly
- ✅ Can extract numbers from currency strings
- ✅ Multiple currency symbols supported

### Date Formatter
- ✅ Can reformat dates to common formats
- ✅ UK format (DD/MM/YYYY) is default
- ✅ Supports international formats (US, ISO, UTC)
- ✅ Handles relative dates ("2 days ago")
- ✅ Custom format strings work
- ✅ Invalid dates handled gracefully

---

## Timeline Estimate

| Type | Estimated Time | Complexity |
|------|----------------|------------|
| Concatenation | 2-3 hours | Low-Medium |
| Currency Formatter | 2-3 hours | Medium |
| Date Formatter | 2-3 hours | Medium |
| **Total Priority 1** | **6-9 hours** | - |
| Conditional (Future) | 3-4 hours | Medium-High |
| Lookup (Future) | 4-5 hours | High |

---

## Notes

- All virtual columns calculated on-the-fly (not stored in database)
- Performance impact should be monitored with large datasets
- Each type should be independently testable
- Form UI should be intuitive and provide clear examples
- Error messages should guide users to correct configuration

---

**Last Updated:** 2025-11-13  
**Next Review:** After each type completion
