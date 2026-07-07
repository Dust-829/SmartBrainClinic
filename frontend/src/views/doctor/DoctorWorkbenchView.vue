<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'

import { doctorApi, type DoctorCallNextResult, type DoctorQueueItem } from '@/api/doctor'
import SectionCard from '@/components/common/SectionCard.vue'
import { useDoctorSessionStore } from '@/stores/doctorSession'

const router = useRouter()
const session = useDoctorSessionStore()
const queueItems = ref<DoctorQueueItem[]>([])
const loading = ref(false)
const errorMessage = ref('')
const callingNext = ref(false)
const actionRegisterUuid = ref('')
const lastCalled = ref<DoctorCallNextResult | null>(null)

const doctor = computed(() => session.staff)
const hasIdentity = computed(() => Boolean(doctor.value?.employeeUuid))
const queueCount = computed(() => queueItems.value.length)
const waitingCount = computed(() => queueItems.value.filter((item) => item.visit_state === 1).length)
const inReceptionCount = computed(() => queueItems.value.filter((item) => item.visit_state === 2).length)

const aiBlocks = [
  'AI 病历草稿',
  '相似病历召回',
  '检查检验建议',
  '影像辅助判断',
  '处方推荐',
]

function tagType(visitState: number) {
  if (visitState === 2) return 'success'
  if (visitState === 1) return 'warning'
  return 'info'
}

function visitTimeLabel(item: DoctorQueueItem) {
  return [item.visit_date, item.time_range].filter(Boolean).join(' ') || '时间待确认'
}

function symptomLabel(item: DoctorQueueItem) {
  return item.symptoms?.trim() || '患者暂未填写症状描述'
}

function canStartReception(item: DoctorQueueItem) {
  return item.visit_state === 1
}

function canContinueEncounter(item: DoctorQueueItem) {
  return item.visit_state === 2
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

async function loadQueue() {
  queueItems.value = []
  errorMessage.value = ''

  if (!doctor.value?.employeeUuid) return

  loading.value = true
  try {
    const response = await doctorApi.getQueue(doctor.value.employeeUuid)
    queueItems.value = response.data.data ?? []
  } catch {
    errorMessage.value = '今日候诊列表加载失败，请稍后重试。'
  } finally {
    loading.value = false
  }
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
      ElMessage.info(result?.message || '当前没有可叫号患者')
    }

    await loadQueue()
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
  } finally {
    actionRegisterUuid.value = ''
  }
}

watch(
  () => doctor.value?.employeeUuid,
  () => {
    loadQueue()
  },
  { immediate: true },
)
</script>

<template>
  <div class="doctor-workbench">
    <section class="doctor-workbench__hero">
      <div>
        <span>当前接诊身份</span>
        <h2>{{ doctor?.displayName || '未登录医生' }}</h2>
        <p>{{ doctor?.deptName || '登录后会在这里显示真实科室，并带入医生候诊队列查询。' }}</p>
      </div>
      <div class="doctor-workbench__hero-metrics">
        <strong>{{ queueCount }} 位候诊/接诊中</strong>
        <p>待接诊 {{ waitingCount }} 位 · 接诊中 {{ inReceptionCount }} 位</p>
      </div>
    </section>

    <div class="doctor-workbench__human">
      <SectionCard title="今日候诊列表" subtitle="已接真实接口，并补上叫下一位和开始接诊操作。">
        <template #extra>
          <div class="doctor-workbench__actions">
            <button
              type="button"
              class="doctor-workbench__call-next"
              :disabled="callingNext || !hasIdentity || !waitingCount"
              @click="handleCallNext"
            >
              {{ callingNext ? '叫号中...' : '叫下一位' }}
            </button>
            <button type="button" class="doctor-workbench__refresh" :disabled="loading || !hasIdentity" @click="loadQueue">
              {{ loading ? '刷新中...' : '刷新队列' }}
            </button>
          </div>
        </template>

        <div v-if="!hasIdentity" class="doctor-workbench__state">
          <strong>当前没有有效医生身份</strong>
          <p>请先从医生登录页选择真实医生后，再进入工作台读取候诊队列。</p>
        </div>

        <el-skeleton v-else :loading="loading" animated :rows="5">
          <template #default>
            <div v-if="lastCalled?.called" class="doctor-workbench__callout">
              <span>最近叫号</span>
              <strong>{{ lastCalled.patient_name }}</strong>
              <p>
                {{ lastCalled.patient_case_number || '门诊号待确认' }}
                <template v-if="lastCalled.time_range"> · {{ lastCalled.time_range }}</template>
              </p>
            </div>

            <div v-if="errorMessage" class="doctor-workbench__state is-error">
              <strong>{{ errorMessage }}</strong>
              <button type="button" @click="loadQueue">重新加载</button>
            </div>

            <div v-else-if="queueItems.length" class="doctor-workbench__queue">
              <article v-for="item in queueItems" :key="item.register_uuid" class="doctor-workbench__queue-item">
                <div class="doctor-workbench__queue-main">
                  <div class="doctor-workbench__queue-head">
                    <div>
                      <strong>{{ item.patient_name }}</strong>
                      <p>门诊号 {{ item.patient_case_number }}</p>
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

                  <p class="doctor-workbench__symptom">症状：{{ symptomLabel(item) }}</p>

                  <div class="doctor-workbench__queue-actions">
                    <button
                      v-if="canStartReception(item)"
                      type="button"
                      class="doctor-workbench__start"
                      :disabled="isActionLoading(item.register_uuid)"
                      @click="handleStartReception(item)"
                    >
                      {{ isActionLoading(item.register_uuid) ? '接诊中...' : '开始接诊' }}
                    </button>
                    <button
                      v-else-if="canContinueEncounter(item)"
                      type="button"
                      class="doctor-workbench__continue"
                      @click="openEncounter(item)"
                    >
                      继续接诊
                    </button>
                    <span v-else class="doctor-workbench__queue-hint">当前患者暂不可接诊</span>
                  </div>
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

    <div class="doctor-workbench__ai">
      <SectionCard title="AI 辅助区" subtitle="这一列暂时保持静态占位，后续再接 AI 病历、相似病例与处方建议。">
        <div class="doctor-workbench__ai-grid">
          <div v-for="block in aiBlocks" :key="block" class="doctor-workbench__ai-block">
            <strong>{{ block }}</strong>
            <span>静态占位</span>
          </div>
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.doctor-workbench {
  min-height: calc(100vh - 48px);
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(320px, 0.9fr);
  gap: 20px;
}

.doctor-workbench__hero {
  grid-column: 1 / -1;
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  padding: 22px 24px;
  border-radius: 18px;
  background: linear-gradient(135deg, #0f766e, #0f9b8e);
  color: #ffffff;
}

.doctor-workbench__hero span,
.doctor-workbench__hero p {
  color: rgba(255, 255, 255, 0.88);
}

.doctor-workbench__hero h2,
.doctor-workbench__hero p {
  margin: 0;
}

.doctor-workbench__hero h2 {
  margin-top: 6px;
  font-size: 28px;
}

.doctor-workbench__hero strong {
  white-space: nowrap;
  font-size: 28px;
}

.doctor-workbench__hero-metrics {
  display: grid;
  gap: 4px;
  justify-items: end;
}

.doctor-workbench__hero-metrics p {
  margin: 0;
}

.doctor-workbench__actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}

.doctor-workbench__call-next,
.doctor-workbench__refresh,
.doctor-workbench__start,
.doctor-workbench__continue,
.doctor-workbench__state button {
  min-height: 38px;
  padding: 0 14px;
  border: 0;
  border-radius: 10px;
  background: #0f766e;
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.doctor-workbench__call-next:disabled,
.doctor-workbench__refresh:disabled,
.doctor-workbench__start:disabled,
.doctor-workbench__continue:disabled,
.doctor-workbench__state button:disabled {
  opacity: 0.68;
  cursor: not-allowed;
}

.doctor-workbench__queue,
.doctor-workbench__ai-grid {
  display: grid;
  gap: 12px;
}

.doctor-workbench__callout {
  display: grid;
  gap: 4px;
  margin-bottom: 12px;
  padding: 14px 16px;
  border: 1px solid #bfdbfe;
  border-radius: 14px;
  background: linear-gradient(180deg, #eff6ff 0%, #f8fbff 100%);
}

.doctor-workbench__callout span {
  color: #0369a1;
  font-size: 12px;
  font-weight: 700;
}

.doctor-workbench__callout strong,
.doctor-workbench__callout p {
  margin: 0;
}

.doctor-workbench__queue-item {
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 14px;
  background: #f8fafc;
}

.doctor-workbench__queue-main {
  display: grid;
  gap: 12px;
}

.doctor-workbench__queue-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.doctor-workbench__queue-head strong {
  font-size: 18px;
  color: #0f172a;
}

.doctor-workbench__queue-head p,
.doctor-workbench__symptom,
.doctor-workbench__state p {
  margin: 0;
  color: #64748b;
  line-height: 1.6;
}

.doctor-workbench__queue-meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin: 0;
}

.doctor-workbench__queue-meta div {
  display: grid;
  gap: 4px;
  padding: 10px 12px;
  border-radius: 10px;
  background: #ffffff;
}

.doctor-workbench__queue-meta dt {
  color: #64748b;
  font-size: 12px;
}

.doctor-workbench__queue-meta dd {
  margin: 0;
  color: #0f172a;
  font-weight: 700;
}

.doctor-workbench__symptom {
  padding-top: 12px;
  border-top: 1px solid #dbe5f0;
}

.doctor-workbench__queue-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
}

.doctor-workbench__start {
  min-width: 108px;
}

.doctor-workbench__continue {
  min-width: 108px;
  background: #1d4ed8;
}

.doctor-workbench__queue-hint {
  color: #0f766e;
  font-size: 13px;
  font-weight: 700;
}

.doctor-workbench__state {
  display: grid;
  gap: 10px;
  justify-items: start;
  padding: 18px;
  border-radius: 14px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}

.doctor-workbench__state strong {
  color: #0f172a;
}

.doctor-workbench__state.is-error {
  background: #fff7ed;
  border-color: #fdba74;
}

.doctor-workbench__ai-block {
  min-height: 84px;
  display: grid;
  align-content: center;
  gap: 8px;
  padding: 14px;
  border-radius: 8px;
  background: #ecfeff;
  color: #134e4a;
  border: 1px solid #99f6e4;
}

.doctor-workbench__ai-block strong,
.doctor-workbench__ai-block span {
  margin: 0;
}

.doctor-workbench__ai-block span {
  font-size: 13px;
  color: #0f766e;
}

@media (max-width: 1100px) {
  .doctor-workbench {
    grid-template-columns: 1fr;
  }

  .doctor-workbench__hero {
    align-items: flex-start;
    flex-direction: column;
  }

  .doctor-workbench__hero-metrics,
  .doctor-workbench__actions,
  .doctor-workbench__queue-actions {
    justify-items: start;
    justify-content: flex-start;
  }

  .doctor-workbench__queue-meta {
    grid-template-columns: 1fr;
  }
}
</style>
