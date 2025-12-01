IsoStack Working Method (AI + Developer Collaboration Guide)
Version 2.0 – Updated for IsoStack Architecture & Revised Developer Workflow
1. Purpose of This Document
This document defines how AI and isocb work together, covering:
communication style
how to request and apply code changes
how AI should structure instructions
tooling preferences (VS Code, CLI, Render, Neon, GitHub)
conventions for long, multi-edit changes
how to avoid line-number drift errors
when to pause and clarify
the correct way for AI to reason about context
This is the single source of truth for future AI interactions.
2. User Profile
Current Skill Level
Intermediate developer using the IsoStack v1.0 framework
Comfortable with:
local dev server via CLI (npm run dev)
Git CLI basics
VS Code editing
Neon SQL console
Render dashboard/logs
Working knowledge of:
Next.js (App Router)
Prisma
tRPC + Zod
Multi-tenant data architectures
Functional, phased development
Core Preferences
Step-by-step instructions
Explicit reasoning & context
Predictable structure
No assumptions
Clear insertions, deletions, replacements
Full file paths always
Reverse-order multi-change edits
Testing after each phase
Explain why, not only what
3. AI Behaviour Requirements (CRITICAL)
These rules MUST be followed for all future instructions.
3.1 Never Use Cached Files (CRITICAL)
AI must always base instructions on the current version of the file.
Required behaviour:
Before giving edits, AI must request the latest file if:
the file has been edited within the last few messages
the user mentions “I changed X”
the AI is not 100% confident the version it has matches the repo
the instructions depend on exact line numbers
Example Required Prompt from AI:
“Before I produce line-numbered changes, please paste the current full version of app/api/projects/route.ts so I can avoid stale or cached file versions.”
NO EXCEPTIONS.
3.2 Multi-Edit Changes MUST Be Given in Reverse Order (CRITICAL)
This prevents line number drift when applying several changes.
Required behaviour:
When multiple edits are required for a file:
AI must order them:
largest line number first
smallest line number last
Required format:
"I will provide all changes in reverse order (largest → smallest line numbers) to preserve correctness when applying earlier modifications."
This applies to:
insertions
replacements
deletions
modifications
3.3 Required Format for Code Changes (AI MUST follow)
For every change:
**File:** /full/path/to/file.ts
**Location:** Lines 145–162
**FIND THIS CODE:**
```typescript
<exact block>
REPLACE WITH:
<exact block>
WHAT CHANGED (bullet points):
…
…

### Additional requirements:
- FIND blocks must be **byte-accurate** with existing code  
- Never paraphrase code in FIND blocks  
- Never use placeholder ellipses (“…”) inside FIND blocks  
- Only use ellipses *outside* exact code (e.g., for context)  

---

## **3.4 When to Ask for Clarification**

AI MUST pause and ask for more information when:

- a request has multiple interpretations  
- a file may not exist  
- a change depends on another subsystem  
- a potential conflict exists (e.g., breaking tenant isolation)  
- an alternative solution may be more aligned with IsoStack  

Required AI behaviour:

> *“Before proceeding, I need to confirm X or Y. Which approach do you intend?”*

---

# **4. Project Development Workflow**

### **4.1 Phase-Based Work**

All features must be delivered as **6–8 phases**, where each:

- is independently testable  
- requires 15–30 minutes of work  
- is safe to deploy incrementally  
- builds on validated progress  

### **4.2 Phase Structure**

Each phase from AI MUST include:

1. **Goal (1–2 sentences)**  
2. **Steps (with file paths)**  
3. **Reverse-order edits**  
4. **Testing Instructions**  
5. **What changed and why**  

AI does not proceed until user confirms:

> “Phase complete — proceed.”

---

# **5. Tooling Preferences**

### **Primary Tools**
- **VS Code (local)** — main editor  
- **Terminal CLI** — acceptable, used for:
  - running local dev server  
  - installing packages  
  - git operations  
  - Prisma commands  
- **GitHub (browser + local Git)** — version control  
- **Render** — hosting, logs, deployments  
- **Neon** — SQL, schema updates via browser  

### **5.1 AI Instruction Rules for CLI**
AI may provide CLI commands if:
- needed for migrations  
- needed for local server  
- needed for dependency installation  
- needed for Git branching  

AI must **explain exactly what each CLI command does**.

---

# **6. Architecture Context (For AI Reasoning)**

IsoStack is a **layered full-stack TypeScript platform**:

Frontend → API → ORM → Database → Infrastructure

### **Frontend Layer**
- Next.js 15 (App Router)
- React 18
- Mantine 7
- TypeScript strict mode

### **API Layer**
- tRPC 11 routers & procedures
- Zod validation for all inputs
- NextAuth.js v5 authentication

### **Database Layer**
- Prisma 5.x ORM
- Neon Serverless PostgreSQL

### **Infrastructure**
- Render (hosting, workers, cron)
- Cloudflare R2 (file storage)
- Resend (email)

### **Patterns AI Must Respect**
- multi-tenant via `orgId`  
- settings engine (global → platform → tenant → user)  
- module-based (Bedrock, Tooltips, Branding, etc.)  
- Prisma schema-first workflow  
- end-to-end type safety  

---

# **7. Code Standards**

### **7.1 Import Paths**

Use module-level CamelCase imports:

import { Button } from './Button'
import { Dialog } from './Dialog'

Never:

./ui/button

### **7.2 API Serialization**
Always use SuperJSON.

### **7.3 ID Generation**
Use `generateId(entityType)`  
AI must reference correct prefixes.

### **7.4 Database Workflow**
1. Change Neon schema  
2. Update Prisma schema  
3. Run migrations  
4. Update TypeScript types if needed  
5. Test with real data  

### **7.5 Types**
- Prisma-generated types for database  
- Zod for input validation  
- tRPC for API inference  

---

# **8. Development Workflow (Detailed)**

### **8.1 Standard Feature Development**

#### **Phase 1 — Requirements & Planning**
- Clarify scope  
- Identify affected files  
- Confirm architectural impact  
- Identify tenant behaviour  

#### **Phase 2 — Database Changes**
- Change Neon schema  
- Update Prisma schema & run migrations  
- Test with `prisma studio`  

#### **Phase 3 — Backend**
- Add/modify tRPC routers  
- Add Zod schemas  
- Update domain logic  
- Test with tRPC devtools or direct calls  

#### **Phase 4 — Frontend**
- Add React components  
- Update Mantine UI  
- Add forms, validation, queries/mutations  
- Test user flows  

#### **Phase 5 — Integration Testing**
- End-to-end tests  
- Tenant isolation testing  
- Error handling  
- Logs validation on Render  

#### **Phase 6 — Refinement & Documentation**
- Fix issues  
- Add comments  
- Update changelog & docs  
- Confirm alignment with conventions  

---

# **9. Commit Rules**

- One commit per phase  
- Clear, descriptive messages  
- Reference exactly what changed  
- No mixed concerns  
- Ask before force-pushing  

---

# **10. Cooperation Rules for AI**

The AI must:

### **Always**
- provide full paths  
- provide reverse-order edits  
- request the latest file before editing  
- explain why something is needed  
- pause and confirm unclear instructions  
- adhere strictly to IsoStack architecture patterns  

### **Never**
- assume file contents  
- use cached or stale versions  
- generate FIND blocks from memory  
- mix multiple concepts in one phase  
- provide large multi-file changes without sequencing  
- skip explanation of why  

---

# **11. Final Summary for AI (Pinned Reference)**

**AI MUST follow these rules at all times:**

1. **Request the latest file version before editing** — never rely on memory or cached content.  
2. **Provide all file edits in reverse order** — largest line numbers first.  
3. **Use full file paths always.**  
4. **Use strict FIND / REPLACE / INSERT formats.**  
5. **Split work into phases (max 6–8).**  
6. **Confirm completion before next phase.**  
7. **Explain why, not just what.**  
8. **Never assume missing context — always ask.**  
9. **Follow IsoStack patterns (Next.js, Prisma, tRPC, Zod).**  
10. **Never modify database or large structures without confirmation.**

---