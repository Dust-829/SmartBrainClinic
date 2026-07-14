# Admin Minimum Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable admin-side minimum closure with navigation, real API wiring, and six working pages for scheduling, approvals, audit, pharmacy, and billing.

**Architecture:** Keep the existing single-frontend structure, add an admin-focused API module set, extend `/admin/*` routes, and implement operation-first pages that prefer real backend calls over fake dashboards. Where backend bulk list APIs are missing, expose targeted operator tools and explicit empty states instead of inventing data.

**Tech Stack:** Vue 3, Vue Router, Pinia, Axios, Element Plus, TypeScript, Vite

---

### Task 1: Add Admin API Modules

**Files:**
- Create: `frontend/src/api/admin.ts`
- Modify: `frontend/src/api/http.ts`

- [ ] Define typed admin API wrappers for scheduling, approvals, audit, pharmacy, and billing.
- [ ] Keep request helpers small and aligned with current backend endpoint shapes.
- [ ] Reuse the shared `http` client and `ApiEnvelope` type.

### Task 2: Extend Admin Routing and Shell

**Files:**
- Modify: `frontend/src/router/index.ts`
- Modify: `frontend/src/layouts/AdminLayout.vue`

- [ ] Add admin child routes for `schedules`, `approvals`, `audit`, `pharmacy`, and `billing`.
- [ ] Turn `AdminLayout` into a persistent shell with header, sidebar navigation, and session-aware user information.
- [ ] Preserve existing auth guard behavior and default `/admin` redirect semantics.

### Task 3: Replace Placeholder Console

**Files:**
- Modify: `frontend/src/views/admin/AdminConsoleView.vue`

- [ ] Replace the tile placeholder with a real dashboard page.
- [ ] Load lightweight real data from approvals and audit endpoints.
- [ ] Show KPI cards, pending approvals summary, and admin action shortcuts.

### Task 4: Build Scheduling and Approvals Pages

**Files:**
- Create: `frontend/src/views/admin/AdminSchedulesView.vue`
- Create: `frontend/src/views/admin/AdminApprovalsView.vue`

- [ ] Implement scheduling generation and rule-adjustment actions.
- [ ] Implement pending application list, approve, and reject actions.
- [ ] Keep forms explicit and operator-friendly.

### Task 5: Build Audit, Pharmacy, and Billing Pages

**Files:**
- Create: `frontend/src/views/admin/AdminAuditView.vue`
- Create: `frontend/src/views/admin/AdminPharmacyView.vue`
- Create: `frontend/src/views/admin/AdminBillingView.vue`

- [ ] Implement AI audit log querying with filters and readable result cards.
- [ ] Implement pharmacy operation page for batch drug import, dispense, and return.
- [ ] Implement billing operation page for register bill lookup and refund action.

### Task 6: Verify and Document

**Files:**
- Modify: `docs/frontend-plan.md`

- [ ] Update the frontend plan to reflect completed admin-side progress.
- [ ] Run `npm run build` in `frontend/`.
- [ ] Review the diff for unintended changes before reporting completion.
