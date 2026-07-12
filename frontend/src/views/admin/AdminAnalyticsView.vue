<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import {
  adminApi,
  type AuditLogRecord,
  type BillRecord,
  type DrugListItem,
  type SchedulingApplicationRecord,
} from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const loading = ref(false)
const audits = ref<AuditLogRecord[]>([])
const bills = ref<BillRecord[]>([])
const lowStockDrugs = ref<DrugListItem[]>([])
const approvals = ref<SchedulingApplicationRecord[]>([])
const auditLoadFailed = ref(false)

const analyticsCards = computed(() => [
  { label: '待审批排班', value: approvals.value.length },
  { label: 'AI 审计记录', value: auditLoadFailed.value ? '异常' : audits.value.length },
  {
    label: '待复核 AI 建议',
    value: auditLoadFailed.value ? '异常' : audits.value.filter((item) => (item.review_status || 'pending') === 'pending').length,
  },
  { label: '低库存药品', value: lowStockDrugs.value.length },
  { label: '最近账单', value: bills.value.length },
])

async function loadAnalytics() {
  loading.value = true
  try {
    const results = await Promise.allSettled([
      adminApi.listAiAudits({ limit: 12 }),
      adminApi.listBills({ limit: 12 }),
      adminApi.listDrugs({ low_stock_only: true, limit: 12 }),
      adminApi.listPendingApplications(),
    ])

    audits.value = results[0].status === 'fulfilled' ? results[0].value.data.data?.items ?? [] : []
    auditLoadFailed.value = results[0].status === 'rejected'
    bills.value = results[1].status === 'fulfilled' ? results[1].value.data.data ?? [] : []
    lowStockDrugs.value = results[2].status === 'fulfilled' ? results[2].value.data.data ?? [] : []
    approvals.value = results[3].status === 'fulfilled' ? results[3].value.data.data ?? [] : []
  } catch {
    audits.value = []
    bills.value = []
    lowStockDrugs.value = []
    approvals.value = []
    auditLoadFailed.value = true
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
      <SectionCard
        title="AI 模块统计"
        :subtitle="auditLoadFailed ? 'AI 审计接口加载失败，当前统计可能不完整。' : '用来讲 AI 问诊、AI 排班、AI 处方等建议留痕情况。'"
      >
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
            <p>{{ bill.bill_state }} | {{ bill.total_amount }}</p>
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
