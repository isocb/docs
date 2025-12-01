

# 📘 **IsoStack Feature Flags**

**Location:** `/docs/core/feature-flags.md`

---

# **1. Purpose**

Feature flags in IsoStack allow:

* Different **tenants** to run different sets of features
* Different **apps** (Bedrock, TailorAid, EmberBox) to run from the *same codebase*
* Modules to be **enabled or disabled** in real time
* Safe rollouts
* Simplified development
* Lower long-term maintenance
* Single-deployment multi-product strategy

Feature flags are a **core system**, not a module—everything in modules relies on them.

---

# **2. High-Level Concept**

IsoStack uses **tenant-scoped feature flags**, meaning:

```
Each organisation decides which features and modules are enabled.
```

There is **no global on/off switch** except for platform-wide defaults.

### Feature Resolution Order:

```
Tenant Setting → Platform Default → Disabled
```

---

# **3. Data Model (Prisma)**

```prisma
model FeatureFlags {
  organizationId String @id
  features       Json   @default("{}")

  organization   Organization 
    @relation(fields: [organizationId], references: [id], onDelete: Cascade)
}
```

### Example `features` JSON:

```json
{
  "billing": true,
  "support": false,
  "bedrock": true,
  "tooltips": true,
  "tailoraid": false,
  "emberbox": false
}
```

### Design principles:

* Every module has **one string key**
* Flags are **tenant-scoped**
* Flags stored as **flat JSON**, not nested
* Flags map **directly to module.config.ts → featureFlag**

---

# **4. Where Feature Flags Are Used**

### 1. **Navigation**

Hide/show links based on whether the module is enabled.

### 2. **Routes**

Block access to pages that should not exist for a tenant.

### 3. **Backend**

tRPC enforces correct access (source of truth).

### 4. **UI Components**

Small enhancements or experimental features can also be toggled.

### 5. **Modules**

Modules are only “active” if their flag is enabled.

---

# **5. Feature Flag Lifecycle**

### **1. Platform defines modules**

In `/src/modules/<module>/module.config.ts`:

```ts
featureFlag: 'billing'
```

### **2. New tenant is created**

IsoStack clones **platform-level default flags** into the new organisation record.

### **3. Tenant admin enables/disables features**

Done via **Settings → Features** UI.

### **4. UI updates instantly**

* Navigation adjusts
* Module pages protected
* Components hidden

### **5. API checks feature flags before running actions**

Prevents accidental access even if UI is bypassed.

---

# **6. Reading Feature Flags (Frontend)**

Typical pattern:

```tsx
const { data: features } = trpc.features.get.useQuery();
const isBillingEnabled = features?.billing === true;
```

### In UI:

```tsx
{isBillingEnabled && <NavLink href="/billing">Billing</NavLink>}
```

### For components:

```tsx
if (!features?.support) return null;
return <SupportWidget />;
```

### For entire module pages:

```tsx
if (!features?.yourModule) redirect('/dashboard');
```

---

# **7. Reading Feature Flags (Backend)**

Flags are loaded in tRPC via:

```ts
const features = await ctx.prisma.featureFlags.findUnique({
  where: { organizationId: ctx.session.user.organizationId }
});
```

### Enforcing in routers:

```ts
if (!features?.features?.billing) {
  throw new TRPCError({ code: 'FORBIDDEN', message: 'Billing is disabled' });
}
```

Or wrap in middleware:

```ts
export const requireFeature = (flag: string) =>
  middleware(async ({ ctx, next }) => {
    const enabled = ctx.features?.[flag] === true;

    if (!enabled) {
      throw new TRPCError({ code: 'FORBIDDEN' });
    }

    return next();
  });
```

Used like:

```ts
billingRouter = router({
  createInvoice: protectedProcedure
    .use(requireFeature('billing'))
    .mutation(...)
});
```

---

# **8. Feature Flags and Modules**

Each module declares its feature flag key:

```ts
export const bedrockModule = {
  id: 'bedrock',
  featureFlag: 'bedrock',
};
```

Modules are enabled based on:

```ts
if (features[module.featureFlag]) {
  enabledModules.push(module);
}
```

This powers:

* Navigation
* Routing
* Module registry
* Permissions
* Module loading in UI

---

# **9. Platform Default Feature Flags**

Platform Admin can define global defaults:

```
/docs/core/platform-defaults.md (optional future doc)
```

When a new tenant is created:

1. Default flags cloned
2. Custom tenant overrides allowed
3. Future platform updates do *not* auto-apply unless tenant chooses

This mirrors the **Tooltip inheritance model**:

> Clone → Override → Optional reversion

---

# **10. Feature Flag Management UI**

### Where:

```
src/app/(app)/settings/features/page.tsx
```

### Pattern:

```tsx
<Switch
  checked={features.billing}
  label="Enable Billing"
  onChange={(e) =>
    updateFeatures.mutate({ billing: e.currentTarget.checked })
  }
/>
```

### Update route:

```ts
update: protectedProcedure
  .input(z.record(z.boolean()))
  .mutation(async ({ ctx, input }) => {
    return ctx.prisma.featureFlags.update({
      where: { organizationId: ctx.session.user.organizationId },
      data: { features: input },
    });
  });
```

---

# **11. Naming Conventions**

### Module keys

```
billing
support
bedrock
tooltips
analytics
tailoraid
emberbox
lmspro
```

### Avoid:

* CamelCase (`billingModule`)
* Capitalisation (`Billing`)
* Long strings (`feature_billing_enabled`)

### Ideal:

* short
* lowercase
* matches module id where possible

---

# **12. Best Practices**

### ✔ Backend-first enforcement

UI can hide things, but backend is the source of truth.

### ✔ Always check feature flag before showing navigation

Avoid dangling links that 404.

### ✔ Only create a feature flag if:

* A module needs it
* A platform-wide UI feature may be optional
* A beta/experimental feature needs gating

### ✔ Avoid over-flagging

If something is not tenant-specific, do not create a flag for it.

---

# **13. Anti-Patterns**

❌ Feature flags controlling per-user behaviour
(Should be roles/permissions instead)

❌ Deeply nested flag objects
(Flat JSON is easier to manage)

❌ Conditional imports based on flags
(Use dynamic routing, not conditional imports)

❌ Writing flags in UI without backend validation
(Security risk)

---

# **14. Extending the Flag System**

Future enhancements that IsoStack can support:

### 1. **Flag groups** (bundles)

E.g.:

```
SMALL_BUSINESS → support + billing
HEALTHCARE → tailoraid + analytics
```

### 2. **Per-role flag enforcement**

Useful when some features are OWNER-only even if enabled.

### 3. **Time-based feature flags**

Trials, limited access periods.

### 4. **Platform-level toggle UI**

Control defaults for new tenants.

### 5. **Feature flag versioning**

Track when flags change and by whom.

---

# **15. Summary**

Feature flags are a **core part of IsoStack’s multi-tenant, multi-product strategy**.

They allow:

* One shared codebase
* Many independent products
* Per-tenant customisation
* Safe migrations
* Flexible rollouts
* Optional modules
* Consistent architecture

Feature flags work together with:

* Roles & permissions
* Module registry
* Tenant settings
* Tooltip inheritance
* Branding system

Together these systems enable IsoStack’s philosophy:

> **Build once. Deploy many. Customise safely. Maintain sanity.**

