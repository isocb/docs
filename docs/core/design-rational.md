Here are **your three fully rewritten, production-ready IsoStack documents**, each placed into the correct location within your `/docs` hierarchy.

These are not summaries — they are *clean, complete, publish-ready files*, with structure, clarity, and the correct scope for each category.

---

# ✅ **FILE 1 — roles-and-permissions.md**

📍 **Location:**

```
/docs/core/roles-and-permissions.md
```

---

# **IsoStack Roles & Permissions Architecture**

## Overview

IsoStack is a multi-tenant SaaS framework where every authenticated user belongs to **one organisation context at a time**.
To support full tenant isolation alongside platform-level control, IsoStack uses two permission layers:

1. **Tenant Roles** — OWNER, ADMIN, MEMBER
2. **Platform-Level Roles** — Platform Admin (separate record, cross-tenant)

This separation is intentional and fundamental to IsoStack’s architecture.

---

# 1. Tenant Roles (Per Organisation)

Tenant roles determine what users can do **inside a single organisation**.

### **MEMBER**

* Basic application access
* Cannot manage users
* Cannot change roles or suspend users

### **ADMIN**

* Can edit user profile fields (name, email)
* Can activate/suspend users in their organisation
* Cannot change any user’s role
* Cannot remove users

### **OWNER**

* Full control inside the organisation
* Can change user roles
* Can remove users
* Can manage organisation settings and features

---

# 2. Platform Admin (Cross-Tenant)

Platform Admin is **not** a tenant role.
It is defined in a separate table:

```
PlatformAdmin
  - id
  - userId (FK to User)
```

### Capabilities:

* Switch into any organisation
* View/manage users across all tenants
* Override all tenant-level permissions
* Access platform-wide tools (billing, organisation status, global feature flags)

### Why a separate table?

1. **Clear separation of tenant vs platform boundaries**
2. **A user can be OWNER in one org and MEMBER in another** while still being Platform Admin
3. **Cross-organisation privileges must not conflict with tenant roles**
4. **Easier to extend with more platform-wide privileges**

---

# 3. Permission Matrix

| Action                | MEMBER | ADMIN | OWNER | Platform Admin |
| --------------------- | ------ | ----- | ----- | -------------- |
| Edit user name/email  | ❌      | ✅     | ✅     | ✅              |
| Change user role      | ❌      | ❌     | ✅     | ✅              |
| Suspend/Activate user | ❌      | ✅     | ✅     | ✅              |
| Remove user           | ❌      | ❌     | ✅     | ✅              |
| Switch organisations  | ❌      | ❌     | ❌     | ✅              |
| View all tenants      | ❌      | ❌     | ❌     | ✅              |

---

# 4. Enforcement in Code

### tRPC guards:

* Tenant roles enforced by checking:

  ```
  ctx.session.user.role
  ```

* Platform Admin enforced by:

  ```
  ctx.session.user.isPlatformAdmin
  ```

### UI visibility:

* Navigation items hidden based on role
* Platform Admin sees “Switch Organisation” menu

---

# 5. Summary

IsoStack’s permission system is intentionally:

* **Simple** (3 tenant roles)
* **Powerful** (one cross-tenant role)
* **Unambiguous** (clean separation)
* **Scalable** (easy to add future platform-only privileges)

This file serves as the authoritative source of truth for access control across the entire platform.

---

# ✅ **FILE 2 — roadmap.md**

📍 **Location:**

```
/docs/core/roadmap.md
```

---

# **IsoStack V2.0 Roadmap**

## Overview

The roadmap outlines delivered features and future deliverables for the IsoStack platform, focusing on authentication, organisation management, UX quality and multi-tenant administration.

---

# 1. Completed Features

## **Phase 1 — Authentication**

* Sign out
* Password reset flow
* Email verification UI

## **Phase 2 — Team Management**

* User CRUD
* Suspend/Activate user via clickable status badge
* Role-based permissions
* OWNER role removed from invite flow
* Platform Admin integrated into user/organisation views

## **Phase 3 — Code Quality & Security**

* Client/server boundary audit
* Security fixes in onboarding
* Validation improvements
* Core refactor to enforce correct multi-tenant boundaries

---

# 2. Upcoming Features

## **Organisation Status Management**

Status options:

```
ACTIVE
COMPED
TRIAL
TRIAL_EXPIRED
PAUSED
CANCELLED
```

### Behaviour:

* TRIAL_EXPIRED → read-only mode
* PAUSED → login blocked, support message
* CANCELLED → access removed, reactivation path
* Linked to Stripe/Paddle subscription system
* Auto-updates based on payment status

### UI:

* Badge toggle like user status
* Confirmation modal
* Platform Admin only

### Effort: 2–3 days

### Priority: High

---

## **Switch Organisation (Platform Admin)**

Allows Platform Admin to switch into any tenant for support.

### UI:

* Dropdown in profile menu
* Current org highlighted
* Instant context switch
* Retains Platform Admin privileges

### Use Cases:

* Support
* Debugging
* Data verification

### Effort: 1 day

### Priority: Medium

---

## **Phase 4 — UX Polish**

* Loading skeletons
* Error boundaries
* Optimistic updates
* Form validation improvements
* Empty-state designs with CTAs

### Effort: 1–2 days

### Priority: Medium

---

# 3. Dependencies

| Feature             | Depends On                             |
| ------------------- | -------------------------------------- |
| Organisation Status | Billing system integration             |
| Org Switching       | Correct platform-level session context |
| UX Polish           | Stabilised layout and navigation       |

---

# 4. Summary

This roadmap ensures IsoStack evolves into a fully featured, polished, multi-tenant SaaS platform with a strong core foundation.

---

# ✅ **FILE 3 — design-rationale.md**

📍 **Location:**

```
/docs/core/design-rationale.md
```

---

# **IsoStack Architecture – Design Rationale**

This document explains *why* certain architectural decisions were made in IsoStack.
These notes prevent accidental regressions and provide intellectual continuity.

---

# 1. Why PlatformAdmin Is a Separate Table

An earlier AI agent misunderstood multi-tenancy and attempted to merge platform and tenant roles.
The original design — which separated PlatformAdmin — was correct.

### Reasons:

### ✔ 1. Separation of Concerns

Tenant roles describe **what a user can do inside an organisation**.
Platform Admin is **cross-organisational** and must not be tied to tenant hierarchy.

### ✔ 2. Flexibility

A user can safely be:

* OWNER in Org A
* ADMIN in Org B
* MEMBER in Org C
* Platform Admin across *all* orgs

### ✔ 3. Security

Cross-tenant operations must never depend on tenant-level privileges.

### ✔ 4. Scalability

Platform role can gain more powers without touching the Role enum.

---

# 2. Why Three Tenant Roles?

IsoStack uses:

```
MEMBER
ADMIN
OWNER
```

### This is intentional:

* MEMBERS stay simple
* ADMIN handles team operations
* OWNER is the final authority
* Avoids unnecessary roles like SUPER_ADMIN or MANAGER

---

# 3. Status Architecture Rationale

Organisation status (ACTIVE/TRIAL/PAUSED/etc.) is necessary because:

* Billing providers require state-based access
* Trials need automatic expiry
* Organisations must be able to pause subscriptions
* Platform Admin needs visibility over all tenant statuses

This creates strong commercial flexibility without custom development.

---

# 4. Switch Organisation: Why It Exists

Platform Admin must be able to impersonate/switch orgs to:

* Provide support
* Access tenant-specific issues
* Debug data
* Validate onboarding flows

This is a core SaaS support pattern used in:
Stripe, GitHub Enterprise, Intercom, Notion.

---

# 5. Historical Note (Important)

A previous incorrect implementation attempted to:

* Treat Platform Admin as a tenant role
* Flatten hierarchy
* Allow tenant-level invites to assign platform-level privileges
* Merge global and organisation roles

This was rejected because it violated IsoStack’s core principles:

* tenant isolation
* platform authority separation
* role clarity
* security expectations

This document ensures that future work does **not drift** in that direction.

---

# 6. Summary

IsoStack’s architecture is distinctly:

* **Multi-tenant first**
* **Security-led**
* **Composable**
* **Extensible**

The rationale here should guide future features, modules, and onboarding of developers or AI agents.

---

# 🎉 All three files are now delivered.

If you'd like, I can now also:

✅ generate the `/docs/core/README.md` index file
✅ update the sidebar navigation for your documentation tooling
or
✅ create a **“Working With IsoStack Roles”** cheat sheet for developers

Just say **“generate the core README”** or similar.
