<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'

import { patientApi, type PayableItem, type PaymentRegisterGroup } from '@/api/patient'
import SectionCard from '@/components/common/SectionCard.vue'
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
</script>

<template>
  <div class="patient-payment-center">
    <PatientFlowHeader title="缴费中心" subtitle="查看并支付本次就诊的待缴医疗项目" back-label="返回首页" @back="goBack" />

    <main class="patient-payment-center__content">
      <section class="patient-payment-center__intro" aria-live="polite">
        <span class="patient-payment-center__intro-icon" aria-hidden="true"></span>
        <div>
          <strong>待缴项目</strong>
          <p>可合并支付同一挂号下的检查、检验和处置项目。</p>
        </div>
        <button type="button" :disabled="loading" @click="loadPaymentItems()">{{ loading ? '刷新中' : '刷新' }}</button>
      </section>

      <section v-if="loading && !registerGroups.length" class="patient-payment-center__skeleton" aria-label="正在加载待缴项目">
        <span v-for="index in 4" :key="index"></span>
      </section>

      <section v-else-if="loadError && !registerGroups.length" class="patient-payment-center__state">
        <strong>暂时无法读取待缴项目</strong>
        <p>{{ loadError }}</p>
        <button type="button" @click="loadPaymentItems()">重新加载</button>
      </section>

      <section v-else-if="!registerGroups.length" class="patient-payment-center__state">
        <strong>当前没有待支付的医疗项目</strong>
        <p>医生开立检查、检验或处置项目后，会显示在这里。</p>
        <button type="button" @click="router.push('/patient/registers')">查看挂号记录</button>
      </section>

      <section v-else class="patient-payment-center__groups" aria-label="待缴挂号项目">
        <SectionCard v-for="group in registerGroups" :key="group.register_uuid" title="本次就诊待缴项目" :subtitle="formatVisitDate(group.visit_date)">
          <template #extra><span class="patient-payment-center__count">{{ group.items.length }} 项</span></template>
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
        </SectionCard>
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
.patient-payment-center { min-height: 100vh; padding-bottom: calc(var(--patient-nav-height) + 148px); background: linear-gradient(180deg, #eaf4ff 0%, #f7fbff 46%, #ffffff 100%); color: var(--patient-text); }
.patient-payment-center__content { display: grid; gap: 14px; margin-top: -22px; padding: 0 var(--patient-page-gutter) 24px; }
.patient-payment-center__intro { display: flex; align-items: center; gap: 11px; padding: 14px; border: 1px solid #d9e9f8; border-radius: 12px; background: #f4faff; color: #24435a; }
.patient-payment-center__intro-icon { position: relative; width: 32px; height: 24px; flex: 0 0 auto; border: 2px solid #1787d7; border-radius: 6px; }
.patient-payment-center__intro-icon::before, .patient-payment-center__intro-icon::after { position: absolute; height: 2px; border-radius: 2px; background: #1787d7; content: ''; }
.patient-payment-center__intro-icon::before { left: 5px; right: 5px; top: 7px; }
.patient-payment-center__intro-icon::after { right: 5px; bottom: 6px; width: 9px; }
.patient-payment-center__intro div { min-width: 0; flex: 1; }
.patient-payment-center__intro strong { display: block; font-size: 14px; }
.patient-payment-center__intro p { margin: 3px 0 0; color: #527087; font-size: 12px; line-height: 1.5; }
.patient-payment-center__intro button, .patient-payment-center__state button { border: 0; border-radius: 8px; background: transparent; color: var(--patient-primary); font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; }
.patient-payment-center__intro button:disabled { cursor: default; opacity: .55; }
.patient-payment-center__groups { display: grid; gap: 14px; }
.patient-payment-center__count { padding: 4px 8px; border-radius: 999px; background: #e8f5ff; color: #1676ba; font-size: 12px; font-weight: 800; white-space: nowrap; }
.patient-payment-center__items { display: grid; gap: 9px; }
.patient-payment-center__item { display: flex; align-items: center; justify-content: space-between; gap: 10px; min-height: 64px; padding: 11px 12px; border: 1px solid #e0eaf2; border-radius: 10px; background: #fbfdff; cursor: pointer; }
.patient-payment-center__item:has(.is-checked) { border-color: #78b5e5; background: #f1f8fe; }
.patient-payment-center__item.is-disabled { cursor: not-allowed; opacity: .58; }
.patient-payment-center__item :deep(.el-checkbox) { display: flex; align-items: center; min-width: 0; flex: 1; height: auto; margin-right: 0; }
.patient-payment-center__item :deep(.el-checkbox__label) { min-width: 0; padding-left: 10px; }
.patient-payment-center__item-copy { display: grid; grid-template-columns: auto minmax(0, 1fr); align-items: center; gap: 2px 7px; }
.patient-payment-center__item-copy em { grid-row: span 2; align-self: center; padding: 3px 6px; border-radius: 5px; background: #eaf4ff; color: #1676ba; font-size: 11px; font-style: normal; font-weight: 800; }
.patient-payment-center__item-copy strong { overflow: hidden; color: #19374d; font-size: 14px; text-overflow: ellipsis; white-space: nowrap; }
.patient-payment-center__item-copy small { color: #63798b; font-size: 12px; }
.patient-payment-center__item b { flex: 0 0 auto; color: #0f766e; font-size: 15px; }
.patient-payment-center__state { display: grid; justify-items: start; gap: 8px; padding: 28px 20px; border: 1px solid #dce7ef; border-radius: 14px; background: #ffffff; }
.patient-payment-center__state strong { color: #254157; font-size: 16px; }
.patient-payment-center__state p { margin: 0; color: #64798b; font-size: 13px; line-height: 1.65; }
.patient-payment-center__state button { min-height: 36px; margin-top: 5px; padding: 0 12px; border: 1px solid #9bc3e1; background: #ffffff; }
.patient-payment-center__skeleton { display: grid; gap: 12px; }
.patient-payment-center__skeleton span { height: 112px; border-radius: 14px; background: linear-gradient(90deg, #edf3f7 20%, #f8fbfd 45%, #edf3f7 70%); background-size: 220% 100%; animation: payment-shimmer 1.25s ease-in-out infinite; }
.patient-payment-center__checkout { position: fixed; z-index: calc(var(--patient-z-nav) - 1); left: 50%; bottom: calc(var(--patient-nav-height) + 8px); width: min(calc(100% - 24px), calc(var(--patient-page-width) - 24px)); display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: 9px 12px; padding: 12px; border: 1px solid #cfe1ef; border-radius: 14px; background: rgba(255, 255, 255, .98); box-shadow: 0 12px 28px rgba(23, 78, 124, .16); transform: translateX(-50%); }
.patient-payment-center__checkout div { display: grid; gap: 2px; }
.patient-payment-center__checkout span { color: #607589; font-size: 12px; }
.patient-payment-center__checkout strong { color: #0f766e; font-size: 22px; line-height: 1.1; }
.patient-payment-center__checkout :deep(.el-segmented) { grid-column: 1 / -1; width: 100%; }
.patient-payment-center__checkout button { grid-column: 2; grid-row: 1; min-height: 42px; padding: 0 13px; border: 1px solid #0f766e; border-radius: 10px; background: #0f766e; color: #ffffff; font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; }
.patient-payment-center__checkout button:disabled { cursor: not-allowed; opacity: .55; }
.patient-payment-center__checkout button:not(:disabled):hover { background: #0b615b; }
.patient-payment-center__checkout button:focus-visible, .patient-payment-center__intro button:focus-visible, .patient-payment-center__state button:focus-visible { outline: 3px solid rgba(23, 118, 186, .25); outline-offset: 2px; }
@keyframes payment-shimmer { to { background-position: -220% 0; } }
@media (max-width: 370px) { .patient-payment-center__checkout { grid-template-columns: 1fr; } .patient-payment-center__checkout button { grid-column: 1; grid-row: auto; width: 100%; } }
@media (prefers-reduced-motion: reduce) { .patient-payment-center__skeleton span { animation: none; } }
</style>
