<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import {
  adminApi,
  type AuditLogRecord,
  type BillRecord,
  type DrugListItem,
  type SchedulingApplicationRecord,
} from '@/api/admin'
import {
  authApi,
  type ClinicRoomRecord,
  type DepartmentRecord,
  type DoctorDirectoryItem,
  type EmployeeRecord,
} from '@/api/auth'
import { http, type ApiEnvelope } from '@/api/http'
import SectionCard from '@/components/common/SectionCard.vue'
import { useAdminSessionStore } from '@/stores/adminSession'

const session = useAdminSessionStore()
const loading = ref(false)
const pendingApplications = ref<SchedulingApplicationRecord[]>([])
const auditLogs = ref<AuditLogRecord[]>([])
const lowStockDrugs = ref<DrugListItem[]>([])
const recentBills = ref<BillRecord[]>([])
const doctors = ref<DoctorDirectoryItem[]>([])
const outpatientEmployees = ref<EmployeeRecord[]>([])
const department = ref<DepartmentRecord | null>(null)
const room = ref<ClinicRoomRecord | null>(null)

const auditAvailable = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))

const metricCards = computed(() => [
  { label: '待审批排班', value: pendingApplications.value.length, tone: 'indigo' },
  { label: 'AI 审计记录', value: auditAvailable.value ? auditLogs.value.length : '未配置', tone: 'sky' },
  { label: '低库存药品', value: lowStockDrugs.value.length, tone: 'amber' },
  { label: '最近账单', value: recentBills.value.length, tone: 'emerald' },
  { label: '医生账号', value: doctors.value.length, tone: 'slate' },
])

const insightItems = computed(() => {
  const items = [
    { label: '待复核 AI 建议', value: auditLogs.value.filter((item) => !item.validated).length, max: Math.max(auditLogs.value.length, 1) },
    { label: '待审批动作', value: pendingApplications.value.length, max: Math.max(pendingApplications.value.length, 1) },
    { label: '低库存药品', value: lowStockDrugs.value.length, max: Math.max(lowStockDrugs.value.length, 1) },
    { label: '门诊人员资源', value: outpatientEmployees.value.length, max: Math.max(outpatientEmployees.value.length, 1) },
  ]

  return items.map((item) => ({
    ...item,
    ratio: Math.min(100, Math.round((item.value / item.max) * 100)),
  }))
})

const moduleSummary = computed(() => {
  const counts = new Map<string, number>()
  for (const item of auditLogs.value) {
    counts.set(item.module_name, (counts.get(item.module_name) ?? 0) + 1)
  }

  return [
    { label: 'triage', value: counts.get('triage') ?? 0 },
    { label: 'scheduling', value: counts.get('scheduling') ?? 0 },
    { label: 'prescription', value: counts.get('prescription') ?? 0 },
  ]
})

const roomCandidates = ['CT一室', '门诊一诊室', '脑电图室'] as const

function formatDateTime(value?: string | null) {
  if (!value) return '暂无时间'
  return value.replace('T', ' ').slice(0, 16)
}

async function tryGetClinicRoomByName(name: string) {
  const response = await http.get<ApiEnvelope<ClinicRoomRecord>>(`/api/v1/auth/clinic-room/name/${encodeURIComponent(name)}`, {
    validateStatus: (status) => status === 200 || status === 404,
  })

  return response.status === 200 ? response.data.data ?? null : null
}

async function loadRoomSnapshot() {
  const results = await Promise.allSettled(roomCandidates.map((name) => tryGetClinicRoomByName(name)))
  const found = results.find((result) => result.status === 'fulfilled' && result.value)
  room.value = found && found.status === 'fulfilled' ? found.value : null
}

async function loadDashboard() {
  loading.value = true
  try {
    const results = await Promise.allSettled([
      adminApi.listPendingApplications(),
      auditAvailable.value ? adminApi.listAiAudits({ limit: 12 }) : Promise.resolve(null),
      adminApi.listDrugs({ low_stock_only: true, limit: 12 }),
      adminApi.listBills({ limit: 12 }),
      authApi.listDoctorsByDepartmentCode('SJWK'),
      authApi.getEmployeesByDeptType('outpatient'),
      authApi.getDepartmentByCode('SJWK'),
      loadRoomSnapshot(),
    ])

    pendingApplications.value = results[0].status === 'fulfilled' ? results[0].value.data.data ?? [] : []
    auditLogs.value = results[1].status === 'fulfilled' && results[1].value ? results[1].value.data.data ?? [] : []
    lowStockDrugs.value = results[2].status === 'fulfilled' ? results[2].value.data.data ?? [] : []
    recentBills.value = results[3].status === 'fulfilled' ? results[3].value.data.data ?? [] : []
    doctors.value = results[4].status === 'fulfilled' ? results[4].value.data.data ?? [] : []
    outpatientEmployees.value = results[5].status === 'fulfilled' ? results[5].value.data.data ?? [] : []
    department.value = results[6].status === 'fulfilled' ? results[6].value.data.data ?? null : null
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadDashboard()
})
</script>

<template>
  <div class="admin-dashboard">
    <section class="admin-dashboard__hero">
      <div>
        <span>首页大屏</span>
        <h2>{{ session.staff?.displayName || '值班管理员' }}</h2>
        <p>聚合审批、AI 审计、药房账单与资源摘要，作为管理员端主屏使用。</p>
      </div>
      <button type="button" :disabled="loading" @click="loadDashboard">
        {{ loading ? '刷新中...' : '刷新看板' }}
      </button>
    </section>

    <section class="admin-dashboard__metrics">
      <article v-for="metric in metricCards" :key="metric.label" :class="['admin-dashboard__metric', `is-${metric.tone}`]">
        <span>{{ metric.label }}</span>
        <strong>{{ metric.value }}</strong>
      </article>
    </section>

    <div class="admin-dashboard__grid">
      <SectionCard title="运营态势" subtitle="按现有真实接口聚合后台关键状态。">
        <div class="admin-dashboard__insights">
          <article v-for="item in insightItems" :key="item.label" class="admin-dashboard__insight">
            <div>
              <strong>{{ item.label }}</strong>
              <span>{{ item.value }}</span>
            </div>
            <div class="admin-dashboard__bar">
              <i :style="{ width: `${item.ratio}%` }" />
            </div>
          </article>
        </div>
      </SectionCard>

      <SectionCard
        title="AI 模块统计"
        :subtitle="auditAvailable ? '展示 AI 审计中已留下证据链的模块记录。' : '当前未配置 AI 审计 token。'"
      >
        <div class="admin-dashboard__module-list">
          <article v-for="item in moduleSummary" :key="item.label">
            <strong>{{ item.label }}</strong>
            <p>{{ item.value }} 条</p>
          </article>
        </div>
      </SectionCard>
    </div>

    <div class="admin-dashboard__grid">
      <SectionCard title="待办快照" subtitle="优先关注会影响主链路演示的后台动作。">
        <div v-if="pendingApplications.length" class="admin-dashboard__list">
          <article v-for="item in pendingApplications.slice(0, 4)" :key="item.uuid" class="admin-dashboard__list-item">
            <strong>{{ item.employee_uuid }}</strong>
            <p>{{ item.prompt }}</p>
            <span>{{ formatDateTime(item.created_at) }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有待审批排班申请。</div>
      </SectionCard>

      <SectionCard title="账单与库存" subtitle="把药房和财务的风险信号收束到首页。">
        <div class="admin-dashboard__stack">
          <article class="admin-dashboard__stat-card">
            <strong>低库存药品</strong>
            <p>{{ lowStockDrugs[0]?.drug_name || '暂无低库存药品' }}</p>
            <span v-if="lowStockDrugs[0]">库存 {{ lowStockDrugs[0].stock }} / 预警 {{ lowStockDrugs[0].min_stock_limit ?? 0 }}</span>
          </article>
          <article class="admin-dashboard__stat-card">
            <strong>最近账单</strong>
            <p>{{ recentBills[0]?.bill_code || '暂无账单记录' }}</p>
            <span v-if="recentBills[0]">{{ recentBills[0].bill_state }} | {{ recentBills[0].total_amount }}</span>
          </article>
        </div>
      </SectionCard>
    </div>

    <SectionCard title="资源概览" subtitle="复用基础资料能力，只展示资源摘要，不再承担维护入口。">
      <div class="admin-dashboard__resources">
        <article class="admin-dashboard__resource-card">
          <span>医生资源</span>
          <strong>{{ doctors.length }} 名</strong>
          <p>默认按神经外科（SJWK）医生账号统计。</p>
        </article>
        <article class="admin-dashboard__resource-card">
          <span>科室概览</span>
          <strong>{{ department?.dept_name || '未加载' }}</strong>
          <p>{{ department?.dept_address || '当前没有可展示的科室地址信息。' }}</p>
        </article>
        <article class="admin-dashboard__resource-card">
          <span>门诊人员</span>
          <strong>{{ outpatientEmployees.length }} 人</strong>
          <p>按 `outpatient` 类型汇总人员资源。</p>
        </article>
        <article class="admin-dashboard__resource-card">
          <span>诊室样本</span>
          <strong>{{ room?.room_name || '未命中样本' }}</strong>
          <p>{{ room?.room_code || '若后端无样本诊室，这里不再报错。' }}</p>
        </article>
      </div>
    </SectionCard>
  </div>
</template>
