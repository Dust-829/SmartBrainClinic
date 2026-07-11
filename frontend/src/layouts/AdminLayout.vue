<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useAdminSessionStore } from '@/stores/adminSession'

const route = useRoute()
const router = useRouter()
const session = useAdminSessionStore()
const auditConfigured = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))

const navItems = computed(() => [
  { label: '首页大屏', to: '/admin/dashboard' },
  { label: '账号管理', to: '/admin/accounts' },
  { label: '智能排班', to: '/admin/schedules' },
  { label: '审批中心', to: '/admin/approvals' },
  { label: auditConfigured.value ? 'AI 审计' : 'AI 审计（需配置）', to: '/admin/audit' },
  { label: '药房工作台', to: '/admin/pharmacy' },
  { label: '财务账单', to: '/admin/billing' },
  { label: '运营分析', to: '/admin/analytics' },
])

const staffLabel = computed(() => session.staff?.displayName || '未登录管理员')
const staffCodeLabel = computed(() => session.staff?.staffCode || 'ADMIN')

function isActive(path: string) {
  return route.path === path
}

function logout() {
  session.logout()
  router.replace('/admin/login')
}
</script>

<template>
  <div class="admin-layout">
    <aside v-if="route.path !== '/admin/login'" class="admin-layout__aside">
      <div class="admin-layout__brand">
        <span class="admin-layout__eyebrow">智慧云脑诊疗平台</span>
        <strong>管理员总控台</strong>
        <p>资源、审批、药房、账单与 AI 审计统一入口</p>
      </div>

      <nav class="admin-layout__nav" aria-label="管理员导航">
        <router-link
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          :class="['admin-layout__nav-link', { 'is-active': isActive(item.to) }]"
        >
          {{ item.label }}
        </router-link>
      </nav>

      <div class="admin-layout__session">
        <div>
          <span>{{ staffLabel }}</span>
          <strong>{{ staffCodeLabel }}</strong>
        </div>
        <button type="button" @click="logout">退出</button>
      </div>
    </aside>

    <div class="admin-layout__content">
      <div v-if="route.path !== '/admin/login' && !auditConfigured" class="admin-layout__banner">
        当前未配置 `VITE_ADMIN_API_TOKEN`。其余后台模块可正常使用，`AI 审计` 仅显示配置提示。
      </div>

      <header v-if="route.path !== '/admin/login'" class="admin-layout__header">
        <div>
          <div class="admin-layout__eyebrow">后台工作台</div>
          <h1>管理员端</h1>
        </div>
      </header>

      <main class="admin-layout__main" :class="{ 'is-login': route.path === '/admin/login' }">
        <router-view />
      </main>
    </div>
  </div>
</template>

<style scoped>
.admin-layout {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 248px minmax(0, 1fr);
  background: var(--admin-page-bg);
}

.admin-layout__aside {
  display: grid;
  grid-template-rows: auto 1fr auto;
  gap: 14px;
  padding: 72px 18px 18px;
  border-right: 1px solid var(--admin-border);
  background: var(--admin-surface);
  color: var(--admin-text);
}

.admin-layout__brand,
.admin-layout__session {
  display: grid;
  gap: 8px;
}

.admin-layout__brand strong {
  font-size: 24px;
  line-height: 1.1;
}

.admin-layout__brand p,
.admin-layout__session span {
  margin: 0;
  color: var(--admin-text-muted);
  line-height: 1.6;
}

.admin-layout__nav {
  display: grid;
  align-content: start;
  gap: 6px;
}

.admin-layout__nav-link {
  display: block;
  padding: 10px 12px;
  border-radius: var(--admin-radius-md);
  color: var(--admin-text);
  border: 1px solid transparent;
  transition: background 160ms ease, border-color 160ms ease, color 160ms ease;
}

.admin-layout__nav-link:hover {
  color: var(--admin-accent-strong);
  background: #f1f5f9;
}

.admin-layout__nav-link.is-active {
  color: var(--admin-accent-strong);
  background: var(--admin-accent-soft);
  border-color: rgba(15, 118, 110, 0.2);
}

.admin-layout__session {
  padding: 14px;
  border-radius: var(--admin-radius-lg);
  background: linear-gradient(180deg, #eff6ff 0%, #f8fbff 100%);
  border: 1px solid var(--admin-border);
}

.admin-layout__session strong {
  display: block;
  margin-top: 4px;
  color: var(--admin-text);
}

.admin-layout__session button {
  min-height: 36px;
  margin-top: 6px;
  border: 0;
  border-radius: var(--admin-radius-sm);
  background: var(--admin-accent);
  color: #ffffff;
  font: inherit;
}

.admin-layout__content {
  min-width: 0;
}

.admin-layout__banner {
  margin: 10px 16px 0;
  padding: 8px 12px;
  border-radius: var(--admin-radius-md);
  border: 1px solid rgba(245, 158, 11, 0.18);
  background: var(--admin-warn-soft);
  color: #92400e;
  line-height: 1.35;
}

.admin-layout__header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 10px 16px 2px;
}

.admin-layout__eyebrow {
  font-size: 12px;
  color: var(--admin-accent);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.admin-layout__header h1 {
  margin: 2px 0 0;
  font-size: 20px;
  color: var(--admin-text);
}

.admin-layout__main {
  padding: 8px 16px 16px;
}

.admin-layout__main.is-login {
  padding-top: 88px;
}

@media (max-width: 980px) {
  .admin-layout {
    grid-template-columns: 1fr;
  }

  .admin-layout__aside {
    grid-template-rows: auto;
    padding: 24px 18px 12px;
    border-right: 0;
    border-bottom: 1px solid var(--admin-border);
  }

  .admin-layout__nav {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 720px) {
  .admin-layout__nav {
    grid-template-columns: 1fr;
  }

  .admin-layout__header,
  .admin-layout__main,
  .admin-layout__banner {
    padding-left: 18px;
    padding-right: 18px;
  }
}
</style>
