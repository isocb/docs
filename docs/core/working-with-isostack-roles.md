

**Developer Cheat Sheet**

```md
# Working With IsoStack Roles — Developer Cheat Sheet

This document is a practical, copy-paste-ready guide for developers implementing features that rely on IsoStack’s multi-tenant role system.

It complements, but does not replace, the formal reference:  
`roles-and-permissions.md`.

---

# 1. Role Definitions (Quick Summary)

## Tenant Roles (per organisation context)
```

MEMBER  → basic access
ADMIN   → manage users (but not roles)
OWNER   → full admin control for the organisation

```

## Platform Role (global)
```

Platform Admin → cross-tenant superuser

```
Stored in its own table:
```

PlatformAdmin { id, userId }

````

---

# 2. How to Check Roles in Backend (tRPC)

### Check tenant role:
```ts
if (ctx.session.user.role === 'OWNER') {
  // owner-only logic
}
````

### Check platform admin:

```ts
if (ctx.session.user.isPlatformAdmin) {
  // global admin logic
}
```

### Combined:

```ts
const isOwner = ctx.session.user.role === 'OWNER';
const isPlatform = ctx.session.user.isPlatformAdmin;

if (!isOwner && !isPlatform) {
  throw new TRPCError({ code: 'FORBIDDEN' });
}
```

---

# 3. How to Restrict Access in tRPC Routers

### Member-only:

```ts
protectedProcedure
  .query(() => {...});
```

### Admin or higher:

```ts
protectedProcedure
  .use(requireRole(['ADMIN', 'OWNER']))
  .query(() => {...});
```

### Owner-only:

```ts
protectedProcedure
  .use(requireRole(['OWNER']))
  .mutation(() => {...});
```

### Owner or Platform Admin:

```ts
protectedProcedure
  .use(requireOwnerOrPlatform())
  .mutation(() => {...});
```

**Best practice:**
Write reusable role guards:

```ts
export const requireOwnerOrPlatform = middleware(async ({ ctx, next }) => {
  if (ctx.session.user.role !== 'OWNER' && !ctx.session.user.isPlatformAdmin) {
    throw new TRPCError({ code: 'FORBIDDEN' });
  }
  return next();
});
```

---

# 4. How to Restrict Access in UI Components

### Show a page only to owners:

```tsx
if (user.role !== 'OWNER') return <RedirectToDashboard />;
```

### Hide buttons based on permission:

```tsx
{(user.role === 'ADMIN' || user.role === 'OWNER') && (
  <Button>Edit</Button>
)}
```

### Platform Admin override:

```tsx
const canManage = user.role === 'OWNER' || user.isPlatformAdmin;

return canManage ? <DangerZone /> : null;
```

---

# 5. Permission Matrix (Developer Format)

### Who can:

| Action                | MEMBER | ADMIN | OWNER | Platform Admin |
| --------------------- | ------ | ----- | ----- | -------------- |
| Edit user name/email  | ❌      | ✅     | ✅     | ✅              |
| Change user role      | ❌      | ❌     | ✅     | ✅              |
| Suspend/Activate user | ❌      | ✅     | ✅     | ✅              |
| Remove user           | ❌      | ❌     | ✅     | ✅              |
| Switch organisations  | ❌      | ❌     | ❌     | ✅              |
| View all tenants      | ❌      | ❌     | ❌     | ✅              |

Copy/paste into PRDs or issues.

---

# 6. Notes on Organisation Context

Every request in IsoStack happens **in the context of one organisation**:

```ts
ctx.session.user.organizationId
```

Platform Admin overrides org isolation, but still requires a **current tenant context** when performing operations.

### Switching organisation (Platform Admin only)

Set via:

```ts
ctx.session.user.organizationId = selectedOrgId;
```

(Implemented in the org-switch feature.)

---

# 7. Best Practices for Developers

### ✔ Always check both:

* Tenant role
* Platform Admin override

### ✔ Never assume a user is OWNER unless explicitly checked

### ✔ Use backend (tRPC) for permission enforcement

UI checks improve UX but **do not secure** anything

### ✔ Keep permission logic *centralised*

Use middleware functions, not scattered if-statements

### ✔ Always include organisationId in database queries

Every Prisma query must be tenant-scoped unless platform admin is explicitly acting globally.

---

# 8. Common Mistakes (Avoid These)

❌ Checking only tenant role when Platform Admin should override
❌ Allowing ADMIN to change roles
❌ Forgetting tenant scoping in Prisma queries
❌ Hardcoding permissions in UI
❌ Giving OWNER role during invite flow (fixed)
❌ Treating Platform Admin as a tenant role

---

# 9. Quick Reference Snippets

### Get current organisation:

```ts
const orgId = ctx.session.user.organizationId;
```

### Fetch admin users:

```ts
prisma.user.findMany({
  where: {
    organizationId: ctx.session.user.organizationId,
    role: 'ADMIN',
  }
});
```

### Check if user can delete another user:

```ts
const canDelete = 
  current.role === 'OWNER' ||
  current.isPlatformAdmin;
```

---

# 10. Summary

IsoStack’s role system ensures:

* Clear tenant boundaries
* Predictable permissions
* Safe platform-level overrides
* Clean separation of concerns
* Scalability for future modules & admin controls

Use this cheat sheet when implementing:

* API endpoints
* UI components
* Admin screens
* User management tools
* Organisation settings
* Module-specific permissions

It should remain your **quick, practical reference** for daily development.

---

```

---
