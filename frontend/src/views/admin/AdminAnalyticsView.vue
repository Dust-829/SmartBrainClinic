<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import { adminApi, type AuditLogRecord, type BillRecord, type DrugListItem, type SchedulingApplicationRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const loading = ref(false)
const audits = ref<AuditLogRecord[]>([])
const bills = ref<BillRecord[]>([])
const lowStockDrugs = ref<DrugListItem[]>([])
const approvals = ref<SchedulingApplicationRecord[]>([])
const auditAvailable = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))

const analyticsCards = computed(() => [
  { label: '待审批排班', value: approvals.value.length },
  { label: 'AI 审计记录', value: auditAvailable.value ? audits.value.length : '未配置' },
  { label: '待复核 AI 建议', value: auditAvailable.value ? audits.value.filter((item) => !item.validated).length : '未配置' },
  { label: '低库存药品', value: lowStockDrugs.value.length },
  { label: '最近账单', value: bills.value.length },
])

async function loadAnalytics() {
  loading.value = true
  try {
    const results = await Promise.allSettled([
      auditAvailable.value ? adminApi.listAiAudits({ limit: 12 }) : Promise.resolve(null),
      adminApi.listBills({ limit: 12 }),
      adminApi.listDrugs({ low_stock_only: true, limit: 12 }),
      adminApi.listPendingApplications(),
    ])

    audits.value =
      results[0].status === 'fulfilled' && results[0].value
        ? results[0].value.data.data ?? []
        : []
    bills.value = results[1].status === 'fulfilled' ? results[1].value.data.data ?? [] : []
    lowStockDrugs.value = results[2].status === 'fulfilled' ? results[2].value.data.data ?? [] : []
    approvals.value = results[3].status === 'fulfilled' ? results[3].value.data.data ?? [] : []
  } catch {
    audits.value = []
    bills.value = []
    lowStockDrugs.value = []
    approvals.value = []
  } finally {
    loading.value = false
  }
}

function moduleSummary(moduleName: string) {
  return audits.value.filter((item) => item.module_name === moduleName).length
}

onMounted(() => {
  loadAnalytics()
})
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>运营分析与答辩展示</span>
        <h2>分析总览</h2>
        <p>按规划文档补一页答辩展示型页面，用现有真实数据做最小运营分析，而不是额外造 BI 系统。</p>
      </div>
      <button type="button" :disabled="loading" @click="loadAnalytics">
        {{ loading ? '刷新中...' : '刷新分析数据' }}
      </button>
    </section>

    <section class="analytics-cards">
      <article v-for="item in analyticsCards" :key="item.label" class="analytics-card">
        <span>{{ item.label }}</span>
        <strong>{{ item.value }}</strong>
      </article>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="AI 模块统计" :subtitle="auditAvailable ? '用来讲 AI 问诊、AI 排班、AI 处方等建议留痕情况。' : '当前未配置审计 token，AI 模块统计仅显示 0。'">
        <div class="analytics-list">
          <article>
            <strong>triage</strong>
            <p>{{ moduleSummary('triage') }} 条</p>
          </article>
          <article>
            <strong>scheduling</strong>
            <p>{{ moduleSummary('scheduling') }} 条</p>
          </article>
          <article>
            <strong>prescription</strong>
            <p>{{ moduleSummary('prescription') }} 条</p>
          </article>
        </div>
      </SectionCard>

      <SectionCard title="低库存药品" subtitle="对应管理员端药房补货与库存预警职责。">
        <div v-if="lowStockDrugs.length" class="analytics-list">
          <article v-for="drug in lowStockDrugs.slice(0, 6)" :key="drug.uuid">
            <strong>{{ drug.drug_name }}</strong>
            <p>库存 {{ drug.stock }} / 预警线 {{ drug.min_stock_limit ?? 10 }}</p>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有低库存药品。</div>
      </SectionCard>
    </div>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="最近账单状态" subtitle="用于答辩展示账务流转和退费处理能力。">
        <div v-if="bills.length" class="analytics-list">
          <article v-for="bill in bills.slice(0, 6)" :key="bill.uuid">
            <strong>{{ bill.bill_code }}</strong>
            <p>{{ bill.bill_state }} · {{ bill.total_amount }}</p>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有账单统计数据。</div>
      </SectionCard>

      <SectionCard title="待办审批" subtitle="用于展示后台流程管控能力。">
        <div v-if="approvals.length" class="analytics-list">
          <article v-for="approval in approvals.slice(0, 6)" :key="approval.uuid">
            <strong>{{ approval.employee_uuid }}</strong>
            <p>{{ approval.prompt }}</p>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有待办审批数据。</div>
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
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  padding: 24px;
  border-radius: 24px;
  border: 1px solid rgba(168, 85, 247, 0.18);
  background: linear-gradient(135deg, #f5f3ff, #ffffff 68%);
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
  color: #7c3aed;
  font-size: 13px;
  font-weight: 700;
}

.admin-page__hero p {
  margin-top: 8px;
  color: #475569;
}

.admin-page__hero button {
  min-height: 42px;
  padding: 0 16px;
  border: 0;
  border-radius: 12px;
  background: linear-gradient(135deg, #7c3aed, #2563eb);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.analytics-cards,
.admin-page__grid,
.analytics-list {
  display: grid;
  gap: 14px;
}

.analytics-cards {
  grid-template-columns: repeat(5, minmax(0, 1fr));
}

.analytics-card {
  display: grid;
  gap: 8px;
  padding: 18px;
  border-radius: 18px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  background: #ffffff;
}

.analytics-card span {
  color: #64748b;
  font-size: 13px;
  font-weight: 700;
}

.analytics-card strong {
  color: #0f172a;
  font-size: 28px;
}

.admin-page__grid.is-two-column {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.analytics-list article {
  display: grid;
  gap: 6px;
  padding: 14px 16px;
  border-radius: 14px;
  border: 1px solid #e9d5ff;
  background: #faf5ff;
}

.analytics-list strong,
.analytics-list p {
  margin: 0;
}

.analytics-list p {
  color: #475569;
  line-height: 1.6;
}

.admin-empty {
  padding: 18px;
  border-radius: 14px;
  background: #f8fafc;
  color: #64748b;
}

@media (max-width: 1100px) {
  .analytics-cards,
  .admin-page__grid.is-two-column {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 760px) {
  .admin-page__hero {
    flex-direction: column;
    align-items: flex-start;
  }

  .analytics-cards,
  .admin-page__grid.is-two-column {
    grid-template-columns: 1fr;
  }
}
</style>
