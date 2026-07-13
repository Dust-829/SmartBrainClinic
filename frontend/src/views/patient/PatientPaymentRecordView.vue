<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { patientApi, type PaymentRecord } from '@/api/patient'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const session = usePatientSessionStore()
const loading = ref(false)
const loadError = ref('')
const records = ref<PaymentRecord[]>([])

onMounted(() => {
  if (!session.patient?.uuid) {
    router.replace('/patient/login')
    return
  }
  void loadRecords()
})

function formatAmount(value: string | number) {
  return `¥${Number(value || 0).toFixed(2)}`
}

function formatDate(value?: string | null) {
  if (!value) return '时间待确认'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false,
  }).format(date)
}

function getErrorMessage(error: unknown, fallback: string) {
  const detail = (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data
  return String(detail?.detail || detail?.message || fallback)
}

function stateClass(state: string) {
  return state.includes('退') ? 'is-refunded' : 'is-paid'
}

async function loadRecords() {
  const patientUuid = session.patient?.uuid
  if (!patientUuid || loading.value) return

  loading.value = true
  loadError.value = ''
  try {
    const response = await patientApi.getPaymentRecords(patientUuid)
    records.value = response.data.data?.records ?? []
  } catch (error) {
    loadError.value = getErrorMessage(error, '缴费记录加载失败，请稍后重试。')
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push('/patient/payments')
}
</script>

<template>
  <div class="patient-payment-records">
    <PatientFlowHeader title="缴费记录" subtitle="查看本人已完成支付的医疗账单" back-label="返回缴费中心" @back="goBack" />

    <main class="patient-payment-records__content">
      <section class="patient-payment-records__summary">
        <span class="patient-payment-records__summary-icon" aria-hidden="true"></span>
        <div><strong>缴费记录</strong><p>账单金额与支付状态均以收费系统为准</p></div>
        <button type="button" :disabled="loading" @click="loadRecords">{{ loading ? '刷新中' : '刷新' }}</button>
      </section>

      <section class="patient-payment-records__panel" aria-labelledby="payment-record-list-title">
        <div class="patient-payment-records__heading"><h2 id="payment-record-list-title">全部账单</h2><span v-if="records.length">{{ records.length }} 笔</span></div>

        <div v-if="loading && !records.length" class="patient-payment-records__skeleton" aria-label="正在加载缴费记录"><span v-for="index in 3" :key="index"></span></div>
        <div v-else-if="loadError && !records.length" class="patient-payment-records__empty is-error"><strong>暂时无法读取缴费记录</strong><p>{{ loadError }}</p><button type="button" @click="loadRecords">重新加载</button></div>
        <div v-else-if="!records.length" class="patient-payment-records__empty"><span class="patient-payment-records__empty-icon" aria-hidden="true"></span><strong>暂时没有缴费记录</strong><p>完成检查、检验或处置项目支付后，账单会显示在这里。</p><button type="button" @click="goBack">返回缴费中心</button></div>
        <div v-else class="patient-payment-records__list">
          <article v-for="record in records" :key="record.uuid || record.bill_code">
            <div class="patient-payment-records__card-head"><div><strong>{{ record.bill_code || '医疗账单' }}</strong><p>{{ formatDate(record.pay_time || record.visit_date) }}</p></div><span :class="stateClass(record.bill_state)">{{ record.bill_state }}</span></div>
            <div class="patient-payment-records__card-foot"><span>{{ record.pay_method || '支付方式待确认' }}</span><b>{{ formatAmount(record.total_amount) }}</b></div>
          </article>
        </div>
      </section>
    </main>
    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-payment-records { min-height: 100vh; padding-bottom: calc(var(--patient-nav-height) + 24px); background: var(--patient-flow-page-bg); color: var(--patient-text); }
.patient-payment-records__content { display: grid; gap: 14px; margin-top: -22px; padding: 0 var(--patient-page-gutter) 24px; }
.patient-payment-records__summary { display: flex; align-items: center; gap: 11px; padding: 14px; border: 1px solid #d7e8f8; border-radius: 16px; background: #fff; box-shadow: 0 10px 24px rgba(28, 100, 162, .08); }
.patient-payment-records__summary-icon { position: relative; flex: 0 0 42px; width: 42px; height: 42px; border-radius: 13px; background: #eaf5ff; }
.patient-payment-records__summary-icon::before { position: absolute; left: 11px; top: 9px; width: 19px; height: 23px; border: 2px solid #187de9; border-radius: 5px; content: ''; }
.patient-payment-records__summary-icon::after { position: absolute; left: 16px; top: 18px; width: 11px; height: 2px; border-radius: 2px; background: #187de9; box-shadow: 0 6px #187de9; content: ''; }
.patient-payment-records__summary div { min-width: 0; flex: 1; }
.patient-payment-records__summary strong { display: block; color: #18395e; font-size: 16px; }
.patient-payment-records__summary p { margin: 4px 0 0; color: #617f9f; font-size: 12px; line-height: 1.45; }
.patient-payment-records__summary button { min-height: 32px; border: 0; background: transparent; color: #1478df; font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; }
.patient-payment-records__summary button:disabled { cursor: default; opacity: .55; }
.patient-payment-records__panel { min-height: 376px; padding: 18px; border: 1px solid #d7e6f4; border-radius: 18px; background: #fff; box-shadow: 0 10px 25px rgba(28, 100, 162, .06); }
.patient-payment-records__heading { display: flex; align-items: center; justify-content: space-between; padding-bottom: 15px; border-bottom: 1px solid #e7f0f8; }
.patient-payment-records__heading h2 { margin: 0; color: #18395e; font-size: 19px; }
.patient-payment-records__heading span { padding: 4px 8px; border-radius: 999px; background: #eaf6ff; color: #1478df; font-size: 12px; font-weight: 800; }
.patient-payment-records__list { display: grid; gap: 10px; padding-top: 14px; }
.patient-payment-records__list article { padding: 14px; border: 1px solid #dfeaf4; border-radius: 13px; background: #fbfdff; }
.patient-payment-records__card-head, .patient-payment-records__card-foot { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
.patient-payment-records__card-head strong { color: #1d4166; font-size: 15px; }
.patient-payment-records__card-head p { margin: 5px 0 0; color: #6a86a3; font-size: 12px; }
.patient-payment-records__card-head > span { flex: 0 0 auto; padding: 4px 8px; border-radius: 999px; font-size: 12px; font-weight: 800; }
.patient-payment-records__card-head > span.is-paid { background: #e7f8f3; color: #087765; }
.patient-payment-records__card-head > span.is-refunded { background: #fff2e8; color: #b65a1e; }
.patient-payment-records__card-foot { align-items: center; margin-top: 13px; padding-top: 12px; border-top: 1px solid #e7f0f8; }
.patient-payment-records__card-foot span { color: #6a86a3; font-size: 13px; }
.patient-payment-records__card-foot b { color: #0f766e; font-size: 17px; }
.patient-payment-records__empty { display: grid; justify-items: center; align-content: center; min-height: 285px; gap: 10px; padding: 26px 12px 12px; text-align: center; }
.patient-payment-records__empty-icon { position: relative; width: 70px; height: 70px; border-radius: 50%; background: #eaf6ff; }
.patient-payment-records__empty-icon::before { position: absolute; left: 21px; top: 18px; width: 28px; height: 33px; border: 2px solid #1684ed; border-radius: 7px; content: ''; }
.patient-payment-records__empty-icon::after { position: absolute; left: 29px; top: 31px; width: 13px; height: 2px; border-radius: 2px; background: #1684ed; box-shadow: 0 7px #1684ed; content: ''; }
.patient-payment-records__empty strong { color: #1b3d62; font-size: 18px; }
.patient-payment-records__empty p { max-width: 280px; margin: 0; color: #6682a0; font-size: 13px; line-height: 1.65; }
.patient-payment-records__empty.is-error strong { color: #ad4b1f; }
.patient-payment-records__empty button { min-height: 42px; margin-top: 7px; padding: 0 16px; border: 1px solid #1684ed; border-radius: 11px; background: #fff; color: #1478df; font: inherit; font-size: 14px; font-weight: 800; cursor: pointer; }
.patient-payment-records__skeleton { display: grid; gap: 12px; padding-top: 16px; }
.patient-payment-records__skeleton span { height: 76px; border-radius: 12px; background: linear-gradient(90deg, #edf3f7 20%, #f8fbfd 45%, #edf3f7 70%); background-size: 220% 100%; animation: payment-record-shimmer 1.25s ease-in-out infinite; }
.patient-payment-records__summary button:focus-visible, .patient-payment-records__empty button:focus-visible { outline: 3px solid rgba(23, 118, 186, .25); outline-offset: 2px; }
@keyframes payment-record-shimmer { to { background-position: -220% 0; } }
@media (prefers-reduced-motion: reduce) { .patient-payment-records__skeleton span { animation: none; } }
</style>
