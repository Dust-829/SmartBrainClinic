<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { patientApi, type DoctorSchedule } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientSessionStore } from '@/stores/patientSession'

interface DateOption {
  date: string
  label: string
  weekday: string
  remaining: number
}

interface NoonOption {
  label: string
  value: string
  remaining: number
  range: string
}

interface TimeOption {
  uuid: string
  range: string
  start: string
  remaining: number
}

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const loading = ref(false)
const submitting = ref(false)
const selectedDate = ref('')
const selectedNoon = ref('')
const showAllTimes = ref(false)

const availableSchedules = computed(() =>
  flow.doctorSchedules
    .map((schedule) => ({
      ...schedule,
      time_slots: schedule.time_slots
        .filter((slot) => !slot.is_booked)
        .sort((a, b) => a.time_range.localeCompare(b.time_range)),
    }))
    .filter((schedule) => schedule.time_slots.length > 0)
    .sort((a, b) => {
      if (a.schedule_date !== b.schedule_date) return a.schedule_date.localeCompare(b.schedule_date)
      return noonOrder(a.noon) - noonOrder(b.noon)
    }),
)

const dateOptions = computed<DateOption[]>(() => {
  const dateMap = new Map<string, DateOption>()
  for (const schedule of availableSchedules.value) {
    const current = dateMap.get(schedule.schedule_date)
    if (current) {
      current.remaining += schedule.time_slots.length
    } else {
      dateMap.set(schedule.schedule_date, {
        date: schedule.schedule_date,
        label: formatDateLabel(schedule.schedule_date),
        weekday: formatWeekday(schedule.schedule_date),
        remaining: schedule.time_slots.length,
      })
    }
  }
  return [...dateMap.values()].sort((a, b) => a.date.localeCompare(b.date))
})

const noonOptions = computed<NoonOption[]>(() => {
  const noonMap = new Map<string, NoonOption>()
  for (const schedule of availableSchedules.value.filter((item) => item.schedule_date === selectedDate.value)) {
    const current = noonMap.get(schedule.noon)
    if (current) {
      current.remaining += schedule.time_slots.length
    } else {
      noonMap.set(schedule.noon, {
        label: formatNoonLabel(schedule.noon),
        value: schedule.noon,
        remaining: schedule.time_slots.length,
        range: formatSessionRange(schedule.noon),
      })
    }
  }
  return [...noonMap.values()].sort((a, b) => noonOrder(a.value) - noonOrder(b.value))
})

const selectedSchedule = computed<DoctorSchedule | null>(() =>
  availableSchedules.value.find(
    (schedule) => schedule.schedule_date === selectedDate.value && schedule.noon === selectedNoon.value,
  ) || null,
)

const timeOptions = computed<TimeOption[]>(() => {
  const buckets = new Map<string, { uuid: string; starts: string[] }>()
  for (const slot of selectedSchedule.value?.time_slots || []) {
    const start = slot.time_range.split('-')[0] || slot.time_range
    const bucketStart = getBucketStart(start)
    const current = buckets.get(bucketStart)
    if (current) {
      current.starts.push(start)
    } else {
      buckets.set(bucketStart, { uuid: slot.uuid, starts: [start] })
    }
  }

  return [...buckets.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([bucketStart, item]) => {
      const bucketEnd = addMinutes(bucketStart, 30)
      return {
        uuid: item.uuid,
        range: `${bucketStart}-${bucketEnd}`,
        start: bucketStart,
        remaining: item.starts.length,
      }
    })
})

const visibleTimeOptions = computed(() => (showAllTimes.value ? timeOptions.value : timeOptions.value.slice(0, 8)))

const selectedTime = computed(() => timeOptions.value.find((item) => item.uuid === flow.selectedTimeSlotUuid) || null)

const selectedNoonMeta = computed(() => noonOptions.value.find((item) => item.value === selectedNoon.value) || null)

const suggestedArrival = computed(() => {
  if (!selectedTime.value) return ''
  return formatSuggestedArrival(selectedTime.value.range)
})

onMounted(async () => {
  if (!session.patient) {
    router.replace('/patient/login')
    return
  }
  if (!flow.selectedDoctor) {
    router.replace('/patient/doctors')
    return
  }
  await loadSchedules()
})

watch(selectedDate, () => {
  const firstNoon = noonOptions.value[0]
  selectedNoon.value = firstNoon?.value || ''
  showAllTimes.value = false
})

watch(selectedNoon, () => {
  const firstTime = timeOptions.value[0]
  flow.selectTimeSlot(firstTime?.uuid || '')
  showAllTimes.value = false
})

async function loadSchedules() {
  if (!flow.selectedDoctor) return
  loading.value = true
  try {
    const response = await patientApi.getDoctorSchedules(flow.selectedDoctor.doctor_uuid)
    flow.setDoctorSchedules(response.data.data || [])
    selectedDate.value = dateOptions.value[0]?.date || ''
    selectedNoon.value = noonOptions.value[0]?.value || ''
    flow.selectTimeSlot(timeOptions.value[0]?.uuid || '')
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push('/patient/doctors')
}

async function submit() {
  if (!session.patient || !flow.selectedDoctor || !flow.selectedTimeSlotUuid) {
    ElMessage.warning('请选择就诊日期、午别和时间')
    return
  }
  submitting.value = true
  try {
    const response = await patientApi.createOnlineRegister({
      patient_uuid: session.patient.uuid,
      employee_uuid: flow.selectedDoctor.doctor_uuid,
      scheduling_time_slot_uuid: flow.selectedTimeSlotUuid,
      triage_session_uuid: flow.triageSessionUuid || undefined,
      symptoms: flow.symptoms,
      is_emergency: false,
    })
    flow.setOnlineRegister(response.data.data)
    ElMessage.success('号源已锁定，请完成支付')
    router.push('/patient/payment')
  } finally {
    submitting.value = false
  }
}

function chooseDate(date: string) {
  selectedDate.value = date
}

function chooseTime(uuid: string) {
  flow.selectTimeSlot(uuid)
}

function formatDateLabel(value: string) {
  const date = parseDate(value)
  if (!date) return value
  return new Intl.DateTimeFormat('zh-CN', { month: '2-digit', day: '2-digit' }).format(date)
}

function formatWeekday(value: string) {
  const date = parseDate(value)
  if (!date) return ''
  return new Intl.DateTimeFormat('zh-CN', { weekday: 'short' }).format(date)
}

function parseDate(value: string) {
  const date = new Date(`${value}T00:00:00`)
  return Number.isNaN(date.getTime()) ? null : date
}

function formatNoonLabel(noon: string) {
  if (noon.includes('上午')) return '上午'
  if (noon.includes('下午')) return '下午'
  if (noon.includes('夜')) return '夜诊'
  return noon
}

function formatSessionRange(noon: string) {
  if (noon.includes('上午')) return '08:00-12:00'
  if (noon.includes('下午')) return '13:00-17:00'
  if (noon.includes('夜')) return '18:00-21:00'
  return '以医院通知为准'
}

function formatSuggestedArrival(timeRange: string) {
  const start = timeRange.split('-')[0] || ''
  if (!/^\d{2}:\d{2}$/.test(start)) return '按预约时间提前到院'
  const [hour, minute] = start.split(':').map(Number)
  const arrival = new Date(2026, 0, 1, hour, minute)
  const end = new Date(arrival.getTime() + 30 * 60 * 1000)
  return `${formatTime(arrival)}-${formatTime(end)}`
}

function formatTime(date: Date) {
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
}

function getBucketStart(time: string) {
  if (!/^\d{2}:\d{2}$/.test(time)) return time
  const [hour, minute] = time.split(':').map(Number)
  const bucketMinute = minute < 30 ? 0 : 30
  return `${String(hour).padStart(2, '0')}:${String(bucketMinute).padStart(2, '0')}`
}

function addMinutes(time: string, minutesToAdd: number) {
  if (!/^\d{2}:\d{2}$/.test(time)) return time
  const [hour, minute] = time.split(':').map(Number)
  const date = new Date(2026, 0, 1, hour, minute + minutesToAdd)
  return formatTime(date)
}

function noonOrder(noon: string) {
  if (noon.includes('上午')) return 0
  if (noon.includes('下午')) return 1
  if (noon.includes('夜')) return 2
  return 3
}
</script>

<template>
  <div class="patient-confirm">
    <PatientFlowHeader
      title="确认挂号"
      subtitle="按日期、午别和时间依次选择"
      back-label="返回医生推荐"
      @back="goBack"
    />
    <main class="patient-confirm__content">
      <SectionCard title="选择就诊时间" subtitle="按日期、午别和时间依次选择，避免一次展示过多号源。">
      <div v-if="flow.selectedDoctor" class="patient-confirm__doctor">
        <h3>{{ flow.selectedDoctor.doctor_name }}</h3>
        <p>挂号费 ¥{{ flow.selectedDoctor.regist_fee }} · {{ flow.selectedDoctor.specialties.join('、') }}</p>
      </div>

      <el-skeleton :loading="loading" animated>
        <template #template>
          <div class="patient-confirm__skeletons">
            <el-skeleton-item variant="rect" style="height: 74px; border-radius: 8px" />
            <el-skeleton-item variant="rect" style="height: 52px; border-radius: 8px" />
            <el-skeleton-item variant="rect" style="height: 140px; border-radius: 8px" />
          </div>
        </template>
        <template #default>
          <div v-if="dateOptions.length" class="patient-confirm__flow">
            <section class="patient-confirm__step">
              <div class="patient-confirm__step-head">
                <strong>1. 选择日期</strong>
                <span>未来可预约日期</span>
              </div>
              <div class="patient-confirm__date-list">
                <button
                  v-for="date in dateOptions"
                  :key="date.date"
                  type="button"
                  :class="['patient-confirm__date', { 'is-active': selectedDate === date.date }]"
                  @click="chooseDate(date.date)"
                >
                  <strong>{{ date.label }}</strong>
                  <span>{{ date.weekday }}</span>
                  <em>余 {{ date.remaining }}</em>
                </button>
              </div>
            </section>

            <section class="patient-confirm__step">
              <div class="patient-confirm__step-head">
                <strong>2. 选择午别</strong>
                <span>{{ selectedNoonMeta?.range || '请选择日期' }}</span>
              </div>
              <div class="patient-confirm__noon-list">
                <button
                  v-for="noon in noonOptions"
                  :key="noon.value"
                  type="button"
                  :class="['patient-confirm__noon', { 'is-active': selectedNoon === noon.value }]"
                  @click="selectedNoon = noon.value"
                >
                  <strong>{{ noon.label }}</strong>
                  <span>{{ noon.range }}</span>
                  <em>余号 {{ noon.remaining }}</em>
                </button>
              </div>
            </section>

            <section class="patient-confirm__step">
              <div class="patient-confirm__step-head">
                <strong>3. 选择时间</strong>
                <span>按 30 分钟合并展示，减少可选项</span>
              </div>
              <div class="patient-confirm__time-grid">
                <button
                  v-for="time in visibleTimeOptions"
                  :key="time.uuid"
                  type="button"
                  :class="['patient-confirm__time', { 'is-active': flow.selectedTimeSlotUuid === time.uuid }]"
                  @click="chooseTime(time.uuid)"
                >
                  <strong>{{ time.range }}</strong>
                  <em>余 {{ time.remaining }}</em>
                </button>
              </div>
              <button v-if="timeOptions.length > 8" type="button" class="patient-confirm__more" @click="showAllTimes = !showAllTimes">
                {{ showAllTimes ? '收起部分时间' : `展开全部 ${timeOptions.length} 个时间段` }}
              </button>
            </section>
          </div>

          <el-empty v-else description="暂无可预约号源" :image-size="90">
            <el-button :loading="loading" @click="loadSchedules">刷新号源</el-button>
          </el-empty>
        </template>
      </el-skeleton>

      <div v-if="selectedTime" class="patient-confirm__notice">
        已选择 {{ formatDateLabel(selectedDate) }} {{ selectedNoonMeta?.label }} {{ selectedTime.range }}，建议到院 {{ suggestedArrival }}。
      </div>

      <el-button type="primary" size="large" :loading="submitting" :disabled="!flow.selectedTimeSlotUuid" @click="submit">
        确认时间并去支付
      </el-button>
      </SectionCard>
    </main>
  </div>
</template>

<style scoped>
.patient-confirm {
  min-height: 100vh;
  padding-bottom: 24px;
  background: linear-gradient(180deg, #eaf4ff 0%, #f7fbff 46%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-confirm__content {
  margin-top: -22px;
  padding: 0 var(--patient-page-gutter) 24px;
}

.patient-confirm__doctor {
  display: grid;
  gap: 4px;
  padding: 14px;
  border-radius: 8px;
  background: #f0fdfa;
  margin-bottom: 14px;
}

.patient-confirm__doctor h3,
.patient-confirm__doctor p {
  margin: 0;
}

.patient-confirm__doctor h3 {
  font-size: 18px;
  letter-spacing: 0;
}

.patient-confirm__doctor p,
.patient-confirm__step-head span,
.patient-confirm__date span,
.patient-confirm__date em,
.patient-confirm__noon span,
.patient-confirm__noon em,
.patient-confirm__notice {
  color: #64748b;
  font-size: 13px;
}

.patient-confirm__skeletons,
.patient-confirm__flow,
.patient-confirm__step {
  display: grid;
  gap: 12px;
}

.patient-confirm__flow {
  margin-bottom: 14px;
}

.patient-confirm__step {
  padding: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
}

.patient-confirm__step-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
}

.patient-confirm__date-list {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(82px, 1fr);
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 2px;
}

.patient-confirm__date,
.patient-confirm__noon,
.patient-confirm__time,
.patient-confirm__more {
  border: 1px solid #dbeafe;
  border-radius: 8px;
  background: #f8fafc;
  color: #0f172a;
}

.patient-confirm__date {
  display: grid;
  gap: 2px;
  min-height: 72px;
  padding: 9px 10px;
  text-align: center;
}

.patient-confirm__date em,
.patient-confirm__noon em,
.patient-confirm__time em {
  font-style: normal;
}

.patient-confirm__noon-list {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}

.patient-confirm__noon {
  display: grid;
  gap: 3px;
  padding: 11px 12px;
  text-align: left;
}

.patient-confirm__time-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}

.patient-confirm__time {
  display: grid;
  gap: 2px;
  min-height: 54px;
  font-weight: 700;
}

.patient-confirm__time strong {
  font-size: 13px;
}

.patient-confirm__time em {
  color: #64748b;
  font-size: 12px;
}

.patient-confirm__date.is-active,
.patient-confirm__noon.is-active,
.patient-confirm__time.is-active {
  border-color: #14b8a6;
  background: #ecfdf5;
  color: #0f766e;
}

.patient-confirm__more {
  min-height: 38px;
  color: #2563eb;
  background: #eff6ff;
}

.patient-confirm__notice {
  padding: 10px 12px;
  border-radius: 8px;
  background: #f8fafc;
  margin-bottom: 14px;
}

.patient-confirm :deep(.el-button) {
  width: 100%;
  min-height: 44px;
}
</style>
