# IsoStack V2.0 Architecture

## Overview

IsoStack V2.0 is a production-ready, multi-tenant SaaS starter platform built with a modern TypeScript stack. This document explains the system design, architecture patterns, and key decisions that make IsoStack scalable, secure, and maintainable.

## Technology Stack

### Frontend
- **Next.js 15** - React framework with App Router for server and client components
- **Mantine 7** - Comprehensive UI component library
- **TypeScript 5.x** - Strict mode enabled for maximum type safety
- **Tabler Icons** - Beautiful, customizable icon set

### API Layer
- **tRPC 11** - End-to-end type-safe APIs without code generation
- **Zod** - Runtime schema validation and type inference
- **TanStack Query** - Powerful data fetching and caching

### Database
- **Prisma 5.x** - Modern ORM with excellent TypeScript support
- **PostgreSQL** - Reliable, production-grade relational database
- **Neon** - Recommended serverless PostgreSQL provider

### Authentication
- **NextAuth.js v5** - Flexible authentication library
- **Magic Link** - Primary authentication method (via Resend)
- **Email/Password** - Secondary method with bcrypt hashing
- **Google OAuth** - Optional social authentication

### Services
- **Resend** - Transactional email with React Email templates
- **Cloudflare R2** - S3-compatible object storage for file uploads
- **Wistia/YouTube/Vimeo** - Video embedding with metadata fetching

## Core Architecture Patterns

### 1. Multi-Tenant Data Isolation

IsoStack implements **organization-based multi-tenancy** with complete data isolation.

#### Key Principles:
- Every tenant-specific model has an `organizationId` foreign key
- All queries filter by the user's `organizationId`
- Prisma's `onDelete: Cascade` ensures data cleanup
- UUID primary keys prevent ID enumeration attacks

#### Implementation:

```typescript
// All protected procedures automatically include organization context
const user = await ctx.prisma.user.findUnique({
  where: { id: ctx.session.user.id },
  select: { organizationId: true },
});

// Always filter by organization
const data = await ctx.prisma.someModel.findMany({
  where: { organizationId: user.organizationId },
});
```

#### Database Schema Pattern:

```prisma
model Organization {
  id    String @id @default(uuid())
  name  String
  // ... other fields
  
  users User[]
  // ... other relations
}

model User {
  id             String       @id @default(uuid())
  organizationId String
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  // ... other fields
}
```

### 2. Role-Based Access Control (RBAC)

Three-tier permission system:

- **OWNER** - Full control, can delete organization, manage features, view audit logs
- **ADMIN** - Can manage users, settings, tooltips, and branding
- **MEMBER** - Standard user access to application features

#### Implementation:

```typescript
// In tRPC procedures
const user = await ctx.prisma.user.findUnique({
  where: { id: ctx.session.user.id },
  select: { role: true, organizationId: true },
});

if (user.role !== 'OWNER') {
  throw new TRPCError({ 
    code: 'FORBIDDEN',
    message: 'Only organization owners can perform this action'
  });
}
```
# Platform Superuser

**### 2. 1.  Platform Owner Super-User Role**

****CRITICAL DISTINCTION:**** IsoStack has ****two separate permission systems**** that work independently:

**#### Tenant-Level Roles (Organization-Scoped)**
Standard three-tier RBAC within each organization:
- ****OWNER**** - Full control over their organization
- ****ADMIN**** - Manage users, settings, tooltips within their organization
- ****MEMBER**** - Standard user access within their organization

**#### Platform Owner Role (Cross-Tenant Super-User)**
A ****separate, elevated permission level**** that exists outside the tenant hierarchy:

```prisma
model PlatformAdmin {
  id     String @id @default(uuid())
  userId String @unique
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
}
### Key Characteristics:
* ✅ Cross-tenant access - Can switch between any organization for support/admin
* ✅ Super-user privileges - Access to platform-level features (Issue Tracker, Tenant Management, Global Settings)
* ✅ Independent from tenant roles - A Platform Owner might be a MEMBER in one org, ADMIN in another, and OWNER in a third
* ✅ Persists across organizations - Platform Owner status is tied to the User, not their Organization membership

⠀Checking Platform Owner Status:

TypeScript


// Server-side check
const user = await prisma.user.findUnique({
  where: { id: session.user.id },
  include: { platformAdmin: true },
});

const isPlatformOwner = !!user. platformAdmin;

// Use for platform-level features
if (! isPlatformOwner) {
  throw new TRPCError({ 
    code: 'FORBIDDEN',
    message: 'Platform owner access required'
  });
}
### Route Protection Pattern:

TypeScript


// Platform-only routes (e.g., /platform/issues, /platform/tenants)
export default async function PlatformPage() {
  const session = await auth();
  
  const user = await prisma.user.findUnique({
    where: { id: session.user.id },
    include: { platformAdmin: true },
  });
  
  if (!user?. platformAdmin) {
    redirect('/dashboard');
  }
  
  // Platform owner content
}
### Use Cases:
* 🔧 Issue Tracker - Track bugs/refinements across all tenants
* 👥 Tenant Management - Create, switch between, and support tenant organizations
* ⚙️ Global Settings - Configure platform-wide defaults
* 🔍 Cross-Tenant Support - Access any tenant's data for troubleshooting
* 📊 Platform Analytics - View usage across all organizations

⠀Security Note: Platform Owners can access any tenant's data. This role should be:
* ❌ Never assigned to regular users
* ✅ Only assigned to trusted platform administrators/developers
* ✅ Audited - All platform owner actions should be logged
* ✅ Minimal - Grant this role to as few users as possible

⠀Why This Matters for AI Agents: Many AI models assume a single-tier permission system. IsoStack's dual-layer approach (Tenant RBAC + Platform Owner) is uncommon and must be explicitly checked:

TypeScript


// ❌ WRONG - Only checking tenant role
if (user.role !== 'OWNER') {
  throw new Error('Access denied');
}

// ✅ CORRECT - Check both systems
const isPlatformOwner = !!user.platformAdmin;
const isTenantOwner = user.role === 'OWNER';

if (!isPlatformOwner && !isTenantOwner) {
  throw new Error('Access denied');
}

```prisma
model PlatformAdmin {
  id     String @id @default(uuid())
  userId String @unique
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
}
### 3. Core/Optional Module System

IsoStack uses a **pluggable module architecture** to support multiple products from one codebase.

#### Directory Structure:

```
src/
├── core/                    # Always present
│   ├── features/
│   │   ├── auth/
│   │   ├── organizations/
│   │   ├── users/
│   │   ├── settings/
│   │   ├── tooltips/        ⭐ The differentiator
│   │   └── permissions/
│   └── components/
├── modules/                 # Optional, feature-flagged
│   ├── billing/
│   ├── support/
│   └── module.registry.ts
```

#### Module Pattern:

```typescript
// modules/billing/module.config.ts
export const billingModule = {
  id: 'billing',
  name: 'Billing',
  description: 'Invoice and subscription management',
  routes: [
    { path: '/billing', component: BillingDashboard },
    { path: '/billing/invoices', component: Invoices },
  ],
  permissions: ['ADMIN', 'OWNER'],
};
```

### 4. Feature Flags

Per-tenant feature toggles control module availability.

```prisma
model FeatureFlag {
  id             String       @id @default(uuid())
  features       Json         @default("{\"billing\": false, \"support\": false}")
  organizationId String       @unique
  organization   Organization @relation(...)
}
```

#### Usage:

```typescript
// Check if feature is enabled
const { data: features } = trpc.features.get.useQuery();
const billingEnabled = features?.features?.billing === true;

// Conditionally render
{billingEnabled && <BillingModule />}
```

### 5. Audit Logging

Complete audit trail for compliance and security.

```prisma
model AuditLog {
  id         String   @id @default(uuid())
  action     String   // e.g., "USER_CREATED", "SETTINGS_UPDATED"
  entityType String   // e.g., "User", "Organization"
  entityId   String?
  metadata   Json     @default("{}")
  ipAddress  String?
  userAgent  String?
  createdAt  DateTime @default(now())
  
  userId         String?
  organizationId String
}
```

#### Implementation:

```typescript
// After important operations
await ctx.prisma.auditLog.create({
  data: {
    action: 'USER_CREATED',
    entityType: 'User',
    entityId: newUser.id,
    metadata: { email: newUser.email, role: newUser.role },
    userId: ctx.session.user.id,
    organizationId: user.organizationId,
  },
});
```

## The Tooltip System ⭐

The flagship feature of IsoStack - a **Single Source of Truth (SSOT) for contextual help** with **three-tier inheritance**.

> **📘 Complete Specification:** See the [IsoStack Manifesto: Visual Multi-Tier Tooltip System](./MANIFESTO.md) for comprehensive documentation including business implications, onboarding logic, and API endpoints.

**Related Issues:** #spec-multitier-visual-tooltips-isostack, #7 (isocb/IsoStack-V2.0#7)

### Key Features:

1. **Three-Tier Tooltip Inheritance**
   - **Tier 1 (Global)**: Platform defaults apply to all organizations (`organizationId = null`)
   - **Tier 2 (App Owner)**: Industry-specific customizations (`isAppOwner = true`)
   - **Tier 3 (Tenant)**: Organization-specific overrides
   - Auto-cloning: New tenants receive app owner tooltips on creation
   - Revert options: Tenants can inherit from parent tiers

2. **Keyboard Shortcuts**
   - `Shift+?` - Toggle help visibility (all users)
   - `Ctrl+Shift+?` - Enter Tooltip Mode for editing (admins only)

3. **Component Integration**

```tsx
import { TooltipAnchor } from '@/core/features/tooltips/TooltipAnchor';

<Title>Dashboard <TooltipAnchor componentId="dashboard.welcome" /></Title>
```

4. **Zustand State Management**

```typescript
// tooltip-store.ts
export const useTooltipStore = create<TooltipStore>((set) => ({
  tooltipMode: false,
  helpVisible: true,
  toggleTooltipMode: () => set((state) => ({ tooltipMode: !state.tooltipMode })),
  toggleHelpVisible: () => set((state) => ({ helpVisible: !state.helpVisible })),
}));
```

5. **Database Schema (Enhanced for Three-Tier)**

```prisma
model Tooltip {
  id             String        @id @default(uuid())
  componentId    String        // Unique identifier
  title          String
  content        String        @db.Text
  placement      String        @default("top")
  criticality    String        @default("info")
  
  // Three-tier support
  organizationId String?       // NULL = global, value = tenant or app owner
  clonedFrom     String?       // Tracks inheritance origin
  
  @@unique([componentId, organizationId])
  @@index([componentId, organizationId])
}

model Organization {
  id         String   @id @default(uuid())
  name       String
  isAppOwner Boolean  @default(false)  // Marks Tier 2: App Owner
  tooltips   Tooltip[]
}
```

### Why This Matters:

- **One Codebase, Multiple Industries** - Build TailorAid (elderly care), EmberBox (cannabis), and more from one platform
- **Professional from Day One** - Tenants get industry-appropriate help via auto-cloning
- **Reduces support tickets** - Contextual, industry-specific guidance reduces support burden by 40-60%
- **Tenant customization** - Organizations can add internal processes and terminology
- **Admin empowerment** - Non-technical admins can update help content via Tooltip Mode
- **Scalable Architecture** - Efficient resolution with single query and proper indexing

> **📘 Implementation Details:** See [Manifesto: Tooltip Resolution Algorithm](./MANIFESTO.md#5-tooltip-resolution-algorithm) for query patterns and performance optimization.

## Media Management

### File Storage (Cloudflare R2)

```prisma
model MediaFile {
  id        String   @id @default(uuid())
  name      String
  fileName  String
  fileUrl   String   // R2 public URL
  fileSize  Int
  mimeType  String
  organizationId String
}
```

### Video Embeds

```prisma
model VideoEmbed {
  id           String  @id @default(uuid())
  title        String
  embedUrl     String
  thumbnailUrl String?
  provider     String  // "youtube", "vimeo", "wistia"
  providerId   String
  duration     Int?
  metadata     Json
  organizationId String
}
```

### Media Usage Tracking

```prisma
model MediaUsage {
  id         String  @id @default(uuid())
  entityType String  // "Tooltip", "Page", "Email"
  entityId   String
  
  mediaFileId  String?
  videoEmbedId String?
  organizationId String
}
```

## Security Considerations

### 1. UUID Primary Keys
- Prevents sequential ID enumeration
- Impossible to guess valid IDs
- No information leakage about record count

### 2. Multi-Tenant Isolation
- Every query filters by `organizationId`
- Impossible to access another tenant's data
- Database constraints enforce relationships

### 3. Authentication Security
- Bcrypt with 12 rounds for password hashing
- Magic links expire after 24 hours
- CSRF protection via NextAuth
- Secure session cookies

### 4. Input Validation
- Zod schemas validate all inputs
- TypeScript provides compile-time safety
- Prisma prevents SQL injection

### 5. Rate Limiting (Recommended)
```typescript
// Add to production
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
```

## Deployment Architecture

### Recommended Stack:
- **Frontend & API**: Vercel (Next.js optimization)
- **Database**: Neon PostgreSQL (serverless, auto-scaling)
- **Email**: Resend (high deliverability)
- **Storage**: Cloudflare R2 (cost-effective, S3-compatible)

### Environment Variables:

```bash
# Database
DATABASE_URL="postgresql://..."

# Auth
NEXTAUTH_SECRET="..."
NEXTAUTH_URL="https://yourdomain.com"

# Email
RESEND_API_KEY="re_..."
EMAIL_FROM="noreply@yourdomain.com"

# Storage (optional)
R2_ACCOUNT_ID="..."
R2_ACCESS_KEY_ID="..."
R2_SECRET_ACCESS_KEY="..."
R2_BUCKET_NAME="..."
R2_PUBLIC_URL="https://..."

# Video APIs (optional)
WISTIA_API_TOKEN="..."
YOUTUBE_API_KEY="..."
VIMEO_ACCESS_TOKEN="..."
```

### Scaling Considerations:

1. **Database Connection Pooling**
   - Use Prisma connection pooling
   - Consider PgBouncer for high traffic

2. **Caching**
   - TanStack Query provides client-side caching
   - Consider Redis for server-side caching

3. **CDN**
   - Vercel provides automatic CDN
   - Cloudflare R2 has built-in CDN

4. **Monitoring**
   - Vercel Analytics for performance
   - Sentry for error tracking
   - Prisma metrics for database

## Development Workflow

### 1. Database Changes

```bash
# Update schema
vim prisma/schema.prisma

# Push to database
npm run db:push

# Generate Prisma Client
npm run db:generate

# Seed data
npm run db:seed
```

### 2. Type Safety

```bash
# Type check
npm run type-check

# Lint
npm run lint

# Format
npm run format
```

### 3. Testing

```bash
# Run tests
npm run test

# Watch mode
npm run test:watch
```

## Best Practices

### 1. Always Filter by Organization
```typescript
// ❌ BAD - No organization filter
const users = await prisma.user.findMany();

// ✅ GOOD - Filtered by organization
const users = await prisma.user.findMany({
  where: { organizationId: user.organizationId },
});
```

### 2. Use Protected Procedures
```typescript
// ❌ BAD - Public procedure for sensitive data
publicProcedure.query(async ({ ctx }) => {
  // Anyone can access this
});

// ✅ GOOD - Protected procedure
protectedProcedure.query(async ({ ctx }) => {
  // Only authenticated users
  // ctx.session.user is guaranteed to exist
});
```

### 3. Audit Important Actions
```typescript
// After creating/updating/deleting important data
await ctx.prisma.auditLog.create({
  data: {
    action: 'ACTION_NAME',
    entityType: 'EntityType',
    entityId: entity.id,
    metadata: { /* relevant data */ },
    userId: ctx.session.user.id,
    organizationId: user.organizationId,
  },
});
```

### 4. Use TooltipAnchors Liberally
```tsx
// Add tooltips to all important UI elements
<Title>
  Settings <TooltipAnchor componentId="settings.title" />
</Title>
```

## Troubleshooting

### Common Issues:

1. **Prisma Client not found**
   ```bash
   npm run db:generate
   ```

2. **Type errors after schema change**
   ```bash
   npm run db:generate
   npm run type-check
   ```

3. **Email not sending**
   - Check RESEND_API_KEY in .env
   - Verify domain in Resend dashboard

4. **Multi-tenant data leakage**
   - Always filter by organizationId
   - Check tRPC context properly extracts user

## Next Steps

- Review [Tooltip System Guide](./TOOLTIPS.md)
- Learn [Module Development](./MODULES.md)
- Follow [Deployment Guide](./DEPLOYMENT.md)
- Explore [Customization Options](./CUSTOMIZATION.md)
