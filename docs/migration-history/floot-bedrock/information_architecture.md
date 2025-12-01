# Bedrock Information Architecture
**Version:** 2.0  
**Date:** 2025-11-18  
**Status:** Proposed Design  
**Author:** Chris (BA/Product Owner)

---

## Overview

This document defines the conceptual model and information architecture for how Bedrock handles data from input through to display. It establishes a clear, linear flow that eliminates confusion and redundancy.  Here Google sheets is used as a metaphor for the data source.  Bedrock is the reporting engine of Isostack and is the first application of IsoStack.  Bedrock is to become the IsoStack Template.  Bedrock functions will be a switchable function in the owner dashboard ie it will be possible for the owner to switch all of the bedrock functionality off in the owner dashboard and enable or disable it per tenant.

---

## Design Principles

1. **Single Source of Truth** - Each configuration should exist in only one place
2. **Clear Data Flow** Selcet Soure - Input → Transform → Configure → Output
3. **Read vs. Write Separation** - Distinguish between "what we received" vs. "what we're doing with it"
4. **Progressive Disclosure** - Simple first, complexity when needed
5. **Explicit State** - Users should always know what data has been detected and validated

---

## Information Architecture




### The Data Journey

```
┌─────────────────────────┐
│  Data Connector         │ (Internal / External source)
└────────┬────────────────┘
         │
         ↓
┌─────────────────┐
│  1. SHEETS TAB  │ (Read-only validation)
│  "Data Input"   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  2. VIRTUAL     │ (Optional transformations)
│     COLUMNS     │
│  "Manipulation" │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  3. DISPLAY &   │ (Configuration for output)
│     ANALYSIS    │
│  "Output Setup" │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   End User      │
│   Data View     │
└─────────────────┘
```

---

## Tab 1: Sheets (Data Input)

### Purpose
Show users what data Bedrock has successfully read from their Google Sheets/ Internal Source. This is a **confirmation and validation** screen, not a configuration screen.

### User Mental Model
*"These are the sheets/Tables I've connected. This is what Bedrock found in them. Everything looks correct."*

### Layout Structure

#### Accordion Format
- **Accordion Header (Collapsed State):**
  - Sheet name (e.g., "Customer Data 2024")
  - Status indicator (✓ Synced, ⚠ Warning, ✗ Error)
  - Last sync timestamp
  - Column count badge (e.g., "12 columns detected")
  - Row count (e.g., "1,247 rows")

- **Accordion Content (Expanded State):**
  - **Column List Table** (read-only)
    - Column name (as it appears in Table/Google Sheet)
    - Detected data type (text, number, date, currency, boolean)
    - Sample values (first 3 non-empty values)
    - Nullable indicator (if column has empty cells)
  
  - **Sheet Metadata Section:**
    - Google Sheet ID
    - Sheet tab name
    - Connected date
    - Last updated timestamp
    - Data range (e.g., "A1:Z1247")
  
  - **Sync Controls:**
    - "Refresh Now" button (manual sync)
    - Auto-sync toggle (if enabled)
    - "View in Google Sheets" link

### What Users CANNOT Do Here
- ❌ Rename columns for display
- ❌ Hide/show columns
- ❌ Change data types
- ❌ Reorder columns
- ❌ Delete columns

### What Users CAN Do Here
- ✅ See confirmation that data was read correctly
- ✅ Verify data types are detected accurately
- ✅ Spot errors in source data (wrong formats, missing values)
- ✅ Manually trigger a refresh
- ✅ View sample data to confirm content
- ✅ Jump to Google Sheet to fix source issues

### Design Notes
- **Read-only** - All fields are displayed as text, not inputs
- **Diagnostic** - Help users troubleshoot connection issues
- **Reassurance** - "Your data is here and we understand it"

---

## Tab 2: Virtual Columns (Data Manipulation)

### Purpose
Create calculated, transformed, or combined columns based on the incoming data from Sheets. These are **new columns** that don't exist in Google Sheets.

### User Mental Model
*"I need to create a 'Full Name' column by combining First Name and Last Name"* or *"I want to calculate a discount percentage based on two price columns."*

### Functionality (Existing - No Major Changes)

**Virtual Column Types:**
1. **Formula** - Mathematical operations (+, -, *, /, %)
2. **Regex** - Pattern matching and text extraction
3. **Concatenation** - Combining multiple columns with separators
4. **Currency Formatter** - Format numbers as currency or extract amounts
5. **Date Formatter** - Reformat dates to different display formats

**Configuration Per Virtual Column:**
- Column name/label
- Data type (output type)
- Calculator type (formula, regex, concat, etc.)
- Source columns (which incoming columns to use)
- Calculation rules/formula
- Text alignment (for display)

### Relationship to Other Tabs
- **Input:** Uses columns from Sheets tab
- **Output:** Virtual columns appear in Display & Analysis tab alongside real columns
- Virtual columns can be included/excluded, reordered, and relabeled just like real columns

### Design Notes
- Virtual columns are **computed at query time** (not stored in Google Sheets)
- Changes to source data automatically update virtual columns
- Virtual columns can reference other virtual columns (if dependencies are clear)

---

## Tab 3: Display & Analysis (Output Configuration)

### New Name
**"Display & Analysis"** (renamed from "Relationships")

### Purpose
This is the **single source of truth** for how data appears to end users. It controls:
1. Which sheets have relationships (master-detail)
2. Which columns to show/hide
3. What order columns appear
4. What labels columns display as
5. How data is grouped
6. What analysis/aggregations to show

### User Mental Model
*"This is where I configure what my users will see and how they'll interact with the data."*

---

### Section 1: Master-Detail Relationships (Existing Functionality)

**What It Does:**
- Define which sheet is "master" (e.g., Teams)
- Define which sheet is "detail" (e.g., Players)
- Specify join column (e.g., Team ID)

**Configuration:**
- Master sheet selection
- Detail sheet selection
- Join column (foreign key)
- Relationship name/label

---

### Section 2: Column Configuration (NEW - Consolidated Here)

**This replaces the old "Columns" tab functionality and is THE place to configure display.**

#### UI Layout: Enhanced Field Management

**Available Columns List (Left Panel):**
- Shows ALL columns (real + virtual)
- Source indicator (which sheet or "Virtual")
- Data type badge
- Drag-and-drop to "Selected Columns"

**Selected Columns List (Right Panel - This is what users will see):**
- Prettier checkboxes to include/exclude quickly
- Drag-and-drop handles for ordering
- Inline editing of display labels
- Visual preview of how table will look

**Per-Column Configuration:**
- **Include/Exclude** - Checkbox (visual on/off toggle)
- **Display Label** - Editable text field (rename for users)
- **Display Order** - Drag-and-drop position
- **Text Alignment** - Left/Center/Right (for tables)
- **Show Field Name** - Toggle (show label or not in master-detail)
- **Grouping** - Set as grouping column (radio button)
- **Sticky/Frozen** - Keep column visible when scrolling (optional)

---

### Section 3: Grouping & Sorting Configuration

**Grouping:**
- Select which column to group by (dropdown)
- Group order (ascending/descending)
- Show group analysis (sum/count/avg)

**Sorting:**
- Default sort column
- Default sort direction
- Multi-level sorting (advanced)

---

### Section 4: Analysis Operations

**Per-Group Analysis:**
- Select columns to sum
- Select columns to count
- Select columns to average
- Display format for results

**Overall Analysis:**
- Same options as per-group
- Displayed at top level when multiple records exist

---

### Section 5: Search & Filter Settings

**Search Configuration:**
- Enable/disable search
- Searchable columns selection
- Fuzzy search threshold
- Search behavior (case-sensitive, etc.)

**Email Filtering:**
- Enable/disable per-user filtering
- Select which column contains user emails
- Filter behavior

---

### Section 6: Currency & Formatting (Project-Level)

**Currency Settings:**
- Currency symbol (£, $, €, etc.)
- Thousands separator (, or .)
- Decimal places (0-4)

**Date Settings:**
- Default date format
- Timezone handling

---

## Data Precedence & Hierarchy

### Column Display Name Resolution

When the app needs to display a column name, it checks in this order:

1. **Display & Analysis Tab** - `fieldDisplayConfig.label`  
   - **THIS IS THE SOURCE OF TRUTH**  
   - Set per relationship  
   - Stored in `sheet_relationships.fieldDisplayConfig`

2. **Virtual Columns Tab** - `label` field  
   - Only applies to virtual columns  
   - Used if no override in Display & Analysis

3. **Original Sheet Column Name**  
   - Direct from Google Sheets  
   - Used if nothing else is set

### What Gets Deleted

**Old "Columns" Tab:**
- ❌ Remove the `displayName` editing functionality
- ❌ Remove show/hide toggles
- ❌ Remove ordering controls
- ✅ Keep this data in backend for potential future use, but don't expose in UI

**Database Changes:**
- `project_columns.displayName` - Deprecate (keep column for backwards compatibility but don't use)
- `project_columns.visible` - Deprecate
- `sheet_relationships.fieldDisplayConfig` - THIS BECOMES THE ONLY PLACE display config is stored

---

## User Experience Flow

### New Project Setup Flow

1. **Step 1: Connect a Sheet**
   - User adds Google Sheet URL
   - Bedrock fetches data
   - User sees "Sheets" tab populate with accordion item
   - User expands accordion to confirm columns detected correctly

2. **Step 2: (Optional) Create Virtual Columns**
   - User switches to "Virtual Columns" tab
   - Creates calculated fields as needed
   - Virtual columns now available for use

3. **Step 3: Configure Display**
   - User switches to "Display & Analysis" tab
   - Defines master-detail relationships (if needed)
   - Selects which columns to show
   - Reorders columns with drag-and-drop
   - Renames columns for end-user clarity
   - Configures grouping and analysis

4. **Step 4: Preview & Publish**
   - User can preview how data will look
   - End users access the configured view

---

## Benefits of This Architecture

### 1. Eliminates Confusion
- **Before:** "I changed the name in Columns tab but it didn't update in my view!"
- **After:** "Display & Analysis is where I configure output. That's the only place to rename."

### 2. Clear Purpose Per Tab
- **Sheets:** Confirmation (did we read it right?)
- **Virtual Columns:** Transformation (add calculated fields)
- **Display & Analysis:** Configuration (how should it look?)

### 3. Matches User Mental Model
- Linear flow from left to right in tabs
- Each step builds on the previous
- No circular dependencies

### 4. Easier to Build & Maintain
- Single source of truth for display config
- No duplicate code for column management
- Clear database schema (one config location)

### 5. Better for Future Features
- Want to add column filtering? Goes in Display & Analysis
- Want to add conditional formatting? Goes in Display & Analysis
- Want to add permissions per column? Goes in Display & Analysis

---

## Implementation Notes

### Phase 1: Planning & Design (Current Stage)
- ✅ Document information architecture (this document)
- ✅ Get stakeholder approval
- Define detailed UI mockups
- Map out database migration strategy

### Phase 2: Backend Refactor
- Deprecate `project_columns` display configuration
- Consolidate into `sheet_relationships.fieldDisplayConfig`
- Update all GET endpoints to use new source
- Add migration script for existing data

### Phase 3: Frontend Refactor
- Rename "Relationships" → "Display & Analysis"
- Make "Sheets" tab read-only
- Move column configuration UI to Display & Analysis
- Add prettier checkboxes and drag-and-drop
- Update all components to read from single source

### Phase 4: Testing & Validation
- Test with existing projects
- Verify data migration
- User acceptance testing
- Fix any issues

### Phase 5: Cleanup
- Remove old "Columns" tab editing features
- Update documentation
- Archive deprecated code

---

## Open Questions for Discussion

1. **Should we keep old `project_columns.displayName` data?**
   - Option A: Migrate it to `fieldDisplayConfig` during upgrade
   - Option B: Let users re-configure (simpler, but requires user action)

2. **Sheets tab sync frequency?**
   - Manual only?
   - Auto-sync on interval?
   - Real-time webhook (future enhancement)?

3. **Virtual columns in accordion?**
   - Should virtual columns appear as a separate "Virtual Sheet" in Sheets tab?
   - Or only appear in Display & Analysis?

4. **Column grouping in Display & Analysis:**
   - Should we visually group "Real Columns" vs "Virtual Columns"?
   - Or treat them identically?

---

## Revision History

| Version | Date       | Author | Changes |
|---------|------------|--------|---------|
| 2.0     | 2025-11-18 | Chris  | Complete IA redesign based on user feedback |
| 1.0     | (Previous) | System | Original implementation (AI-generated) |

---

## Approval

- [ ] Product Owner Approved
- [ ] Technical Lead Reviewed
- [ ] UX Design Reviewed
- [ ] Ready for Implementation

---

**Next Steps:** Review this document, provide feedback, then create detailed UI mockups before beginning implementation.