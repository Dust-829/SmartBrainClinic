<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import { adminApi, type BillRecord, type BillRefundResult } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const lookupLoading = ref(false)
const listingLoading = ref(false)
const refundingBillCode = ref('')
const bills = ref<BillRecord[]>([])
const recentBills = ref<BillRecord[]>([])
const lastRefund = ref<BillRefundResult | null>(null)

const queryForm = reactive({
  register_uuid: '',
})
const listFilters = reactive({
  state: '',
})

async function lookupBills() {
  lookupLoading.value = true
  try {
    const response = await adminApi.getBillsByRegister(queryForm.register_uuid)
    bills.value = response.data.data ?? []
  } catch {
    bills.value = []
  } finally {
    lookupLoading.value = false
  }
}

async function refundBill(billCode: string) {
  if (refundingBillCode.value) return
  refundingBillCode.value = billCode
  try {
    const response = await adminApi.refundBill(billCode)
    lastRefund.value = response.data.data ?? null
    ElMessage.success('退费成功')
    await lookupBills()
    await loadRecentBills()
  } finally {
    refundingBillCode.value = ''
  }
}

function canRefund(item: BillRecord) {
  return item.bill_state !== '已退费' && item.bill_state !== 'REFUNDED'
}

async function loadRecentBills() {
  listingLoading.value = true
  try {
    const response = await adminApi.listBills({
      state: listFilters.state.trim() || undefined,
      limit: 10,
    })
    recentBills.value = response.data.data ?? []
  } catch {
    recentBills.value = []
  } finally {
    listingLoading.value = false
  }
}

onMounted(() => {
  loadRecentBills()
})
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>收费与异常处理</span>
        <h2>财务账单中心</h2>
        <p>一期先保证挂号账单查询与退费链路可运行，再逐步扩展运营视图。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="最近账单概览" subtitle="第二轮开始接入账单列表接口。">
        <form class="admin-form" @submit.prevent="loadRecentBills">
          <label>
            <span>账单状态</span>
            <select v-model="listFilters.state">
              <option value="">全部</option>
              <option value="已缴费">已缴费</option>
              <option value="退费中">退费中</option>
              <option value="已退费">已退费</option>
              <option value="退费失败">退费失败</option>
            </select>
          </label>
          <button type="submit" :disabled="listingLoading">
            {{ listingLoading ? '刷新中...' : '刷新最近账单' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="按挂号单查询账单" subtitle="输入 register_uuid 读取该挂号单下所有账单。">
        <form class="admin-form" @submit.prevent="lookupBills">
          <label>
            <span>挂号单 UUID</span>
            <input v-model="queryForm.register_uuid" type="text" placeholder="请输入 register_uuid" />
          </label>
          <button type="submit" :disabled="lookupLoading">
            {{ lookupLoading ? '查询中...' : '查询账单' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="最近退费结果" subtitle="便于答辩时展示账单状态变更。">
        <pre class="admin-result">{{ lastRefund ? JSON.stringify(lastRefund, null, 2) : '尚未执行退费。' }}</pre>
      </SectionCard>
    </div>

    <SectionCard title="最近账单列表" subtitle="可先浏览近期账单，再决定是否按挂号单深查。">
      <div v-if="recentBills.length" class="bill-list">
        <article v-for="item in recentBills" :key="item.uuid" class="bill-card">
          <div class="bill-card__head">
            <div>
              <strong>{{ item.bill_code }}</strong>
              <p>挂号单：{{ item.register_uuid || '未记录' }}</p>
            </div>
            <span>{{ item.bill_state }}</span>
          </div>

          <dl class="bill-card__meta">
            <div>
              <dt>金额</dt>
              <dd>{{ item.total_amount }}</dd>
            </div>
            <div>
              <dt>支付时间</dt>
              <dd>{{ item.pay_time?.replace('T', ' ').slice(0, 16) || '未记录' }}</dd>
            </div>
          </dl>
        </article>
      </div>
      <div v-else class="admin-empty">当前没有命中的最近账单记录。</div>
    </SectionCard>

    <SectionCard title="账单列表" subtitle="真实接口优先；没有结果时不造假账单。">
      <div v-if="bills.length" class="bill-list">
        <article v-for="item in bills" :key="item.uuid" class="bill-card">
          <div class="bill-card__head">
            <div>
              <strong>{{ item.bill_code }}</strong>
              <p>支付方式：{{ item.pay_method || '未记录' }}</p>
            </div>
            <span>{{ item.bill_state }}</span>
          </div>

          <dl class="bill-card__meta">
            <div>
              <dt>金额</dt>
              <dd>{{ item.total_amount }}</dd>
            </div>
            <div>
              <dt>交易号</dt>
              <dd>{{ item.transaction_id || '未记录' }}</dd>
            </div>
          </dl>

          <div class="bill-card__actions">
            <button
              type="button"
              :disabled="!canRefund(item) || refundingBillCode === item.bill_code"
              @click="refundBill(item.bill_code)"
            >
              {{ refundingBillCode === item.bill_code ? '退费中...' : '执行退费' }}
            </button>
          </div>
        </article>
      </div>
      <div v-else class="admin-empty">请输入挂号单 UUID 后查询账单。</div>
    </SectionCard>
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
  border: 1px solid rgba(244, 114, 182, 0.18);
  background: linear-gradient(135deg, #fdf2f8, #ffffff 68%);
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
  color: #be185d;
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

.admin-form {
  display: grid;
  gap: 12px;
}

.admin-form label {
  display: grid;
  gap: 8px;
}

.admin-form span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

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

.admin-form button,
.bill-card__actions button {
  border: 0;
  background: linear-gradient(135deg, #ec4899, #be185d);
  color: #ffffff;
  font-weight: 700;
}

.admin-result,
.admin-empty {
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

.bill-list {
  display: grid;
  gap: 14px;
}

.bill-card {
  display: grid;
  gap: 12px;
  padding: 18px;
  border-radius: 16px;
  border: 1px solid #fbcfe8;
  background: #fffafc;
}

.bill-card__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.bill-card__head strong,
.bill-card__head p {
  margin: 0;
}

.bill-card__head p {
  margin-top: 4px;
  color: #475569;
}

.bill-card__head span {
  color: #be185d;
  font-weight: 700;
}

.bill-card__meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin: 0;
}

.bill-card__meta div {
  display: grid;
  gap: 4px;
  padding: 12px;
  border-radius: 12px;
  background: #ffffff;
}

.bill-card__meta dt {
  color: #64748b;
  font-size: 12px;
}

.bill-card__meta dd {
  margin: 0;
  color: #0f172a;
  font-weight: 700;
}

.bill-card__actions {
  display: flex;
  justify-content: flex-end;
}

@media (max-width: 920px) {
  .admin-page__grid.is-two-column,
  .bill-card__meta {
    grid-template-columns: 1fr;
  }
}
</style>
