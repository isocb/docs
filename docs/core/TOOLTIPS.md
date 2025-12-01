Below is a **fully rewritten Tooltip Manifesto**, rebuilt from the ground up to reflect:

✔ Two-tier model you requested: **Platform Tooltips** → **Tenant Tooltips**
✔ Tenants can **override, extend, or add new** tooltips
✔ **Visual feedback editor** with roll-over highlight that detects DOM nodes (element, class, ID)
✔ Tooltip metadata: **Category**, **Function**, **rich text + code embeds**, **video/PDFs via Cloudflare R2**
✔ Clean, modern, and aligned with IsoStack principles
✔ Based on your original manifesto  but re-authored for this new architecture

---

# **IsoStack Tooltip Manifesto — Two-Tier Visual Tooltip System**

*A unified, visual, multi-layer help system for multi-tenant SaaS applications.*

---

## **1. Purpose**

Modern SaaS apps fail users when help content is scattered, generic, or out-of-date. Documentation lives in Google Docs, wikis, old PDFs, Slack threads, and the heads of a few team members.
IsoStack fixes this with a **visual, inheritable tooltip system** that keeps help content:

* **Centralised**
* **Contextual**
* **Customisable**
* **Rich-media capable**

And crucially: **non-technical people can maintain it.**

---

# **2. The Two-Tier Tooltip Architecture**

IsoStack implements a simple, powerful inheritance model:

```
Tier 1 → Platform Tooltips (the template)
Tier 2 → Tenant Tooltips (custom to each organisation)
```

### **Tier 1 — Platform Tooltips (Global Defaults)**

* Created and maintained by the platform team.
* Serve as the **baseline** for any app built on IsoStack.
* Define the intended behaviour, purpose, and best practice for each UI element.
* Automatically copied (“cloned”) into each new tenant at onboarding.
* Tenants can override them at will.

### **Tier 2 — Tenant Tooltips (Overrides & Additions)**

* Owned by tenant administrators.
* Allow internal terminology, custom processes, internal videos, PDF procedures, or onboarding instructions.
* Can override a platform tooltip or add completely new tooltips that don’t exist in the template.
* Can revert back to the platform version with one click.

### **Resolution Order**

When resolving a tooltip:

1. **Tenant tooltip** (if present)
2. **Platform tooltip**
3. **None** (no tooltip defined)

This simple two-step model is easy to reason about, easy to maintain, and fully aligned with multi-tenant SaaS inheritance expectations.

---

# **3. Visual Tooltip Builder (Core Feature)**

IsoStack includes a **visual, in-app tooltip editor**—no code, no guessing CSS selectors, no DevTools.

### Entering Visual Tooltip Mode

Admin presses:
**Ctrl + Shift + ?**

This activates:

* A **DOM roll-over detector** that highlights each element
* A floating tag showing:

  * Element type (div, button, input…)
  * CSS class
  * Element ID (if applicable)
* A click-to-attach tooltip editor modal

### How Elements Are Identified

The visual editor extracts and stores:

* **Preferred**: Stable element ID
* **Fallback**: Semantic class selectors
* **Computed stable selector**: e.g. `#saveButton`, `.navbar .menu-item[data-key="reports"]`

IsoStack stores the selector as:

```
selectorType: "id" | "class" | "auto"
selectorValue: "#saveButton"
```

Users never see selector syntax—it’s all behind the scenes.

---

# **4. Tooltip Metadata Model**

Every tooltip includes:

### **Mandatory Fields**

* **Category** — e.g. “Navigation”, “Data Entry”, “Dashboard”, “Reporting”
* **Function** — what the element does and why
* **Rich Text Content** — Markdown-based editor

### **Rich Media Support**

Tooltips accept:

* Embedded video (MP4 from Cloudflare R2)
* Embedded audio
* Inline PDFs (served directly from R2)
* Images and icons
* Formatted code snippets
* Links to help articles or policies

Tenants can therefore attach:

* Internal training videos
* Policy docs
* SOP PDFs
* Internal workflow diagrams
* Quick explainer videos recorded on Loom-style tools

All media is uploaded via the tooltip editor directly into the tenant’s **Cloudflare R2 bucket**.

---

# **5. Tooltip Editor Interface**

When a user clicks an element in Tooltip Mode, the following modal appears:

```
┌──────────────────────────────────────────────────┐
│          Tooltip Editor (Tenant / Platform)       │
├──────────────────────────────────────────────────┤
│ Element:  .dashboard-metric-card                 │
│ Selector: auto-resolved                          │
│ Tier: Platform (inherited) / Tenant (override)   │
│                                                  │
│ Category:  [Dropdown]                            │
│ Function:  [Short description]                   │
│                                                  │
│ Content (Markdown):                              │
│ [Rich text editor with Preview tab]              │
│                                                  │
│ Media Upload                                     │
│ [Upload to Cloudflare R2]                        │
│                                                  │
│ Actions:                                         │
│  [ Create Tenant Override ]                      │
│  [ Save Tenant Tooltip ] (if already overridden) │
│  [ Revert to Platform Tooltip ]                  │
└──────────────────────────────────────────────────┘
```

---

# **6. Lifecycle of a Tooltip**

### **1. Platform creates tooltip**

A global definition is added to the Platform Tooltip Library.

### **2. Tenant is created**

All platform tooltips are **cloned** into the tenant account (soft clone referencing parent ID).

### **3. Tenant customises**

If a tenant edits a tooltip, it becomes an **override**, replacing the platform version.

### **4. Platform updates tooltip**

Tenants can choose **per tooltip** whether to:

* Keep their override
* Or revert to updated platform version

### **5. Tenant adds extra tooltips**

Tenants can create tooltips for custom elements not covered by the platform.

---

# **7. Tooltip Inheritance Data Model**

```prisma
model Tooltip {
  id             String   @id @default(uuid())
  selectorType   String   // id, class, auto
  selectorValue  String   // e.g. '#saveButton'
  category       String
  function       String
  content        String   @db.Text
  mediaUrl       String?  // Cloudflare R2
  tier           String   // 'platform' or 'tenant'
  clonedFrom     String?  // Platform tooltip id
  organizationId String?  // NULL if platform
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt
}
```

This is significantly simpler than hierarchical multi-tier schemas, but still fully expressive.

---

# **8. Security & Permissions**

* Tenants can edit **tenant tooltips only**
* Platform admins can edit **platform tooltips**
* Tenants can never modify platform tier directly
* Tenants only see their own overrides in the editor
* Tooltip media stored in R2 is tenant-isolated (prefix-based segregation)

---

# **9. Business Benefits**

### **Platform/Your Business**

✔ Faster onboarding
✔ Controls the “canonical” help content
✔ Reduces support load
✔ Makes the platform feel polished and enterprise-grade
✔ Allows you to ship a template with professional help baked in

### **Tenants**

✔ Customise tooltips to reflect internal language and processes
✔ Add videos and PDFs without developer help
✔ Provide staff onboarding and training directly in the UI
✔ Reduce training overhead for new employees
✔ Revert to safe platform defaults at any time

### **End Users**

✔ Immediate understanding of features
✔ Context-aware help exactly where it’s needed
✔ Rich media helps different learning styles
✔ Option to hide tooltips entirely once experienced

---

# **10. Future-Proofing & Enhancements**

* AI-assisted tooltip writing (“Generate a tooltip for this element”)
* Usage analytics (“Which tooltips are viewed most?”)
* User-level learning modes (“Beginner, Intermediate, Expert”)
* Multilingual tooltips with fallback
* Versioning and approval workflows (enterprise tier)

---

# **11. Conclusion**

The IsoStack Two-Tier Visual Tooltip System is:

* **developer-friendly** (one global template)
* **tenant-friendly** (easy override & media embeds)
* **end-user-friendly** (contextual, beautiful, useful)
* **future-ready** (R2 media support, upgrade path to AI-generated content)

It embodies your platform philosophy:
**Build once. Adapt forever. Maintain sanely.**

