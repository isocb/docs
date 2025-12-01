

# 📘 **IsoStack Platform Default Feature Flags**

**Location:** `/docs/core/platform-default-flags.md`
**Status:** Core Documentation
**Audience:** Developers, Architects, AI Agents

---

# **1. Purpose**

Platform Default Feature Flags define the **starting point** for every new tenant in IsoStack.

When a new organization (tenant) is created, it receives a **cloned copy** of these defaults.
From that point forward:

```
Tenant Flags are independent.
Platform does not auto-overwrite.
Tenants may override individually.
```

This mirrors the **Tooltip inheritance model** and ensures predictable multi-tenant behaviour.

---

# **2. What Platform Defaults Are**

Platform defaults are:

* A **JSON map** of feature flags
* Defined by the platform owner (you)
* Used as the template for onboarding new tenants
* Not dynamic per tenant
* Not directly editable by tenants

Essentially:

```
Platform Default = Blueprint
Tenant Feature Flags = Customised instance of the blueprint
```

---

# **3. Why They Exist**

Platform defaults solve several architectural problems:

### **✔ Consistent onboarding**

Every new tenant starts with the same baseline.

### ✔ Avoids developer duplication

No need to enable flags manually after every onboarding.

### ✔ Safe customisation

Tenants can override without affecting others.

### ✔ Detaches platform decisions from tenant behaviour

Platform Admin updates do **not** force changes downstream.

### ✔ Enables multi-product strategy

e.g., TailorAid tenants vs Bedrock tenants vs EmberBox tenants.

---

# **4. Data Model**

Platform defaults live in:

```
prisma/schema.prisma (singleton record)
```

### Suggested Prisma Model

```prisma
model PlatformFeatureDefaults {
  id       Int    @id @default(1)     // Singleton
  defaults Json   @default("{}")      // Feature map
}
```

### Sample defaults:

```json
{
  "billing": false,
  "support": true,
  "tooltips": true,
  "bedrock": true,
  "tailoraid": false,
  "emberbox": false,
  "analytics": true
}
```

---

# **5. Cloning Logic (On New Tenant Creation)**

### Triggered when:

* A new tenant (Organisation) is created
* Invitation flow creates new organization
* Platform Admin manually creates a new organisation

### Pseudocode:

```ts
const platformDefaults = await prisma.platformFeatureDefaults.findUnique({
  where: { id: 1 }
});

await prisma.featureFlags.create({
  data: {
    organizationId,
    features: platformDefaults.defaults
  }
});
```

### Important:

After cloning:

```
Tenant owns their copy.
Platform defaults become irrelevant for that tenant.
```

---

# **6. How Tenants Override Defaults**

Each tenant maintains its own `FeatureFlags` record:

```ts
await prisma.featureFlags.update({
  where: { organizationId },
  data: { features: { ...existing, billing: true } }
});
```

### Overrides:

* Need no approval from platform
* Do not affect other tenants
* Persist indefinitely
* Are stored permanently in database

### Recommended UI:

**Settings → Features**
(toggle per feature)

---

# **7. How Platform Updates Interact with Tenants**

### ❗ Platform defaults are **not** automatically applied to existing tenants.

If you change the platform defaults:

* New tenants get new defaults
* Existing tenants **remain unchanged**
* No auto-merge
* No hierarchy
* No retroactive enforcement

### Why?

For multi-tenant stability:

Tenants may be paying customers who expect:

* Consistency
* No surprise feature changes
* Predictable behaviour

If platform defaults suddenly overwrite tenant choices, this risks breaking UX contracts.

---

# **8. Manual Update Workflow (Optional)**

If a new platform feature should be rolled out globally:

You manually apply the change using an admin migration script or UI toggle (future):

### Example Script

```ts
const tenants = await prisma.featureFlags.findMany();

for (const tenant of tenants) {
  await prisma.featureFlags.update({
    where: { organizationId: tenant.organizationId },
    data: {
      features: {
        ...tenant.features,
        myNewFeature: true
      }
    }
  });
}
```

### Optional improvements (future):

* "Apply to all tenants" button
* "Apply to selected tenants" batch UI
* Tenant groups (industry profiles)

---

# **9. Recommended Governance Rules**

### 1. **Do NOT change defaults frequently**

Defaults should reflect stable, baseline functionality.

### 2. **Keep defaults minimal**

Enable common/shared functionality only.

Example:

```
tooltips = true  
branding = true  
analytics = true  
billing = false  
sector-specific modules = false  
```

### 3. **Avoid industry-specific defaults**

Sector modules should start off disabled unless selling only one product.

### 4. **Document default changes**

Record changes in:

```
/docs/changelog/core.md
```

### 5. **Provide tenants with autonomy**

Let tenants enable their own features through settings.

---

# **10. Best Practice: Platform Defaults as “New Tenant Profiles”**

You may evolve this into multiple **platform profiles**:

```
Healthcare Default Profile
Financial Services Default Profile
Education Default Profile
General SaaS Default Profile
```

This is especially powerful for:

* TailorAid sectors
* EmberBox variants
* Future industry-specific apps

But: **keep it simple in Version 1.**

---

# **11. Future Enhancements (Supported Later)**

IsoStack’s architecture supports future extensions:

### ✔ Versioning of defaults

Track which version a tenant cloned from.

### ✔ Multi-profile onboarding

Choose "Bedrock Tenant", "TailorAid Tenant", etc.

### ✔ Per-tenant diff view

See what differs from the default profile.

### ✔ Apply updated defaults selectively

Useful when introducing new core features.

### ✔ Wizard-driven selection of module bundles

More intuitive tenant onboarding.

---

# **12. Summary**

Platform Default Feature Flags form the **baseline** for new tenants.

They provide:

* A clean, consistent onboarding experience
* Predictable behaviour
* Multi-product flexibility
* Safe autonomy for tenants
* Alignment with IsoStack’s “build once, deploy many” philosophy

Tenant overrides are always respected, and platform updates never silently overwrite tenant settings.

This document is the **single source of truth** for platform-level flag behaviour across all IsoStack deployments.

