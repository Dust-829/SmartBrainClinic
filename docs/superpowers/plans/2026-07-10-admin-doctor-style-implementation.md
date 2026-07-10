# Admin Doctor Style Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle every admin frontend screen so it uses the same visual language as the doctor frontend without changing admin information architecture, routes, or business behavior.

**Architecture:** Keep the existing admin view structure and business logic intact, then add one shared admin skin layer that reuses the doctor-side visual grammar. Apply that skin first at the layout level, then migrate each admin page from local one-off styles to the shared patterns.

**Tech Stack:** Vue 3, TypeScript, Vite, Element Plus, scoped CSS, shared stylesheet imports

---

## File Structure

### Files to Modify

- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\layouts\AdminLayout.vue`
  - Replace the current dark sidebar treatment with a doctor-style light workspace shell.
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\styles\theme.css`
  - Add admin-side CSS variables and Element Plus token overrides that match doctor-side visuals.
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminLoginView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminDashboardView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminAccountsView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminSchedulesView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminApprovalsView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminAuditView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminBillingView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminAnalyticsView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminPharmacyView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminDoctorsView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminDepartmentsView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminRoomsView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminConsoleView.vue`
  - Replace per-page visual rules with shared skin classes while preserving templates and logic.

### Files to Create

- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\styles\admin-skin.css`
  - Shared admin visual primitives: page, hero, grid, form, toolbar, list, item, state, empty, button, badge.

### Files to Inspect During Work

- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\layouts\DoctorLayout.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\doctor\DoctorWorkbenchView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\doctor\DoctorEncounterView.vue`
- `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\components\common\SectionCard.vue`

## Task 1: Build The Shared Admin Skin Layer

**Files:**
- Create: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\styles\admin-skin.css`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\styles\theme.css`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\main.ts`
- Test: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\package.json`

- [ ] **Step 1: Add the shared admin skin stylesheet with doctor-style primitives**

```css
:root {
  --admin-skin-bg: #f8fafc;
  --admin-skin-surface: #ffffff;
  --admin-skin-surface-muted: #f8fafc;
  --admin-skin-ink: #0f172a;
  --admin-skin-muted: #64748b;
  --admin-skin-line: #dbe5f0;
  --admin-skin-accent: #0f766e;
  --admin-skin-accent-strong: #115e59;
  --admin-skin-accent-soft: #ecfdf5;
  --admin-skin-info-soft: #eff6ff;
  --admin-skin-warn-soft: #fff7ed;
  --admin-skin-radius-lg: 18px;
  --admin-skin-radius-md: 16px;
  --admin-skin-radius-sm: 12px;
}

.admin-skin-page {
  display: grid;
  gap: 20px;
}

.admin-skin-hero {
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  gap: 18px;
  padding: 24px;
  border-radius: var(--admin-skin-radius-lg);
  background: linear-gradient(135deg, var(--admin-skin-accent) 0%, var(--admin-skin-accent-strong) 100%);
  color: #ffffff;
}

.admin-skin-form input,
.admin-skin-form textarea,
.admin-skin-form select {
  width: 100%;
  min-height: 42px;
  padding: 0 14px;
  border: 1px solid var(--admin-skin-line);
  border-radius: var(--admin-skin-radius-sm);
}
```

- [ ] **Step 2: Wire admin tokens into the existing theme layer**

```css
.admin-layout {
  --el-color-primary: var(--admin-skin-accent);
  --el-color-primary-light-9: #f0fdfa;
}

.admin-layout .el-dialog {
  border-radius: 16px;
}

.admin-layout .el-input__wrapper,
.admin-layout .el-textarea__inner {
  border-radius: 12px;
}
```

- [ ] **Step 3: Import the shared admin skin stylesheet into the app entry**

```ts
import './styles/reset.css'
import './styles/theme.css'
import './styles/admin-skin.css'
```

- [ ] **Step 4: Run build verification after adding the shared style layer**

Run: `npm run build`

Expected: `vue-tsc --noEmit` and `vite build` both complete with exit code `0`.

- [ ] **Step 5: Commit the shared skin layer**

```bash
git add frontend/src/styles/theme.css frontend/src/styles/admin-skin.css frontend/src/main.ts
git commit -m "feat: add shared admin skin layer"
```

## Task 2: Restyle The Admin Layout Shell

**Files:**
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\layouts\AdminLayout.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\styles\admin-skin.css`
- Test: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\package.json`

- [ ] **Step 1: Replace the dark sidebar visual treatment with a doctor-style light shell**

```vue
<div class="admin-layout">
  <aside v-if="route.path !== '/admin/login'" class="admin-layout__aside">
    <div class="admin-layout__brand">
      <span class="admin-layout__eyebrow">智慧云脑诊疗平台</span>
      <strong>管理员总控台</strong>
      <p>资源、审批、药房、账单与 AI 审计统一入口</p>
    </div>
    <nav class="admin-layout__nav" aria-label="管理员导航">
      <!-- keep existing router-link loop -->
    </nav>
    <div class="admin-layout__session">
      <!-- keep existing session content -->
    </div>
  </aside>
</div>
```

- [ ] **Step 2: Update layout styles to align spacing, surfaces, and buttons with doctor visuals**

```css
.admin-layout {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  background: var(--admin-skin-bg);
}

.admin-layout__aside {
  border-right: 1px solid var(--admin-skin-line);
  padding: 88px 24px 24px;
  background: var(--admin-skin-surface);
}

.admin-layout__session {
  padding: 16px;
  border: 1px solid var(--admin-skin-line);
  border-radius: 16px;
  background: linear-gradient(180deg, #eff6ff 0%, #f8fbff 100%);
}
```

- [ ] **Step 3: Keep the existing auth/banner logic intact while simplifying the content shell**

```vue
<main class="admin-layout__main" :class="{ 'is-login': route.path === '/admin/login' }">
  <router-view />
</main>
```

- [ ] **Step 4: Run build verification after the layout migration**

Run: `npm run build`

Expected: build succeeds and `AdminLayout.vue` compiles cleanly.

- [ ] **Step 5: Commit the layout restyle**

```bash
git add frontend/src/layouts/AdminLayout.vue frontend/src/styles/admin-skin.css
git commit -m "feat: align admin layout with doctor shell"
```

## Task 3: Migrate Login And Dashboard To The Shared Skin

**Files:**
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminLoginView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminDashboardView.vue`
- Test: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\package.json`

- [ ] **Step 1: Replace local login hero/form styles with shared admin skin classes**

```vue
<div class="admin-skin-page admin-login">
  <section class="admin-skin-hero admin-skin-hero--compact">
    <div class="admin-skin-hero__main">
      <span class="admin-skin-eyebrow">智慧云脑诊疗平台</span>
      <h1>管理员登录</h1>
      <p>当前先提供占位登录入口，用于进入统一风格后的管理员工作台。</p>
    </div>
  </section>

  <SectionCard title="登录控制台" subtitle="输入演示姓名和工号后进入管理后台首页。">
    <div class="admin-skin-form admin-login__form">
      <!-- keep existing fields -->
    </div>
  </SectionCard>
</div>
```

- [ ] **Step 2: Convert dashboard hero, metric cards, and resource cards to shared skin structure**

```vue
<div class="admin-skin-page admin-dashboard">
  <section class="admin-skin-hero">
    <div class="admin-skin-hero__main">
      <span class="admin-skin-eyebrow">首页大屏</span>
      <h2>{{ session.staff?.displayName || '值班管理员' }}</h2>
      <p>聚合审批、AI 审计、药房账单与资源摘要，作为管理员端主屏使用。</p>
    </div>
    <button type="button" class="admin-skin-button is-secondary" :disabled="loading" @click="loadDashboard">
      {{ loading ? '刷新中...' : '刷新看板' }}
    </button>
  </section>
</div>
```

- [ ] **Step 3: Delete page-specific indigo/blue gradients that conflict with the doctor visual language**

```css
.admin-dashboard__metric,
.admin-dashboard__resource-card,
.admin-dashboard__stat-card {
  border: 1px solid var(--admin-skin-line);
  border-radius: 16px;
  background: var(--admin-skin-surface);
}
```

- [ ] **Step 4: Run build verification after login/dashboard migration**

Run: `npm run build`

Expected: build succeeds with the login and dashboard views using the shared classes.

- [ ] **Step 5: Commit the login/dashboard restyle**

```bash
git add frontend/src/views/admin/AdminLoginView.vue frontend/src/views/admin/AdminDashboardView.vue
git commit -m "feat: restyle admin login and dashboard"
```

## Task 4: Migrate List And Approval Oriented Pages

**Files:**
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminApprovalsView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminAnalyticsView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminAuditView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminBillingView.vue`
- Test: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\package.json`

- [ ] **Step 1: Convert each page hero to the shared admin hero pattern**

```vue
<section class="admin-skin-hero">
  <div class="admin-skin-hero__main">
    <span class="admin-skin-eyebrow">人工审核入口</span>
    <h2>审批中心</h2>
    <p>集中处理排班申请，体现 AI 建议和人工确认分离的后台职责。</p>
  </div>
</section>
```

- [ ] **Step 2: Replace local list card styles with shared list/item/state classes**

```vue
<div v-if="applications.length" class="admin-skin-list">
  <article v-for="item in applications" :key="item.uuid" class="admin-skin-item">
    <!-- keep existing content -->
  </article>
</div>
<div v-else class="admin-skin-empty">当前没有待审批申请。</div>
```

- [ ] **Step 3: Normalize status buttons and badges to the shared button/badge styles**

```css
.approval-card__actions .is-approve {
  composes: admin-skin-button;
}

.approval-card__actions .is-reject {
  background: #dc2626;
  color: #ffffff;
}
```

- [ ] **Step 4: Run build verification after list/approval page migration**

Run: `npm run build`

Expected: build succeeds for approvals, analytics, audit, and billing pages.

- [ ] **Step 5: Commit the list and approval page restyle**

```bash
git add frontend/src/views/admin/AdminApprovalsView.vue frontend/src/views/admin/AdminAnalyticsView.vue frontend/src/views/admin/AdminAuditView.vue frontend/src/views/admin/AdminBillingView.vue
git commit -m "feat: restyle admin review and analytics pages"
```

## Task 5: Migrate Form Heavy Admin Workbench Pages

**Files:**
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminAccountsView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminSchedulesView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminPharmacyView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminDoctorsView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminDepartmentsView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminRoomsView.vue`
- Modify: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\src\views\admin\AdminConsoleView.vue`
- Test: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\package.json`

- [ ] **Step 1: Replace per-page toolbars and forms with shared toolbar/form classes**

```vue
<div class="admin-skin-toolbar">
  <form class="admin-skin-form admin-skin-form--inline" @submit.prevent="loadDoctors">
    <!-- keep existing inputs/buttons -->
  </form>
  <button type="button" class="admin-skin-button" @click="openCreateDoctorDialog">新增医生</button>
</div>
```

- [ ] **Step 2: Replace result lists, account cards, and work panels with shared item/state blocks**

```vue
<div v-if="doctors.length" class="admin-skin-list">
  <article v-for="doctor in doctors" :key="doctor.uuid" class="admin-skin-item">
    <!-- keep existing doctor card content -->
  </article>
</div>
<div v-else class="admin-skin-empty">当前没有符合条件的 doctor 账号。</div>
```

- [ ] **Step 3: Add admin-layout scoped Element Plus dialog footer/button polish where needed**

```css
.admin-layout :deep(.el-dialog__footer) {
  padding-top: 0;
}

.dialog-actions__primary {
  background: var(--admin-skin-accent);
  color: #ffffff;
}
```

- [ ] **Step 4: Run build verification after form-heavy page migration**

Run: `npm run build`

Expected: build succeeds for accounts, schedules, pharmacy, doctors, departments, rooms, and console pages.

- [ ] **Step 5: Commit the workbench page restyle**

```bash
git add frontend/src/views/admin/AdminAccountsView.vue frontend/src/views/admin/AdminSchedulesView.vue frontend/src/views/admin/AdminPharmacyView.vue frontend/src/views/admin/AdminDoctorsView.vue frontend/src/views/admin/AdminDepartmentsView.vue frontend/src/views/admin/AdminRoomsView.vue frontend/src/views/admin/AdminConsoleView.vue
git commit -m "feat: restyle admin workbench pages"
```

## Task 6: Final Cleanup And Verification

**Files:**
- Modify: any admin view still carrying redundant one-off styles after migration
- Test: `D:\neusoft\SmartBrainClinic\SmartBrainClinic\frontend\package.json`

- [ ] **Step 1: Remove leftover per-page visual rules that duplicate the shared skin**

```css
/* delete page-specific gradient/color rules once the shared classes are in place */
```

- [ ] **Step 2: Re-check spec coverage against the migrated files**

```text
Verify: layout shell, hero unification, buttons, inputs, lists, empty states, dialogs, responsive behavior.
```

- [ ] **Step 3: Run the full build verification**

Run: `npm run build`

Expected: exit code `0` with no TypeScript or Vite build failures.

- [ ] **Step 4: Review the final diff before closing**

Run: `git diff --stat`

Expected: changes are limited to admin layout/views and shared styling files.

- [ ] **Step 5: Commit the cleanup and verification pass**

```bash
git add frontend/src/layouts/AdminLayout.vue frontend/src/styles/admin-skin.css frontend/src/styles/theme.css frontend/src/views/admin
git commit -m "refactor: unify admin visuals with doctor style"
```

## Self-Review

### Spec coverage

- Layout unification: covered in Task 2
- Shared skin layer: covered in Task 1
- Login/dashboard first impression pages: covered in Task 3
- Approval/list/analytics pages: covered in Task 4
- Form-heavy workbench pages: covered in Task 5
- Build verification and final diff review: covered in Task 6

### Placeholder scan

- No `TODO`, `TBD`, or “implement later” placeholders remain.
- Commands, file paths, and target files are explicit.

### Type consistency

- Shared class naming is consistent across tasks: `admin-skin-page`, `admin-skin-hero`, `admin-skin-form`, `admin-skin-list`, `admin-skin-item`, `admin-skin-empty`, `admin-skin-button`.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-10-admin-doctor-style-implementation.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
