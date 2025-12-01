Below is a clean, canonical **IsoStack Architecture Overview**, ready for `/docs/core/architecture.md`.

It is written in the correct voice for internal developer documentation AND AI-assistant context loading.

---

# 📘 **IsoStack Architecture Overview**

**Location:** `/docs/core/architecture.md`

---

# **1. Purpose**

This document provides a full architectural overview of **IsoStack V2.0** — the foundation for all Isoblue SaaS applications.

It defines:

* Core technologies
* Folder and module structure
* Multi-tenant architecture
* API strategy
* Database design
* Authentication & session model
* Component conventions
* Deployment architecture
* Guiding principles

This is a **Single Source of Truth** for both developers and AI agents.
**AI must ALWAYS reference this document and never use cached assumptions.**

---

# **2. High-Level Architecture Diagram**

```
┌───────────────────────────────────────────────────────────┐
│                       IsoStack Core                       │
│  (Next.js App Router + tRPC + Prisma + Neon Postgres)     │
└───────────────────────────────────────────────────────────┘
            ▲                   ▲                   ▲
            │                   │                   │
            │                   │                   │
            ▼                   ▼                   ▼
   Tenant A App         Tenant B App         Tenant C App
   (modules enabled)    (different modules)   (different modules)
```

IsoStack provides a **shared platform** with:

* Authentication
* Multi-tenancy
* Role and permission framework
* Settings engine
* Branding
* Tooltip system
* Audit logging
* UI foundations
* tRPC API layer

Apps (EmberBox, TailorAid, Bedrock, LMSPro…) sit **on top**, enabling/extending features through modules.

---

# **3. Core Technology Stack**

### **Frontend**

* **Next.js 15** (App Router)
* **React Server Components**
* **Mantine 7** (design system)
* **Tabler Icons**
* **TypeScript 5.x**
* **Zod** for validation

### **API Layer**

* **tRPC 11** (no REST controllers)
* **SuperJSON** for serialization
* **Next.js Route Handlers** for edge-safe API hosting

### **Database**

* **Prisma 5.x** ORM
* **Neon PostgreSQL (serverless)**
* **UUID primary keys**
* **Entity-prefixed IDs** via `generateId(entityType)`

### **Authentication**

* **NextAuth.js v5**

  * Magic link primary auth
  * JWT session tokens
  * Org context encoded into session

### **Services**

* **Resend** for email
* **Cloudflare R2** (optional) for file and media storage

### **Deployment**

* **Render** for production deployment (current stack)
* **Local dev** via `npm run dev`
* Optional: **Vercel**, **Railway**

---

# **4. Multi-Tenant Architecture**

IsoStack is built around **strict tenant isolation**, enforced at every layer.

## Tenant Isolation Rules

1. **Every DB table with tenant-owned data includes `organizationId`**
2. Every request includes:

   ```
   ctx.session.user.organizationId
   ```
3. Platform Admin is the *only* role allowed to switch organisation context
4. tRPC routers must never fetch records outside the active tenant context
5. Prisma queries must be filtered by `organizationId`

### Example:

```ts
await prisma.user.findMany({
  where: {
    organizationId: ctx.session.user.organizationId,
  }
});
```

### Platform Admin override:

Platform Admin can switch context via:

```ts
session.user.organizationId = targetOrgId;
```

…but still must operate within a defined org context — there is no “global” tenant context for actions.

---

# **5. Role & Permission Layer**

Defined in `/docs/core/roles-and-permissions.md`.

Quick outline:

### Tenant Roles

```
MEMBER  → basic access
ADMIN   → manage users (except role changes)
OWNER   → full control of a tenant
```

### Platform Role (global)

```
PlatformAdmin → cross-tenant superuser
```

### Enforcement

* **Backend (tRPC)** is the source of truth
* **UI checks** improve UX but do not enforce rules

Middleware examples:

```ts
requireRole(['ADMIN'])
requireOwnerOrPlatform()
```

---

# **6. Folder Structure Overview**

```
src/
├── app/                         # App Router pages
│   ├── (auth)/                  # Auth screens (public)
│   ├── (app)/                   # Tenant-protected area
│   ├── layout.tsx               # Root layout
│   └── page.tsx                 # Landing page
│
├── core/                        # IsoStack core engine
│   ├── components/              # Reusable UI
│   ├── features/                # Tooltips, Branding, Settings
│   ├── providers/               # Theming, tRPC, session providers
│   ├── hooks/                   
│   └── utils/
│
├── modules/                     # Optional feature modules
│   ├── billing/
│   ├── support/
│   └── bedrock/                 # Example: Bedrock as a module
│
├── server/                      # API logic
│   ├── core/                    # Core tRPC routers
│   └── modules/                 # Module routers
│
├── prisma/
│   ├── schema.prisma            # Database schema
│   └── migrations/              
│
└── styles/                      # Global CSS
```

---

# **7. API Architecture (tRPC)**

IsoStack uses **tRPC as the primary API layer**, not REST.

Key principles:

### 1. **No manual JSON parsing**

tRPC handles type-safe validation using Zod.

### 2. **Automatic session injection**

Every procedure receives:

```ts
ctx.session
ctx.prisma
ctx.user
```

### 3. **SuperJSON everywhere**

Responses **must** use superjson format:

```ts
return new Response(
  superjson.stringify(data),
  { headers: { 'Content-Type': 'application/json' } }
);
```

### 4. **Strong typing end-to-end**

tRPC ensures the same type is shared:

* Input
* Output
* Frontend consumption

---

# **8. Authentication & Session Model**

IsoStack uses:

### **Magic Link Only**

No passwords by default.

### **Session JWT contains:**

* User ID
* Email
* Role
* PlatformAdmin flag
* Current organizationId

### **Organisation context in NextAuth**

tRPC procedures assume organisation context is set.

If Platform Admin switches org:

```ts
await updateSession({ organizationId: newOrg });
```

---

# **9. Settings & Feature Flags**

Every organization has:

```prisma
model FeatureFlags {
  organizationId String @id
  features Json @default("{}")
}
```

Modules are enabled/disabled per tenant based on these flags.

### Example:

```
{
  "billing": true,
  "support": false,
  "tailoraid": true
}
```

This allows **one deploy → multiple products**.

---

# **10. The Tooltip System**

Documented in detail in `/docs/modules/tooltips/`.

Core principles:

* Platform → Tenant inheritance
* Visual editor
* DOM selector detection
* Rich content with R2 media uploads
* Per-element Category, Function, and Markdown
* Stored in Prisma model
* Org-scoped customisations

Tooltips are central to IsoStack’s **contextual help-as-data** philosophy.

---

# **11. Deployment Architecture**

### **Production**

* Hosted on **Render Web Service**
* Connected to GitHub `main` branch
* Environment variables configured in Dashboard
* Auto-deploy enabled

### **Database**

* Provided by **Neon PostgreSQL**
* Serverless
* Branching available for preview environments

### **Email**

* Provided by **Resend**

### **Asset Storage**

* Cloudflare R2 (tenant-isolated object prefixes)

### **Local Development**

* `npm run dev`
* Local `.env.local` for environment variables

---

# **12. Development Principles**

These principles MUST be followed by human and AI developers:

### **(1) Always work backwards when updating files**

To avoid line-number shift problems.

### **(2) Never use cached file versions**

Always request the latest file content before modifying it.

### **(3) Always provide edits as:**

* File path
* Line numbers
* “Find this” block
* “Replace with” block
* Reverse order for multiple edits

### **(4) All database changes follow the sequence:**

1. Neon schema update
2. Prisma update
3. VS Code commit
4. Deploy
5. Test

### **(5) Tenant isolation is sacred**

Never access another tenant without explicit logic.

---

# **13. Guiding Philosophy**

IsoStack is:

* **Multi-tenant first**
* **Module-based**
* **Secure-by-default**
* **Highly customisable**
* **Future-proof**
* **AI-assistant friendly**
* **Simple enough for solo devs**
* **Strong enough for enterprise architecture**

IsoStack allows you to:

> Build once. Deploy many times.
> Customize per tenant.
> Maintain sanity.

---

