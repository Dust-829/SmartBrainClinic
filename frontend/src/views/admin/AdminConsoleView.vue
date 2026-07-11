<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import { adminApi, type AuditLogRecord, type SchedulingApplicationRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'
import { useAdminSessionStore } from '@/stores/adminSession'

const session = useAdminSessionStore()
const loading = ref(false)
const pendingApplications = ref<SchedulingApplicationRecord[]>([])
const auditLogs = ref<AuditLogRecord[]>([])
const auditAvailable = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))

const metricCards = computed(() => [
  { label: '待审批排班', value: pendingApplications.value.length, tone: 'indigo' },
  { label: 'AI 审计记录', value: auditAvailable.value ? auditLogs.value.length : '未配置', tone: 'sky' },
  {
    label: '待人工复核',
    value: auditAvailable.value ? auditLogs.value.filter((item) => !item.validated).length : '未配置',
    tone: 'amber',
  },
  {
    label: '管理员身份',
    value: session.staff?.staffCode || 'ADMIN',
    tone: 'slate',
  },
])

const quickLinks = computed(() => [
  { title: '医生管理', subtitle: '查看医生、维护专长、调整 AI 评分', to: '/admin/doctors' },
  { title: '科室资料', subtitle: '查看科室和人员资源分布', to: '/admin/departments' },
  { title: '诊室资源', subtitle: '查询门诊诊室、CT室和检查室资源', to: '/admin/rooms' },
  { title: '智能排班', subtitle: '生成常规排班、提交 AI 微调和人工规则干预', to: '/admin/schedules' },
  { title: '审批中心', subtitle: '集中处理排班申请与高风险后台动作', to: '/admin/approvals' },
  {
    title: 'AI 审计',
    subtitle: auditAvailable.value ? '查看 AI 输出、人工确认结果和证据链' : '当前需要先配置前端审计 token',
    to: '/admin/audit',
  },
  { title: '药房工作台', subtitle: '批量入库、发药、退药和库存预警', to: '/admin/pharmacy' },
  { title: '财务账单', subtitle: '查询挂号账单、退费和异常收费处理', to: '/admin/billing' },
  { title: '运营分析', subtitle: '用于答辩展示后台统计与证据链概览', to: '/admin/analytics' },
])

async function loadDashboard() {
  loading.value = true
  try {
    const tasks = [
      adminApi.listPendingApplications(),
      auditAvailable.value ? adminApi.listAiAudits({ limit: 8 }) : Promise.resolve(null),
    ] as const

    const [applicationsResult, auditsResult] = await Promise.allSettled(tasks)
    pendingApplications.value = applicationsResult.status === 'fulfilled' ? applicationsResult.value.data.data ?? [] : []
    auditLogs.value = auditsResult.status === 'fulfilled' && auditsResult.value ? auditsResult.value.data.data?.items ?? [] : []
  } catch {
    pendingApplications.value = []
    auditLogs.value = []
  } finally {
    loading.value = false
  }
}

function formatDateTime(value?: string | null) {
  if (!value) return '暂无时间'
  return value.replace('T', ' ').slice(0, 16)
}

onMounted(() => {
  loadDashboard()
})
</script>

<template>
  <div class="admin-console">
    <section class="admin-console__hero">
      <div>
        <span>当前管理员</span>
        <h2>{{ session.staff?.displayName || '值班管理员' }}</h2>
        <p>这里承接医院资源、流程、审批、药房、账单与 AI 审计的统一控制入口。</p>
      </div>
      <button type="button" :disabled="loading" @click="loadDashboard">
        {{ loading ? '刷新中...' : '刷新总览' }}
      </button>
    </section>

    <section class="admin-console__metrics">
      <article v-for="metric in metricCards" :key="metric.label" :class="['admin-console__metric', `is-${metric.tone}`]">
        <span>{{ metric.label }}</span>
        <strong>{{ metric.value }}</strong>
      </article>
    </section>

    <div class="admin-console__grid">
      <SectionCard title="待办与异常" subtitle="优先处理最能影响演示闭环的后台动作。">
        <div v-if="pendingApplications.length" class="admin-list">
          <article v-for="item in pendingApplications.slice(0, 4)" :key="item.uuid" class="admin-console__list-item">
            <strong>{{ item.employee_uuid }}</strong>
            <p>{{ item.prompt }}</p>
            <span>{{ formatDateTime(item.created_at) }}</span>
          </article>
        </div>
        <div v-else class="admin-console__empty">当前没有待审批排班申请。</div>
      </SectionCard>

      <SectionCard
        title="AI 审计快照"
        :subtitle="auditAvailable ? '用来展示 AI 产生信息与人工确认信息的留痕证据。' : '当前未配置审计 token，只显示配置提示。'"
      >
        <div v-if="auditLogs.length" class="admin-list">
          <article v-for="item in auditLogs.slice(0, 4)" :key="item.uuid" class="admin-console__list-item">
            <strong>{{ item.module_name }}</strong>
            <p>{{ item.source || '未知来源' }} | {{ item.model || '未记录模型' }}</p>
            <span>{{ item.validated ? '已验证' : '待复核' }}</span>
          </article>
        </div>
        <div v-else class="admin-console__empty">
          {{ auditAvailable ? '当前没有可展示的 AI 审计记录。' : '后端未配置 AI audit token，审计快照暂不可用。' }}
        </div>
      </SectionCard>
    </div>

    <SectionCard title="管理员工作台入口" subtitle="按最小闭环组织，避免后台只有单页骨架。">
      <div class="admin-console__links">
        <router-link v-for="item in quickLinks" :key="item.to" :to="item.to" class="admin-console__link-card">
          <strong>{{ item.title }}</strong>
          <p>{{ item.subtitle }}</p>
        </router-link>
      </div>
    </SectionCard>
  </div>
</template>
