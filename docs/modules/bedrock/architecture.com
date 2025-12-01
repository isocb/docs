

## 2. `modules/bedrock/architecture.md` – suggested content

```md
---
title: Bedrock Module Architecture
description: Domain model, data flow, and UI structure for the Bedrock reporting module
status: draft
version: 0.1.0
compatible_with: isostack-core v2.x
---

# Bedrock – Module Architecture

> **Purpose**  
> Bedrock is an IsoStack module that turns semi-structured data (initially Google Sheets) into configurable, branded reports and dashboards.  
> This document describes the **domain model, data flow, tRPC surface and UI** for the module.

---

## 1. Position in the IsoStack ecosystem

Bedrock:

- runs **inside** an organisation (tenant)
- is enabled/disabled via `organisation_module` with `module_key = 'bedrock'`
- relies on:
  - tenant branding & branded login
  - tenant users and the `_api/client/users` endpoint
  - tooltip engine for contextual help
  - Cloudflare R2 for logos and help assets
  - `data_connector` for Google Sheets via service account

It does **not** implement its own branding, login, user model or tooltip logic.

---

## 2. Domain model

### 2.1 Projects

One **Bedrock project** represents a configured analytics/reporting space for a tenant.

```sql
bedrock_project
- id               uuid
- organisation_id  uuid
- name             text
- description      text
- default_currency text
- default_date_format text
- created_by_user_id uuid
- created_at       timestamptz
- updated_at       timestamptz
````

### 2.2 Sheets & columns

Bedrock reads data from Google Sheets (public to a service account) via a `data_connector`.

```sql
project_sheet
- id               uuid
- project_id       uuid           -- FK → bedrock_project.id
- connector_id     uuid           -- FK → data_connector.id
- sheet_id         text           -- Google spreadsheet ID
- tab_name         text           -- worksheet name
- display_name     text
- last_synced_at   timestamptz
- row_count        integer
- column_count     integer
- sync_status      text           -- 'ok' | 'error' | 'pending'
- sync_error       text
- created_at       timestamptz
- updated_at       timestamptz
```

**Physical columns** (as returned by the sheet header row):

```sql
sheet_column
- id               uuid
- sheet_id         uuid           -- FK → project_sheet.id
- column_name      text           -- exact header; used as JSON key
- data_type        text           -- 'text' | 'number' | 'date' | 'boolean' | 'currency'
- is_active        boolean
- created_at       timestamptz
- updated_at       timestamptz
```

> **Key rule:**
> `column_name` is the **only** name for the column. There is no `display_name` here. The same value is used as the JSON key in data rows.

### 2.3 Virtual columns

Computed columns (formula/regex/etc.) are defined per sheet:

```sql
virtual_column
- id               uuid
- project_id       uuid
- sheet_id         uuid
- column_name      text           -- key added to row objects
- data_type        text
- column_type      text           -- 'formula' | 'regex' | etc.
- expression_json  jsonb          -- structured formula or regex spec
- visible          boolean
- display_order    integer
- created_at       timestamptz
- updated_at       timestamptz
```

* Virtual columns **append** new keys to row objects.
* Any label, alignment or analysis configuration is handled at the **view layer**, not here.

### 2.4 Relationships

Bedrock supports **master–detail** relationships between sheets (e.g. “Projects → Orders”).

```sql
sheet_relationship
- id                 uuid
- project_id         uuid
- master_sheet_id    uuid
- detail_sheet_id    uuid
- master_key_name    text   -- column_name on master sheet
- detail_key_name    text   -- column_name on detail sheet
- label              text   -- human-friendly description
- created_at         timestamptz
- updated_at         timestamptz
```

### 2.5 Display configuration

The **Display & Analysis** config is the Single Source of Truth for:

* which columns are shown
* labels
* ordering
* grouping
* sorting
* per-column analysis operations (subtotal, count, average, min, max)

```sql
display_config
- id               uuid
- project_id       uuid
- relationship_id  uuid NULL      -- NULL for single-sheet views
- config_json      jsonb
- created_at       timestamptz
- updated_at       timestamptz
```

TypeScript shape for `config_json`:

```ts
type AnalysisOps = {
  subtotal?: boolean;
  count?: boolean;
  average?: boolean;
  min?: boolean;
  max?: boolean;
};

type DisplayFieldConfig = {
  columnName: string;     // must match sheet_column/virtual_column.column_name
  label?: string;         // optional view-layer label
  visible: boolean;
  order: number;
  textAlign?: 'left' | 'centre' | 'right';
  isGroupingKey?: boolean;
  analysis?: AnalysisOps;
};

type DisplayConfigJson = {
  fields: DisplayFieldConfig[];
  search: {
    enabled: boolean;
    searchableColumns: string[];
  };
  sorting: {
    primary?: { columnName: string; direction: 'asc' | 'desc' };
    secondary?: { columnName: string; direction: 'asc' | 'desc' };
  };
};
```

### 2.6 Data cache

Bedrock may cache rows for performance, using `column_name` keys:

```sql
sheet_data
- id           uuid
- sheet_id     uuid           -- FK → project_sheet.id
- row_data     jsonb          -- array of { [columnName]: value }
- synced_at    timestamptz
```

Example row:

```json
{
  "CustomerName": "Alice",
  "Amount": 123.45,
  "CreatedOn": "2025-11-30",
  "NetAmount": 102.88
}
```

* `CustomerName`, `Amount`, `CreatedOn` → `sheet_column.column_name`
* `NetAmount` → `virtual_column.column_name`

---

## 3. Integration with platform services

### 3.1 Tenant users

Bedrock does **not** define its own user table. It relies on `tenant_user`:

* Filters data by `organisation_id`.
* Checks `tenant_user.permission_to_export` before allowing CSV/PDF exports.
* Uses `_api/client/users` endpoint and `tenant_bedrock_settings` for:

  * default export permissions on new users
  * maximum batch size for user imports.

### 3.2 Branding & login

* Bedrock surfaces under a **branded login** powered by `tenant_branding`.
* The main module routes (e.g. `/bedrock` and `/bedrock/[projectId]`) render within the shared `<TenantShell>` using logo, colours and fonts defined at tenant level.

### 3.3 Tooltips

Bedrock components expose **stable DOM hooks** (ids/data attributes) so Platform Admins and Tenant Owners can attach tooltips.

Examples:

* Sheets tab root: `data-tooltip-id="bedrock-sheets-tab"`
* Virtual Column editor: `data-tooltip-id="bedrock-virtual-column-form"`
* Display & Analysis grid: `data-tooltip-id="bedrock-display-config"`

Tooltip content is stored in `tooltip_entry` (platform) and may include:

* rich text (field explanations)
* embedded video (e.g. Wistia popover) via `content_html`.

---

## 4. Data flow

### 4.1 Sync from Google Sheets

1. Tenant admin configures a `data_connector` of type `google_sheets` and one or more `project_sheet` records.

2. A sync job (tRPC mutation / background worker) runs:

   * Uses a **shared service account** to access public or shared sheets.
   * Reads the header row:

     * upserts `sheet_column` entries with `column_name`.
   * Reads all rows:

     * builds an array of row objects keyed by `column_name`.
     * persists into `sheet_data.row_data`.

3. On schema changes (new/removed columns):

   * Bedrock updates `sheet_column` and leaves it to the admin to adjust DisplayConfig.

### 4.2 Runtime view assembly

When requesting a Bedrock data view (e.g. master–detail):

1. Load `project_sheet`, `sheet_column`, `virtual_column`, `sheet_relationship`, and `display_config`.
2. Load `sheet_data.row_data` for relevant sheets.
3. For each row:

   * compute all `virtual_column`s and add them to the row object.
4. Apply filters, grouping and sorting defined in `DisplayConfigJson`.
5. For each `DisplayFieldConfig.analysis`:

   * if `subtotal`, compute per-group subtotal.
   * if `count`, `average`, `min`, `max`, compute the relevant aggregate.
6. Return a structured result to the front-end containing:

   * groups
   * rows per group
   * per-column metrics
   * overall totals (if needed).

---

## 5. API surface (tRPC)

Bedrock exposes a tRPC router under `bedrock.*` (exact path may vary):

* `bedrock.projects`

  * `listByOrganisation`
  * `getById`
  * `create`
  * `update`
  * `archive`
* `bedrock.sheets`

  * `listByProject`
  * `create`
  * `update`
  * `delete`
  * `syncSheet`
* `bedrock.columns`

  * `getSchema` (sheet + `sheet_column` + `virtual_column`)
* `bedrock.virtualColumns`

  * `listBySheet`
  * `create`
  * `update`
  * `delete`
* `bedrock.relationships`

  * `listByProject`
  * `create`
  * `update`
  * `delete`
* `bedrock.displayConfig`

  * `getByRelationship`
  * `upsert`
* `bedrock.dataView`

  * `getMasterDetailView` (master sheet, relationship, view key)
  * `getSheetView` (single-sheet view)

All procedures:

* infer `organisation_id` from session
* enforce module enablement (`organisation_module`)
* respect tenant-module settings (e.g. export permissions).

---

## 6. UI structure

The Bedrock admin UI is rendered with Next.js App Router + Mantine:

### 6.1 Top-level

* `/bedrock` – list of projects
* `/bedrock/[projectId]` – project detail with tabs:

  1. **Sheets** (Data Input)

     * List of `project_sheet`s
     * sync status, last synced
     * preview of column headers and sample rows
  2. **Virtual Columns**

     * per-sheet view of `virtual_column`s
     * editor for expression JSON, type, data type
  3. **Display & Analysis**

     * selection and ordering of fields (from physical + virtual columns)
     * grouping keys
     * sorting
     * per-column analysis toggles (subtotal, count, average, min, max)
     * button to preview the resulting data view

### 6.2 End-user / reporting views

* Routes such as `/reports/[projectId]/[viewId]` or embedded within other IsoStack apps.
* Use `bedrock.dataView` APIs to render:

  * grouped tables
  * metrics rows
  * exports (CSV, later PDF).

Exports are only enabled where `tenant_user.permission_to_export = true`.

---

## 7. Future extensions (non-blocking)

* Additional connectors (`data_connector.type`):

  * Knack, Airtable, direct CSV upload.
* Charting layer on top of `bedrock.dataView`.
* Scheduled email reports.
* Per-tenant “canned views” with their own access controls.

````

---