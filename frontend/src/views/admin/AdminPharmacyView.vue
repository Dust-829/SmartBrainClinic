<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import {
  adminApi,
  type DispenseResult,
  type DrugImportDraft,
  type DrugImportResponse,
  type DrugListItem,
  type DrugStockAdjustmentPayload,
  type DrugStockAdjustmentResult,
  type PharmacyWorkbenchDrugPage,
  type PharmacyWorkbenchOverview,
  type PharmacyWorkbenchPrescriptionDetail,
  type PharmacyWorkbenchPrescriptionPage,
} from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

type PrescriptionTab = 'paid' | 'dispensed' | 'all'

const DEFAULT_OVERVIEW: PharmacyWorkbenchOverview = {
  paid_prescription_count: 0,
  dispensed_prescription_count: 0,
  low_stock_drug_count: 0,
  total_drug_count: 0,
  low_stock_drugs: [],
  actionable_prescriptions: [],
}

const DEFAULT_PRESCRIPTION_PAGE: PharmacyWorkbenchPrescriptionPage = {
  items: [],
  pagination: { total: 0, limit: 8, offset: 0 },
}

const DEFAULT_DRUG_PAGE: PharmacyWorkbenchDrugPage = {
  items: [],
  pagination: { total: 0, limit: 8, offset: 0 },
}

const loadingOverview = ref(false)
const loadingPrescriptions = ref(false)
const loadingDetail = ref(false)
const loadingDrugs = ref(false)
const importing = ref(false)
const adjusting = ref(false)
const actionLoading = ref(false)

const overview = ref<PharmacyWorkbenchOverview>({ ...DEFAULT_OVERVIEW })
const prescriptionPage = ref<PharmacyWorkbenchPrescriptionPage>({ ...DEFAULT_PRESCRIPTION_PAGE })
const selectedPrescriptionUuid = ref('')
const selectedPrescriptionDetail = ref<PharmacyWorkbenchPrescriptionDetail | null>(null)
const selectedDrug = ref<DrugListItem | null>(null)
const drugPage = ref<PharmacyWorkbenchDrugPage>({ ...DEFAULT_DRUG_PAGE })

const importRows = ref<DrugImportDraft[]>([
  {
    drug_code: 'DRUG-001',
    drug_name: '甘露醇注射液',
    specification: '250ml/瓶',
    unit: '瓶',
    price: 38,
    stock: 60,
    min_stock_limit: 10,
  },
])

const importFeedback = ref<DrugImportResponse | null>(null)
const stockAdjustmentResult = ref<DrugStockAdjustmentResult | null>(null)
const prescriptionOperationResult = ref<DispenseResult | null>(null)

const prescriptionTab = ref<PrescriptionTab>('paid')
const prescriptionFilters = reactive({
  prescription_code: '',
  limit: 8,
  offset: 0,
})
const drugFilters = reactive({
  keyword: '',
  low_stock_only: false,
  limit: 8,
  offset: 0,
})
const adjustmentForm = reactive<DrugStockAdjustmentPayload & { drug_uuid: string }>({
  drug_uuid: '',
  mode: 'increase',
  quantity: 1,
})

const heroMetrics = computed(() => [
  { label: '待发药', value: overview.value.paid_prescription_count },
  { label: '可退药', value: overview.value.dispensed_prescription_count },
  { label: '低库存', value: overview.value.low_stock_drug_count },
  { label: '药品总数', value: overview.value.total_drug_count },
])

const tabOptions = computed(() => [
  { key: 'paid' as const, label: '待发药', count: overview.value.paid_prescription_count },
  { key: 'dispensed' as const, label: '可退药', count: overview.value.dispensed_prescription_count },
  {
    key: 'all' as const,
    label: '全部处方',
    count: overview.value.paid_prescription_count + overview.value.dispensed_prescription_count,
  },
])

const selectedDrugDisplay = computed(() => {
  if (selectedDrug.value) return selectedDrug.value
  if (!adjustmentForm.drug_uuid) return null
  return (
    drugPage.value.items.find((item) => item.uuid === adjustmentForm.drug_uuid) ||
    overview.value.low_stock_drugs.find((item) => item.uuid === adjustmentForm.drug_uuid) ||
    null
  )
})

const canGoPrevPrescriptions = computed(() => prescriptionPage.value.pagination.offset > 0)
const canGoNextPrescriptions = computed(() => {
  const { offset, limit, total } = prescriptionPage.value.pagination
  return offset + limit < total
})
const canGoPrevDrugs = computed(() => drugPage.value.pagination.offset > 0)
const canGoNextDrugs = computed(() => {
  const { offset, limit, total } = drugPage.value.pagination
  return offset + limit < total
})

function formatDateTime(value?: string | null) {
  if (!value) return '暂无'
  return value.replace('T', ' ').slice(0, 16)
}

function resolvePrescriptionState() {
  if (prescriptionTab.value === 'all') return undefined
  return prescriptionTab.value
}

function createIdempotencyKey(prefix: string) {
  const randomPart =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(16).slice(2)}`
  return `${prefix}-${randomPart}`
}

function addDrugRow() {
  importRows.value.push({
    drug_code: '',
    drug_name: '',
    specification: '',
    unit: '',
    price: 0,
    stock: 0,
    min_stock_limit: 10,
  })
}

function removeDrugRow(index: number) {
  if (importRows.value.length === 1) return
  importRows.value.splice(index, 1)
}

function selectDrug(item: DrugListItem) {
  selectedDrug.value = item
  adjustmentForm.drug_uuid = item.uuid
}

async function loadOverview() {
  loadingOverview.value = true
  try {
    const response = await adminApi.getPharmacyWorkbenchOverview()
    overview.value = response.data.data ?? { ...DEFAULT_OVERVIEW }
  } finally {
    loadingOverview.value = false
  }
}

async function loadPrescriptionDetail() {
  if (!selectedPrescriptionUuid.value) {
    selectedPrescriptionDetail.value = null
    return
  }

  loadingDetail.value = true
  try {
    const response = await adminApi.getPharmacyWorkbenchPrescriptionDetail(selectedPrescriptionUuid.value)
    selectedPrescriptionDetail.value = response.data.data ?? null
  } finally {
    loadingDetail.value = false
  }
}

async function loadPrescriptions() {
  loadingPrescriptions.value = true
  try {
    const response = await adminApi.listPharmacyWorkbenchPrescriptions({
      state: resolvePrescriptionState(),
      limit: prescriptionFilters.limit,
      offset: prescriptionFilters.offset,
      prescription_code: prescriptionFilters.prescription_code.trim() || undefined,
    })
    const nextPage = response.data.data ?? { ...DEFAULT_PRESCRIPTION_PAGE }
    prescriptionPage.value = nextPage

    const stillVisible = nextPage.items.some((item) => item.uuid === selectedPrescriptionUuid.value)
    if (!stillVisible) {
      selectedPrescriptionUuid.value = nextPage.items[0]?.uuid ?? ''
    }

    await loadPrescriptionDetail()
  } catch {
    prescriptionPage.value = { ...DEFAULT_PRESCRIPTION_PAGE }
    selectedPrescriptionUuid.value = ''
    selectedPrescriptionDetail.value = null
  } finally {
    loadingPrescriptions.value = false
  }
}

async function loadDrugs() {
  loadingDrugs.value = true
  try {
    const response = await adminApi.listPharmacyWorkbenchDrugs({
      keyword: drugFilters.keyword.trim() || undefined,
      low_stock_only: drugFilters.low_stock_only,
      limit: drugFilters.limit,
      offset: drugFilters.offset,
    })
    const nextPage = response.data.data ?? { ...DEFAULT_DRUG_PAGE }
    drugPage.value = nextPage

    if (selectedDrug.value) {
      const matched = nextPage.items.find((item) => item.uuid === selectedDrug.value?.uuid)
      if (matched) {
        selectedDrug.value = matched
      }
    }

    if (!selectedDrug.value && nextPage.items.length) {
      selectDrug(nextPage.items[0])
    }
  } catch {
    drugPage.value = { ...DEFAULT_DRUG_PAGE }
    selectedDrug.value = null
  } finally {
    loadingDrugs.value = false
  }
}

async function refreshWorkbench() {
  await Promise.all([loadOverview(), loadPrescriptions(), loadDrugs()])
}

async function submitImport() {
  importing.value = true
  try {
    const response = await adminApi.batchImportDrugs(importRows.value)
    importFeedback.value = response.data.data ?? null
    ElMessage.success('入库请求已提交')
    await Promise.all([loadOverview(), loadDrugs()])
  } finally {
    importing.value = false
  }
}

async function submitStockAdjustment() {
  if (!adjustmentForm.drug_uuid) {
    ElMessage.warning('请先选择药品')
    return
  }

  adjusting.value = true
  try {
    const response = await adminApi.adjustDrugStock(adjustmentForm.drug_uuid, {
      mode: adjustmentForm.mode,
      quantity: adjustmentForm.quantity,
    })
    stockAdjustmentResult.value = response.data.data ?? null
    ElMessage.success('库存调整完成')
    await Promise.all([loadOverview(), loadDrugs()])
  } finally {
    adjusting.value = false
  }
}

async function runPrimaryAction() {
  const detail = selectedPrescriptionDetail.value
  const action = detail?.actions.primary_action
  if (!detail || !action || actionLoading.value) return

  actionLoading.value = true
  try {
    const idempotencyKey = createIdempotencyKey(`pharmacy-${action}`)
    const response =
      action === 'dispense'
        ? await adminApi.dispensePrescription(detail.header.uuid, { idempotencyKey })
        : await adminApi.returnPrescription(detail.header.uuid, { idempotencyKey })
    prescriptionOperationResult.value = response.data.data ?? null
    ElMessage.success(action === 'dispense' ? '发药完成' : '退药完成')
    await refreshWorkbench()
  } finally {
    actionLoading.value = false
  }
}

function pickPrescription(uuid: string) {
  if (selectedPrescriptionUuid.value === uuid) return
  selectedPrescriptionUuid.value = uuid
  void loadPrescriptionDetail()
}

function setPrescriptionTab(nextTab: PrescriptionTab) {
  if (prescriptionTab.value === nextTab) return
  prescriptionTab.value = nextTab
  prescriptionFilters.offset = 0
  void loadPrescriptions()
}

function submitPrescriptionFilters() {
  prescriptionFilters.offset = 0
  void loadPrescriptions()
}

function submitDrugFilters() {
  drugFilters.offset = 0
  void loadDrugs()
}

function goPrescriptionPage(direction: 'prev' | 'next') {
  const step = prescriptionPage.value.pagination.limit
  prescriptionFilters.offset = Math.max(
    0,
    prescriptionFilters.offset + (direction === 'next' ? step : -step),
  )
  void loadPrescriptions()
}

function goDrugPage(direction: 'prev' | 'next') {
  const step = drugPage.value.pagination.limit
  drugFilters.offset = Math.max(0, drugFilters.offset + (direction === 'next' ? step : -step))
  void loadDrugs()
}

onMounted(() => {
  void refreshWorkbench()
})
</script>

<template>
  <div class="admin-page admin-pharmacy">
    <section class="admin-pharmacy__hero">
      <div class="admin-pharmacy__hero-copy">
        <span>Admin Pharmacy Workbench</span>
        <h2>药房工作台</h2>
        <p>把待发药、可退药、低库存和库存写操作收在一个真实可用的管理员驾驶舱里。</p>
      </div>
      <div class="admin-pharmacy__hero-actions">
        <button type="button" :disabled="loadingOverview || loadingPrescriptions || loadingDrugs" @click="refreshWorkbench">
          {{ loadingOverview || loadingPrescriptions || loadingDrugs ? '刷新中...' : '刷新工作台' }}
        </button>
      </div>
      <div class="admin-pharmacy__hero-metrics">
        <article v-for="metric in heroMetrics" :key="metric.label" class="admin-pharmacy__metric-card">
          <span>{{ metric.label }}</span>
          <strong>{{ metric.value }}</strong>
        </article>
      </div>
    </section>

    <div class="admin-pharmacy__main-grid">
      <SectionCard title="处方队列" subtitle="待发药、可退药和全部处方统一从真实列表进入，不再手输 UUID。">
        <div class="admin-pharmacy__toolbar">
          <div class="admin-pharmacy__tabs">
            <button
              v-for="tab in tabOptions"
              :key="tab.key"
              type="button"
              class="admin-pharmacy__tab"
              :class="{ 'is-active': prescriptionTab === tab.key }"
              @click="setPrescriptionTab(tab.key)"
            >
              <span>{{ tab.label }}</span>
              <strong>{{ tab.count }}</strong>
            </button>
          </div>

          <form class="admin-form admin-pharmacy__toolbar-form" @submit.prevent="submitPrescriptionFilters">
            <label>
              <span>处方号</span>
              <input v-model="prescriptionFilters.prescription_code" type="text" placeholder="按处方号筛选" />
            </label>
            <button type="submit" :disabled="loadingPrescriptions">
              {{ loadingPrescriptions ? '筛选中...' : '筛选列表' }}
            </button>
          </form>
        </div>

        <div v-if="prescriptionPage.items.length" class="admin-pharmacy__prescription-list">
          <article
            v-for="item in prescriptionPage.items"
            :key="item.uuid"
            class="admin-pharmacy__prescription-card"
            :class="{ 'is-active': selectedPrescriptionUuid === item.uuid }"
            @click="pickPrescription(item.uuid)"
          >
            <div class="admin-pharmacy__card-head">
              <div>
                <strong>{{ item.prescription_code }}</strong>
                <p>{{ item.patient_name || '未补齐患者姓名' }} | {{ item.patient_case_number || '无病案号' }}</p>
              </div>
              <span>{{ item.drug_state }}</span>
            </div>
            <div class="admin-pharmacy__card-meta">
              <span>{{ item.dept_name || '未补齐科室' }}</span>
              <span>{{ item.employee_name || '未补齐医生' }}</span>
              <span>{{ item.actual_time_range || '时段待确认' }}</span>
              <span>{{ item.items_count }} 项</span>
            </div>
          </article>
        </div>
        <div v-else class="admin-empty">当前筛选下没有命中的处方。</div>

        <div class="admin-pharmacy__pager">
          <button type="button" class="is-secondary" :disabled="!canGoPrevPrescriptions" @click="goPrescriptionPage('prev')">
            上一页
          </button>
          <span>
            {{ prescriptionPage.pagination.offset + 1 }} -
            {{ Math.min(prescriptionPage.pagination.offset + prescriptionPage.pagination.limit, prescriptionPage.pagination.total) }}
            / {{ prescriptionPage.pagination.total }}
          </span>
          <button type="button" class="is-secondary" :disabled="!canGoNextPrescriptions" @click="goPrescriptionPage('next')">
            下一页
          </button>
        </div>
      </SectionCard>

      <SectionCard title="处方详情" subtitle="右侧固定展示选中处方的患者、挂号、药品明细与唯一主操作。">
        <div v-if="selectedPrescriptionDetail" class="admin-pharmacy__detail">
          <div class="admin-pharmacy__detail-header">
            <div>
              <strong>{{ selectedPrescriptionDetail.header.prescription_code }}</strong>
              <p>
                {{ selectedPrescriptionDetail.register_context.patient_name || '未补齐患者' }}
                |
                {{ selectedPrescriptionDetail.register_context.patient_case_number || '无病案号' }}
              </p>
            </div>
            <span>{{ selectedPrescriptionDetail.header.drug_state }}</span>
          </div>

          <dl class="admin-pharmacy__detail-grid">
            <div>
              <dt>医生</dt>
              <dd>{{ selectedPrescriptionDetail.register_context.employee_name || '暂无' }}</dd>
            </div>
            <div>
              <dt>科室</dt>
              <dd>{{ selectedPrescriptionDetail.register_context.dept_name || '暂无' }}</dd>
            </div>
            <div>
              <dt>时段</dt>
              <dd>{{ selectedPrescriptionDetail.register_context.actual_time_range || '暂无' }}</dd>
            </div>
            <div>
              <dt>诊室</dt>
              <dd>{{ selectedPrescriptionDetail.register_context.clinic_room_name || '暂无' }}</dd>
            </div>
            <div>
              <dt>挂号状态</dt>
              <dd>{{ selectedPrescriptionDetail.register_context.visit_state_text || '暂无' }}</dd>
            </div>
            <div>
              <dt>开立时间</dt>
              <dd>{{ formatDateTime(selectedPrescriptionDetail.header.creation_time) }}</dd>
            </div>
          </dl>

          <div class="admin-pharmacy__items">
            <article v-for="item in selectedPrescriptionDetail.items" :key="item.uuid" class="admin-pharmacy__item-card">
              <strong>{{ item.drug_name || '未知药品' }}</strong>
              <p>{{ item.drug_code || '无编码' }} | {{ item.specification || '无规格' }}</p>
              <span>{{ item.drug_usage }} | {{ item.drug_number }} {{ item.unit || '份' }}</span>
              <span>库存 {{ item.stock ?? '-' }} / 预警 {{ item.min_stock_limit ?? '-' }}</span>
            </article>
          </div>

          <div class="admin-pharmacy__detail-actions">
            <button
              v-if="selectedPrescriptionDetail.actions.primary_action"
              type="button"
              :disabled="actionLoading"
              @click="runPrimaryAction"
            >
              {{
                actionLoading
                  ? '执行中...'
                  : selectedPrescriptionDetail.actions.primary_action === 'dispense'
                    ? '执行发药'
                    : '执行退药'
              }}
            </button>
            <div v-else class="admin-empty">当前处方状态没有可执行的主操作。</div>
          </div>
        </div>
        <div v-else class="admin-empty">
          {{ loadingDetail ? '正在加载处方详情...' : '请从左侧选择一张处方。' }}
        </div>

        <div class="admin-pharmacy__result-panel">
          <strong>最近处方操作</strong>
          <pre class="admin-result">{{
            prescriptionOperationResult ? JSON.stringify(prescriptionOperationResult, null, 2) : '尚未执行发药或退药。'
          }}</pre>
        </div>
      </SectionCard>
    </div>

    <div class="admin-pharmacy__secondary-grid">
      <SectionCard title="低库存重点" subtitle="首页优先暴露需要补货的药品，并可一键带入库存操作区。">
        <div v-if="overview.low_stock_drugs.length" class="admin-pharmacy__drug-highlight-list">
          <article
            v-for="item in overview.low_stock_drugs"
            :key="item.uuid"
            class="admin-pharmacy__highlight-card"
            @click="selectDrug(item)"
          >
            <strong>{{ item.drug_name }}</strong>
            <p>{{ item.drug_code }} | {{ item.specification }}</p>
            <span>库存 {{ item.stock }} / 预警 {{ item.min_stock_limit ?? '-' }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有低库存药品。</div>
      </SectionCard>

      <SectionCard title="库存总览" subtitle="筛选库存列表并选择目标药品，进入补货或库存校正。">
        <form class="admin-form admin-pharmacy__toolbar-form" @submit.prevent="submitDrugFilters">
          <label>
            <span>药品关键字</span>
            <input v-model="drugFilters.keyword" type="text" placeholder="按药品名称或编码筛选" />
          </label>
          <label class="admin-form__checkbox">
            <input v-model="drugFilters.low_stock_only" type="checkbox" />
            <span>仅看低库存</span>
          </label>
          <button type="submit" :disabled="loadingDrugs">
            {{ loadingDrugs ? '筛选中...' : '筛选库存' }}
          </button>
        </form>

        <div v-if="drugPage.items.length" class="admin-pharmacy__drug-list">
          <article
            v-for="item in drugPage.items"
            :key="item.uuid"
            class="admin-pharmacy__drug-card"
            :class="{ 'is-active': selectedDrugDisplay?.uuid === item.uuid }"
            @click="selectDrug(item)"
          >
            <div>
              <strong>{{ item.drug_name }}</strong>
              <p>{{ item.drug_code }} | {{ item.specification }}</p>
            </div>
            <span>库存 {{ item.stock }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前筛选下没有药品记录。</div>

        <div class="admin-pharmacy__pager">
          <button type="button" class="is-secondary" :disabled="!canGoPrevDrugs" @click="goDrugPage('prev')">
            上一页
          </button>
          <span>
            {{ drugPage.pagination.offset + 1 }} -
            {{ Math.min(drugPage.pagination.offset + drugPage.pagination.limit, drugPage.pagination.total) }}
            / {{ drugPage.pagination.total }}
          </span>
          <button type="button" class="is-secondary" :disabled="!canGoNextDrugs" @click="goDrugPage('next')">
            下一页
          </button>
        </div>
      </SectionCard>
    </div>

    <div class="admin-pharmacy__secondary-grid">
      <SectionCard title="新药批量入库" subtitle="保留批量新增能力，并逐行返回成功与失败结果。">
        <form class="drug-import-form" @submit.prevent="submitImport">
          <div v-for="(item, index) in importRows" :key="`${item.drug_code}-${index}`" class="drug-import-form__row">
            <input v-model="item.drug_code" type="text" placeholder="药品编码" />
            <input v-model="item.drug_name" type="text" placeholder="药品名称" />
            <input v-model="item.specification" type="text" placeholder="规格" />
            <input v-model="item.unit" type="text" placeholder="单位" />
            <input v-model.number="item.price" type="number" min="0" step="0.01" placeholder="单价" />
            <input v-model.number="item.stock" type="number" min="0" placeholder="库存" />
            <input v-model.number="item.min_stock_limit" type="number" min="0" placeholder="预警线" />
            <button type="button" class="is-secondary" @click="removeDrugRow(index)">删除</button>
          </div>

          <div class="drug-import-form__actions">
            <button type="button" class="is-secondary" @click="addDrugRow">新增一行</button>
            <button type="submit" :disabled="importing">
              {{ importing ? '提交中...' : '提交入库' }}
            </button>
          </div>
        </form>

        <div class="admin-pharmacy__import-feedback">
          <article class="admin-pharmacy__feedback-card">
            <strong>成功项</strong>
            <div v-if="importFeedback?.successes.length" class="result-list">
              <div v-for="item in importFeedback.successes" :key="item.uuid" class="result-card">
                <strong>{{ item.drug_name }}</strong>
                <p>{{ item.drug_code }}</p>
                <span>{{ item.uuid }}</span>
              </div>
            </div>
            <div v-else class="admin-empty">尚无成功入库记录。</div>
          </article>

          <article class="admin-pharmacy__feedback-card">
            <strong>失败项</strong>
            <div v-if="importFeedback?.failures.length" class="result-list">
              <div v-for="item in importFeedback.failures" :key="item.drug_code" class="result-card">
                <strong>{{ item.drug_code }}</strong>
                <p>{{ item.reason }}</p>
              </div>
            </div>
            <div v-else class="admin-empty">尚无失败项。</div>
          </article>
        </div>
      </SectionCard>

      <SectionCard title="库存补货 / 校正" subtitle="对已有药品做增加库存或直接校正，不开放任意减库存。">
        <div class="admin-pharmacy__stock-panel">
          <div class="admin-pharmacy__selected-drug">
            <strong>{{ selectedDrugDisplay?.drug_name || '未选择药品' }}</strong>
            <p>
              {{
                selectedDrugDisplay
                  ? `${selectedDrugDisplay.drug_code} | 库存 ${selectedDrugDisplay.stock} | 预警 ${selectedDrugDisplay.min_stock_limit ?? '-'}`
                  : '请先从左侧库存列表或低库存卡片中选择药品。'
              }}
            </p>
          </div>

          <form class="admin-form" @submit.prevent="submitStockAdjustment">
            <label>
              <span>调整模式</span>
              <select v-model="adjustmentForm.mode">
                <option value="increase">补货增加</option>
                <option value="set">直接校正</option>
              </select>
            </label>
            <label>
              <span>数量</span>
              <input v-model.number="adjustmentForm.quantity" type="number" min="1" placeholder="请输入正整数" />
            </label>
            <button type="submit" :disabled="adjusting || !adjustmentForm.drug_uuid">
              {{ adjusting ? '提交中...' : '执行库存调整' }}
            </button>
          </form>

          <pre class="admin-result">{{
            stockAdjustmentResult ? JSON.stringify(stockAdjustmentResult, null, 2) : '尚未执行库存调整。'
          }}</pre>
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.admin-pharmacy {
  gap: 14px;
}

.admin-pharmacy__hero {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) auto;
  gap: 14px;
  padding: 20px;
  border-radius: 22px;
  background:
    radial-gradient(circle at top right, rgba(255, 255, 255, 0.18), transparent 34%),
    linear-gradient(135deg, #0f766e 0%, #115e59 52%, #164e63 100%);
  color: #ffffff;
  box-shadow: 0 20px 42px rgba(15, 23, 42, 0.14);
}

.admin-pharmacy__hero-copy,
.admin-pharmacy__hero-actions {
  display: grid;
  gap: 8px;
  align-content: start;
}

.admin-pharmacy__hero-copy h2,
.admin-pharmacy__hero-copy p,
.admin-pharmacy__hero-copy span,
.admin-pharmacy__metric-card span,
.admin-pharmacy__metric-card strong {
  margin: 0;
}

.admin-pharmacy__hero-copy h2 {
  font-size: 30px;
  line-height: 1.05;
}

.admin-pharmacy__hero-copy p {
  max-width: 54ch;
  color: rgba(255, 255, 255, 0.86);
  line-height: 1.6;
}

.admin-pharmacy__hero-copy span {
  color: rgba(255, 255, 255, 0.78);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.admin-pharmacy__hero-actions button {
  min-height: 40px;
  padding: 0 16px;
  border: 0;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.14);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.admin-pharmacy__hero-metrics {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}

.admin-pharmacy__metric-card {
  display: grid;
  gap: 4px;
  min-height: 84px;
  padding: 14px;
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(255, 255, 255, 0.12);
}

.admin-pharmacy__metric-card span {
  color: rgba(255, 255, 255, 0.76);
  font-size: 12px;
  font-weight: 700;
}

.admin-pharmacy__metric-card strong {
  font-size: 26px;
  line-height: 1;
}

.admin-pharmacy__main-grid,
.admin-pharmacy__secondary-grid,
.admin-pharmacy__toolbar,
.admin-pharmacy__tabs,
.admin-pharmacy__prescription-list,
.admin-pharmacy__detail,
.admin-pharmacy__detail-grid,
.admin-pharmacy__items,
.admin-pharmacy__drug-highlight-list,
.admin-pharmacy__drug-list,
.admin-pharmacy__stock-panel,
.admin-pharmacy__import-feedback {
  display: grid;
  gap: 12px;
}

.admin-pharmacy__main-grid,
.admin-pharmacy__secondary-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.admin-pharmacy__tabs {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.admin-pharmacy__tab {
  display: grid;
  gap: 4px;
  min-height: 72px;
  padding: 12px 14px;
  border-radius: 16px;
  border: 1px solid var(--admin-border);
  background: #f8fafc;
  color: var(--admin-text);
  text-align: left;
  font: inherit;
}

.admin-pharmacy__tab span,
.admin-pharmacy__tab strong,
.admin-pharmacy__card-head strong,
.admin-pharmacy__card-head p,
.admin-pharmacy__card-head span,
.admin-pharmacy__card-meta span,
.admin-pharmacy__detail-header strong,
.admin-pharmacy__detail-header p,
.admin-pharmacy__detail-header span,
.admin-pharmacy__item-card strong,
.admin-pharmacy__item-card p,
.admin-pharmacy__item-card span,
.admin-pharmacy__highlight-card strong,
.admin-pharmacy__highlight-card p,
.admin-pharmacy__highlight-card span,
.admin-pharmacy__drug-card strong,
.admin-pharmacy__drug-card p,
.admin-pharmacy__drug-card span,
.admin-pharmacy__selected-drug strong,
.admin-pharmacy__selected-drug p,
.admin-pharmacy__feedback-card strong {
  margin: 0;
}

.admin-pharmacy__tab span,
.admin-pharmacy__card-meta span,
.admin-pharmacy__card-head p,
.admin-pharmacy__detail-header p,
.admin-pharmacy__item-card p,
.admin-pharmacy__item-card span,
.admin-pharmacy__highlight-card p,
.admin-pharmacy__highlight-card span,
.admin-pharmacy__drug-card p,
.admin-pharmacy__selected-drug p {
  color: var(--admin-text-muted);
  line-height: 1.55;
}

.admin-pharmacy__tab strong {
  font-size: 22px;
}

.admin-pharmacy__tab.is-active {
  border-color: rgba(15, 118, 110, 0.22);
  background: var(--admin-accent-soft);
  color: var(--admin-accent-strong);
}

.admin-pharmacy__toolbar-form {
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: end;
}

.admin-pharmacy__prescription-card,
.admin-pharmacy__item-card,
.admin-pharmacy__highlight-card,
.admin-pharmacy__drug-card,
.admin-pharmacy__selected-drug,
.admin-pharmacy__feedback-card {
  padding: 14px;
  border-radius: 16px;
  border: 1px solid var(--admin-border);
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.admin-pharmacy__prescription-card,
.admin-pharmacy__highlight-card,
.admin-pharmacy__drug-card {
  cursor: pointer;
}

.admin-pharmacy__prescription-card.is-active,
.admin-pharmacy__drug-card.is-active {
  border-color: rgba(15, 118, 110, 0.28);
  background: linear-gradient(180deg, #ecfdf5 0%, #ffffff 100%);
}

.admin-pharmacy__card-head,
.admin-pharmacy__detail-header,
.admin-pharmacy__drug-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.admin-pharmacy__card-head span,
.admin-pharmacy__detail-header span {
  display: inline-flex;
  align-items: center;
  min-height: 28px;
  padding: 0 12px;
  border-radius: 999px;
  background: var(--admin-info-soft);
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 700;
}

.admin-pharmacy__card-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 12px;
}

.admin-pharmacy__detail-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.admin-pharmacy__detail-grid div {
  padding: 12px;
  border-radius: 14px;
  border: 1px solid var(--admin-border);
  background: #f8fafc;
}

.admin-pharmacy__detail-grid dt {
  color: var(--admin-text-muted);
  font-size: 12px;
  font-weight: 700;
}

.admin-pharmacy__detail-grid dd {
  margin: 6px 0 0;
  color: var(--admin-text);
}

.admin-pharmacy__detail-actions {
  display: grid;
  gap: 10px;
}

.admin-pharmacy__detail-actions button {
  min-height: 42px;
  border: 0;
  border-radius: 14px;
  background: var(--admin-accent);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.admin-pharmacy__pager {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  color: var(--admin-text-muted);
}

.admin-pharmacy__pager button {
  min-height: 38px;
  padding: 0 14px;
  border-radius: 12px;
  border: 1px solid var(--admin-border);
  background: #ffffff;
  color: var(--admin-text);
  font: inherit;
  font-weight: 700;
}

.admin-pharmacy__result-panel {
  display: grid;
  gap: 8px;
}

.admin-pharmacy__feedback-card {
  display: grid;
  gap: 10px;
}

@media (max-width: 1180px) {
  .admin-pharmacy__main-grid,
  .admin-pharmacy__secondary-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 900px) {
  .admin-pharmacy__hero,
  .admin-pharmacy__hero-metrics,
  .admin-pharmacy__tabs,
  .admin-pharmacy__detail-grid,
  .admin-pharmacy__toolbar-form {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 720px) {
  .admin-pharmacy__card-head,
  .admin-pharmacy__detail-header,
  .admin-pharmacy__drug-card,
  .admin-pharmacy__pager {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
