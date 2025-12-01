

# ✅ **FILE 2 — roadmap.md**

📍 **Location:**

```
/docs/core/roadmap.md
```

---

# **IsoStack V2.0 Roadmap**

## Overview

The roadmap outlines delivered features and future deliverables for the IsoStack platform, focusing on authentication, organisation management, UX quality and multi-tenant administration.

---

# 1. Completed Features

## **Phase 1 — Authentication**

* Sign out
* Password reset flow
* Email verification UI

## **Phase 2 — Team Management**

* User CRUD
* Suspend/Activate user via clickable status badge
* Role-based permissions
* OWNER role removed from invite flow
* Platform Admin integrated into user/organisation views

## **Phase 3 — Code Quality & Security**

* Client/server boundary audit
* Security fixes in onboarding
* Validation improvements
* Core refactor to enforce correct multi-tenant boundaries

---

# 2. Upcoming Features

## **Organisation Status Management**

Status options:

```
ACTIVE
COMPED
TRIAL
TRIAL_EXPIRED
PAUSED
CANCELLED
```

### Behaviour:

* TRIAL_EXPIRED → read-only mode
* PAUSED → login blocked, support message
* CANCELLED → access removed, reactivation path
* Linked to Stripe/Paddle subscription system
* Auto-updates based on payment status

### UI:

* Badge toggle like user status
* Confirmation modal
* Platform Admin only

### Effort: 2–3 days

### Priority: High

---

## **Switch Organisation (Platform Admin)**

Allows Platform Admin to switch into any tenant for support.

### UI:

* Dropdown in profile menu
* Current org highlighted
* Instant context switch
* Retains Platform Admin privileges

### Use Cases:

* Support
* Debugging
* Data verification

### Effort: 1 day

### Priority: Medium

---

## **Phase 4 — UX Polish**

* Loading skeletons
* Error boundaries
* Optimistic updates
* Form validation improvements
* Empty-state designs with CTAs

### Effort: 1–2 days

### Priority: Medium

---

# 3. Dependencies

| Feature             | Depends On                             |
| ------------------- | -------------------------------------- |
| Organisation Status | Billing system integration             |
| Org Switching       | Correct platform-level session context |
| UX Polish           | Stabilised layout and navigation       |

---

# 4. Summary

This roadmap ensures IsoStack evolves into a fully featured, polished, multi-tenant SaaS platform with a strong core foundation.

