




title: IsoStack Platform — Services for Modules
description: Platform capabilities available to all IsoStack modules (Bedrock, Emberbox, LMSPro, etc.)
status: draft
version: 0.2.0
---

# IsoStack Platform for Modules
IsoStack provides a stable, multi-tenant foundation used by all modules.  
This document defines the shared platform services that every module can rely on.

Bedrock is the worked example, but these services apply equally to all modules.

---

# 1. Multi-Tenant Model & Module Enablement
IsoStack is organisation-centred.  
Each module runs *inside* an organisation (tenant), and each organisation may have one or more enabled modules.

## 1.1 Core Entities
### `organisation_module`
Specifies which modules are enabled for a tenant.

```sql
organisation_module
- id              uuid
- organisation_id uuid
- module_key      text      -- 'bedrock', 'emberbox', 'api_keychain', etc.
- enabled         boolean
- created_at      timestamptz
- updated_at      timestamptz
````

Modules must always scope to `organisation_id` and check `organisation_module.enabled`.

---

# 2. Branding & Branded Login (Client-ID Model)

IsoStack supports tenant-specific branding with a secure *client-id–based* login URL.

## 2.1 Login URLs

Given:

* `APP_BASE_URL` — where the module is deployed (e.g. `https://bedrock-3xvo.onrender.com`)
* A `client_id` stored on the tenant’s branding record

The tenant’s branded URLs are:

### **Branded Login URL**

```
{APP_BASE_URL}/login?client={client_id}
```

### **Branded Set-Password / Password Reset URL**

```
{APP_BASE_URL}/set-password?client={client_id}
```

These URLs are copied by the tenant and sent to their users.

## 2.2 Branding Storage

Branding is tenant-specific:

```sql
tenant_branding
- id                      uuid
- organisation_id         uuid
- client_id               text        -- e.g. "clt_SNHRbI6ttrOckf925lbaX", pseudo-random
- logo_file_asset_id      uuid?       -- FK → file_asset.id
- logo_scale_percent      integer     -- 0–200 (size slider)
- show_company_name       boolean
- brand_primary_colour    text
- brand_accent_colour     text
- brand_font_family       text
- created_at              timestamptz
- updated_at              timestamptz
```

## 2.3 Branding Behaviour

When the login or password-set route is accessed:

1. The platform looks up the tenant by `client_id`.
2. It resolves `organisation_id`.
3. It applies the tenant brand:

   * logo (from R2)
   * scaled using `logo_scale_percent`
   * organisation name shown only if `show_company_name = true`
   * colours & font applied to the login and shell UI

Modules (like Bedrock) **never implement their own branding**.
They use the platform’s `<TenantShell>` component.

---

# 3. Tenant Users & API-Based User Creation

Modules do not create their own user model.
IsoStack provides one tenant-scoped user table.

## 3.1 `tenant_user`

```sql
tenant_user
- id                     uuid
- organisation_id        uuid
- email                  text unique
- full_name              text
- password_hash          text
- role                   text        -- 'client_user' | 'client_admin'
- permission_to_export   boolean
- created_at             timestamptz
- updated_at             timestamptz
```

## 3.2 Module-Specific User Defaults

Each module may define its own tenant-level settings record.

Example for Bedrock:

```sql
tenant_bedrock_settings
- id                            uuid
- organisation_id               uuid
- permission_to_export_default  boolean
- user_import_max_count         integer
```

## 3.3 API → Create Users

API keys authenticate the tenant.

### **Endpoint**

```
POST /_api/client/users
Authorization: Bearer <api-key>
```

### **Payload**

```json
{
  "email": "user@example.com",
  "displayName": "Jane Doe",
  "password": "securepassword",
  "role": "clientUser",
  "permissionToExport": true   // optional
}
```

### **Rules**

* If `permissionToExport` omitted → use module default.
* Bulk creation must obey module’s `user_import_max_count`.

---

# 4. Tooltip System (Three-Tier SSOT)

Tooltips are **platform-owned** and provide contextual help across all modules.

## 4.1 Who Can Edit

* Platform Admins
* Tenant Owners / Tenant Admins
  **End users cannot edit tooltips.**

## 4.2 DOM-Based Selection

The tooltip editor allows:

1. Enter Tooltip Mode.
2. Hover an element.
3. A floating inspector shows its CSS selector.
4. Admin confirms → tooltip is attached to that selector.

## 4.3 Tooltip Storage

```sql
tooltip_entry
- id                 uuid
- scope_level        text      -- 'global' | 'owner' | 'tenant'
- organisation_id    uuid?
- module_key         text?
- selector           text      -- DOM id/class/data-attribute
- category           text      -- e.g. 'data-input', 'howto'
- type               text
- title              text
- content_rich_text  text
- content_html       text      -- optional trusted embed (e.g. Wistia)
- created_by_user_id uuid
- updated_by_user_id uuid
- created_at         timestamptz
- updated_at         timestamptz
```

### Supports:

* Rich text
* **Raw HTML embedding**, including Wistia popovers
* R2-hosted assets (images, PDF help, icons)

## 4.4 Inheritance (Global → Owner → Tenant)

Lookup order:

1. Tenant entry (most specific)
2. App Owner entry
3. Global entry (platform default)

---

# 5. File & Asset Storage (Cloudflare R2)

All binary assets — logos, PDFs, tooltip attachments — use R2.

```sql
file_asset
- id               uuid
- organisation_id  uuid?
- bucket_key       text
- file_name        text
- mime_type        text
- size_bytes       bigint
- created_by_user_id uuid
- created_at       timestamptz
```

### Upload rules (branding module)

* Max size: **5 MB**
* Allowed types: PNG, JPG, GIF, SVG

---

# 6. Data Connectors & Secret Handling

Modules use the platform connector abstraction.

```sql
data_connector
- id                uuid
- organisation_id   uuid
- type              text        -- 'google_sheets', 'knack', 'airtable', ...
- display_name      text
- status            text
- config_json       jsonb       -- non-secret config
- created_at        timestamptz
- updated_at        timestamptz
```

Secrets (API keys, service accounts) are stored **separately and securely**.

---

# 7. What Modules Can Assume

Any IsoStack module can rely on:

* Branded login & shell
* Tenant users + user-creation API
* Tooltip engine
* R2 asset service
* Generic connector interface
* Per-module tenant settings table pattern
* Multi-tenant scoping applied by platform

````
