<script setup lang="ts">
import * as echarts from 'echarts'
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'

import {
  adminApi,
  type AuditLogRecord,
  type AuditSummary,
  type BillRecord,
  type DrugListItem,
  type PatientAdminListItem,
  type PatientAdminStats,
  type SchedulingApplicationRecord,
} from '@/api/admin'
import { authApi, type AdminResourceStats, type DepartmentRecord } from '@/api/auth'
import SectionCard from '@/components/common/SectionCard.vue'
import { auditModuleLabel, auditSourceLabel } from '@/constants/adminAudit'
import { useAdminSessionStore } from '@/stores/adminSession'

const session = useAdminSessionStore()

const DEFAULT_RESOURCE_STATS: AdminResourceStats = {
  doctor_total: 0,
  outpatient_employee_total: 0,
  department_total: 0,
  clinic_room_total: 0,
}

const DEFAULT_PATIENT_STATS: PatientAdminStats = {
  patient_total: 0,
}

const DEFAULT_AUDIT_SUMMARY: AuditSummary = {
  total_count: 0,
  validated_count: 0,
  pending_count: 0,
  not_queued_count: 0,
  review_pending_count: 0,
  review_approved_count: 0,
  review_rejected_count: 0,
}

const REFUND_PRIORITY_STATES = new Set(['退款中', '退款失败', 'REFUNDING', 'REFUND_FAILED'])

const loading = ref(false)
const lastUpdatedAt = ref('')
const pendingApplications = ref<SchedulingApplicationRecord[]>([])
const pendingReviewLogs = ref<AuditLogRecord[]>([])
const lowStockDrugs = ref<DrugListItem[]>([])
const recentBills = ref<BillRecord[]>([])
const recentPatients = ref<PatientAdminListItem[]>([])
const resourceStats = ref<AdminResourceStats>({ ...DEFAULT_RESOURCE_STATS })
const patientStats = ref<PatientAdminStats>({ ...DEFAULT_PATIENT_STATS })
const auditSummary = ref<AuditSummary>({ ...DEFAULT_AUDIT_SUMMARY })
const defaultDepartment = ref<DepartmentRecord | null>(null)

const resourceChartRef = ref<HTMLDivElement | null>(null)
const stockChartRef = ref<HTMLDivElement | null>(null)
const riskChartRef = ref<HTMLDivElement | null>(null)

const resourceChartInstance = ref<any>(null)
const stockChartInstance = ref<any>(null)
const riskChartInstance = ref<any>(null)

const auditLoaded = ref(false)
const auditLoadFailed = ref(false)
const aiRiskMetric = computed(() => (auditLoadFailed.value ? '异常' : auditSummary.value.review_pending_count))

const heroMetrics = computed(() => [
  { label: '待审批', value: pendingApplications.value.length },
  { label: 'AI 风险', value: aiRiskMetric.value },
  { label: '低库存', value: lowStockDrugs.value.length },
  { label: '患者总量', value: patientStats.value.patient_total },
])

const resourceMetrics = computed(() => [
  { label: '医生总量', value: resourceStats.value.doctor_total },
  { label: '门诊人员', value: resourceStats.value.outpatient_employee_total },
  { label: '科室总量', value: resourceStats.value.department_total },
  { label: '诊室总量', value: resourceStats.value.clinic_room_total },
])

const lowStockChartData = computed(() => {
  const items = lowStockDrugs.value.slice(0, 5)
  return items.map((item) => ({
    uuid: item.uuid,
    label: item.drug_name,
    stock: Math.max(item.stock, 0),
    limit: Math.max(item.min_stock_limit ?? 0, 1),
  }))
})

const aiRiskChartData = computed(() => {
  const total =
    auditSummary.value.review_pending_count +
    auditSummary.value.review_approved_count +
    auditSummary.value.review_rejected_count
  const pending = auditSummary.value.review_pending_count
  const validated = Math.max(total - pending, 0)
  const pendingRatio = total ? Math.round((pending / total) * 100) : 0
  return { total, pending, validated, pendingRatio }
})

const keyBills = computed(() => {
  const prioritized = recentBills.value.filter((item) => REFUND_PRIORITY_STATES.has(item.bill_state))
  if (prioritized.length >= 2) return prioritized.slice(0, 2)
  if (prioritized.length === 1) {
    const fallback = recentBills.value.find((item) => item.uuid !== prioritized[0].uuid)
    return fallback ? [...prioritized, fallback] : prioritized
  }
  return recentBills.value.slice(0, 2)
})

function formatDateTime(value?: string | null) {
  if (!value) return '暂无时间'
  return value.replace('T', ' ').slice(0, 16)
}

function formatGender(value?: string | null) {
  if (!value) return '未知'
  const normalized = value.trim().toLowerCase()
  if (normalized === 'female' || normalized === '女') return '女'
  if (normalized === 'male' || normalized === '男') return '男'
  return value
}

function maskPatientName(value?: string | null) {
  const name = value?.trim() || '匿名患者'
  if (name.length <= 1) return name
  if (name.length === 2) return `${name[0]}*`
  return `${name[0]}${'*'.repeat(name.length - 2)}${name[name.length - 1]}`
}

function getWarningText(item: AuditLogRecord) {
  if (Array.isArray(item.warnings)) return item.warnings[0] || '待管理员复核'
  if (typeof item.warnings === 'string' && item.warnings.trim()) return item.warnings.trim()
  return '待管理员复核'
}

function formatRiskReason(value: string) {
  const text = value.trim()
  const labels: Record<string, string> = {
    llm_triage_no_valid_result_fallback: '真实分诊未返回有效结果，已降级到 fallback',
    llm_triage_request_failed_fallback: '真实分诊请求失败，已降级到 fallback',
    llm_triage_low_quality_fallback: '真实分诊结果质量不足，已切换到 fallback',
    llm_triage_not_configured_fallback: '真实分诊未配置，已使用 fallback',
    agent_execution_failed: 'Agent 执行失败',
    no_valid_draft_context: '病历初稿上下文不足',
    scheduling_no_actions_detected: '未识别出可执行的排班动作',
  }
  if (labels[text]) return labels[text]
  return text.split('_').join(' ')
}

function ensureChart(target: HTMLDivElement | null, current: any) {
  if (!target) return null
  if (current && !current.isDisposed() && current.getDom() === target) return current
  current?.dispose()
  return echarts.init(target)
}

function renderResourceChart() {
  resourceChartInstance.value = ensureChart(resourceChartRef.value, resourceChartInstance.value)
  if (!resourceChartInstance.value) return

  resourceChartInstance.value.setOption({
    animationDuration: 350,
    grid: { left: 8, right: 8, top: 18, bottom: 6, containLabel: true },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    xAxis: {
      type: 'category',
      data: resourceMetrics.value.map((item) => item.label),
      axisTick: { show: false },
      axisLine: { lineStyle: { color: '#dbe5f0' } },
      axisLabel: { color: '#64748b', fontSize: 11 },
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#e2e8f0' } },
      axisLabel: { color: '#94a3b8', fontSize: 11 },
    },
    series: [
      {
        type: 'bar',
        barWidth: 20,
        data: resourceMetrics.value.map((item) => item.value),
        itemStyle: {
          borderRadius: [8, 8, 0, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#14b8a6' },
            { offset: 1, color: '#0f766e' },
          ]),
        },
      },
    ],
  })
}

function renderStockChart() {
  if (!lowStockChartData.value.length) {
    stockChartInstance.value?.dispose()
    stockChartInstance.value = null
    return
  }

  stockChartInstance.value = ensureChart(stockChartRef.value, stockChartInstance.value)
  if (!stockChartInstance.value) return

  stockChartInstance.value.setOption({
    animationDuration: 350,
    grid: { left: 82, right: 18, top: 6, bottom: 0 },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    xAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#e2e8f0' } },
      axisLabel: { color: '#94a3b8', fontSize: 11 },
    },
    yAxis: {
      type: 'category',
      data: lowStockChartData.value.map((item) => item.label),
      axisTick: { show: false },
      axisLine: { show: false },
      axisLabel: { color: '#64748b', fontSize: 11 },
    },
    series: [
      {
        name: '预警值',
        type: 'bar',
        data: lowStockChartData.value.map((item) => item.limit),
        barWidth: 12,
        itemStyle: {
          borderRadius: 999,
          color: '#fed7aa',
        },
        z: 1,
      },
      {
        name: '当前库存',
        type: 'bar',
        data: lowStockChartData.value.map((item) => item.stock),
        barWidth: 12,
        barGap: '-100%',
        label: {
          show: true,
          position: 'right',
          color: '#0f172a',
          fontSize: 11,
          formatter: ({ dataIndex }: { dataIndex: number }) => {
            const item = lowStockChartData.value[dataIndex]
            return `${item.stock}/${item.limit}`
          },
        },
        itemStyle: {
          borderRadius: 999,
          color: new echarts.graphic.LinearGradient(1, 0, 0, 0, [
            { offset: 0, color: '#f97316' },
            { offset: 1, color: '#f59e0b' },
          ]),
        },
        z: 2,
      },
    ],
  })
}

function renderRiskChart() {
  riskChartInstance.value = ensureChart(riskChartRef.value, riskChartInstance.value)
  if (!riskChartInstance.value) return

  const hasData = aiRiskChartData.value.total > 0
  const seriesData = hasData
    ? [
        { value: aiRiskChartData.value.pending, name: '待人工复核', itemStyle: { color: '#f59e0b' } },
        { value: aiRiskChartData.value.validated, name: '已处理', itemStyle: { color: '#bfdbfe' } },
      ]
    : [{ value: 1, name: auditLoadFailed.value ? '加载异常' : '暂无记录', itemStyle: { color: '#e2e8f0' } }]

  riskChartInstance.value.setOption({
    animationDuration: 350,
    tooltip: { trigger: 'item' },
    legend: {
      bottom: 0,
      icon: 'circle',
      itemWidth: 8,
      itemHeight: 8,
      textStyle: { color: '#64748b', fontSize: 11 },
    },
    series: [
      {
        type: 'pie',
        radius: ['60%', '82%'],
        center: ['50%', '42%'],
        label: { show: false },
        labelLine: { show: false },
        data: seriesData,
      },
    ],
    graphic: [
      {
        type: 'group',
        left: 'center',
        top: '30%',
        children: [
          {
            type: 'text',
            left: -24,
            style: {
              text: hasData ? `${aiRiskChartData.value.pendingRatio}%` : '--',
              fill: '#0f172a',
              fontSize: 24,
              fontWeight: 700,
              textAlign: 'center',
            },
          },
          {
            type: 'text',
            left: -34,
            top: 28,
            style: {
              text: hasData ? '待人工复核占比' : auditLoadFailed.value ? 'AI 审计异常' : '暂无审计记录',
              fill: '#64748b',
              fontSize: 11,
              textAlign: 'center',
            },
          },
        ],
      },
    ],
  })
}

function renderCharts() {
  renderResourceChart()
  renderStockChart()
  renderRiskChart()
}

function resizeCharts() {
  resourceChartInstance.value?.resize()
  stockChartInstance.value?.resize()
  riskChartInstance.value?.resize()
}

function disposeCharts() {
  resourceChartInstance.value?.dispose()
  stockChartInstance.value?.dispose()
  riskChartInstance.value?.dispose()
  resourceChartInstance.value = null
  stockChartInstance.value = null
  riskChartInstance.value = null
}

async function loadDashboard() {
  loading.value = true
  try {
    const results = await Promise.allSettled([
      adminApi.listPendingApplications(),
      adminApi.listAiAudits({ limit: 1 }),
      adminApi.listAiAudits({ limit: 12, review_status: 'pending' }),
      adminApi.listDrugs({ low_stock_only: true, limit: 12 }),
      adminApi.listBills({ limit: 12 }),
      authApi.getAdminResourceStats(),
      adminApi.getPatientAdminStats(),
      adminApi.listPatients({ limit: 4 }),
      authApi.getDepartmentByCode('SJWK'),
    ])

    pendingApplications.value = results[0].status === 'fulfilled' ? results[0].value.data.data ?? [] : []
    auditSummary.value = results[1].status === 'fulfilled' ? results[1].value.data.data?.summary ?? { ...DEFAULT_AUDIT_SUMMARY } : { ...DEFAULT_AUDIT_SUMMARY }
    pendingReviewLogs.value = results[2].status === 'fulfilled' ? results[2].value.data.data?.items ?? [] : []
    auditLoaded.value = results[1].status === 'fulfilled'
    auditLoadFailed.value = results[1].status === 'rejected' || results[2].status === 'rejected'
    lowStockDrugs.value = results[3].status === 'fulfilled' ? results[3].value.data.data ?? [] : []
    recentBills.value = results[4].status === 'fulfilled' ? results[4].value.data.data ?? [] : []
    resourceStats.value = results[5].status === 'fulfilled' ? results[5].value.data.data ?? { ...DEFAULT_RESOURCE_STATS } : { ...DEFAULT_RESOURCE_STATS }
    patientStats.value = results[6].status === 'fulfilled' ? results[6].value.data.data ?? { ...DEFAULT_PATIENT_STATS } : { ...DEFAULT_PATIENT_STATS }
    recentPatients.value = results[7].status === 'fulfilled' ? results[7].value.data.data ?? [] : []
    defaultDepartment.value = results[8].status === 'fulfilled' ? results[8].value.data.data ?? null : null
    lastUpdatedAt.value = new Date().toLocaleString('zh-CN', { hour12: false })
  } finally {
    loading.value = false
  }
}

watch([resourceStats, lowStockDrugs, pendingReviewLogs, auditLoadFailed], async () => {
  await nextTick()
  renderCharts()
}, { deep: true })

onMounted(() => {
  void loadDashboard()
  window.addEventListener('resize', resizeCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeCharts)
  disposeCharts()
})
</script>

<template>
  <div class="admin-dashboard admin-dashboard--workbench">
    <section class="admin-dashboard__hero-shell">
      <div class="admin-dashboard__hero-copy">
        <span class="admin-dashboard__eyebrow">Admin Workbench</span>
        <h2>{{ session.staff?.displayName || '值班管理员' }}</h2>
        <p>以待办与风险为第一优先级，整合审批、AI 审计、资源承载与库存账单预警。</p>
      </div>

      <div class="admin-dashboard__hero-middle">
        <div class="admin-dashboard__hero-meta admin-dashboard__hero-meta--audit">
          <span>AI 审计</span>
          <strong>{{ auditLoadFailed ? '异常' : auditLoaded ? '已接入' : '加载中' }}</strong>
        </div>
      </div>

      <div class="admin-dashboard__hero-side">
        <div class="admin-dashboard__hero-meta">
          <span>最近刷新</span>
          <strong>{{ lastUpdatedAt || '尚未刷新' }}</strong>
        </div>
        <button type="button" :disabled="loading" @click="loadDashboard">
          {{ loading ? '刷新中...' : '刷新看板' }}
        </button>
      </div>

      <section class="admin-dashboard__hero-metrics">
        <article v-for="metric in heroMetrics" :key="metric.label" class="admin-dashboard__metric-card">
          <span>{{ metric.label }}</span>
          <strong>{{ metric.value }}</strong>
        </article>
      </section>
    </section>

    <div class="admin-dashboard__top-grid">
      <SectionCard title="待办 / 风险" subtitle="将排班审批与 AI 风险放在首页的第一处理优先级。" class="admin-dashboard__top-main">
        <div class="admin-dashboard__focus-grid">
          <section class="admin-dashboard__focus-panel">
            <header class="admin-dashboard__panel-head">
              <div>
                <strong>待审批排班</strong>
                <p>优先处理影响排班主链路的待审批请求。</p>
              </div>
              <span class="admin-dashboard__pill">{{ pendingApplications.length }}</span>
            </header>

            <div v-if="pendingApplications.length" class="admin-dashboard__compact-list">
              <article v-for="item in pendingApplications.slice(0, 4)" :key="item.uuid" class="admin-dashboard__compact-item">
                <div>
                  <strong>{{ item.employee_uuid }}</strong>
                  <p>{{ item.prompt }}</p>
                </div>
                <span>{{ formatDateTime(item.created_at) }}</span>
              </article>
            </div>
            <div v-else class="admin-empty">当前没有待审批排班申请。</div>
          </section>

          <section class="admin-dashboard__focus-panel is-risk">
            <header class="admin-dashboard__panel-head">
              <div>
                <strong>AI 风险摘要</strong>
                <p>突出待复核 AI 建议，保留模块与风险说明。</p>
              </div>
              <span class="admin-dashboard__pill is-warning">{{ auditLoadFailed ? '异常' : auditSummary.review_pending_count }}</span>
            </header>

            <div v-if="pendingReviewLogs.length" class="admin-dashboard__compact-list">
              <article v-for="item in pendingReviewLogs.slice(0, 4)" :key="item.uuid" class="admin-dashboard__compact-item admin-dashboard__compact-item--risk">
                <div>
                  <strong>{{ auditModuleLabel(item.module_name) }}</strong>
                  <p>{{ auditSourceLabel(item.source) }}</p>
                  <p class="admin-dashboard__risk-reason">{{ formatRiskReason(getWarningText(item)) }}</p>
                </div>
                <span class="admin-dashboard__compact-time">{{ formatDateTime(item.created_at) }}</span>
              </article>
            </div>
            <div v-else-if="auditLoadFailed" class="admin-empty">AI 审计数据加载失败，请检查后端服务状态。</div>
            <div v-else class="admin-empty">当前没有待复核的 AI 风险记录。</div>
          </section>
        </div>
      </SectionCard>

      <SectionCard title="资源总量图" subtitle="把资源图表直接抬到首屏。" class="admin-dashboard__top-chart-card">
        <div class="admin-dashboard__resource-metrics admin-dashboard__resource-metrics--compact">
          <article v-for="metric in resourceMetrics" :key="metric.label" class="admin-dashboard__resource-stat">
            <span>{{ metric.label }}</span>
            <strong>{{ metric.value }}</strong>
          </article>
        </div>
        <div ref="resourceChartRef" class="admin-dashboard__echart admin-dashboard__echart--top" />
      </SectionCard>

      <div class="admin-dashboard__top-side">
        <SectionCard title="AI 风险占比" subtitle="首屏直接看到结构。" class="admin-dashboard__top-side-card">
          <div ref="riskChartRef" class="admin-dashboard__echart admin-dashboard__echart--side" />
        </SectionCard>
      </div>
    </div>

    <div class="admin-dashboard__bottom-grid">
      <SectionCard title="资源 / 患者" subtitle="资源摘要和最近患者切片继续保留，但不再占用过高首屏空间。">
        <div class="admin-dashboard__resource-body">
          <article class="admin-dashboard__resource-spotlight">
            <span>资源总览</span>
            <strong>{{ defaultDepartment?.dept_name || '默认科室摘要' }}</strong>
            <p>{{ defaultDepartment?.dept_address || '首页聚合展示真实资源统计，不再使用样本数量冒充总量。' }}</p>
            <dl class="admin-dashboard__resource-detail">
              <div>
                <dt>科室类型</dt>
                <dd>{{ defaultDepartment?.dept_type || 'outpatient' }}</dd>
              </div>
              <div>
                <dt>诊室总量</dt>
                <dd>{{ resourceStats.clinic_room_total }}</dd>
              </div>
            </dl>
          </article>

          <article class="admin-dashboard__patient-slice">
            <header class="admin-dashboard__panel-head">
              <div>
                <strong>最近患者记录</strong>
                <p>首页只展示脱敏后的患者切片，不展示证件号和住址。</p>
              </div>
              <span class="admin-dashboard__pill">{{ recentPatients.length }}</span>
            </header>

            <div v-if="recentPatients.length" class="admin-dashboard__compact-list">
              <article v-for="patient in recentPatients" :key="patient.uuid" class="admin-dashboard__compact-item">
                <div>
                  <strong>{{ maskPatientName(patient.real_name) }}</strong>
                  <p>{{ patient.case_number }} · {{ formatGender(patient.gender) }}</p>
                </div>
                <span>{{ formatDateTime(patient.created_at) }}</span>
              </article>
            </div>
            <div v-else class="admin-empty">当前没有可展示的患者记录。</div>
          </article>
        </div>
      </SectionCard>

      <SectionCard title="库存 / 账单" subtitle="把库存图表也压缩到更高位置。">
        <div class="admin-dashboard__risk-grid">
          <article class="admin-dashboard__risk-panel">
            <header class="admin-dashboard__panel-head">
              <div>
                <strong>低库存药品</strong>
                <p>优先暴露需要补货或进一步关注的库存项。</p>
              </div>
              <span class="admin-dashboard__pill is-warning">{{ lowStockDrugs.length }}</span>
            </header>

            <div v-if="lowStockChartData.length" ref="stockChartRef" class="admin-dashboard__echart admin-dashboard__echart--stock" />

            <div v-if="lowStockDrugs.length" class="admin-dashboard__compact-list">
              <article v-for="drug in lowStockDrugs.slice(0, 3)" :key="drug.uuid" class="admin-dashboard__compact-item">
                <div>
                  <strong>{{ drug.drug_name }}</strong>
                  <p>库存 {{ drug.stock }} / 预警 {{ drug.min_stock_limit ?? 0 }}</p>
                </div>
                <span>{{ drug.unit }}</span>
              </article>
            </div>
            <div v-else class="admin-empty">当前没有低库存药品预警。</div>
          </article>

          <article class="admin-dashboard__risk-panel">
            <header class="admin-dashboard__panel-head">
              <div>
                <strong>关键账单</strong>
                <p>优先展示退款相关异常状态，否则回退到最近账单。</p>
              </div>
              <span class="admin-dashboard__pill">{{ keyBills.length }}</span>
            </header>

            <div v-if="keyBills.length" class="admin-dashboard__compact-list">
              <article v-for="bill in keyBills" :key="bill.uuid" class="admin-dashboard__compact-item">
                <div>
                  <strong>{{ bill.bill_code }}</strong>
                  <p>{{ bill.bill_state }} · {{ bill.total_amount }}</p>
                </div>
                <span>{{ formatDateTime(bill.pay_time) }}</span>
              </article>
            </div>
            <div v-else class="admin-empty">当前没有可展示的关键账单记录。</div>
          </article>
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.admin-dashboard--workbench {
  gap: 12px;
}

.admin-dashboard__hero-shell {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) 240px 280px;
  grid-template-areas:
    'copy audit side'
    'metrics metrics metrics';
  align-items: start;
  justify-content: stretch;
  column-gap: 20px;
  row-gap: 10px;
  padding: 16px;
  border-radius: 24px;
  background:
    radial-gradient(circle at top right, rgba(255, 255, 255, 0.22), transparent 34%),
    linear-gradient(135deg, #0f766e 0%, #115e59 55%, #164e63 100%);
  color: #ffffff;
  box-shadow: 0 22px 48px rgba(15, 23, 42, 0.16);
}

.admin-dashboard__hero-copy,
.admin-dashboard__hero-middle,
.admin-dashboard__hero-side {
  display: grid;
  gap: 6px;
  align-content: start;
}

.admin-dashboard__hero-copy {
  grid-area: copy;
}

.admin-dashboard__eyebrow {
  color: rgba(255, 255, 255, 0.82);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.admin-dashboard__hero-copy h2,
.admin-dashboard__hero-copy p,
.admin-dashboard__hero-meta span,
.admin-dashboard__hero-meta strong,
.admin-dashboard__metric-card span,
.admin-dashboard__metric-card strong {
  margin: 0;
}

.admin-dashboard__hero-copy h2 {
  font-size: 28px;
  line-height: 1.05;
}

.admin-dashboard__hero-copy p {
  max-width: 48ch;
  color: rgba(255, 255, 255, 0.88);
  line-height: 1.4;
}

.admin-dashboard__hero-middle {
  grid-area: audit;
  align-items: stretch;
}

.admin-dashboard__hero-side {
  grid-area: side;
  justify-items: stretch;
}

.admin-dashboard__hero-meta {
  display: grid;
  gap: 4px;
  padding: 10px 12px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.14);
}

.admin-dashboard__hero-meta--audit {
  min-height: 100%;
  align-content: center;
}

.admin-dashboard__hero-meta span {
  color: rgba(255, 255, 255, 0.74);
  font-size: 12px;
}

.admin-dashboard__hero-meta strong {
  font-size: 14px;
}

.admin-dashboard__hero-side button {
  min-height: 36px;
  border: 0;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.16);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.admin-dashboard__hero-side button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.admin-dashboard__hero-metrics {
  grid-area: metrics;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
}

.admin-dashboard__metric-card {
  display: grid;
  gap: 2px;
  min-height: 72px;
  padding: 10px 12px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.14);
  backdrop-filter: blur(10px);
}

.admin-dashboard__metric-card span {
  color: rgba(255, 255, 255, 0.78);
  font-size: 12px;
  font-weight: 700;
}

.admin-dashboard__metric-card strong {
  font-size: 24px;
  line-height: 1;
}

.admin-dashboard__top-grid,
.admin-dashboard__bottom-grid,
.admin-dashboard__focus-grid,
.admin-dashboard__risk-grid,
.admin-dashboard__resource-body,
.admin-dashboard__summary-list,
.admin-dashboard__top-side {
  display: grid;
  gap: 12px;
}

.admin-dashboard__top-grid {
  grid-template-columns: minmax(0, 1.35fr) minmax(332px, 0.86fr) minmax(280px, 0.74fr);
}

.admin-dashboard__bottom-grid {
  grid-template-columns: minmax(0, 1.06fr) minmax(0, 0.94fr);
}

.admin-dashboard__focus-grid,
.admin-dashboard__risk-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.admin-dashboard__focus-panel,
.admin-dashboard__risk-panel,
.admin-dashboard__summary-card,
.admin-dashboard__resource-spotlight,
.admin-dashboard__patient-slice,
.admin-dashboard__resource-stat {
  padding: 12px;
  border-radius: 16px;
  border: 1px solid var(--admin-border);
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.admin-dashboard__focus-panel.is-risk {
  background: linear-gradient(180deg, #fffaf0 0%, #ffffff 100%);
}

.admin-dashboard__panel-head,
.admin-dashboard__compact-item,
.admin-dashboard__resource-detail div {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.admin-dashboard__panel-head strong,
.admin-dashboard__compact-item strong,
.admin-dashboard__summary-card strong,
.admin-dashboard__resource-spotlight strong,
.admin-dashboard__resource-stat strong {
  margin: 0;
  color: var(--admin-text);
}

.admin-dashboard__panel-head p,
.admin-dashboard__compact-item p,
.admin-dashboard__summary-card p,
.admin-dashboard__resource-spotlight p,
.admin-dashboard__resource-stat span,
.admin-dashboard__resource-detail dt,
.admin-dashboard__resource-detail dd,
.admin-dashboard__compact-item span,
.admin-dashboard__summary-card span {
  margin: 0;
  color: var(--admin-text-muted);
  line-height: 1.45;
}

.admin-dashboard__pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 34px;
  min-height: 24px;
  padding: 0 10px;
  border-radius: 999px;
  background: var(--admin-accent-soft);
  color: var(--admin-accent-strong);
  font-size: 11px;
  font-weight: 700;
}

.admin-dashboard__pill.is-warning {
  background: var(--admin-warn-soft);
  color: #b45309;
}

.admin-dashboard__compact-list,
.admin-dashboard__resource-metrics,
.admin-dashboard__summary-list--compact {
  display: grid;
  gap: 8px;
}

.admin-dashboard__resource-metrics {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

.admin-dashboard__resource-metrics--compact {
  gap: 8px;
}

.admin-dashboard__resource-stat {
  display: grid;
  gap: 4px;
  min-height: 68px;
}

.admin-dashboard__resource-stat span {
  font-size: 12px;
  font-weight: 700;
}

.admin-dashboard__resource-stat strong {
  font-size: 20px;
}

.admin-dashboard__echart {
  width: 100%;
  height: 156px;
  margin-top: 4px;
}

.admin-dashboard__echart--top {
  height: 156px;
}

.admin-dashboard__echart--side {
  height: 140px;
}

.admin-dashboard__echart--stock {
  height: 128px;
}

.admin-dashboard__resource-body {
  grid-template-columns: minmax(0, 1fr) minmax(280px, 1fr);
  gap: 10px;
}

.admin-dashboard__resource-spotlight {
  display: grid;
  gap: 6px;
}

.admin-dashboard__resource-spotlight span {
  color: var(--admin-accent);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.admin-dashboard__resource-spotlight strong {
  font-size: 22px;
}

.admin-dashboard__resource-detail {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.admin-dashboard__resource-detail dd {
  color: var(--admin-text);
  font-weight: 700;
}

.admin-dashboard__compact-item {
  padding: 10px;
  border-radius: 14px;
  border: 1px solid #dbe5f0;
  background: #ffffff;
}

.admin-dashboard__compact-item--risk {
  display: grid;
  gap: 8px;
  align-items: start;
  justify-content: stretch;
}

.admin-dashboard__compact-item strong {
  display: block;
  margin-bottom: 2px;
}

.admin-dashboard__compact-item span {
  font-size: 11px;
  white-space: nowrap;
}

.admin-dashboard__compact-time {
  color: var(--admin-text-muted);
  white-space: nowrap;
}

.admin-dashboard__risk-reason {
  color: var(--admin-text);
  font-size: 13px;
  line-height: 1.5;
  word-break: break-word;
}

.admin-dashboard__summary-card strong {
  font-size: 18px;
}

.admin-dashboard__summary-list--compact .admin-dashboard__summary-card {
  padding: 10px;
}

@media (max-width: 1440px) {
  .admin-dashboard__hero-shell {
    grid-template-columns: minmax(0, 1.1fr) 220px 240px;
    column-gap: 16px;
  }

  .admin-dashboard__top-grid {
    grid-template-columns: minmax(0, 1.2fr) minmax(240px, 0.65fr) minmax(240px, 0.65fr);
  }

  .admin-dashboard__top-side {
    grid-column: 1 / -1;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 1280px) {
  .admin-dashboard__hero-shell {
    grid-template-columns: 1fr 1fr;
    grid-template-areas:
      'copy copy'
      'audit side'
      'metrics metrics';
  }

  .admin-dashboard__top-grid,
  .admin-dashboard__top-grid,
  .admin-dashboard__bottom-grid,
  .admin-dashboard__resource-body,
  .admin-dashboard__top-side {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 1080px) {
  .admin-dashboard__hero-metrics,
  .admin-dashboard__resource-metrics,
  .admin-dashboard__focus-grid,
  .admin-dashboard__risk-grid,
  .admin-dashboard__resource-detail {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 760px) {
  .admin-dashboard--workbench {
    gap: 12px;
  }

  .admin-dashboard__hero-shell {
    padding: 14px;
    grid-template-columns: 1fr;
    grid-template-areas:
      'copy'
      'audit'
      'side'
      'metrics';
  }

  .admin-dashboard__hero-metrics,
  .admin-dashboard__resource-metrics,
  .admin-dashboard__focus-grid,
  .admin-dashboard__risk-grid,
  .admin-dashboard__resource-detail {
    grid-template-columns: 1fr;
  }

  .admin-dashboard__panel-head,
  .admin-dashboard__compact-item {
    flex-direction: column;
  }
}
</style>
