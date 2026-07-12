<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import {
  adminApi,
  type AdminBillDetail,
  type AdminBillListItem,
  type AdminBillPage,
  type AdminBillSummary,
  type BillRefundResult,
} from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const DEFAULT_SUMMARY: AdminBillSummary = {
  total_count: 0,
  paid_count: 0,
  refunding_count: 0,
  refunded_count: 0,
  refund_failed_count: 0,
  state_counts: {},
  total_amount: '0.00',
  refunded_amount: '0.00',
}

const DEFAULT_PAGE: AdminBillPage = {
  items: [],
  pagination: {
    total: 0,
    limit: 8,
    offset: 0,
  },
  summary: { ...DEFAULT_SUMMARY },
}

const workbenchLoading = ref(false)
const detailLoading = ref(false)
const refundingBillCode = ref('')
const selectedBillCode = ref('')
const pageData = ref<AdminBillPage>({ ...DEFAULT_PAGE })
const selectedBillDetail = ref<AdminBillDetail | null>(null)
const lastRefund = ref<BillRefundResult | null>(null)
const listError = ref('')
const detailError = ref('')

const filters = reactive({
  keyword: '',
  state: '',
  limit: 8,
  offset: 0,
})

const selectedListItem = computed<AdminBillListItem | null>(() => {
  return pageData.value.items.find((item) => item.bill_code === selectedBillCode.value) ?? null
})

const summaryCards = computed(() => [
  { label: '账单总数', value: String(pageData.value.summary.total_count), tone: 'is-slate' },
  { label: '退费处理中', value: String(pageData.value.summary.refunding_count), tone: 'is-amber' },
  { label: '已退费', value: String(pageData.value.summary.refunded_count), tone: 'is-indigo' },
  { label: '累计金额', value: formatCurrency(pageData.value.summary.total_amount), tone: 'is-emerald' },
])

const hasPrevPage = computed(() => pageData.value.pagination.offset > 0)
const hasNextPage = computed(() => {
  const { offset, limit, total } = pageData.value.pagination
  return offset + limit < total
})
const pageStart = computed(() => {
  if (!pageData.value.pagination.total) return 0
  return pageData.value.pagination.offset + 1
})
const pageEnd = computed(() => {
  const { offset, limit, total } = pageData.value.pagination
  return Math.min(offset + limit, total)
})

function formatDateTime(value?: string | null) {
  return value ? value.replace('T', ' ').slice(0, 16) : '未记录'
}

function formatCurrency(value?: string | null) {
  const amount = Number(value ?? 0)
  if (Number.isNaN(amount)) return value || '0.00'
  return `¥ ${amount.toFixed(2)}`
}

function canRefund(item?: { bill_state?: string | null } | null) {
  return !!item && item.bill_state !== '已退费' && item.bill_state !== 'REFUNDED'
}

function resetFilters() {
  filters.keyword = ''
  filters.state = ''
  filters.offset = 0
}

async function loadBillDetail(billCode: string) {
  selectedBillCode.value = billCode
  detailLoading.value = true
  detailError.value = ''
  try {
    const response = await adminApi.getAdminBillDetail(billCode)
    selectedBillDetail.value = response.data.data ?? null
  } catch (error) {
    selectedBillDetail.value = null
    detailError.value = extractErrorMessage(error, '账单详情加载失败')
  } finally {
    detailLoading.value = false
  }
}

function resolvePreferredBillCode(preferredBillCode?: string) {
  if (preferredBillCode && pageData.value.items.some((item) => item.bill_code === preferredBillCode)) {
    return preferredBillCode
  }
  if (selectedBillCode.value && pageData.value.items.some((item) => item.bill_code === selectedBillCode.value)) {
    return selectedBillCode.value
  }
  return pageData.value.items[0]?.bill_code ?? ''
}

async function loadWorkbench(preferredBillCode?: string) {
  workbenchLoading.value = true
  listError.value = ''
  try {
    const response = await adminApi.getAdminBillsPage({
      keyword: filters.keyword.trim() || undefined,
      state: filters.state || undefined,
      limit: filters.limit,
      offset: filters.offset,
    })
    pageData.value = response.data.data ?? { ...DEFAULT_PAGE }

    const nextBillCode = resolvePreferredBillCode(preferredBillCode)
    if (!nextBillCode) {
      selectedBillCode.value = ''
      selectedBillDetail.value = null
      detailError.value = ''
      return
    }
    await loadBillDetail(nextBillCode)
  } catch (error) {
    pageData.value = { ...DEFAULT_PAGE }
    selectedBillCode.value = ''
    selectedBillDetail.value = null
    listError.value = extractErrorMessage(error, '账单工作台加载失败')
  } finally {
    workbenchLoading.value = false
  }
}

async function searchBills() {
  filters.offset = 0
  await loadWorkbench()
}

async function handleReset() {
  resetFilters()
  await loadWorkbench()
}

async function selectBill(item: AdminBillListItem) {
  if (selectedBillCode.value === item.bill_code && selectedBillDetail.value?.bill_code === item.bill_code) {
    return
  }
  await loadBillDetail(item.bill_code)
}

async function goPrevPage() {
  if (!hasPrevPage.value) return
  filters.offset = Math.max(0, filters.offset - filters.limit)
  await loadWorkbench()
}

async function goNextPage() {
  if (!hasNextPage.value) return
  filters.offset += filters.limit
  await loadWorkbench()
}

async function refundSelectedBill() {
  const billCode = selectedBillDetail.value?.bill_code
  if (!billCode || refundingBillCode.value) return

  refundingBillCode.value = billCode
  try {
    const response = await adminApi.refundBill(billCode)
    lastRefund.value = response.data.data ?? null
    ElMessage.success('退费成功')
    await loadWorkbench(billCode)
  } finally {
    refundingBillCode.value = ''
  }
}

function extractErrorMessage(error: unknown, fallback: string) {
  const detail =
    (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.detail ||
    (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.message
  return detail || fallback
}

onMounted(() => {
  loadWorkbench()
})
</script>

<template>
  <div class="admin-page admin-billing-workbench">
    <section class="admin-page__hero">
      <div>
        <span>收费与退费闭环</span>
        <h2>财务账单工作台</h2>
        <p>首屏直接进入账单检索、详情查看和退费处理，不再依赖手输 UUID 才能开始工作。</p>
      </div>
    </section>

    <section class="analytics-cards admin-billing-workbench__metrics">
      <article v-for="card in summaryCards" :key="card.label" :class="['analytics-card', card.tone]">
        <span>{{ card.label }}</span>
        <strong>{{ card.value }}</strong>
      </article>
    </section>

    <div class="admin-billing-workbench__grid">
      <SectionCard title="账单筛选与结果" subtitle="支持账单号、挂号 UUID、患者姓名、病历号、身份证号检索。">
        <form class="toolbar__search admin-billing-workbench__search" @submit.prevent="searchBills">
          <input
            v-model="filters.keyword"
            type="text"
            placeholder="账单号 / 挂号 UUID / 患者姓名 / 病历号 / 身份证号"
          />
          <select v-model="filters.state">
            <option value="">全部状态</option>
            <option value="已收费">已收费</option>
            <option value="退费中">退费中</option>
            <option value="已退费">已退费</option>
            <option value="退费失败">退费失败</option>
          </select>
          <button type="submit" :disabled="workbenchLoading">
            {{ workbenchLoading ? '刷新中...' : '查询账单' }}
          </button>
          <button type="button" class="admin-inline-button is-secondary" :disabled="workbenchLoading" @click="handleReset">
            重置筛选
          </button>
        </form>

        <div class="admin-billing-workbench__list-toolbar">
          <p>
            当前显示 {{ pageStart }} - {{ pageEnd }} / {{ pageData.pagination.total }}
            <span v-if="selectedListItem">· 已选 {{ selectedListItem.bill_code }}</span>
          </p>
          <div class="admin-billing-workbench__pager">
            <button type="button" class="admin-inline-button is-secondary" :disabled="!hasPrevPage || workbenchLoading" @click="goPrevPage">
              上一页
            </button>
            <button type="button" class="admin-inline-button is-secondary" :disabled="!hasNextPage || workbenchLoading" @click="goNextPage">
              下一页
            </button>
          </div>
        </div>

        <div v-if="listError" class="admin-empty admin-billing-workbench__panel-empty">
          {{ listError }}
        </div>
        <div v-else-if="workbenchLoading && !pageData.items.length" class="admin-empty admin-billing-workbench__panel-empty">
          正在加载账单工作台...
        </div>
        <div v-else-if="pageData.items.length" class="bill-list admin-billing-workbench__list">
          <article
            v-for="item in pageData.items"
            :key="item.bill_code"
            :class="['bill-card', 'admin-billing-workbench__list-card', { 'is-active': selectedBillCode === item.bill_code }]"
            @click="selectBill(item)"
          >
            <div class="bill-card__head">
              <div>
                <strong>{{ item.bill_code }}</strong>
                <p>{{ item.patient_name || '未知患者' }} · {{ item.case_number || '无病历号' }}</p>
              </div>
              <span>{{ item.bill_state }}</span>
            </div>

            <div class="bill-card__meta">
              <div>
                <dt>金额</dt>
                <dd>{{ formatCurrency(item.total_amount) }}</dd>
              </div>
              <div>
                <dt>支付时间</dt>
                <dd>{{ formatDateTime(item.pay_time) }}</dd>
              </div>
              <div>
                <dt>挂号日期</dt>
                <dd>{{ formatDateTime(item.visit_date) }}</dd>
              </div>
              <div>
                <dt>明细数</dt>
                <dd>{{ item.detail_count }}</dd>
              </div>
            </div>

            <p class="admin-billing-workbench__subline">
              挂号单：{{ item.register_uuid }}<br />
              证件：{{ item.card_number_masked || '未记录' }}
            </p>
          </article>
        </div>
        <div v-else class="admin-empty admin-billing-workbench__panel-empty">
          当前筛选条件下没有命中的账单记录。
        </div>
      </SectionCard>

      <div class="admin-page__stack admin-billing-workbench__detail-stack">
        <SectionCard title="当前账单详情" subtitle="右侧固定展示当前选中账单的上下文与退费操作。">
          <div v-if="detailError" class="admin-empty admin-billing-workbench__panel-empty">
            {{ detailError }}
          </div>
          <div v-else-if="detailLoading" class="admin-empty admin-billing-workbench__panel-empty">
            正在加载账单详情...
          </div>
          <div v-else-if="selectedBillDetail" class="admin-billing-workbench__detail">
            <header class="admin-billing-workbench__detail-head">
              <div>
                <strong>{{ selectedBillDetail.bill_code }}</strong>
                <p>
                  {{ selectedBillDetail.patient_name || '未知患者' }}
                  <span>· {{ selectedBillDetail.case_number || '无病历号' }}</span>
                </p>
              </div>
              <span class="admin-billing-workbench__state-pill">{{ selectedBillDetail.bill_state }}</span>
            </header>

            <dl class="admin-billing-workbench__detail-grid">
              <div>
                <dt>挂号单</dt>
                <dd>{{ selectedBillDetail.register_uuid }}</dd>
              </div>
              <div>
                <dt>账单金额</dt>
                <dd>{{ formatCurrency(selectedBillDetail.total_amount) }}</dd>
              </div>
              <div>
                <dt>支付方式</dt>
                <dd>{{ selectedBillDetail.pay_method || '未记录' }}</dd>
              </div>
              <div>
                <dt>交易号</dt>
                <dd>{{ selectedBillDetail.transaction_id || '未记录' }}</dd>
              </div>
              <div>
                <dt>支付时间</dt>
                <dd>{{ formatDateTime(selectedBillDetail.pay_time) }}</dd>
              </div>
              <div>
                <dt>挂号状态</dt>
                <dd>{{ selectedBillDetail.visit_state_label || '未记录' }}</dd>
              </div>
              <div>
                <dt>挂号日期</dt>
                <dd>{{ formatDateTime(selectedBillDetail.visit_date) }}</dd>
              </div>
              <div>
                <dt>证件号</dt>
                <dd>{{ selectedBillDetail.card_number_masked || '未记录' }}</dd>
              </div>
            </dl>

            <div class="bill-card__actions admin-billing-workbench__actions">
              <button
                type="button"
                :disabled="!canRefund(selectedBillDetail) || refundingBillCode === selectedBillDetail.bill_code"
                @click="refundSelectedBill"
              >
                {{ refundingBillCode === selectedBillDetail.bill_code ? '退费中...' : '执行退费' }}
              </button>
            </div>
          </div>
          <div v-else class="admin-empty admin-billing-workbench__panel-empty">
            左侧选中一条账单后，这里会展示完整详情、明细和退费链路。
          </div>
        </SectionCard>

        <SectionCard title="收费明细" subtitle="展示当前账单关联的收费项目明细。">
          <div v-if="selectedBillDetail?.details?.length" class="admin-list admin-billing-workbench__detail-list">
            <article v-for="detail in selectedBillDetail.details" :key="detail.uuid" class="admin-list__item">
              <strong>{{ detail.item_type }}</strong>
              <p>{{ detail.item_source_id }}</p>
              <span>{{ formatCurrency(detail.amount) }}</span>
            </article>
          </div>
          <div v-else class="admin-empty admin-billing-workbench__panel-empty">
            当前账单没有可展示的收费明细。
          </div>
        </SectionCard>

        <SectionCard title="退费链路 / 最近结果" subtitle="同时展示 saga step 进度和最近一次退费返回。">
          <div v-if="selectedBillDetail?.refund_steps?.length" class="result-list admin-billing-workbench__steps">
            <article v-for="step in selectedBillDetail.refund_steps" :key="`${step.step_name}-${step.updated_at}`" class="result-card">
              <strong>{{ step.step_name }}</strong>
              <p>{{ step.status }} · {{ formatDateTime(step.updated_at) }}</p>
              <span>{{ step.error_message || '无错误信息' }}</span>
            </article>
          </div>
          <div v-else class="admin-empty admin-billing-workbench__panel-empty">
            当前账单还没有退费 saga step 记录。
          </div>

          <pre class="admin-result admin-billing-workbench__refund-result">
{{ lastRefund ? JSON.stringify(lastRefund, null, 2) : '尚未执行退费。' }}
          </pre>
        </SectionCard>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin-billing-workbench {
  gap: 16px;
}

.admin-billing-workbench__metrics {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

.admin-billing-workbench__grid {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(320px, 0.8fr);
  gap: 16px;
  align-items: start;
}

.admin-billing-workbench__detail-stack,
.admin-billing-workbench__list,
.admin-billing-workbench__detail-list,
.admin-billing-workbench__steps {
  gap: 12px;
}

.admin-billing-workbench__search {
  grid-template-columns: minmax(0, 1.6fr) 180px auto auto;
}

.admin-inline-button.is-secondary {
  border: 1px solid var(--admin-border);
  background: var(--admin-surface);
  color: var(--admin-text);
}

.admin-billing-workbench__list-toolbar,
.admin-billing-workbench__pager,
.admin-billing-workbench__detail-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.admin-billing-workbench__list-toolbar {
  margin-top: 16px;
}

.admin-billing-workbench__list-toolbar p,
.admin-billing-workbench__detail-head p,
.admin-billing-workbench__subline {
  margin: 0;
  color: var(--admin-text-muted);
  line-height: 1.6;
}

.admin-billing-workbench__list-card {
  cursor: pointer;
  transition: border-color 160ms ease, box-shadow 160ms ease, transform 160ms ease;
}

.admin-billing-workbench__list-card:hover {
  border-color: rgba(15, 118, 110, 0.24);
  transform: translateY(-1px);
}

.admin-billing-workbench__list-card.is-active {
  border-color: rgba(15, 118, 110, 0.3);
  background: linear-gradient(180deg, #ffffff 0%, #f3fbf8 100%);
}

.admin-billing-workbench__subline {
  margin-top: 10px;
  word-break: break-all;
}

.admin-billing-workbench__panel-empty {
  min-height: 140px;
  display: grid;
  align-items: center;
}

.admin-billing-workbench__detail {
  display: grid;
  gap: 16px;
}

.admin-billing-workbench__detail-head strong {
  font-size: 20px;
}

.admin-billing-workbench__state-pill {
  display: inline-flex;
  align-items: center;
  min-height: 32px;
  padding: 0 12px;
  border-radius: 999px;
  background: var(--admin-accent-soft);
  color: var(--admin-accent-strong);
  font-weight: 700;
}

.admin-billing-workbench__detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin: 0;
}

.admin-billing-workbench__detail-grid div {
  padding: 12px;
  border-radius: var(--admin-radius-md);
  background: var(--admin-surface-muted);
  border: 1px solid var(--admin-border);
}

.admin-billing-workbench__detail-grid dt {
  color: var(--admin-text-muted);
  font-size: 12px;
}

.admin-billing-workbench__detail-grid dd {
  margin: 6px 0 0;
  color: var(--admin-text);
  font-weight: 700;
  word-break: break-all;
}

.admin-billing-workbench__actions {
  justify-content: flex-end;
}

.admin-billing-workbench__refund-result {
  margin-top: 12px;
  min-height: 100px;
}

@media (max-width: 1200px) {
  .admin-billing-workbench__metrics {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .admin-billing-workbench__search {
    grid-template-columns: minmax(0, 1fr) 160px auto;
  }
}

@media (max-width: 960px) {
  .admin-billing-workbench__grid,
  .admin-billing-workbench__detail-grid,
  .admin-billing-workbench__search {
    grid-template-columns: 1fr;
  }

  .admin-billing-workbench__list-toolbar,
  .admin-billing-workbench__pager,
  .admin-billing-workbench__detail-head {
    flex-direction: column;
    align-items: flex-start;
  }

  .admin-billing-workbench__actions {
    justify-content: stretch;
  }
}

@media (max-width: 760px) {
  .admin-billing-workbench__metrics {
    grid-template-columns: 1fr;
  }
}
</style>
