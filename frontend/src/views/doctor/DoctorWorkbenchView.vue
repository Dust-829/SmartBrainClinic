<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'

import { doctorApi, type DoctorCallNextResult, type DoctorQueueItem } from '@/api/doctor'
import SectionCard from '@/components/common/SectionCard.vue'
import { useDoctorSessionStore } from '@/stores/doctorSession'

const VISIT_STATE_REGISTERED = 1
const VISIT_STATE_RECEPTION = 2
const UNKNOWN_TIME_RANGE = '时间待确认'

interface QueueStatusSummaryItem {
  key: 'waiting' | 'inReception'
  label: string
  count: number
  percentage: number
}

interface QueueTimeBucket {
  label: string
  count: number
}

const router = useRouter()
const session = useDoctorSessionStore()

const queueItems = ref<DoctorQueueItem[]>([])
const loading = ref(false)
const errorMessage = ref('')
const callingNext = ref(false)
const actionRegisterUuid = ref('')
const lastCalled = ref<DoctorCallNextResult | null>(null)
const lastRefreshedAt = ref<Date | null>(null)

let queuePollTimer: number | null = null

const doctor = computed(() => session.staff)
const hasIdentity = computed(() => Boolean(doctor.value?.employeeUuid))
const queueCount = computed(() => queueItems.value.length)
const waitingCount = computed(
  () => queueItems.value.filter((item) => item.visit_state === VISIT_STATE_REGISTERED).length,
)
const inReceptionCount = computed(
  () => queueItems.value.filter((item) => item.visit_state === VISIT_STATE_RECEPTION).length,
)
const currentReception = computed(
  () => queueItems.value.find((item) => item.visit_state === VISIT_STATE_RECEPTION) ?? null,
)
const nextWaiting = computed(
  () => queueItems.value.find((item) => item.visit_state === VISIT_STATE_REGISTERED) ?? null,
)
const queueStatusSummary = computed<QueueStatusSummaryItem[]>(() => {
  const total = queueCount.value
  const toPercentage = (count: number) => (total > 0 ? Math.round((count / total) * 100) : 0)

  return [
    {
      key: 'waiting',
      label: '待接诊',
      count: waitingCount.value,
      percentage: toPercentage(waitingCount.value),
    },
    {
      key: 'inReception',
      label: '接诊中',
      count: inReceptionCount.value,
      percentage: toPercentage(inReceptionCount.value),
    },
  ]
})
const queueTimeBuckets = computed<QueueTimeBucket[]>(() => {
  const bucketCounts = new Map<string, number>()

  for (const item of queueItems.value) {
    const label = item.time_range?.trim() || UNKNOWN_TIME_RANGE
    bucketCounts.set(label, (bucketCounts.get(label) ?? 0) + 1)
  }

  return [...bucketCounts.entries()]
    .sort(([left], [right]) => {
      if (left === UNKNOWN_TIME_RANGE) return 1
      if (right === UNKNOWN_TIME_RANGE) return -1
      return left.localeCompare(right)
    })
    .map(([label, count]) => ({ label, count }))
})

function getErrorMessage(error: unknown, fallback: string) {
  const detail = (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data
  return String(detail?.detail || detail?.message || fallback)
}

function tagType(visitState: number) {
  if (visitState === 2) return 'success'
  if (visitState === 1) return 'warning'
  return 'info'
}

function visitTimeLabel(item: DoctorQueueItem) {
  return [item.visit_date, item.time_range].filter(Boolean).join(' ') || '时间待确认'
}

function symptomLabel(item: DoctorQueueItem) {
  return item.symptoms?.trim() || '患者暂未填写主诉摘要。'
}

function canStartReception(item: DoctorQueueItem) {
  return item.visit_state === VISIT_STATE_REGISTERED
}

function canContinueEncounter(item: DoctorQueueItem) {
  return item.visit_state === VISIT_STATE_RECEPTION
}

function isActionLoading(registerUuid: string) {
  return actionRegisterUuid.value === registerUuid
}

function openEncounter(item: DoctorQueueItem) {
  router.push({
    name: 'doctor-encounter',
    params: {
      registerId: item.register_uuid,
    },
  })
}

async function loadQueue(options: { silent?: boolean } = {}) {
  if (!doctor.value?.employeeUuid) {
    queueItems.value = []
    errorMessage.value = ''
    return
  }

  if (!options.silent) {
    loading.value = true
  }

  errorMessage.value = ''
  try {
    const response = await doctorApi.getQueue(doctor.value.employeeUuid)
    queueItems.value = response.data.data ?? []
    lastRefreshedAt.value = new Date()
  } catch (error) {
    errorMessage.value = getErrorMessage(error, '今日候诊列表加载失败，请稍后重试。')
  } finally {
    if (!options.silent) {
      loading.value = false
    }
  }
}

function stopQueuePolling() {
  if (queuePollTimer !== null) {
    window.clearInterval(queuePollTimer)
    queuePollTimer = null
  }
}

function startQueuePolling() {
  stopQueuePolling()
  if (!hasIdentity.value) {
    return
  }

  queuePollTimer = window.setInterval(() => {
    void loadQueue({ silent: true })
  }, 15000)
}

async function handleCallNext() {
  if (!doctor.value?.employeeUuid || callingNext.value) return

  callingNext.value = true
  try {
    const response = await doctorApi.callNext(doctor.value.employeeUuid)
    const result = response.data.data
    lastCalled.value = result ?? null

    if (result?.called) {
      ElMessage.success(`已叫号：${result.patient_name ?? '当前患者'}`)
    } else {
      ElMessage.info(result?.message || '当前没有可叫号患者。')
    }

    await loadQueue()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '叫号失败，请稍后重试。'))
  } finally {
    callingNext.value = false
  }
}

async function handleStartReception(item: DoctorQueueItem) {
  if (!canStartReception(item) || isActionLoading(item.register_uuid)) return

  actionRegisterUuid.value = item.register_uuid
  try {
    const response = await doctorApi.startReception(item.register_uuid)
    const result = response.data.data

    if (lastCalled.value?.register_uuid === item.register_uuid) {
      lastCalled.value = {
        ...lastCalled.value,
        visit_state: result?.visit_state,
        visit_state_text: result?.visit_state_text,
      }
    }

    ElMessage.success(`已开始接诊：${item.patient_name}`)
    await loadQueue()
    openEncounter(item)
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '开始接诊失败，请稍后重试。'))
  } finally {
    actionRegisterUuid.value = ''
  }
}

watch(
  () => doctor.value?.employeeUuid,
  () => {
    void loadQueue()
    startQueuePolling()
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  stopQueuePolling()
})
</script>

<template>
  <div class="doctor-workbench">
    <section class="doctor-workbench__hero">
      <div class="doctor-workbench__hero-main">
        <span class="doctor-workbench__eyebrow">医生工作台</span>
        <h2>{{ doctor?.displayName || '未登录医生' }}</h2>
        <p>{{ doctor?.deptName || '登录后在这里带入真实医生身份，并读取今日候诊队列。' }}</p>
      </div>
      <div class="doctor-workbench__hero-metrics">
        <div>
          <strong>{{ queueCount }}</strong>
          <span>今日队列</span>
        </div>
        <div>
          <strong>{{ waitingCount }}</strong>
          <span>待接诊</span>
        </div>
        <div>
          <strong>{{ inReceptionCount }}</strong>
          <span>接诊中</span>
        </div>
      </div>
    </section>

    <div class="doctor-workbench__workspace">
      <div class="doctor-workbench__main">
        <SectionCard title="今日候诊队列" subtitle="左侧保留真实候诊主工作区，当前支持叫下一位、开始接诊和继续接诊。">
          <template #extra>
            <div class="doctor-workbench__actions">
              <button
                type="button"
                class="doctor-workbench__primary"
                :disabled="callingNext || !hasIdentity || !waitingCount"
                @click="handleCallNext"
              >
                {{ callingNext ? '叫号中...' : '叫下一位' }}
              </button>
              <button
                type="button"
                class="doctor-workbench__secondary"
                :disabled="loading || !hasIdentity"
                @click="loadQueue()"
              >
                {{ loading ? '刷新中...' : '刷新队列' }}
              </button>
            </div>
          </template>

          <div v-if="!hasIdentity" class="doctor-workbench__state">
            <strong>当前没有有效医生身份</strong>
            <p>请先从医生登录页选择真实医生，再进入工作台读取候诊队列。</p>
          </div>

          <el-skeleton v-else :loading="loading" animated :rows="6">
            <template #default>
              <div v-if="errorMessage" class="doctor-workbench__state is-error">
                <strong>{{ errorMessage }}</strong>
                <button type="button" class="doctor-workbench__secondary" @click="loadQueue()">重新加载</button>
              </div>

              <div v-else-if="queueItems.length" class="doctor-workbench__queue">
                <article v-for="item in queueItems" :key="item.register_uuid" class="doctor-workbench__queue-item">
                  <div class="doctor-workbench__queue-head">
                    <div>
                      <div class="doctor-workbench__queue-title">
                        <strong>{{ item.patient_name }}</strong>
                        <span>{{ item.patient_case_number }}</span>
                      </div>
                      <p>{{ symptomLabel(item) }}</p>
                    </div>
                    <el-tag :type="tagType(item.visit_state)" effect="plain">
                      {{ item.visit_state_text }}
                    </el-tag>
                  </div>

                  <dl class="doctor-workbench__queue-meta">
                    <div>
                      <dt>就诊时间</dt>
                      <dd>{{ visitTimeLabel(item) }}</dd>
                    </div>
                    <div>
                      <dt>诊室</dt>
                      <dd>{{ item.clinic_room_name || '未指定诊室' }}</dd>
                    </div>
                  </dl>

                  <div class="doctor-workbench__queue-actions">
                    <button
                      v-if="canStartReception(item)"
                      type="button"
                      class="doctor-workbench__primary"
                      :disabled="isActionLoading(item.register_uuid)"
                      @click="handleStartReception(item)"
                    >
                      {{ isActionLoading(item.register_uuid) ? '接诊中...' : '开始接诊' }}
                    </button>
                    <button
                      v-else-if="canContinueEncounter(item)"
                      type="button"
                      class="doctor-workbench__primary is-blue"
                      @click="openEncounter(item)"
                    >
                      继续接诊
                    </button>
                    <span v-else class="doctor-workbench__queue-hint">当前状态不可进入接诊</span>
                  </div>
                </article>
              </div>

              <div v-else class="doctor-workbench__state">
                <strong>今日暂无候诊患者</strong>
                <p>当前医生名下没有“已挂号”或“接诊中”的当日患者。</p>
              </div>
            </template>
          </el-skeleton>
        </SectionCard>
      </div>

      <aside class="doctor-workbench__sidebar">
        <SectionCard title="当前接诊摘要" subtitle="右侧改成紧凑支持区，不再放大块静态 AI 占位。">
          <div class="doctor-workbench__summary-card">
            <div>
              <span>接诊医生</span>
              <strong>{{ doctor?.displayName || '未登录' }}</strong>
            </div>
            <div>
              <span>科室</span>
              <strong>{{ doctor?.deptName || '待登录' }}</strong>
            </div>
            <div>
              <span>当前接诊中</span>
              <strong>{{ currentReception?.patient_name || '暂无' }}</strong>
            </div>
          </div>
        </SectionCard>

        <SectionCard title="最近叫号" subtitle="帮助医生确认刚刚推进到哪位患者。">
          <div v-if="lastCalled?.called" class="doctor-workbench__note-card">
            <strong>{{ lastCalled.patient_name }}</strong>
            <p>{{ lastCalled.patient_case_number || '病案号待确认' }}</p>
            <span>{{ lastCalled.time_range || '时间段待确认' }}</span>
          </div>
          <div v-else class="doctor-workbench__note-card is-muted">
            <strong>尚未叫号</strong>
            <p>点击“叫下一位”后，这里会保留最近一次叫号摘要。</p>
            <span>{{ nextWaiting?.patient_name ? `下一位：${nextWaiting.patient_name}` : '当前没有待接诊患者' }}</span>
          </div>
        </SectionCard>

        <SectionCard title="队列概览" subtitle="把统计、约束和操作边界收在一列。">
          <div class="doctor-workbench__overview">
            <div class="doctor-workbench__overview-item">
              <span>待接诊</span>
              <strong>{{ waitingCount }}</strong>
            </div>
            <div class="doctor-workbench__overview-item">
              <span>接诊中</span>
              <strong>{{ inReceptionCount }}</strong>
            </div>
            <div class="doctor-workbench__overview-item">
              <span>下一位</span>
              <strong>{{ nextWaiting?.patient_name || '暂无' }}</strong>
            </div>
          </div>
          <div class="doctor-workbench__hint">
            同一名医生同一时刻只允许一位患者处于“接诊中”。如果已有接诊中的患者，开始下一位时会直接拦截并提示。
          </div>
        </SectionCard>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.doctor-workbench {
  display: grid;
  gap: 20px;
}

.doctor-workbench__hero {
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  gap: 18px;
  padding: 24px;
  border-radius: 18px;
  background: linear-gradient(135deg, #0f766e 0%, #115e59 100%);
  color: #ffffff;
}

.doctor-workbench__hero-main {
  display: grid;
  gap: 8px;
}

.doctor-workbench__eyebrow {
  color: rgba(255, 255, 255, 0.82);
  font-size: 13px;
  font-weight: 700;
}

.doctor-workbench__hero h2,
.doctor-workbench__hero p,
.doctor-workbench__hero strong,
.doctor-workbench__hero span {
  margin: 0;
}

.doctor-workbench__hero h2 {
  font-size: 30px;
  line-height: 1.1;
}

.doctor-workbench__hero p {
  max-width: 56ch;
  color: rgba(255, 255, 255, 0.86);
  line-height: 1.6;
}

.doctor-workbench__hero-metrics {
  display: grid;
  grid-template-columns: repeat(3, minmax(88px, 1fr));
  gap: 12px;
  min-width: 320px;
}

.doctor-workbench__hero-metrics div {
  display: grid;
  align-content: center;
  gap: 6px;
  padding: 14px 16px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(4px);
}

.doctor-workbench__hero-metrics strong {
  font-size: 28px;
}

.doctor-workbench__hero-metrics span {
  color: rgba(255, 255, 255, 0.82);
  font-size: 13px;
}

.doctor-workbench__workspace {
  display: grid;
  grid-template-columns: minmax(0, 1.7fr) minmax(300px, 0.7fr);
  gap: 20px;
  align-items: start;
}

.doctor-workbench__main,
.doctor-workbench__sidebar {
  display: grid;
  gap: 20px;
}

.doctor-workbench__actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}

.doctor-workbench__primary,
.doctor-workbench__secondary {
  min-height: 40px;
  padding: 0 16px;
  border: 0;
  border-radius: 10px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

.doctor-workbench__primary {
  background: #0f766e;
  color: #ffffff;
}

.doctor-workbench__primary.is-blue {
  background: #1d4ed8;
}

.doctor-workbench__secondary {
  background: #e2e8f0;
  color: #0f172a;
}

.doctor-workbench__primary:disabled,
.doctor-workbench__secondary:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.doctor-workbench__queue {
  display: grid;
  gap: 14px;
}

.doctor-workbench__queue-item {
  display: grid;
  gap: 14px;
  padding: 16px;
  border: 1px solid #dbe5f0;
  border-radius: 16px;
  background: #f8fafc;
}

.doctor-workbench__queue-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.doctor-workbench__queue-title {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 10px;
}

.doctor-workbench__queue-title strong {
  color: #0f172a;
  font-size: 18px;
}

.doctor-workbench__queue-title span,
.doctor-workbench__queue-head p,
.doctor-workbench__queue-hint,
.doctor-workbench__state p,
.doctor-workbench__note-card p,
.doctor-workbench__note-card span,
.doctor-workbench__hint {
  margin: 0;
  color: #64748b;
  line-height: 1.6;
}

.doctor-workbench__queue-meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin: 0;
}

.doctor-workbench__queue-meta div,
.doctor-workbench__summary-card,
.doctor-workbench__note-card,
.doctor-workbench__overview-item {
  padding: 14px;
  border-radius: 14px;
  background: #ffffff;
  border: 1px solid #dbe5f0;
}

.doctor-workbench__queue-meta dt,
.doctor-workbench__summary-card span,
.doctor-workbench__overview-item span {
  color: #64748b;
  font-size: 12px;
}

.doctor-workbench__queue-meta dd,
.doctor-workbench__summary-card strong,
.doctor-workbench__note-card strong,
.doctor-workbench__overview-item strong,
.doctor-workbench__state strong {
  margin: 0;
  color: #0f172a;
}

.doctor-workbench__queue-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}

.doctor-workbench__summary-card,
.doctor-workbench__overview {
  display: grid;
  gap: 12px;
}

.doctor-workbench__note-card {
  display: grid;
  gap: 6px;
}

.doctor-workbench__note-card.is-muted {
  background: #f8fafc;
}

.doctor-workbench__overview {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.doctor-workbench__overview-item {
  display: grid;
  gap: 6px;
}

.doctor-workbench__hint {
  margin-top: 14px;
  padding: 14px;
  border-radius: 14px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  color: #1e3a8a;
}

.doctor-workbench__state {
  display: grid;
  gap: 10px;
  justify-items: start;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.doctor-workbench__state.is-error {
  background: #fff7ed;
  border-color: #fdba74;
}

@media (max-width: 1180px) {
  .doctor-workbench__workspace {
    grid-template-columns: 1fr;
  }

  .doctor-workbench__hero {
    flex-direction: column;
  }

  .doctor-workbench__hero-metrics {
    min-width: 0;
  }
}

@media (max-width: 720px) {
  .doctor-workbench__hero-metrics,
  .doctor-workbench__overview,
  .doctor-workbench__queue-meta {
    grid-template-columns: 1fr;
  }

  .doctor-workbench__queue-head,
  .doctor-workbench__queue-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .doctor-workbench__actions {
    justify-content: stretch;
  }

  .doctor-workbench__actions button,
  .doctor-workbench__queue-actions button {
    width: 100%;
  }
}
</style>
