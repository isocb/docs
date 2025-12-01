



---
status: active
architecture: isostack-v1
category: guide
purpose: deployment
---
# Deployment Guide

## Overview
IsoStack V2.0 is deployed to production using **Render**. This guide covers our production deployment process and alternative deployment options.

## Production Deployment (Render)

### Why Render?
- ✅ Simple full-stack deployment
- ✅ Native PostgreSQL database support
- ✅ Automatic HTTPS and SSL
- ✅ GitHub auto-deploy integration
- ✅ Fair pricing for startups
- ✅ **This is what we actually use in production**

### Prerequisites
- GitHub account with access to your IsoStack repository
- Render account (free tier available at [render.com](https://render.com))
- PostgreSQL database (Neon recommended, or Render PostgreSQL)
- Resend account for transactional emails

### Step 1: Create Render Web Service

1. Go to [dashboard.render.com](https://dashboard.render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Configure the service:
   - **Name**: `isostack-v2` (or your preferred app name)
   - **Region**: Choose closest to your users
   - **Branch**: `main`
   - **Runtime**: Node
   - **Build Command**: `npm install && npm run db:generate && npm run build`
   - **Start Command**: `npm start`
   - **Instance Type**: Free tier (or paid tier as needed)

### Step 2: Set Environment Variables

In Render dashboard, add these environment variables:

**Required:**
```bash
# Database
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require

# Authentication
NEXTAUTH_SECRET=your-random-secret-here # Generate: openssl rand -base64 32
NEXTAUTH_URL=https://your-app.onrender.com
AUTH_TRUST_HOST=true

# Email Service
RESEND_API_KEY=re_xxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com
```

**Optional (OAuth):**
```bash
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
```

### Step 3: Set Up Database

**Option A: Using Neon (Recommended)**

1. Visit [neon.tech](https://neon.tech) and create an account
2. Create a new project
3. Copy the connection string (PostgreSQL format)
4. Add to Render as `DATABASE_URL` environment variable

**Option B: Using Render PostgreSQL**

1. In Render dashboard, create new "PostgreSQL" database
2. Copy the internal connection string
3. Add to your web service as `DATABASE_URL` environment variable

### Step 4: Deploy

1. Click "Create Web Service" in Render
2. Render will automatically:
   - Install dependencies
   - Generate Prisma client
   - Build your Next.js application
   - Start the server
3. Your app will be available at: `https://your-app.onrender.com`

### Step 5: Initialize Database

After first deployment, you need to push the database schema:

```bash
# Set DATABASE_URL locally (from Render)
export DATABASE_URL="postgresql://..."

# Push schema to production database
npm run db:push

# Seed initial data
npm run db:seed
```

### Step 6: Verify Deployment

1. Visit your deployed URL
2. Test login with seed credentials (if seeded): `owner@acme.com / password123`
3. Verify key features:
   - Multi-tenant organization switching
   - Tooltip system (press `Shift+?`)
   - Settings pages
   - User management

### Step 7: Custom Domain (Optional)

1. In Render dashboard, go to your service settings
2. Click "Custom Domain"
3. Add your domain (e.g., `app.yourdomain.com`)
4. Follow DNS instructions to point domain to Render
5. Update `NEXTAUTH_URL` environment variable to your custom domain
6. Redeploy to apply changes

## Alternative Deployment Options

### Option 1: Deploy to Vercel

Vercel is an alternative platform built by the Next.js creators.

**Pros:**
- ✅ Zero-config Next.js optimization
- ✅ Automatic HTTPS and CDN
- ✅ Preview deployments for pull requests
- ✅ Generous free tier

**Setup:**

1. Visit [vercel.com](https://vercel.com) and sign in with GitHub
2. Click "Add New Project"
3. Import your IsoStack repository
4. Add environment variables (same as Render setup above)
5. Deploy

**Note:** The platform detection code in `trpc-provider.tsx` already supports Vercel via the `VERCEL_URL` environment variable.

### Option 2: Deploy to Railway

Railway offers simplified full-stack deployment with built-in database support.

**Pros:**
- ✅ Built-in PostgreSQL database
- ✅ Simple CLI workflow
- ✅ Automatic HTTPS

**Setup:**

1. Install Railway CLI: `npm install -g @railway/cli`
2. Login: `railway login`
3. Initialize project: `railway init`
4. Add PostgreSQL: `railway add postgresql`
5. Set environment variables: `railway variables set KEY=value`
6. Deploy: `railway up`

**Note:** The platform detection code in `trpc-provider.tsx` already supports Railway via the `RAILWAY_PUBLIC_DOMAIN` environment variable.

## Database Hosting Options

### Neon (Recommended)

**Pros:**
- ✅ Serverless, auto-scaling PostgreSQL
- ✅ Generous free tier (3GB storage, 191 hours/month)
- ✅ Database branching for preview environments
- ✅ Built-in connection pooling

**Setup:**
1. Create account at [neon.tech](https://neon.tech)
2. Create project and copy connection string
3. Use as `DATABASE_URL` in your deployment platform

### Supabase

**Pros:**
- ✅ Free tier includes PostgreSQL
- ✅ Built-in authentication option
- ✅ Real-time subscriptions
- ✅ Integrated storage

**Setup:**
1. Create project at [supabase.com](https://supabase.com)
2. Get connection string from Settings → Database
3. Use as `DATABASE_URL`

### Render PostgreSQL

**Pros:**
- ✅ Integrated with Render platform
- ✅ Automatic backups
- ✅ Simple setup

**Cons:**
- ❌ No free tier (starts at $7/month)

## Email Configuration

### Using Resend (Required)

IsoStack uses [Resend](https://resend.com) for transactional emails.

**Setup:**

1. Create account at [resend.com](https://resend.com)
2. Add and verify your domain
3. Generate API key
4. Set environment variables:
   ```bash
   RESEND_API_KEY=re_xxxxxxxxxxxx
   EMAIL_FROM=noreply@yourdomain.com
   ```

**For Development/Testing:**

You can skip email sending in development by checking the environment:

```typescript
// The email service already handles this appropriately
// Emails won't be sent if RESEND_API_KEY is not configured
```

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host/db?sslmode=require` |
| `NEXTAUTH_SECRET` | Random secret for session encryption | Generate: `openssl rand -base64 32` |
| `NEXTAUTH_URL` | Full URL of your deployed app | `https://your-app.onrender.com` |
| `AUTH_TRUST_HOST` | Trust proxy headers | `true` |
| `RESEND_API_KEY` | Resend API key for emails | `re_xxxxxxxxxxxx` |
| `EMAIL_FROM` | Sender email address | `noreply@yourdomain.com` |

### Optional Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | From Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret | From Google Cloud Console |

**Note:** The `.env.example` file contains references to additional optional services (R2, video APIs) that are **not currently implemented** in the codebase. These can be safely ignored unless you plan to implement those features yourself.

## Security Checklist

Before going to production:

- [ ] Generate strong `NEXTAUTH_SECRET`: `openssl rand -base64 32`
- [ ] Enable HTTPS (automatic on Render/Vercel/Railway)
- [ ] Set `AUTH_TRUST_HOST=true` for proxy environments
- [ ] Use environment variables for all secrets
- [ ] Never commit `.env` or `.env.local` files
- [ ] Enable database backups (automatic on managed providers)
- [ ] Set up monitoring (Render/Vercel provide basic monitoring)
- [ ] Review and test authentication flow
- [ ] Verify multi-tenant isolation works correctly

## Troubleshooting

### Build Fails

**Error: Prisma Client not found**

Solution: Ensure `prisma generate` runs before build:

```bash
# Build command should be:
npm install && npm run db:generate && npm run build
```

**Error: TypeScript compilation errors**

Solution: Run type check locally first:

```bash
npm run type-check
```

### Database Connection Issues

**Error: Connection timeout**

Check:
1. Database is running and accessible
2. Connection string is correct
3. SSL mode is set: `?sslmode=require`
4. Database firewall allows connections from deployment platform

**Error: Schema not in sync**

Solution: Push schema to production database:

```bash
npm run db:push
```

### Email Not Sending

**Check:**
1. `RESEND_API_KEY` is set correctly
2. Domain is verified in Resend dashboard
3. `EMAIL_FROM` uses your verified domain

### Environment Variables Not Loading

**Render/Vercel/Railway:**
- Environment variable changes require a redeploy
- Verify variables are set for correct environment (Production/Preview)
- Check for typos in variable names

**Local Development:**
- Use `.env.local` not `.env`
- Restart dev server after changing variables

## Performance Tips

### Database Connection Pooling

Prisma handles connection pooling automatically. For high-traffic applications using Neon, connection pooling is built-in.

### Static Page Generation

For public pages that don't change often:

```typescript
// src/app/(public)/pricing/page.tsx
export const dynamic = 'force-static';
```

### Image Optimization

Use Next.js Image component for automatic optimization:

```tsx
import Image from 'next/image';

<Image
  src="/logo.png"
  alt="Logo"
  width={200}
  height={50}
  priority
/>
```

## CI/CD Setup (Optional)

### Automatic Deploys

**Render:**
- Enable "Auto-Deploy" in service settings
- Pushes to `main` branch trigger automatic deployment

**Vercel:**
- Automatic deployment on every push
- Preview deployments for pull requests

**Railway:**
- Enable GitHub integration
- Configure deployment triggers

### GitHub Actions (Optional)

Example workflow for running tests before deployment:

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Type check
        run: npm run type-check
      
      - name: Lint
        run: npm run lint
      
      - name: Run tests
        run: npm test
```

## Summary

**Recommended Production Stack:**
- ✅ **Render** for hosting (our actual platform)
- ✅ **Neon** for PostgreSQL database
- ✅ **Resend** for transactional emails

This combination provides:
- Excellent performance
- Simple deployment workflow
- Generous free tiers for getting started
- Scalability as your application grows
- Minimal configuration required

**Your IsoStack app is now ready for production!**
