---
status: active
architecture: isostack-v1
category: guide
purpose: application-customisation
---

# Customization Guide

## Overview

IsoStack V2.0 is designed to be customized for your specific use case. This guide explains how to extend, modify, and brand IsoStack to build your unique SaaS product.

## Philosophy

IsoStack provides:
- ✅ **Solid Foundation** - Authentication, multi-tenancy, settings
- ✅ **Best Practices** - Security, type safety, architecture patterns
- ✅ **Flexibility** - Easy to modify, extend, and customize

You build:
- 🎨 Your unique features and modules
- 🎨 Your industry-specific logic
- 🎨 Your brand identity

## Quick Wins: Simple Customizations

### 1. Change Application Name

**In multiple files:**

```typescript
// src/app/layout.tsx
export const metadata = {
  title: 'Your App Name',
  description: 'Your app description',
};

// src/app/page.tsx
<Title order={1}>Your App Name</Title>

// src/core/components/layout/Navbar.tsx
<Text size="xl" fw={700}>Your App</Text>
```

### 2. Update Logo

```tsx
// src/core/components/layout/Navbar.tsx
<Image 
  src="/logo.svg" 
  alt="Your Logo" 
  height={32}
/>

// Add your logo to public/ folder
// public/logo.svg
// public/logo-dark.svg (for dark mode)
```

### 3. Change Default Colors

```typescript
// src/core/components/providers/theme-provider.tsx
const theme = createTheme({
  primaryColor: 'blue',    // Change to: violet, teal, grape, etc.
  defaultRadius: 'md',     // sm, md, lg, xl
  // ... other theme options
});
```

### 4. Customize Email Templates

```tsx
// src/server/email/templates/WelcomeEmail.tsx
export function WelcomeEmail({ name }: { name: string }) {
  return (
    <Html>
      <Head />
      <Body>
        <Container>
          <Heading>Welcome to Your App!</Heading>
          <Text>Hi {name}, we're excited to have you...</Text>
          {/* Customize content */}
        </Container>
      </Body>
    </Html>
  );
}
```

### 5. Modify Landing Page

```tsx
// src/app/page.tsx
export default function HomePage() {
  return (
    <Container size="lg">
      <Stack gap="xl">
        {/* Customize hero section */}
        <Title order={1}>Your Unique Value Proposition</Title>
        <Text size="xl">Your compelling description</Text>
        
        {/* Add your features */}
        {/* Add your testimonials */}
        {/* Add your call-to-action */}
      </Stack>
    </Container>
  );
}
```

## Advanced Customizations

### Adding Custom User Fields

**Step 1: Update Prisma Schema**

```prisma
// prisma/schema.prisma
model User {
  // ... existing fields
  
  // Add custom fields
  phoneNumber String?
  department  String?
  jobTitle    String?
  avatar      String?
  metadata    Json @default("{}")
}
```

**Step 2: Push Schema Changes**

```bash
npm run db:push
npm run db:generate
```

**Step 3: Update Registration**

```tsx
// src/app/(auth)/auth/signup/page.tsx
const form = useForm({
  initialValues: {
    email: '',
    name: '',
    password: '',
    phoneNumber: '',    // Add custom field
    department: '',     // Add custom field
  },
});
```

**Step 4: Update Profile Settings**

```tsx
// src/app/(app)/settings/profile/page.tsx
<TextInput
  label="Phone Number"
  {...form.getInputProps('phoneNumber')}
/>
<TextInput
  label="Department"
  {...form.getInputProps('department')}
/>
```

### Adding Custom Organization Fields

**Step 1: Update Schema**

```prisma
model Organization {
  // ... existing fields
  
  // Add custom fields
  industry    String?
  companySize String?
  website     String?
  address     Json @default("{}")
}
```

**Step 2: Update Organization Settings**

```tsx
// src/app/(app)/settings/organization/page.tsx
<Select
  label="Industry"
  data={[
    'Healthcare',
    'Education',
    'Technology',
    'Finance',
  ]}
  {...form.getInputProps('industry')}
/>

<TextInput
  label="Website"
  placeholder="https://yourcompany.com"
  {...form.getInputProps('website')}
/>
```

### Custom Branding Beyond Basics

**Step 1: Extended Branding Fields**

```prisma
model Organization {
  // ... existing fields
  
  // Extended branding
  logoUrl          String?
  logoDarkUrl      String?  // Dark mode logo
  faviconUrl       String?
  primaryColor     String @default("#228be6")
  secondaryColor   String @default("#15aabf")
  accentColor      String @default("#f76707")
  fontFamily       String @default("Inter")
  customCSS        String? @db.Text
}
```

**Step 2: Apply Custom Branding**

```tsx
// src/core/features/branding/hooks.ts
export function useBrandingTheme() {
  const { data: org } = trpc.organizations.getCurrent.useQuery();
  
  return {
    colors: {
      primary: org?.primaryColor || '#228be6',
      secondary: org?.secondaryColor || '#15aabf',
      accent: org?.accentColor || '#f76707',
    },
    fonts: {
      body: org?.fontFamily || 'Inter',
    },
  };
}

// src/core/components/providers/theme-provider.tsx
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const branding = useBrandingTheme();
  
  const theme = createTheme({
    colors: {
      brand: [
        branding.colors.primary,
        // ... color shades
      ],
    },
    fontFamily: branding.fonts.body,
  });
  
  return <MantineProvider theme={theme}>{children}</MantineProvider>;
}
```

### Creating Custom Dashboard Widgets

**Step 1: Create Widget Component**

```tsx
// src/core/components/dashboard/CustomWidget.tsx
export function CustomWidget() {
  const { data } = trpc.yourModule.getStats.useQuery();
  
  return (
    <Card withBorder>
      <Stack gap="xs">
        <Group justify="space-between">
          <Text size="sm" c="dimmed">Your Metric</Text>
          <IconYourIcon size={20} />
        </Group>
        <Text size="xl" fw={700}>{data?.value || 0}</Text>
        <Text size="xs" c="dimmed">+12% from last month</Text>
      </Stack>
    </Card>
  );
}
```

**Step 2: Add to Dashboard**

```tsx
// src/app/(app)/dashboard/page.tsx
import { CustomWidget } from '@/core/components/dashboard/CustomWidget';

export default function DashboardPage() {
  return (
    <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }}>
      <CustomWidget />
      {/* Other widgets */}
    </SimpleGrid>
  );
}
```

### Custom Navigation Structure

**Step 1: Define Navigation Schema**

```typescript
// src/core/config/navigation.ts
export const navigationItems = [
  {
    label: 'Dashboard',
    href: '/dashboard',
    icon: IconDashboard,
  },
  {
    label: 'Your Module',
    href: '/your-module',
    icon: IconYourIcon,
    featureFlag: 'yourModule',
  },
  {
    label: 'Settings',
    href: '/settings',
    icon: IconSettings,
    children: [
      { label: 'Profile', href: '/settings/profile' },
      { label: 'Organization', href: '/settings/organization' },
      // Add more...
    ],
  },
];
```

**Step 2: Use in Navbar**

```tsx
// src/core/components/layout/Navbar.tsx
import { navigationItems } from '@/core/config/navigation';

export function Navbar() {
  const { data: features } = trpc.features.get.useQuery();
  
  return (
    <nav>
      {navigationItems.map((item) => {
        if (item.featureFlag && !features?.[item.featureFlag]) {
          return null;
        }
        
        return <NavLink key={item.href} {...item} />;
      })}
    </nav>
  );
}
```

### Adding Custom Permissions

**Step 1: Extend Role System**

```prisma
// Add custom permissions to User
model User {
  // ... existing fields
  
  permissions Json @default("{}")
  // Example: { "canDeleteUsers": false, "canExportData": true }
}
```

**Step 2: Create Permission Helper**

```typescript
// src/core/features/permissions/helpers.ts
export function hasPermission(
  user: User, 
  permission: string
): boolean {
  if (user.role === 'OWNER') return true;
  
  const perms = user.permissions as Record<string, boolean>;
  return perms[permission] === true;
}

// Use in tRPC
export const protectedWithPermission = (permission: string) => {
  return protectedProcedure.use(async ({ ctx, next }) => {
    const user = await ctx.prisma.user.findUnique({
      where: { id: ctx.session.user.id },
    });
    
    if (!user || !hasPermission(user, permission)) {
      throw new TRPCError({ code: 'FORBIDDEN' });
    }
    
    return next();
  });
};
```

**Step 3: Use in Routes**

```typescript
// src/server/core/routers/your-module.router.ts
export const yourModuleRouter = router({
  dangerousAction: protectedWithPermission('canDeleteUsers')
    .mutation(async ({ ctx }) => {
      // Only users with permission can access
    }),
});
```

### Custom Onboarding Flow

**Step 1: Add Onboarding State**

```prisma
model User {
  // ... existing fields
  
  onboardingComplete Boolean @default(false)
  onboardingStep     Int     @default(0)
}
```

**Step 2: Create Onboarding Component**

```tsx
// src/core/components/onboarding/OnboardingWizard.tsx
export function OnboardingWizard() {
  const { data: user } = trpc.users.getProfile.useQuery();
  const [step, setStep] = useState(user?.onboardingStep || 0);
  
  const steps = [
    <Step1Welcome />,
    <Step2InviteTeam />,
    <Step3ConfigureSettings />,
    <Step4Complete />,
  ];
  
  return (
    <Modal opened={!user?.onboardingComplete}>
      <Stepper active={step}>
        {steps.map((StepComponent, index) => (
          <Stepper.Step key={index}>
            {StepComponent}
          </Stepper.Step>
        ))}
      </Stepper>
    </Modal>
  );
}
```

**Step 3: Add to App Layout**

```tsx
// src/app/(app)/layout.tsx
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <OnboardingWizard />
      <AppShell>{children}</AppShell>
    </>
  );
}
```

### Custom Notification System

**Step 1: Add Notification Model**

```prisma
model Notification {
  id        String   @id @default(uuid())
  title     String
  message   String
  type      String   // "info", "success", "warning", "error"
  read      Boolean  @default(false)
  actionUrl String?
  createdAt DateTime @default(now())
  
  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  organizationId String
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  
  @@map("notifications")
}
```

**Step 2: Create Notification Component**

```tsx
// src/core/components/notifications/NotificationBell.tsx
export function NotificationBell() {
  const { data: notifications } = trpc.notifications.list.useQuery();
  const unreadCount = notifications?.filter(n => !n.read).length || 0;
  
  return (
    <Indicator label={unreadCount} disabled={unreadCount === 0}>
      <ActionIcon onClick={openNotifications}>
        <IconBell />
      </ActionIcon>
    </Indicator>
  );
}
```

**Step 3: Add to Navbar**

```tsx
// src/core/components/layout/Header.tsx
<Group>
  <NotificationBell />
  {/* Other header items */}
</Group>
```

## Styling Customization

### Custom Theme

Full theme customization:

```typescript
// src/core/components/providers/theme-provider.tsx
const theme = createTheme({
  // Colors
  primaryColor: 'blue',
  colors: {
    brand: ['#e6f7ff', '#bae7ff', '#91d5ff', ...],
  },
  
  // Fonts
  fontFamily: 'Inter, sans-serif',
  fontFamilyMonospace: 'Fira Code, monospace',
  headings: {
    fontFamily: 'Poppins, sans-serif',
    fontWeight: '700',
  },
  
  // Spacing
  spacing: {
    xs: '0.5rem',
    sm: '0.75rem',
    md: '1rem',
    lg: '1.5rem',
    xl: '2rem',
  },
  
  // Border radius
  defaultRadius: 'md',
  radius: {
    xs: '0.25rem',
    sm: '0.5rem',
    md: '0.75rem',
    lg: '1rem',
    xl: '1.5rem',
  },
  
  // Shadows
  shadows: {
    xs: '0 1px 3px rgba(0, 0, 0, 0.05)',
    sm: '0 1px 3px rgba(0, 0, 0, 0.1)',
    md: '0 4px 6px rgba(0, 0, 0, 0.1)',
    lg: '0 10px 15px rgba(0, 0, 0, 0.1)',
    xl: '0 20px 25px rgba(0, 0, 0, 0.1)',
  },
});
```

### Custom Global Styles

```css
/* src/styles/globals.css */

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 12px;
}

::-webkit-scrollbar-track {
  background: var(--mantine-color-gray-0);
}

::-webkit-scrollbar-thumb {
  background: var(--mantine-color-gray-4);
  border-radius: 6px;
}

/* Custom animations */
@keyframes slideIn {
  from {
    transform: translateX(-100%);
  }
  to {
    transform: translateX(0);
  }
}

.slide-in {
  animation: slideIn 0.3s ease-out;
}

/* Custom utilities */
.text-gradient {
  background: linear-gradient(to right, #228be6, #15aabf);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
```

## Integrations

### Add Stripe for Payments

**Step 1: Install Stripe**

```bash
npm install stripe @stripe/stripe-js
```

**Step 2: Create Stripe Router**

```typescript
// src/server/modules/stripe.router.ts
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export const stripeRouter = router({
  createCheckoutSession: protectedProcedure
    .input(z.object({ priceId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const session = await stripe.checkout.sessions.create({
        customer_email: ctx.session.user.email,
        line_items: [{ price: input.priceId, quantity: 1 }],
        mode: 'subscription',
        success_url: `${process.env.NEXTAUTH_URL}/billing/success`,
        cancel_url: `${process.env.NEXTAUTH_URL}/billing`,
      });
      
      return { url: session.url };
    }),
});
```

### Add Analytics

**Option 1: Vercel Analytics**

```bash
npm install @vercel/analytics
```

```tsx
// src/app/layout.tsx
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

**Option 2: Google Analytics**

```tsx
// src/app/layout.tsx
<Script src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID" />
<Script id="google-analytics">
  {`
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'GA_MEASUREMENT_ID');
  `}
</Script>
```

### Add Live Chat

**Using Intercom:**

```tsx
// src/core/components/chat/IntercomWidget.tsx
export function IntercomWidget() {
  const { data: user } = trpc.users.getProfile.useQuery();
  
  useEffect(() => {
    if (window.Intercom && user) {
      window.Intercom('boot', {
        app_id: process.env.NEXT_PUBLIC_INTERCOM_APP_ID,
        email: user.email,
        name: user.name,
        user_id: user.id,
      });
    }
  }, [user]);
  
  return null;
}
```

## Testing Your Customizations

### Unit Tests

```typescript
// src/core/features/your-feature/__tests__/yourFeature.test.ts
import { describe, it, expect } from 'vitest';

describe('Your Feature', () => {
  it('should work correctly', () => {
    // Test your customization
  });
});
```

### E2E Tests (Optional)

Using Playwright:

```bash
npm install -D @playwright/test
```

```typescript
// tests/e2e/custom-flow.spec.ts
import { test, expect } from '@playwright/test';

test('custom onboarding flow', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.locator('text=Welcome')).toBeVisible();
  // Test your flow
});
```

## Best Practices

### 1. Don't Modify Core Files Directly

```
❌ BAD:
Editing src/core/components/layout/AppShell.tsx

✅ GOOD:
Create src/components/CustomAppShell.tsx
Import and extend the core component
```

### 2. Use Environment Variables

```typescript
// ✅ GOOD
const apiKey = process.env.YOUR_API_KEY;

// ❌ BAD
const apiKey = 'hardcoded-api-key';
```

### 3. Follow Naming Conventions

```
✅ GOOD:
- PascalCase for components: YourComponent.tsx
- camelCase for utilities: yourHelper.ts
- kebab-case for routes: your-module/

❌ BAD:
- Inconsistent naming
- Generic names (component1.tsx)
```

### 4. Document Your Changes

```typescript
// ✅ GOOD
/**
 * Custom widget for displaying industry-specific metrics
 * @param metric - The metric to display
 * @param trend - The trend direction
 */
export function IndustryWidget({ metric, trend }) {
  // Implementation
}
```

### 5. Keep Updates in Mind

Structure customizations to make updates easier:

```
src/
├── core/              # IsoStack core (rarely modify)
├── custom/            # Your customizations (isolate here)
│   ├── components/
│   ├── features/
│   └── utils/
└── modules/           # Your modules
```

## Getting Help

### Resources

- 📖 [Architecture Docs](./ARCHITECTURE.md)
- 📖 [Tooltip Guide](./TOOLTIPS.md)
- 📖 [Module Guide](./MODULES.md)
- 📖 [Deployment Guide](./DEPLOYMENT.md)

### Community

- 🐛 [Issue Tracker](https://github.com/isocb/IsoStack-V2.0/issues)
- 💬 Discussions (coming soon)

## Summary

IsoStack V2.0 is designed for customization:

- ✅ **Simple**: Change colors, logo, text
- ✅ **Moderate**: Add fields, widgets, pages
- ✅ **Advanced**: Custom modules, integrations, flows

**Start with simple customizations, then build up to your unique SaaS product!**
