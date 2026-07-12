Exit code: 0
Wall time: 0.3 seconds
Output:
<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

import type { RegisterDetail } from '@/api/patient'
import { patientApi } from '@/api/patient'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientRegisterHistoryStore } from '@/stores/patientRegisterHistory'
import { usePatientSessionStore } from '@/stores/patientSession'

const AUTO_REFRESH_MS = 15_000

const route = useRoute()
const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const historyStore = usePatientRegisterHistoryStore()
const loading = ref(false)
const selectedRegisterUuid = ref('')
const loadError = ref('')
const updatedAt = ref<Date | null>(null)
let refreshTimer: ReturnType<typeof setInterval> | undefined

const history = computed(() => historyStore.records)
const activeRecords = computed(() => history.value.filter((item) => item.visit_state === 1 || item.visit_state === 2))
const selectedRecord = computed<RegisterDetail | null>(
  () => history.value.find((item) => item.uuid === selectedRegisterUuid.value) ?? null,
)
const statusMeta = computed(() => {
  switch (flow.queueStatus?.status) {
    case 1:
      return { label: '正在候诊', hint: '请留意叫号信息，并提前到诊室附近等候。', tone: 'waiting' }
    case 2:
      return { label: '请前往就诊', hint: '医生正在接诊，请尽快前往诊室。', tone: 'reception' }
    case 3:
      return { label: '本次就诊已结束', hint: '如需查看既往记录，可前往挂号记录。', tone: 'finished' }
    case 4:
      return { label: '本次挂号已退号', hint: '该挂号单不再处于候诊队列。', tone: 'cancelled' }
    default:
      return { label: '候诊状态待确认', hint: '正在读取本次挂号的最新状态。', tone: 'pending' }
  }
})
const queueNumberText = computed(() => {
  if (flow.queueStatus?.status === 2) return '请前往诊室'
  if (flow.queueStatus?.status === 3 || flow.queueStatus?.status === 4) return '—'
  return String(flow.queueStatus?.ahead_of_you ?? '—')
})
const updatedText = computed(() => {
  if (!updatedAt.value) return '尚未更新'
  return `更新于 ${updatedAt.value.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })}`
})

onMounted(async () => {
  if (!session.patient) {
    router.replace('/patient/login')
    return
  }

  await historyStore.fetchHistory()
  const requestedUuid = typeof route.query.registerUuid === 'string' ? route.query.registerUuid : ''
  const flowRegisterUuid = flow.payment?.register_uuid || flow.onlineRegister?.register_uuid || ''
  const requestedRecord = history.value.find((item) => item.uuid === requestedUuid)
  selectedRegisterUuid.value = requestedRecord?.uuid || flowRegisterUuid || activeRecords.value[0]?.uuid || ''

  if (!selectedRegisterUuid.value) {
    return
  }

  await refresh()
  refreshTimer = setInterval(() => void refresh(true), AUTO_REFRESH_MS)
})

onBeforeUnmount(() => {
  if (refreshTimer) clearInterval(refreshTimer)
})

function goBack() {
  router.push('/patient/home')
}

async function refresh(silent = false) {
  if (!selectedRegisterUuid.value || loading.value) return
  loading.value = true
  loadError.value = ''
  try {
    const response = await patientApi.getQueueStatus(selectedRegisterUuid.value)
    flow.setQueueStatus(response.data.data)
    updatedAt.value = new Date()
  } catch {
    loadError.value = '候诊状态加载失败，请检查网络后重试。'
    if (!silent) ElMessage.error(loadError.value)
  } finally {
    loading.value = false
  }
}

function selectRegister(registerUuid: string) {
  if (registerUuid === selectedRegisterUuid.value) return
  selectedRegisterUuid.value = registerUuid
  flow.setQueueStatus({ ahead_of_you: 0, status: 0 })
  updatedAt.value = null
  void refresh()
}

function goToRegisters() {
  router.push('/patient/registers')
}
</script>

<template>
  <div class="patient-queue">
    <PatientFlowHeader
      title="候诊状态"
      subtitle="候诊进度会自动更新，也可手动刷新"
      back-label="返回首页"
      @back="goBack"
    />

    <main class="patient-queue__content">
      <template v-if="selectedRegisterUuid">
        <SectionCard title="当前候诊" :subtitle="statusMeta.hint">
          <template #extra>
            <span class="patient-queue__status-tag" :class="`is-${statusMeta.tone}`">{{ statusMeta.label }}</span>
          </template>

          <div class="patient-queue__progress" :class="`is-${statusMeta.tone}`" aria-live="polite">
            <span>{{ flow.queueStatus?.status === 2 ? '当前提醒' : '前方等待人数' }}</span>
            <strong>{{ queueNumberText }}</strong>
            <p v-if="flow.queueStatus?.status === 1">人数会随医生叫号实时变化</p>
            <p v-else>{{ statusMeta.hint }}</p>
          </div>

          <div class="patient-queue__details">
            <div>
              <span>诊室</span>
              <strong>{{ flow.queueStatus?.clinic_room_name || selectedRecord?.clinic_room_name || '待分配' }}</strong>
            </div>
            <div>
              <span>位置</span>
              <strong>{{ flow.queueStatus?.clinic_room_location || '到院后查看导诊屏' }}</strong>
            </div>
          </div>

          <div v-if="loadError" class="patient-queue__error" role="alert">{{ loadError }}</div>
          <div class="patient-queue__refresh-row">
            <span>{{ updatedText }}</span>
            <el-button type="primary" plain :loading="loading" @click="refresh()">刷新状态</el-button>
          </div>
        </SectionCard>

        <SectionCard title="本次挂号">
          <div class="patient-queue__summary">
            <div>
              <span>科室与医生</span>
              <strong>{{ selectedRecord?.dept_name || '科室待确认' }} · {{ selectedRecord?.employee_name || flow.selectedDoctor?.doctor_name || '医生待确认' }}</strong>
            </div>
            <div>
              <span>就诊时间</span>
              <strong>{{ selectedRecord?.actual_schedule_date || selectedRecord?.visit_date || '待确认' }} {{ selectedRecord?.actual_time_range || selectedRecord?.noon || '' }}</strong>
            </div>
            <div v-if="selectedRecord?.symptoms || flow.symptoms">
              <span>症状</span>
              <strong>{{ selectedRecord?.symptoms || flow.symptoms }}</strong>
            </div>
          </div>
        </SectionCard>

        <SectionCard v-if="activeRecords.length > 1" title="切换候诊挂号" subtitle="仅显示仍在候诊或接诊中的挂号单。">
          <div class="patient-queue__register-list">
            <button
              v-for="item in activeRecords"
              :key="item.uuid"
              type="button"
              :class="{ 'is-selected': item.uuid === selectedRegisterUuid }"
              @click="selectRegister(item.uuid)"
            >
              <strong>{{ item.dept_name || '科室待确认' }} · {{ item.employee_name || '医生待确认' }}</strong>
              <span>{{ item.visit_state_str || item.visit_state_text || '候诊中' }}</span>
            </button>
          </div>
        </SectionCard>
      </template>

      <SectionCard v-else title="暂无进行中的候诊">
        <div class="patient-queue__empty">
          <p>完成支付后的挂号单会出现在这里，您也可以从挂号记录进入候诊详情。</p>
          <el-button type="primary" @click="goToRegisters">查看挂号记录</el-button>
        </div>
      </SectionCard>
    </main>
  </div>
</template>

<style scoped>
.patient-queue { min-height: 100vh; padding-bottom: 24px; background: linear-gradient(180deg, #eaf4ff 0%, #f7fbff 46%, #ffffff 100%); color: var(--patient-text); }
.patient-queue__content { display: grid; gap: 14px; margin-top: -22px; padding: 0 var(--patient-page-gutter) 24px; }
.patient-queue__status-tag { flex: 0 0 auto; padding: 5px 9px; border-radius: 999px; background: #e0f2fe; color: #075985; font-size: 12px; font-weight: 800; white-space: nowrap; }
.patient-queue__status-tag.is-reception { background: #dcfce7; color: #166534; }
.patient-queue__status-tag.is-finished, .patient-queue__status-tag.is-cancelled { background: #f1f5f9; color: #475569; }
.patient-queue__progress { display: grid; justify-items: center; gap: 6px; margin-bottom: 14px; padding: 22px 14px; border-radius: 12px; background: #e0f2fe; color: #0c4a6e; text-align: center; }
.patient-queue__progress.is-reception { background: #dcfce7; color: #14532d; }
.patient-queue__progress.is-finished, .patient-queue__progress.is-cancelled { background: #f1f5f9; color: #334155; }
.patient-queue__progress span, .patient-queue__progress p { margin: 0; font-size: 13px; }
.patient-queue__progress strong { font-size: 42px; line-height: 1.08; }
.patient-queue__details, .patient-queue__summary, .patient-queue__register-list { display: grid; gap: 10px; }
.patient-queue__details { margin-bottom: 14px; }
.patient-queue__details div, .patient-queue__summary div, .patient-queue__register-list button { display: grid; gap: 4px; padding: 12px 14px; border: 1px solid transparent; border-radius: 10px; background: #f8fafc; color: var(--patient-text); text-align: left; }
.patient-queue__details span, .patient-queue__summary span, .patient-queue__register-list span, .patient-queue__refresh-row > span { color: #475569; font-size: 13px; }
.patient-queue__summary strong { word-break: break-word; }
.patient-queue__error { margin: 0 0 12px; padding: 10px 12px; border-radius: 8px; background: #fef2f2; color: #b91c1c; font-size: 14px; }
.patient-queue__refresh-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.patient-queue__register-list button { width: 100%; font: inherit; cursor: pointer; }
.patient-queue__register-list button.is-selected { border-color: var(--patient-primary); background: var(--patient-blue-soft); }
.patient-queue__empty { display: grid; gap: 14px; color: var(--patient-text-muted); line-height: 1.65; }
.patient-queue__empty p { margin: 0; }
@media (max-width: 360px) { .patient-queue__refresh-row { align-items: stretch; flex-direction: column; } }
@media (prefers-reduced-motion: reduce) { .patient-queue__register-list button { transition: none; } }
</style>
. : File C:\Users\Twilight\Documents\WindowsPowerShell\profile.ps1 cannot be loaded because running scripts is disabled
 on this system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:3
+ . 'C:\Users\Twilight\Documents\WindowsPowerShell\profile.ps1'
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
