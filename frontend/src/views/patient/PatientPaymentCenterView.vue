<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'

import { patientApi, type PayableItem, type PaymentRegisterGroup } from '@/api/patient'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const session = usePatientSessionStore()
const loading = ref(false)
const paying = ref(false)
const loadError = ref('')
const payMethod = ref('微信')
const registerGroups = ref<PaymentRegisterGroup[]>([])
const selectedItemIds = reactive<Record<string, string[]>>({})

const payableCount = computed(() => registerGroups.value.reduce((total, group) => total + group.items.length, 0))
const selectedRegisterUuid = computed(() => {
  const group = registerGroups.value.find((item) => selectedItemIds[item.register_uuid]?.length)
  return group?.register_uuid ?? ''
})
const selectedGroup = computed(() => registerGroups.value.find((item) => item.register_uuid === selectedRegisterUuid.value) ?? null)
const selectedItems = computed<PayableItem[]>(() => {
  const group = selectedGroup.value
  if (!group) return []
  const ids = new Set(selectedItemIds[group.register_uuid] ?? [])
  return group.items.filter((item) => ids.has(item.uuid))
})
const selectedTotal = computed(() => selectedItems.value.reduce((total, item) => total + Number(item.amount || 0), 0))
const canPay = computed(() => Boolean(session.patient?.uuid && selectedGroup.value && selectedItems.value.length && !paying.value))

onMounted(() => {
  if (!session.patient?.uuid) {
    router.replace('/patient/login')
    return
  }
  void loadPaymentItems()
})

function getErrorMessage(error: unknown, fallback: string) {
  const detail = (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data
  return String(detail?.detail || detail?.message || fallback)
}

function itemTypeLabel(type: PayableItem['type']) {
  if (type === 'check') return '检查'
  if (type === 'inspection') return '检验'
  if (type === 'disposal') return '处置'
  return '药品'
}

function formatAmount(value: string | number) {
  return `¥${Number(value || 0).toFixed(2)}`
}

function formatVisitDate(value?: string | null) {
  if (!value) return '本次就诊'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('zh-CN', {
    month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false,
  }).format(date)
}

function isItemDisabled(registerUuid: string) {
  return Boolean(selectedRegisterUuid.value && selectedRegisterUuid.value !== registerUuid)
}

async function loadPaymentItems(silent = false) {
  const patientUuid = session.patient?.uuid
  if (!patientUuid || loading.value) return

  loading.value = true
  loadError.value = ''
  try {
    const response = await patientApi.getPaymentItems(patientUuid)
    const groups = response.data.data?.registers ?? []
    registerGroups.value = groups
    for (const group of groups) selectedItemIds[group.register_uuid] ??= []
    for (const registerUuid of Object.keys(selectedItemIds)) {
      if (!groups.some((group) => group.register_uuid === registerUuid)) delete selectedItemIds[registerUuid]
    }
  } catch (error) {
    loadError.value = getErrorMessage(error, '待缴项目加载失败，请稍后重试。')
    if (!silent) ElMessage.error(loadError.value)
  } finally {
    loading.value = false
  }
}

async function refreshPaymentState() {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    await new Promise((resolve) => window.setTimeout(resolve, 1200))
    await loadPaymentItems(true)
  }
}

async function paySelectedItems() {
  const patientUuid = session.patient?.uuid
  const group = selectedGroup.value
  if (!patientUuid || !group || !canPay.value) return

  paying.value = true
  try {
    const response = await patientApi.payPaymentItems({
      patient_uuid: patientUuid,
      register_uuid: group.register_uuid,
      items: selectedItems.value.map((item) => ({ uuid: item.uuid, type: item.type })),
      pay_method: payMethod.value,
      idempotency_key: `medical-payment-${group.register_uuid}-${Date.now()}`,
    })
    const billCode = response.data.data?.bill_code
    selectedItemIds[group.register_uuid] = []
    ElMessage.success(billCode ? `支付成功，账单号：${billCode}` : '支付成功，正在同步项目状态。')
    await refreshPaymentState()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '支付提交失败，请稍后重试。'))
  } finally {
    paying.value = false
  }
}

function goBack() {
  router.push('/patient/home')
}

function goPaymentRecords() {
  router.push('/patient/payment-records')
}
</script>

<template>
  <div class="patient-payment-center">
    <PatientFlowHeader title="缴费中心" subtitle="查看并支付本次就诊的待缴医疗项目" back-label="返回首页" @back="goBack" />

    <main class="patient-payment-center__content">
      <section class="patient-payment-center__summary" aria-live="polite">
        <span class="patient-payment-center__summary-icon" aria-hidden="true"></span>
        <div>
          <strong>待缴项目</strong>
          <p>{{ payableCount ? `本次就诊共有 ${payableCount} 项待缴项目` : '本次就诊暂未产生待缴医疗项目' }}</p>
        </div>
        <span class="patient-payment-center__summary-count">{{ payableCount }} 项</span>
      </section>

      <section class="patient-payment-center__panel" aria-labelledby="payment-list-title">
        <div class="patient-payment-center__panel-heading">
          <div>
            <h2 id="payment-list-title">当前待缴</h2>
            <p>同一次结算仅可选择同一挂号下的项目</p>
          </div>
          <div class="patient-payment-center__panel-actions">
            <button type="button" class="is-records" @click="goPaymentRecords">缴费记录</button>
            <button type="button" :disabled="loading" @click="loadPaymentItems()">{{ loading ? '刷新中' : '刷新' }}</button>
          </div>
        </div>

        <div v-if="loading && !registerGroups.length" class="patient-payment-center__skeleton" aria-label="正在加载待缴项目">
          <span v-for="index in 3" :key="index"></span>
        </div>

        <div v-else-if="loadError && !registerGroups.length" class="patient-payment-center__empty is-error">
          <span class="patient-payment-center__empty-icon" aria-hidden="true"></span>
          <strong>暂时无法读取待缴项目</strong>
          <p>{{ loadError }}</p>
          <button type="button" class="patient-payment-center__outline-button" @click="loadPaymentItems()">重新加载</button>
        </div>

        <div v-else-if="!registerGroups.length" class="patient-payment-center__empty">
          <span class="patient-payment-center__empty-icon" aria-hidden="true"></span>
          <strong>暂时没有待缴项目</strong>
          <p>医生开立检查、检验或处置项目后，将自动同步到这里。</p>
          <button type="button" class="patient-payment-center__outline-button" @click="goPaymentRecords">查看缴费记录</button>
          <small>已支付项目可在缴费记录中查看状态与金额</small>
        </div>

        <div v-else class="patient-payment-center__groups" aria-label="待缴挂号项目">
          <article v-for="group in registerGroups" :key="group.register_uuid" class="patient-payment-center__group">
            <div class="patient-payment-center__group-heading">
              <div>
                <strong>本次就诊待缴项目</strong>
                <span>{{ formatVisitDate(group.visit_date) }}</span>
              </div>
              <em>{{ group.items.length }} 项</em>
            </div>
            <el-checkbox-group v-model="selectedItemIds[group.register_uuid]" class="patient-payment-center__items">
              <label v-for="item in group.items" :key="item.uuid" class="patient-payment-center__item" :class="{ 'is-disabled': isItemDisabled(group.register_uuid) }">
                <el-checkbox :label="item.uuid" :disabled="isItemDisabled(group.register_uuid)">
                  <span class="patient-payment-center__item-copy">
                    <em>{{ itemTypeLabel(item.type) }}</em>
                    <strong>{{ item.title }}</strong>
                    <small>待支付</small>
                  </span>
                </el-checkbox>
                <b>{{ formatAmount(item.amount) }}</b>
              </label>
            </el-checkbox-group>
          </article>
        </div>
      </section>
    </main>

    <aside v-if="selectedItems.length" class="patient-payment-center__checkout" aria-live="polite">
      <div><span>已选 {{ selectedItems.length }} 项</span><strong>{{ formatAmount(selectedTotal) }}</strong></div>
      <el-segmented v-model="payMethod" :options="['微信', '支付宝']" aria-label="选择支付方式" />
      <button type="button" :disabled="!canPay" @click="paySelectedItems">
        {{ paying ? '支付提交中...' : `确认支付 ${formatAmount(selectedTotal)}` }}
      </button>
    </aside>
    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-payment-center { min-height: 100vh; padding-bottom: calc(var(--patient-nav-height) + 142px); background: var(--patient-flow-page-bg); color: var(--patient-text); }
.patient-payment-center__content { display: grid; gap: 14px; margin-top: -22px; padding: 0 var(--patient-page-gutter) 24px; }
.patient-payment-center__summary { display: flex; align-items: center; gap: 11px; padding: 14px; border: 1px solid #d7e8f8; border-radius: 16px; background: #fff; box-shadow: 0 10px 24px rgba(28, 100, 162, .08); }
.patient-payment-center__summary-icon { position: relative; flex: 0 0 42px; width: 42px; height: 42px; border-radius: 13px; background: #eaf5ff; }
.patient-payment-center__summary-icon::before, .patient-payment-center__summary-icon::after { position: absolute; left: 10px; border: 2px solid #187de9; border-radius: 4px; content: ''; }
.patient-payment-center__summary-icon::before { top: 10px; width: 20px; height: 18px; }
.patient-payment-center__summary-icon::after { top: 17px; width: 12px; height: 0; border-width: 0 0 2px; border-radius: 0; }
.patient-payment-center__summary div { min-width: 0; flex: 1; }
.patient-payment-center__summary strong { display: block; color: #18395e; font-size: 16px; }
.patient-payment-center__summary p { margin: 4px 0 0; color: #617f9f; font-size: 12px; line-height: 1.45; }
.patient-payment-center__summary-count { flex: 0 0 auto; padding: 5px 9px; border-radius: 999px; background: #eaf6ff; color: #1478df; font-size: 12px; font-weight: 800; }
.patient-payment-center__panel { min-height: 376px; padding: 18px; border: 1px solid #d7e6f4; border-radius: 18px; background: #fff; box-shadow: 0 10px 25px rgba(28, 100, 162, .06); }
.patient-payment-center__panel-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; padding-bottom: 15px; border-bottom: 1px solid #e7f0f8; }
.patient-payment-center__panel-heading h2, .patient-payment-center__panel-heading p { margin: 0; }
.patient-payment-center__panel-heading h2 { color: #18395e; font-size: 19px; line-height: 1.25; }
.patient-payment-center__panel-heading p { margin-top: 5px; color: #6c86a3; font-size: 12px; line-height: 1.45; }
.patient-payment-center__panel-actions { display: flex; align-items: center; gap: 4px; }
.patient-payment-center__panel-actions button { min-height: 30px; padding: 0 4px; border: 0; background: transparent; color: #1478df; font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; white-space: nowrap; }
.patient-payment-center__panel-actions button:disabled { cursor: default; opacity: .55; }
.patient-payment-center__panel-actions .is-records { color: #37658f; }
.patient-payment-center__empty { display: grid; justify-items: center; align-content: center; min-height: 285px; gap: 10px; padding: 26px 12px 12px; text-align: center; }
.patient-payment-center__empty-icon { position: relative; width: 70px; height: 70px; border-radius: 50%; background: #eaf6ff; }
.patient-payment-center__empty-icon::before { position: absolute; left: 20px; top: 17px; width: 30px; height: 35px; border: 2px solid #1684ed; border-radius: 7px; content: ''; }
.patient-payment-center__empty-icon::after { position: absolute; left: 28px; top: 31px; width: 14px; height: 2px; border-radius: 2px; background: #1684ed; box-shadow: 0 7px #1684ed; content: ''; }
.patient-payment-center__empty strong { color: #1b3d62; font-size: 18px; }
.patient-payment-center__empty p { max-width: 280px; margin: 0; color: #6682a0; font-size: 13px; line-height: 1.65; }
.patient-payment-center__empty small { margin-top: 5px; color: #7890aa; font-size: 12px; }
.patient-payment-center__empty.is-error strong { color: #ad4b1f; }
.patient-payment-center__outline-button { min-height: 42px; margin-top: 7px; padding: 0 16px; border: 1px solid #1684ed; border-radius: 11px; background: #fff; color: #1478df; font: inherit; font-size: 14px; font-weight: 800; cursor: pointer; }
.patient-payment-center__groups { display: grid; gap: 12px; padding-top: 14px; }
.patient-payment-center__group { overflow: hidden; border: 1px solid #dfeaf4; border-radius: 13px; background: #fbfdff; }
.patient-payment-center__group-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; padding: 13px 14px; border-bottom: 1px solid #e3edf6; background: #f5faff; }
.patient-payment-center__group-heading div { display: grid; gap: 4px; }
.patient-payment-center__group-heading strong { color: #1d4166; font-size: 15px; }
.patient-payment-center__group-heading span { color: #6a86a3; font-size: 12px; }
.patient-payment-center__group-heading em { padding: 4px 8px; border-radius: 999px; background: #e8f5ff; color: #1676ba; font-size: 12px; font-style: normal; font-weight: 800; white-space: nowrap; }
.patient-payment-center__items { display: grid; gap: 8px; padding: 10px; }
.patient-payment-center__item { display: flex; align-items: center; justify-content: space-between; gap: 10px; min-height: 64px; padding: 10px 11px; border: 1px solid #e0eaf2; border-radius: 10px; background: #fff; cursor: pointer; }
.patient-payment-center__item:has(.is-checked) { border-color: #78b5e5; background: #f1f8fe; }
.patient-payment-center__item.is-disabled { cursor: not-allowed; opacity: .58; }
.patient-payment-center__item :deep(.el-checkbox) { display: flex; align-items: center; min-width: 0; flex: 1; height: auto; margin-right: 0; }
.patient-payment-center__item :deep(.el-checkbox__label) { min-width: 0; padding-left: 10px; }
.patient-payment-center__item-copy { display: grid; grid-template-columns: auto minmax(0, 1fr); align-items: center; gap: 2px 7px; }
.patient-payment-center__item-copy em { grid-row: span 2; align-self: center; padding: 3px 6px; border-radius: 5px; background: #eaf4ff; color: #1676ba; font-size: 11px; font-style: normal; font-weight: 800; }
.patient-payment-center__item-copy strong { overflow: hidden; color: #19374d; font-size: 14px; text-overflow: ellipsis; white-space: nowrap; }
.patient-payment-center__item-copy small { color: #63798b; font-size: 12px; }
.patient-payment-center__item b { flex: 0 0 auto; color: #0f766e; font-size: 15px; }
.patient-payment-center__skeleton { display: grid; gap: 12px; padding-top: 16px; }
.patient-payment-center__skeleton span { height: 76px; border-radius: 12px; background: linear-gradient(90deg, #edf3f7 20%, #f8fbfd 45%, #edf3f7 70%); background-size: 220% 100%; animation: payment-shimmer 1.25s ease-in-out infinite; }
.patient-payment-center__checkout { position: fixed; z-index: calc(var(--patient-z-nav) - 1); left: 50%; bottom: calc(var(--patient-nav-height) + 8px); width: min(calc(100% - 24px), calc(var(--patient-page-width) - 24px)); display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: 9px 12px; padding: 12px; border: 1px solid #cfe1ef; border-radius: 14px; background: rgba(255, 255, 255, .98); box-shadow: 0 12px 28px rgba(23, 78, 124, .16); transform: translateX(-50%); }
.patient-payment-center__checkout div { display: grid; gap: 2px; }
.patient-payment-center__checkout span { color: #607589; font-size: 12px; }
.patient-payment-center__checkout strong { color: #0f766e; font-size: 22px; line-height: 1.1; }
.patient-payment-center__checkout :deep(.el-segmented) { grid-column: 1 / -1; width: 100%; }
.patient-payment-center__checkout button { grid-column: 2; grid-row: 1; min-height: 42px; padding: 0 13px; border: 1px solid #0f766e; border-radius: 10px; background: #0f766e; color: #fff; font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; }
.patient-payment-center__checkout button:disabled { cursor: not-allowed; opacity: .55; }
.patient-payment-center__checkout button:not(:disabled):hover { background: #0b615b; }
.patient-payment-center__outline-button:focus-visible, .patient-payment-center__panel-actions button:focus-visible, .patient-payment-center__checkout button:focus-visible { outline: 3px solid rgba(23, 118, 186, .25); outline-offset: 2px; }
@keyframes payment-shimmer { to { background-position: -220% 0; } }
@media (max-width: 370px) { .patient-payment-center__checkout { grid-template-columns: 1fr; } .patient-payment-center__checkout button { grid-column: 1; grid-row: auto; width: 100%; } .patient-payment-center__panel { padding: 15px; } }
@media (prefers-reduced-motion: reduce) { .patient-payment-center__skeleton span { animation: none; } }
</style>
