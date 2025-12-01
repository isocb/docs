
```

It uses placeholder tokens (`<module>`, `<FlagName>`, etc.) that authors replace when creating a new module.

It is concise but complete, perfectly aligned with IsoStack’s multi-tenant architecture and module system, and written to be AI-optimised.

---

# 📘 **Module Feature Flags Template**

**Location:** `/docs/modules/<module>/_feature-flags.md`
**Audience:** Module Authors, Developers, AI Agents
**Purpose:** Define how this module uses feature flags in IsoStack
**Status:** Template — copy this file into a new module’s doc folder and customise.

---

# 1. **Module Identification**

* **Module Name:** `<Module Name>`
* **Module ID:** `<module>`
* **Feature Flag Key:** `<flagKey>`

  * (Must match `featureFlag` property in `module.config.ts`)

---

# 2. **Purpose of This Feature Flag**

Explain what turning the flag **on** or **off** does.

Example:

```
Enables <Module Name> functionality for the tenant, including its pages,
tRPC endpoints, navigation entries, UI widgets, and background processes.
```

---

# 3. **Default State**

### Platform Default

```
<true/false> 
```

Explain why.

Example:

```
Default: false  
Reason: This module is industry-specific; only certain tenants require it.
```

---

# 4. **Tenant Behaviour**

### When `<flagKey>` is **enabled**:

* Navigation entries appear
* Pages under `/app/<module>` become accessible
* tRPC routers execute normally
* UI components depending on this module are visible
* Background processes for the module run (if applicable)
* Tooltip anchors for this module are active

### When `<flagKey>` is **disabled**:

* All module routes redirect to `/dashboard`
* Nav entries are hidden
* tRPC routers throw `FORBIDDEN`
* Dependent widgets do not render
* Module settings are hidden
* No background tasks run

---

# 5. **Frontend Usage Examples**

### Navigation

```tsx
const enabled = features?.<flagKey> === true;

{enabled && (
  <NavLink href="/<module>">
    <IconYourIcon />
    <span>Your Module</span>
  </NavLink>
)}
```

### Hiding UI Widgets

```tsx
if (!features?.<flagKey>) return null;

return <YourModuleCard />;
```

### Protecting Pages (Client Component)

```tsx
if (!features?.<flagKey>) {
  redirect('/dashboard');
}
```

---

# 6. **Backend Usage (tRPC Enforcement)**

### Middleware version:

```ts
import { TRPCError } from '@trpc/server';

export const require<Module>Feature = middleware(async ({ ctx, next }) => {
  if (ctx.features?.<flagKey> !== true) {
    throw new TRPCError({
      code: 'FORBIDDEN',
      message: '<Module Name> is not enabled for this organisation',
    });
  }
  return next();
});
```

### Router usage:

```ts
export const <module>Router = router({
  list: protectedProcedure
    .use(require<Module>Feature)
    .query(async ({ ctx }) => {
      return ctx.prisma.<module>Item.findMany({
        where: { organizationId: ctx.session.user.organizationId }
      });
    }),
});
```

---

# 7. **Dependencies (Optional)**

If your module requires others:

```
Depends on: ["billing", "analytics"]
```

Add to `module.config.ts`:

```ts
dependencies: ['billing', 'analytics']
```

The system will:

* Prevent enabling `<module>` unless dependencies are enabled
* Prevent navigation rendering
* Prevent tRPC access

---

# 8. **Configuration UI (optional)**

If your module provides a settings page:

```tsx
// src/app/(app)/<module>/settings/page.tsx

if (!features?.<flagKey>) redirect('/dashboard');
```

Document:

* Default settings
* Visibility rules
* Behaviour changes when flag is enabled/disabled

---

# 9. **Tooltip Integration**

Document how tooltips behave:

### Example:

```
When <module> is disabled, tooltips linked to this module's pages and
components will not appear in Tooltip Mode.

When enabled, tenants may customise these tooltips.
```

Optional:
List your tooltip IDs:

```
<module>.welcome
<module>.dashboard.card1
<module>.settings.help
```

---

# 10. **Migration and Rollout Notes**

Add notes specific to module rollout:

Examples:

* “Enabling `<module>` creates required database tables.”
* “Disabling `<module>` does not delete data; UI-only change.”
* “Safe to enable/disable at any time.”
* “Stores module data in `<module>Items` table.”

---

# 11. **Testing Checklist**

### Frontend

* [ ] Navigation hides when flag = false
* [ ] Pages redirect when disabled
* [ ] Components and widgets conditionally render
* [ ] Tooltip anchors appear/disappear appropriately

### Backend

* [ ] tRPC throws FORBIDDEN when disabled
* [ ] tRPC succeeds when enabled
* [ ] Feature-dependent DB operations work
* [ ] Background tasks (if any) check flags

### Multi-Tenancy

* [ ] Tenant A enabled / Tenant B disabled works correctly
* [ ] Platform Admin overrides respected
* [ ] Onboarding clones default flag correctly

---

# 12. **Changelog**

Keep a small per-module changelog:

```
1.0.0 – Module created  
1.1.0 – Added feature flag handling  
1.2.0 – Added tooltip integration  
1.3.0 – Added module dependencies  
```

---

# ✔ Summary

This template ensures that every module provides:

* A documented feature flag
* Consistent UI & backend enforcement
* Multi-tenant support
* Integration with tooltips, navigation, and routes
* Predictable behaviour
* Clear testing and rollout guidance

