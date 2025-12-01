Yes, that all lines up – we are now at the “turn it into concrete docs + make the AI build from them” stage. I’ll do two things:

1. Give you **drop-in content** for the two docs you’ve created.
2. Give you **practical steps to get Claude building Bedrock** against those specs.

I’ll keep it tight, but you can paste these straight into:

* `docs/core/isostack-platform-for-modules.md`
* `docs/modules/bedrock/architecture.md`

Feel free to tweak headings to your house style.

---

## 1. `isostack-platform-for-modules.md` – suggested content

````md
---
title: IsoStack Platform – Services for Modules
description: Platform capabilities available to all IsoStack modules (Bedrock, Emberbox, etc.)
status: draft
version: 0.1.0
compatible_with: isostack-core v2.x
---

# IsoStack Platform for Modules

> **Purpose**  
> Define the shared platform services that every IsoStack module can rely on: multi-tenant model, branding, login, tooltips, file storage, connectors, and tenant user APIs.  
> Bedrock is used as the worked example, but this contract applies to all modules.

---

## 1. Multi-tenant model & module flags

IsoStack is **organisation-centred**. Every module runs *inside* an organisation (tenant).

### 1.1 Core entities (simplified)

- `organisation`
  - logical tenant
- `user`
  - platform/system user; may belong to one or more organisations
- `organisation_module`
  - which modules are enabled for a tenant

```sql
organisation_module
- id              uuid
- organisation_id uuid
- module_key      text      -- e.g. 'bedrock', 'tooltips', 'branding'
- enabled         boolean
- created_at      timestamptz
- updated_at      timestamptz
````

Modules MUST always scope by `organisation_id` and `module_key` before doing anything.

---

## 2. Tenant branding & branded login

All multi-tenant apps must be able to present a **branded login and shell** for the tenant. Modules (like Bedrock) consume this; they do not reimplement it.

```sql
tenant_branding
- id                      uuid
- organisation_id         uuid
- client_id               text    -- public identifier, e.g. "clt_SNHRbI6ttrOckf925lbaX"
- logo_file_asset_id      uuid?   -- FK → file_asset.id
- logo_scale_percent      integer -- 0–200, used for slider control
- show_company_name       boolean
- brand_primary_colour    text
- brand_accent_colour     text
- brand_font_family       text
- created_at              timestamptz
- updated_at              timestamptz
```
- Branded login URL:
APP_BASE_URL/login?client={client_id}
- Branded set–password URL:
APP_BASE_URL/set-password?client={client_id}
### Security semantics
- client_id is a pseudo-random UUID-like string, not a human slug.
- It is safe to share with the tenant and their users.
- On every request, the app:
1.  Looks up tenant_branding by client_id.
2. Resolves organisation_id from that row.
3. Applies branding (logo, colours, fonts, show_company_name).
4. Routes login / set-password for that organisation’s users only.

### 2.1 Branded login flow

And under file storage, add the allowed types and size limit.

### In `modules/bedrock/architecture.md`

Add a short subsection under “Integration with platform services”:

```md
### 3.4 Branded login URLs

Bedrock does not own its own login; it relies on the platform’s client-id based scheme.

For a Bedrock deployment at `APP_BASE_URL`, and a tenant with `tenant_branding.client_id`, the module:

- exposes a login screen at  
  `/login?client={client_id}`

- exposes a set-password / password reset screen at  
  `/set-password?client={client_id}`

These links are presented in the Bedrock admin UI and supplied to the tenant for distribution to their end users.

Both screens:

- resolve `tenant_branding` and `organisation_id` from `client_id`
- brand the UI using the tenant logo, colour and font settings
- honour `logo_scale_percent` and `show_company_name`.


## 3. Tenant users & API-based creation

Tenants need their own “client users” independent of platform-level staff.

### 3.1 Tenant user model

```sql
tenant_user
- id                     uuid
- organisation_id        uuid
- email                  text        -- unique globally
- full_name              text
- password_hash          text
- role                   text        -- 'client_user' | 'client_admin'
- permission_to_export   boolean     -- module-consumed, platform-stored
- created_at             timestamptz
- updated_at             timestamptz
```

This table is **platform-owned** and may be used by multiple modules (e.g. Bedrock, Emberbox).

### 3.2 Tenant-module settings pattern

Each module may define per-tenant settings in a `tenant_<module>_settings` table.
For Bedrock:

```sql
tenant_bedrock_settings
- id                            uuid
- organisation_id               uuid
- permission_to_export_default  boolean
- user_import_max_count         integer
- created_at                    timestamptz
- updated_at                    timestamptz
```

Platform guarantees:

* settings are always scoped by `organisation_id`
* modules initialise sensible defaults on first enable.

### 3.3 API credentials & user-creation endpoint

The platform exposes an **API key** per organisation and a standard user-creation endpoint.

* API key is mapped to an organisation behind the scenes.
* Endpoint (example):

```http
POST /_api/client/users
Authorization: Bearer <api-key>
Content-Type: application/json
```

Payload → DB mapping:

| Payload field        | Column                 | Notes                                   |
| -------------------- | ---------------------- | --------------------------------------- |
| `email`              | `email`                | required, unique                        |
| `displayName`        | `full_name`            | required                                |
| `password`           | `password_hash`        | min 8 chars, hashed before storage      |
| `role`               | `role`                 | 'clientUser' → `client_user` etc.       |
| `permissionToExport` | `permission_to_export` | optional; defaults from module settings |

If `permissionToExport` is omitted, the platform uses the module’s default (e.g. `tenant_bedrock_settings.permission_to_export_default`).

Bulk imports MUST respect `user_import_max_count` at the module level.

---

## 4. Tooltip system (three-tier SSOT)

Tooltips are a platform service and are treated as part of the **documentation Single Source of Truth**. 

### 4.1 Roles & security

* Only **Platform Admins** and **Tenant Owners/Admins** can edit tooltip content.
* End users can only **view** tooltips.
* Editing is done via a **Tooltip Mode** in the UI, not by arbitrary users.

### 4.2 Targeting elements

Tooltips are attached to elements by **on-hover selection** in the editor:

1. Admin enters Tooltip Mode.
2. Admin hovers an element; the editor shows the DOM selector (id, class, data attribute).
3. Admin confirms the element; platform stores a **stable selector**.

### 4.3 Tooltip entity

```sql
tooltip_entry
- id                 uuid
- scope_level        text      -- 'global' | 'owner' | 'tenant'
- organisation_id    uuid?     -- null when global
- module_key         text?     -- 'bedrock', 'emberbox', etc.
- selector           text      -- CSS or data-* selector
- category           text      -- e.g. 'data-input', 'virtual-columns'
- type               text      -- e.g. 'concept', 'howto', 'warning'
- title              text
- content_rich_text  text      -- markdown / rich text
- content_html       text      -- OPTIONAL raw HTML embed (trusted)
- created_by_user_id uuid
- updated_by_user_id uuid
- created_at         timestamptz
- updated_at         timestamptz
```

Every create/update is logged with user and timestamp for audit.

### 4.4 Inheritance

* **Global** entries are provided by Isoblue (platform).
* **Owner** entries are provided by the app owner (e.g. you, as solution provider).
* **Tenant** entries are overrides/extensions made by a specific organisation.

Resolution order (for a given `module_key + selector`):

1. Tenant tooltip (most specific)
2. Owner tooltip
3. Global tooltip (fallback)

### 4.5 Rich embeds & Wistia

`content_html` may contain **trusted embeds**, for example Wistia popover players:

* Scripts are **whitelisted** by domain (e.g. `fast.wistia.com`).
* CSS & `<wistia-player>` tags are rendered as provided.
* Embeds may rely on assets stored in Cloudflare R2 (screenshots, thumbnails).

This enables **video help in context**, without hard-coding support into individual modules.

---

## 5. File & media storage (Cloudflare R2)

IsoStack uses **Cloudflare R2** for binary assets (logos, PDFs, help images, etc.). 

### 5.1 File model (platform)

```sql
file_asset
- id               uuid
- organisation_id  uuid?        -- null for global assets
- bucket_key       text         -- R2 object key
- file_name        text
- mime_type        text
- size_bytes       bigint
- created_by_user_id uuid
- created_at       timestamptz
```

* `tenant_branding.logo_url` points at a `file_asset` (or a signed URL derived from it).
* Tooltip attachments may link to PDFs/images stored in R2.

Modules **do not** talk directly to R2; they call platform file services.

---

## 6. Connectors & secrets (for modules like Bedrock)

The platform defines a generic **connector** interface. Modules consume it.

```sql
data_connector
- id                uuid
- organisation_id   uuid
- type              text          -- 'google_sheets', 'knack', etc.
- display_name      text
- status            text          -- 'connected' | 'error' | 'disabled'
- config_json       jsonb         -- non-secret config
- created_at        timestamptz
- updated_at        timestamptz
```

* Secrets (API keys, service account JSON, etc.) are stored in **platform secret storage**, not in this table.
* Bedrock’s Google Sheets integration uses:

  * a shared **service account** configured at platform level
  * per-tenant **sheet IDs / URLs** stored in `config_json` or module tables.

---

## 7. Expectations for modules

Any IsoStack module (including Bedrock) can assume:

1. **Organisation context** available in every request.
2. **Module flag** (`organisation_module.enabled`) checked by platform before routing.
3. **Tenant branding** and **branded shell** available.
4. **Tenant users** and **user-creation API** available.
5. **Tooltip engine** ready to attach help content to the module’s UI.
6. **R2-backed file service** for logos/docs.
7. **Connector abstraction** for talking to 3rd-party data sources.

Modules MUST:

* honour `permission_to_export` when offering exports
* respect `tenant_<module>_settings` for their own rules
* expose stable DOM hooks for tooltips
* avoid duplicating platform capabilities.

````

