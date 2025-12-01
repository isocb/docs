
---
title: conventions.md
description: Naming conventions used by Isoblue
author: Isoblue Ltd
maintainer: CB
created: 1/12/2025
updated: 
status:  active 
tags:
  - isostack
  - <module/app name>
  - documentation
  - internal
related:
  - ../path/to/another/doc.md
  - ../../core/architecture.md
---

# Naming Conventions used by Isoblue

*Last updated: 1/12/2025*

> **Purpose:**  
> This document is to create file name consistency across development to minimise errors.
>
> **Applies to:**  
> Core | Module | Connector | App | Guide | Policy - EVERYTHING
>
> **Prerequisites:**  
Development understnading would be an advantage.

# **IsoStack Repository Naming Standard v1.0**

*Isoblue Ltd – Engineering & Architecture*

---

## **1. Purpose**

This document defines the official naming conventions for:

* IsoStack repositories
* IsoStack modules
* IsoStack connectors
* IsoStack applications (SaaS products)
* Internal Isoblue utilities
* Migration and experimental repos
* Branches
* Files, folders, and environments
* Documents

The goal is to create a **consistent, predictable, scalable, and professional** naming structure that supports:

* multi-tenant SaaS development
* AI-assisted workflows
* clean organisation on GitHub
* cross-team comprehension
* long-term maintainability
* non-breaking Git behaviours (case-sensitivity, remotes, etc.)

This standard applies to all new projects.
Existing repos should be migrated to this convention over time.

---

## **2. Naming Principles**

1. **All repository names MUST be lowercase**
   (avoids Git case-sensitivity issues)

2. **Use hyphens (`-`) not underscores (`_`)**
   (GitHub standard; improves readability)

3. **Prefer descriptive names over brand names**
   (easier for external developers and AI-assisted tooling)

4. **One repository = one module/service**
   (clear boundaries, easier CI/CD, easier security reviews)

5. **Prefix by function**
   (clusters related repos together)

6. **Avoid abbreviations where possible**
   (future-proofing)

7. **Avoid special characters** except hyphen
   (URL safety)

---

## **3. Prefix Groups**

All official IsoStack ecosystem repos must use one of the following prefixes:

### **3.1 IsoStack Core**

```
isostack-<component>
```

### **3.2 IsoStack Modules**

```
isostack-module-<module>
```

Modules are pluggable sub-systems used across all apps.

### **3.3 IsoStack Connectors (Integrations)**

```
isostack-connector-<service>
```

Integration with third-party systems (e.g., Knack, R2, Google Workspace).

### **3.4 IsoStack Applications (SaaS products)**

```
isoapp-<product>
```

These are user-facing products built *on* the stack.

### **3.5 Isoblue Internal Utility Repos**

```
isoblue-<utility>
```

### **3.6 Migration Repos**

```
migration-<product>-<source>
```

### **3.7 Experimental / Research Repos**

```
lab-<experiment>
exp-<experiment>
```

---

## **4. Official Repository Naming Rules**

### **4.1 IsoStack Core**

The core platform, framework, and foundational libraries.

Examples:

```
isostack-core
isostack-platform
isostack-cli
```

---

### **4.2 IsoStack Modules (pluggable platform modules)**

Examples:

```
isostack-module-bedrock
isostack-module-tooltips
isostack-module-branding
isostack-module-billing
isostack-module-support
```

Characteristics of a module repo:

* has a well-defined API
* can be enabled/disabled per tenant
* is versioned independently
* may have its own schema migrations

---

### **4.3 IsoStack Connectors**

Integrations with external systems MUST be named:

```
isostack-connector-<service>
```

Examples:

```
isostack-connector-knack
isostack-connector-supabase
isostack-connector-cloudflare
isostack-connector-render
isostack-connector-googleworkspace
isostack-connector-ecwid
```

---

### **4.4 IsoStack Applications (SaaS Products)**

Consumer-facing SaaS products should use:

```
isoapp-<product>
```

Examples with your current products:

```
isoapp-emberbox
isoapp-tailoraid
isoapp-apikeychain
isoapp-lmspro
isoapp-sparkaid
```

Guidelines:

* Names should be short, brandable, product-centric
* Only the prefix carries system meaning
* Avoid embedding “isostack” in app names

---

### **4.5 Isoblue Utilities & Supporting Repos**

Internal tools, websites, templates:

```
isoblue-website
isoblue-utils
isoblue-devops
isoblue-design-system
isoblue-templates
```

---

### **4.6 Migration Repos**

Used only for temporary Floot/Base44/Xano-to-IsoStack migrations.

```
migration-tailoraid-floot
migration-bedrock-floot
migration-apikeychain-base44
```

Once complete, repos should be archived.

---

### **4.7 Experimental Repos**

R&D, prototypes, AI-agent experiments:

```
lab-bedrock-r2-cache
lab-knack-api-proxy
exp-context-mapper
exp-realtime-dashboard
```

These should remain small, disposable, and isolated.

---

## **5. Branch Naming Standard**

To support your **Dev → Staging → Production** flow, branches must follow:

### **5.1 Mainline Branches**

```
main
staging
dev
```

### **5.2 Feature Branches**

```
feature/<name>
```

Examples:

```
feature/tenant-billing
feature/r2-file-upload
```

### **5.3 Module-Specific Feature Branches**

```
module-bedrock/<feature>
module-tooltips/<feature>
```

### **5.4 Bugfix Branches**

```
fix/<issue>
```

### **5.5 Hotfixes for Production**

```
hotfix/<issue>
```

### **5.6 Naming Hygiene**

* must use lowercase
* hyphens allowed
* slashes MUST only separate logical segments
* keep names short

---

## **6. File & Folder Naming Conventions**

### **6.1 Repo root folder (local machine)**

Should match the repo name exactly:

```
isostack-module-bedrock
isoapp-emberbox
```

### **6.2 Code files**

Use **camelCase**:

```
authHandler.ts
tenantService.ts
fileUploader.ts
```

### **6.3 Folders**

Use **kebab-case**:

```
/server
/api
/components
/hooks
/modules
```

### **6.4 Database columns**

Use **snake_case** (Postgres + Prisma-friendly):

```
tenant_id
created_at
module_enabled
branding_color_primary
```

### **6.5 Environment variables**

Use **UPPERCASE_SNAKE_CASE**:

```
DATABASE_URL
NEXTAUTH_SECRET
CLOUDFLARE_R2_BUCKET
RESEND_API_KEY
```

---

## **7. Versioning Conventions**

### **7.1 Modules**

Semantic versioning:

```
isostack-module-bedrock v1.4.2
```

### **7.2 Apps**

Product release naming:

```
emberbox v2025.2
tailoraid v2025.1-beta
```

### **7.3 Platform**

```
isostack-core v2.0
```

---

## **8. Renaming Existing Repos**

When bringing existing repos into compliance:

1. Rename on GitHub
2. Update VS Code remote
3. Rename local folder
4. Ensure CI/CD remotes updated
5. Update relevant documentation
6. Retag releases if necessary

---

## **9. Examples of Your Ecosystem After Adoption**

### Core

```
isostack-core
```

### Modules

```
isostack-module-bedrock
isostack-module-tooltips
isostack-module-support
isostack-module-branding
```

### Connectors

```
isostack-connector-knack
isostack-connector-cloudflare
isostack-connector-ecwid
```

### Apps

```
isoapp-emberbox
isoapp-tailoraid
isoapp-apikeychain
isoapp-lmspro
isoapp-sparkaid
```

### Others

```
isoblue-website
isoblue-templates
lab-knack-proxy
migration-tailoraid-floot
```

---

## **10. Compliance**

This naming convention is mandatory for:

* all new repos
* all new modules
* all new connectors
* all future IsoStack applications

Legacy repos should be migrated as soon as practical.

---

Absolutely — **docs *must* be part of the specification**, because in a multi-tenant, multi-module ecosystem like IsoStack, documentation becomes a *first-class citizen* alongside code, modules, apps, and connectors.

Below is a complete **docs section** designed to slot directly into the Naming Standard.
This defines:

* how docs repos are named
* how in-repo docs are organised
* how per-module docs integrate
* how architecture, developer, and user docs are standardised
* how platform docs differ from app docs
* how versions and tenants interact with documentation
* how your future “IsoStack Documentation Hub” would structure content

You can append this directly as **Section 12** of your formal specification.

---

# **11. Documentation Naming & Structure Standard**

Documentation within the IsoStack ecosystem is **explicitly part of the architecture**.
It must follow predictable naming and organisational patterns to support:

* onboarding
* tenant support
* internal engineering
* module integration
* AI-assisted code navigation
* version control across modules, connectors, and apps

This section defines *where documentation lives, how it is named, and how it should be structured*.

---

## **12.1 Documentation Repository Naming**

Documentation repos follow the same prefix rules as code repos, with the suffix:

```
-docs
```

### **Examples**

**Core platform docs**

```
isostack-docs
```

**Module docs**

```
isostack-module-bedrock-docs
isostack-module-tooltips-docs
```

**Connector docs**

```
isostack-connector-knack-docs
isostack-connector-cloudflare-docs
```

**App/product docs**

```
isoapp-emberbox-docs
isoapp-tailoraid-docs
isoapp-apikeychain-docs
```

**Internal/company docs**

```
isoblue-internal-docs
isoblue-process-docs
isoblue-architecture-docs
```

---

## **12.2 In-repo Documentation Structure**

Every repository MUST contain a `docs/` directory at the root.

Contents:

```
docs/
  index.md
  architecture/
  guides/
  api/
  troubleshooting/
  changelog.md
  version-history.md
```

### **Mandatory files**

| File                      | Purpose                             |
| ------------------------- | ----------------------------------- |
| `README.md`               | Entry point for GitHub repo viewers |
| `docs/index.md`           | Master index for the docset         |
| `docs/changelog.md`       | Semantic versioned changes          |
| `docs/version-history.md` | Module/app/platform version notes   |

---

## **12.3 Module Documentation Requirements**

Every IsoStack module MUST document:

* Purpose
* Scope
* API (tRPC procedures, endpoints, context)
* Configuration
* Tenant inheritance behaviour
* Schema additions
* Permissions/RLS notes
* Integration with other modules
* Upgrade/migration notes

This ensures modules remain swappable and self-contained.

---

## **12.4 Application Documentation Requirements**

Every IsoStack app MUST include:

* User-facing help
* Admin manual
* Tenant configuration
* API usage (where relevant)
* Integration with Official Modules
* Lifecycle (Onboarding → Support → Retention)

App docs MUST be written for non-technical users unless otherwise stated.

---

## **12.5 Connector Documentation Requirements**

Each connector MUST include:

* Purpose
* Authentication model
* Security considerations
* Setup guide
* API surface
* Error handling
* Rate limits
* Known issues
* Test instructions (sandbox vs production)

This section removes ambiguity when onboarding new connectors (e.g., for Knack, R2, Render, Supabase, Ecwid, Mailchimp, etc.)

---

## **12.6 Architecture & Cross-Platform Documentation**

Some documents belong to the **entire IsoStack ecosystem**, not just a repo.

These SHOULD live in:

```
isostack-docs/
```

Examples:

* IsoStack Architecture Whitepaper
* IsoStack Manifesto
* Tooltip Manifesto
* Settings Engine Specification
* Module bootstrap protocol
* Multi-tenant strategy
* Security & Compliance (GDPR, DPA, UK cyber standards)
* RLS & permissions matrix
* Deployment pipelines (Dev → Staging → Prod)
* CLI usage
* Coding standards
* Repo naming standards (this document)
* Environment naming standards
* Next.js app templates
* Prisma usage (schemas, migrations, branches)

---

## **12.7 Versioning of Documentation**

Documentation MUST be versioned in step with:

* module version (`v1.2.4`)
* platform version (`v2.0`)
* app version (`2025.3`)

Each docset MUST indicate:

```
Compatible with: isostack-core v2.x
```

This ensures developers never read incompatible docs.

---

## **12.8 Tenant & Platform Layer Documentation**

IsoStack is multi-tenant and multi-inheritance.
Documentation must reflect this:

### **Platform Level (Global)**

* what modules exist
* default settings
* supported connectors
* architecture and behaviour

### **Tenant Level**

* tenant customisation guides
* branding options
* module-specific settings
* tenant onboarding
* audit logging
* data retention policies

### **User Level**

* how to use the app
* help content generated from tooltips
* permissions and roles
* feature walkthroughs

---

## **12.9 Integration with Tooltips (the SSOT)**

IsoStack's tooltips system *is* a documentation system.

Documentation MUST support:

1. **Tooltip content as SSOT**
2. **Tooltip categories and functions**
3. **Tooltip inheritance (Global → App Owner → Tenant)**
4. **Tooltip embed examples (video, PDF, code)**
5. **Cloudflare R2 storage for help assets**
6. **Tooltip Mode + UI Switch** instructions
7. **Cross-linking between tooltips and docs**

This ensures:

* help content is generated once
* reused globally
* overridden per tenant
* delivered in-context

Documentation itself MUST explain how this works.

---

## **12.10 Future: IsoStack Documentation Hub**

All documentation (repos + tooltips) should eventually flow into:

```
isostack-docs
```

with an automatically generated static site using:

* Docusaurus
* Mintlify
* Next.js docs site
* or similar tooling

This provides:

* unified branding
* multi-version docs
* module navigation
* app navigation
* search
* tenant-specific docs via permissions

---

## **12.11 Summary of Documentation Requirements**

Every part of IsoStack MUST be documented in one of three ways:

### **1. In-repo docs (`docs/`)**

Technical, code, module, API.

### **2. Platform docs (`isostack-docs`)**

Architecture, standards, security, deployment, modules.

### **3. Tooltip-based contextual docs**

End-user help, in-app instructions, tenant overrides.

Together these form a **three-layer Single Source of Truth**.

---




## **14. Document Version**

**IsoStack Repository Naming Standard v1.0**
Published: 1 December 2025
Author: Isoblue Ltd
Status: Approved


