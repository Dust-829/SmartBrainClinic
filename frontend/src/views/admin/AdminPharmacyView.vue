<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import {
  adminApi,
  type DispenseResult,
  type DrugImportDraft,
  type DrugImportResult,
  type DrugListItem,
  type PrescriptionListItem,
} from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const importing = ref(false)
const dispensing = ref(false)
const returning = ref(false)
const loadingOverview = ref(false)
const recentDrugs = ref<DrugListItem[]>([])
const recentPrescriptions = ref<PrescriptionListItem[]>([])

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

const dispenseForm = reactive({
  prescription_uuid: '',
})

const returnForm = reactive({
  prescription_uuid: '',
})

const importResult = ref<DrugImportResult[]>([])
const dispenseResult = ref<DispenseResult | null>(null)
const returnResult = ref<DispenseResult | null>(null)
const overviewFilters = reactive({
  keyword: '',
  low_stock_only: true,
  prescription_state: '',
})

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

async function submitImport() {
  importing.value = true
  try {
    const response = await adminApi.batchImportDrugs(importRows.value)
    importResult.value = response.data.data ?? []
    ElMessage.success('药品入库完成')
    await loadOverview()
  } finally {
    importing.value = false
  }
}

async function submitDispense() {
  dispensing.value = true
  try {
    const response = await adminApi.dispensePrescription(dispenseForm.prescription_uuid)
    dispenseResult.value = response.data.data ?? null
    ElMessage.success('发药操作完成')
    await loadOverview()
  } finally {
    dispensing.value = false
  }
}

async function submitReturn() {
  returning.value = true
  try {
    const response = await adminApi.returnPrescription(returnForm.prescription_uuid)
    returnResult.value = response.data.data ?? null
    ElMessage.success('退药操作完成')
    await loadOverview()
  } finally {
    returning.value = false
  }
}

async function loadOverview() {
  loadingOverview.value = true
  try {
    const [drugsResponse, prescriptionsResponse] = await Promise.all([
      adminApi.listDrugs({
        keyword: overviewFilters.keyword.trim() || undefined,
        low_stock_only: overviewFilters.low_stock_only,
        limit: 8,
      }),
      adminApi.listPrescriptions({
        state: overviewFilters.prescription_state.trim() || undefined,
        limit: 8,
      }),
    ])

    recentDrugs.value = drugsResponse.data.data ?? []
    recentPrescriptions.value = prescriptionsResponse.data.data ?? []
  } catch {
    recentDrugs.value = []
    recentPrescriptions.value = []
  } finally {
    loadingOverview.value = false
  }
}

onMounted(() => {
  loadOverview()
})
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>执行型后台工作台</span>
        <h2>药房工作台</h2>
        <p>优先保证药品入库、发药、退药三条真实操作链路可跑通。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="库存与处方概览" subtitle="第二轮开始接入后台列表接口，不再只靠手工输入 UUID。">
        <form class="admin-form" @submit.prevent="loadOverview">
          <label>
            <span>药品关键字</span>
            <input v-model="overviewFilters.keyword" type="text" placeholder="药品名或编码" />
          </label>
          <label>
            <span>处方状态</span>
            <select v-model="overviewFilters.prescription_state">
              <option value="">全部</option>
              <option value="开立">开立</option>
              <option value="已缴费">已缴费</option>
              <option value="已发药">已发药</option>
              <option value="已退药">已退药</option>
            </select>
          </label>
          <label class="admin-form__checkbox">
            <input v-model="overviewFilters.low_stock_only" type="checkbox" />
            <span>仅看低库存药品</span>
          </label>
          <button type="submit" :disabled="loadingOverview">
            {{ loadingOverview ? '刷新中...' : '刷新概览' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="批量药品入库" subtitle="一期先做操作工作台，不伪造全量库存看板。">
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
              {{ importing ? '入库中...' : '提交入库' }}
            </button>
          </div>
        </form>
      </SectionCard>

      <SectionCard title="发药与退药" subtitle="通过处方 UUID 驱动真实后端执行。">
        <div class="admin-page__stack">
          <form class="admin-form" @submit.prevent="submitDispense">
            <label>
              <span>发药处方 UUID</span>
              <input v-model="dispenseForm.prescription_uuid" type="text" placeholder="请输入 prescription_uuid" />
            </label>
            <button type="submit" :disabled="dispensing">
              {{ dispensing ? '发药中...' : '执行发药' }}
            </button>
          </form>

          <form class="admin-form" @submit.prevent="submitReturn">
            <label>
              <span>退药处方 UUID</span>
              <input v-model="returnForm.prescription_uuid" type="text" placeholder="请输入 prescription_uuid" />
            </label>
            <button type="submit" :disabled="returning">
              {{ returning ? '退药中...' : '执行退药' }}
            </button>
          </form>
        </div>
      </SectionCard>
    </div>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="低库存药品" subtitle="用于管理员快速发现需要补货的药品。">
        <div v-if="recentDrugs.length" class="result-list">
          <article v-for="item in recentDrugs" :key="item.uuid" class="result-card">
            <strong>{{ item.drug_name }}</strong>
            <p>{{ item.drug_code }} · {{ item.specification }}</p>
            <span>库存 {{ item.stock }} / 预警线 {{ item.min_stock_limit ?? 10 }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有命中的药品记录。</div>
      </SectionCard>

      <SectionCard title="最近处方" subtitle="用于直接复制处方 UUID 进行发药或退药操作。">
        <div v-if="recentPrescriptions.length" class="result-list">
          <article v-for="item in recentPrescriptions" :key="item.uuid" class="result-card">
            <strong>{{ item.prescription_code }}</strong>
            <p>{{ item.drug_state }} · {{ item.is_ai_recommended ? 'AI 建议' : '人工开立' }}</p>
            <span>{{ item.uuid }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有命中的处方记录。</div>
      </SectionCard>
    </div>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="入库结果" subtitle="展示后端返回的真实入库确认。">
        <div v-if="importResult.length" class="result-list">
          <article v-for="item in importResult" :key="item.uuid" class="result-card">
            <strong>{{ item.drug_name }}</strong>
            <p>{{ item.drug_code }}</p>
            <span>{{ item.uuid }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">尚未提交药品入库。</div>
      </SectionCard>

      <SectionCard title="发药 / 退药结果" subtitle="用于演示库存扣减、库存恢复等后台动作反馈。">
        <div class="admin-page__stack">
          <pre class="admin-result">{{ dispenseResult ? JSON.stringify(dispenseResult, null, 2) : '尚未执行发药。' }}</pre>
          <pre class="admin-result">{{ returnResult ? JSON.stringify(returnResult, null, 2) : '尚未执行退药。' }}</pre>
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.admin-page {
  display: grid;
  gap: 20px;
}

.admin-page__hero {
  padding: 24px;
  border-radius: 24px;
  border: 1px solid rgba(14, 165, 233, 0.18);
  background: linear-gradient(135deg, #eff6ff, #ffffff 68%);
}

.admin-page__hero h2,
.admin-page__hero p {
  margin: 0;
}

.admin-page__hero h2 {
  margin-top: 6px;
  font-size: 28px;
}

.admin-page__hero span {
  color: #0369a1;
  font-size: 13px;
  font-weight: 700;
}

.admin-page__hero p {
  margin-top: 8px;
  color: #475569;
}

.admin-page__grid {
  display: grid;
  gap: 16px;
}

.admin-page__grid.is-two-column {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.admin-page__stack {
  display: grid;
  gap: 14px;
}

.drug-import-form,
.admin-form {
  display: grid;
  gap: 12px;
}

.drug-import-form__row {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
  padding: 14px;
  border-radius: 14px;
  background: #f8fafc;
}

.drug-import-form__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.drug-import-form input,
.drug-import-form button,
.admin-form input,
.admin-form button {
  min-height: 42px;
  padding: 0 14px;
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
}

.admin-form label {
  display: grid;
  gap: 8px;
}

.admin-form__checkbox {
  grid-auto-flow: column;
  justify-content: start;
  align-items: center;
  gap: 10px;
}

.admin-form__checkbox input {
  width: 16px;
  min-height: auto;
  padding: 0;
}

.admin-form span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.drug-import-form button,
.admin-form button {
  border: 0;
  background: linear-gradient(135deg, #0891b2, #2563eb);
  color: #ffffff;
  font-weight: 700;
}

.drug-import-form button.is-secondary {
  background: #e2e8f0;
  color: #0f172a;
}

.result-list {
  display: grid;
  gap: 12px;
}

.result-card {
  display: grid;
  gap: 6px;
  padding: 14px;
  border-radius: 14px;
  border: 1px solid #dbeafe;
  background: #f8fbff;
}

.result-card p,
.result-card span {
  margin: 0;
  color: #475569;
}

.result-card span {
  font-size: 12px;
}

.admin-empty,
.admin-result {
  padding: 16px;
  border-radius: 14px;
  background: #f8fafc;
  color: #64748b;
}

.admin-result {
  margin: 0;
  min-height: 120px;
  white-space: pre-wrap;
  word-break: break-word;
}

@media (max-width: 1080px) {
  .admin-page__grid.is-two-column,
  .drug-import-form__row {
    grid-template-columns: 1fr;
  }
}
</style>
