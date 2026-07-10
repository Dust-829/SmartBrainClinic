<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useAdminSessionStore } from '@/stores/adminSession'

const route = useRoute()
const router = useRouter()
const session = useAdminSessionStore()
const auditConfigured = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))

const navItems = computed(() => [
  { label: '主页大屏', to: '/admin/dashboard' },
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
        <span class="admin-layout__eyebrow">SmartBrainClinic</span>
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
          <div class="admin-layout__eyebrow">智慧云脑诊疗平台</div>
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
  grid-template-columns: 260px minmax(0, 1fr);
  background:
    radial-gradient(circle at top left, rgba(129, 140, 248, 0.12), transparent 34%),
    linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
}

.admin-layout__aside {
  display: grid;
  grid-template-rows: auto 1fr auto;
  gap: 18px;
  padding: 24px 18px;
  border-right: 1px solid rgba(129, 140, 248, 0.15);
  background: rgba(15, 23, 42, 0.96);
  color: #e2e8f0;
}

.admin-layout__brand,
.admin-layout__session {
  display: grid;
  gap: 8px;
}

.admin-layout__brand strong {
  font-size: 22px;
}

.admin-layout__brand p,
.admin-layout__session span {
  margin: 0;
  color: rgba(226, 232, 240, 0.72);
  line-height: 1.6;
}

.admin-layout__nav {
  display: grid;
  align-content: start;
  gap: 8px;
}

.admin-layout__nav-link {
  display: block;
  padding: 12px 14px;
  border-radius: 14px;
  color: #cbd5e1;
  border: 1px solid transparent;
  transition: background 160ms ease, border-color 160ms ease, color 160ms ease;
}

.admin-layout__nav-link:hover {
  color: #ffffff;
  background: rgba(99, 102, 241, 0.12);
}

.admin-layout__nav-link.is-active {
  color: #ffffff;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.28), rgba(59, 130, 246, 0.18));
  border-color: rgba(129, 140, 248, 0.26);
}

.admin-layout__session {
  padding: 16px;
  border-radius: 16px;
  background: rgba(30, 41, 59, 0.96);
  border: 1px solid rgba(148, 163, 184, 0.16);
}

.admin-layout__session strong {
  display: block;
  margin-top: 4px;
  color: #ffffff;
}

.admin-layout__session button {
  min-height: 40px;
  border: 0;
  border-radius: 12px;
  background: linear-gradient(135deg, #4f46e5, #2563eb);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.admin-layout__content {
  min-width: 0;
}

.admin-layout__banner {
  margin: 18px 28px 0;
  padding: 12px 16px;
  border-radius: 14px;
  border: 1px solid rgba(245, 158, 11, 0.24);
  background: #fffbeb;
  color: #92400e;
  line-height: 1.6;
}

.admin-layout__header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 40px 28px 18px;
}

.admin-layout__eyebrow {
  font-size: 12px;
  color: #4f46e5;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.admin-layout__header h1 {
  margin: 8px 0 0;
  font-size: 30px;
  color: #0f172a;
}

.admin-layout__main {
  padding: 24px 28px 32px;
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
    padding-bottom: 12px;
    border-right: 0;
    border-bottom: 1px solid rgba(129, 140, 248, 0.15);
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
