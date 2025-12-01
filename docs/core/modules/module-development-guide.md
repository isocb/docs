
---
status: active
architecture: isostack-v1
category: core
subsystem: modules
purpose: module-development
---

# Module Development Guide

## Overview

IsoStack V2.0 uses a **pluggable module architecture** that allows you to build multiple sector-specific products from a single codebase. This guide explains how to create, configure, and deploy custom modules.

## Core vs. Optional Architecture

### Core Features (Always Present)
Located in `src/core/`:
- Authentication & authorization
- Multi-tenant organization management
- User management
- Settings & preferences
- **Tooltip System** ⭐
- Branding & customization
- Audit logging

### Optional Modules (Feature-Flagged)
Located in `src/modules/`:
- **Billing** - Invoice and subscription management
- **Support** - Ticket system and knowledge base
- **Your Custom Module** - Build anything!

## Why Use Modules?

### Traditional Approach (Problems):
- Separate codebases for each product
- Duplicated authentication, user management, etc.
- Hard to maintain consistency
- Expensive to add shared features

### IsoStack Approach (Solutions):
- ✅ **Single Codebase** - One application, multiple products
- ✅ **Feature Flags** - Enable/disable per tenant
- ✅ **Shared Core** - All products benefit from core improvements
- ✅ **Rapid Development** - Focus on domain logic, not infrastructure
- ✅ **Cost Effective** - Deploy once, serve many industries

## Quick Start: Creating a Module

### Step 1: Create Module Directory

```bash
mkdir -p src/modules/your-module
```

### Step 2: Create Module Configuration

```typescript
// src/modules/your-module/module.config.ts
import { ModuleConfig } from '@/types/module';

export const yourModule: ModuleConfig = {
  id: 'your-module',
  name: 'Your Module',
  description: 'Description of what your module does',
  version: '1.0.0',
  
  // Routes that belong to this module
  routes: [
    {
      path: '/your-module',
      label: 'Your Module',
    },
    {
      path: '/your-module/settings',
      label: 'Module Settings',
    },
  ],
  
  // Required permissions
  permissions: ['MEMBER', 'ADMIN', 'OWNER'],
  
  // Feature flag key
  featureFlag: 'yourModule',
};
```

### Step 3: Register Module

```typescript
// src/modules/module.registry.ts
import { billingModule } from './billing/module.config';
import { supportModule } from './support/module.config';
import { yourModule } from './your-module/module.config';

export const modules = [
  billingModule,
  supportModule,
  yourModule, // Add your module
];

export function getModule(id: string) {
  return modules.find((module) => module.id === id);
}

export function getEnabledModules(features: Record<string, boolean>) {
  return modules.filter((module) => features[module.featureFlag] === true);
}
```

### Step 4: Create Pages

```tsx
// src/app/(app)/your-module/page.tsx
'use client';

import { Title, Text, Stack } from '@mantine/core';
import { TooltipAnchor } from '@/core/features/tooltips/TooltipAnchor';

export default function YourModulePage() {
  return (
    <Stack gap="md">
      <Title>
        Your Module <TooltipAnchor componentId="your-module.welcome" />
      </Title>
      <Text>Welcome to your custom module!</Text>
    </Stack>
  );
}
```

### Step 5: Add tRPC Router (Optional)

```typescript
// src/server/modules/your-module.router.ts
import { router, protectedProcedure } from '@/server/core/trpc';
import { z } from 'zod';

export const yourModuleRouter = router({
  list: protectedProcedure.query(async ({ ctx }) => {
    const user = await ctx.prisma.user.findUnique({
      where: { id: ctx.session.user.id },
      select: { organizationId: true },
    });

    // Your logic here
    return [];
  }),

  create: protectedProcedure
    .input(z.object({
      name: z.string(),
    }))
    .mutation(async ({ ctx, input }) => {
      // Your logic here
    }),
});
```

### Step 6: Update Feature Flags

```typescript
// Update FeatureFlag default in prisma/schema.prisma
features Json @default("{\"billing\": false, \"support\": false, \"yourModule\": false}")
```

## Module Structure

Recommended directory structure for a module:

```
src/modules/your-module/
├── module.config.ts          # Module metadata
├── components/               # Module-specific components
│   ├── YourModuleCard.tsx
│   └── YourModuleList.tsx
├── hooks/                    # Module-specific hooks
│   └── useYourModule.ts
├── types/                    # Module-specific types
│   └── index.ts
└── utils/                    # Module-specific utilities
    └── helpers.ts
```

Pages go in App Router:
```
src/app/(app)/your-module/
├── page.tsx                  # Main module page
├── settings/
│   └── page.tsx             # Module settings
└── [id]/
    └── page.tsx             # Detail pages
```

Backend routers:
```
src/server/modules/
└── your-module.router.ts     # tRPC router
```

## Database Models

### Option 1: Module-Specific Models

Add models to `prisma/schema.prisma`:

```prisma
model YourModuleItem {
  id        String   @id @default(uuid())
  name      String
  data      Json     @default("{}")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Always include organization for multi-tenancy
  organizationId String
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)

  @@map("your_module_items")
}
```

Don't forget to add relation to Organization:

```prisma
model Organization {
  // ... existing fields
  
  yourModuleItems YourModuleItem[]
}
```

### Option 2: Generic JSON Storage

For simpler modules, use JSON fields:

```prisma
model Organization {
  // ... existing fields
  
  moduleData Json @default("{}") // Store all module data here
}
```

## Feature Flag Integration

### Check Feature Flags in UI

```tsx
'use client';

import { trpc } from '@/lib/trpc/client';

export function YourModuleButton() {
  const { data: features } = trpc.features.get.useQuery();
  const isEnabled = features?.features?.yourModule === true;

  if (!isEnabled) {
    return null; // Don't show if disabled
  }

  return <Button>Your Module</Button>;
}
```

### Route Protection

```typescript
// src/middleware.ts
import { getToken } from 'next-auth/jwt';
import { NextResponse } from 'next/server';

export async function middleware(request: NextRequest) {
  const token = await getToken({ req: request });
  
  if (request.nextUrl.pathname.startsWith('/your-module')) {
    // Check if module is enabled for this organization
    const features = await prisma.featureFlag.findUnique({
      where: { organizationId: token.organizationId },
    });
    
    if (!features?.features?.yourModule) {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
  }

  return NextResponse.next();
}
```

### Navigation Integration

```tsx
// src/core/components/layout/Navbar.tsx
export function Navbar() {
  const { data: features } = trpc.features.get.useQuery();
  const { data: modules } = useModuleRegistry();

  return (
    <nav>
      {/* Core routes */}
      <NavLink href="/dashboard">Dashboard</NavLink>
      
      {/* Module routes */}
      {modules.map((module) => {
        const isEnabled = features?.features?.[module.featureFlag];
        if (!isEnabled) return null;
        
        return (
          <NavLink key={module.id} href={`/${module.id}`}>
            {module.name}
          </NavLink>
        );
      })}
    </nav>
  );
}
```

## Examples: Existing Modules

### Billing Module

```typescript
// src/modules/billing/module.config.ts
export const billingModule: ModuleConfig = {
  id: 'billing',
  name: 'Billing',
  description: 'Invoice and subscription management',
  version: '1.0.0',
  routes: [
    { path: '/billing', label: 'Billing' },
    { path: '/billing/invoices', label: 'Invoices' },
    { path: '/billing/subscriptions', label: 'Subscriptions' },
  ],
  permissions: ['ADMIN', 'OWNER'],
  featureFlag: 'billing',
};
```

### Support Module

```typescript
// src/modules/support/module.config.ts
export const supportModule: ModuleConfig = {
  id: 'support',
  name: 'Support',
  description: 'Customer support ticket system',
  version: '1.0.0',
  routes: [
    { path: '/support', label: 'Support' },
    { path: '/support/tickets', label: 'Tickets' },
    { path: '/support/knowledge-base', label: 'Knowledge Base' },
  ],
  permissions: ['MEMBER', 'ADMIN', 'OWNER'],
  featureFlag: 'support',
};
```

## Real-World Module Ideas

### Healthcare Module (TailorAid)

```typescript
export const healthcareModule: ModuleConfig = {
  id: 'healthcare',
  name: 'Healthcare Management',
  description: 'Patient care management and scheduling',
  routes: [
    { path: '/healthcare/patients', label: 'Patients' },
    { path: '/healthcare/appointments', label: 'Appointments' },
    { path: '/healthcare/care-plans', label: 'Care Plans' },
  ],
  permissions: ['ADMIN', 'OWNER'],
  featureFlag: 'healthcare',
};
```

### Cannabis Module (EmberBox)

```typescript
export const cannabisModule: ModuleConfig = {
  id: 'cannabis',
  name: 'Cannabis Compliance',
  description: 'Track-and-trace compliance for cannabis industry',
  routes: [
    { path: '/cannabis/inventory', label: 'Inventory' },
    { path: '/cannabis/compliance', label: 'Compliance' },
    { path: '/cannabis/reports', label: 'Reports' },
  ],
  permissions: ['ADMIN', 'OWNER'],
  featureFlag: 'cannabis',
};
```

### E-Learning Module

```typescript
export const elearningModule: ModuleConfig = {
  id: 'elearning',
  name: 'E-Learning',
  description: 'Course management and student tracking',
  routes: [
    { path: '/elearning/courses', label: 'Courses' },
    { path: '/elearning/students', label: 'Students' },
    { path: '/elearning/assignments', label: 'Assignments' },
  ],
  permissions: ['MEMBER', 'ADMIN', 'OWNER'],
  featureFlag: 'elearning',
};
```

## Advanced Patterns

### Module Dependencies

```typescript
export const advancedModule: ModuleConfig = {
  id: 'advanced-module',
  name: 'Advanced Module',
  description: 'Requires billing module',
  dependencies: ['billing'], // Requires billing module
  routes: [/* ... */],
  permissions: ['ADMIN', 'OWNER'],
  featureFlag: 'advancedModule',
};

// In module.registry.ts
export function canEnableModule(
  moduleId: string, 
  enabledFeatures: Record<string, boolean>
) {
  const module = getModule(moduleId);
  if (!module) return false;
  
  // Check dependencies
  if (module.dependencies) {
    for (const dep of module.dependencies) {
      const depModule = getModule(dep);
      if (!depModule || !enabledFeatures[depModule.featureFlag]) {
        return false;
      }
    }
  }
  
  return true;
}
```

### Module Settings

```typescript
// src/app/(app)/your-module/settings/page.tsx
'use client';

export default function YourModuleSettings() {
  const { data: settings } = trpc.yourModule.getSettings.useQuery();
  const updateSettings = trpc.yourModule.updateSettings.useMutation();

  return (
    <Stack gap="md">
      <Title>Module Settings</Title>
      <Switch
        label="Enable Advanced Features"
        checked={settings?.advancedFeatures}
        onChange={(event) => 
          updateSettings.mutate({ 
            advancedFeatures: event.currentTarget.checked 
          })
        }
      />
    </Stack>
  );
}
```

### Module Permissions

```typescript
// In your module router
export const yourModuleRouter = router({
  adminOnly: protectedProcedure
    .query(async ({ ctx }) => {
      const user = await ctx.prisma.user.findUnique({
        where: { id: ctx.session.user.id },
        select: { role: true },
      });

      if (user.role === 'MEMBER') {
        throw new TRPCError({ 
          code: 'FORBIDDEN',
          message: 'Admin access required'
        });
      }

      // Admin logic
    }),
});
```

## Testing Modules

### Unit Tests

```typescript
// src/modules/your-module/__tests__/yourModule.test.ts
import { describe, it, expect } from 'vitest';
import { yourModuleFunction } from '../utils/helpers';

describe('YourModule', () => {
  it('should process data correctly', () => {
    const result = yourModuleFunction({ input: 'test' });
    expect(result).toBe('expected output');
  });
});
```

### Integration Tests

```typescript
// Test feature flag integration
describe('YourModule Feature Flag', () => {
  it('should hide routes when disabled', async () => {
    const features = { yourModule: false };
    const modules = getEnabledModules(features);
    expect(modules.find(m => m.id === 'your-module')).toBeUndefined();
  });

  it('should show routes when enabled', async () => {
    const features = { yourModule: true };
    const modules = getEnabledModules(features);
    expect(modules.find(m => m.id === 'your-module')).toBeDefined();
  });
});
```

## Deployment Strategy

### Single Deployment, Multiple Products

```bash
# .env for Acme Corp (Healthcare)
FEATURES_BILLING=true
FEATURES_HEALTHCARE=true
FEATURES_CANNABIS=false
FEATURES_SUPPORT=true

# .env for EmberBox (Cannabis)
FEATURES_BILLING=true
FEATURES_HEALTHCARE=false
FEATURES_CANNABIS=true
FEATURES_SUPPORT=true
```

### Per-Tenant Configuration

Feature flags stored in database, configured via Settings > Features:

```typescript
// Settings > Features page
const toggleFeature = trpc.features.update.useMutation({
  onSuccess: () => {
    notifications.show({
      title: 'Success',
      message: 'Feature updated successfully',
      color: 'green',
    });
  },
});

<Switch
  label="Enable Billing Module"
  checked={features.billing}
  onChange={(e) => 
    toggleFeature.mutate({ 
      billing: e.currentTarget.checked 
    })
  }
/>
```

## Best Practices

### 1. Keep Modules Independent

```
✅ GOOD:
- Module has its own components, hooks, utilities
- Module only imports from core, not other modules
- Module can be enabled/disabled without breaking app

❌ BAD:
- Module imports from another module
- Module modifies core functionality
- Module has hard-coded feature checks
```

### 2. Use Descriptive Names

```
✅ GOOD:
- healthcare-module
- billing-module
- inventory-management

❌ BAD:
- module1
- new-feature
- temp-module
```

### 3. Document Dependencies

```typescript
export const myModule: ModuleConfig = {
  // ... other config
  dependencies: ['billing'], // Clearly state dependencies
  requirements: 'Requires Stripe integration', // Document external requirements
};
```

### 4. Add Tooltips

```tsx
// Always add tooltips for module features
<Title>
  Module Feature <TooltipAnchor componentId="your-module.feature" />
</Title>
```

### 5. Audit Log Important Actions

```typescript
// In module mutations
await ctx.prisma.auditLog.create({
  data: {
    action: 'YOUR_MODULE_ACTION',
    entityType: 'YourModuleEntity',
    entityId: entity.id,
    metadata: { /* relevant data */ },
    userId: ctx.session.user.id,
    organizationId: user.organizationId,
  },
});
```

## Troubleshooting

### Module Not Showing

**Check 1: Feature Flag**
- Go to Settings > Features
- Enable the module

**Check 2: Permissions**
- Check module.config.ts permissions array
- Verify user role

**Check 3: Module Registry**
- Ensure module is registered in module.registry.ts

### Module Route 404

**Check 1: Page File**
- Verify file exists at `src/app/(app)/your-module/page.tsx`

**Check 2: Layout**
- Ensure protected layout wraps your module routes

### TypeScript Errors

**Solution:**
```bash
npm run db:generate  # Regenerate Prisma client
npm run type-check   # Verify types
```

## Summary

The module system enables:
- ✅ **Rapid Development** - Focus on domain logic
- ✅ **Cost Effectiveness** - One codebase, multiple products
- ✅ **Flexibility** - Enable/disable per tenant
- ✅ **Scalability** - Add modules without breaking existing functionality

**Start building your custom module today!**
