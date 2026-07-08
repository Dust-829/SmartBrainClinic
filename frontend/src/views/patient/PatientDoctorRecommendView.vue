<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { authApi, type DoctorDirectoryItem } from '@/api/auth'
import { patientApi, type DoctorRecommendation } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientSessionStore } from '@/stores/patientSession'

interface DoctorDirectoryCard {
  doctor_uuid: string
  doctor_name: string
  specialties: string[]
  gender?: string | null
  isAvailable: boolean
  recommendation: DoctorRecommendation | null
}

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const loading = ref(false)
const errorMessage = ref('')
const doctors = ref<DoctorDirectoryCard[]>([])

const deptCode = computed(() => flow.recommendedDeptCode)
const symptoms = computed(() => flow.symptoms)
const availableDoctors = computed(() => doctors.value.filter((doctor) => doctor.isAvailable))

const departmentNames: Record<string, string> = {
  SJWK: '神经外科',
  XNK: '心内科',
  GK: '骨科',
  EK: '儿科',
  FCK: '妇产科',
}

const departmentLabel = computed(() => {
  if (!deptCode.value) return '待确认'
  if (flow.manualDeptName) return flow.manualDeptName
  const name = departmentNames[deptCode.value]
  return name || deptCode.value
})

onMounted(async () => {
  if (!session.patient) {
    router.replace('/patient/login')
    return
  }
  if (!deptCode.value) {
    router.replace('/patient/triage')
    return
  }
  await loadDoctors()
})

async function loadDoctors() {
  loading.value = true
  errorMessage.value = ''
  try {
    const directoryResponse = await authApi.listDoctorsByDepartmentCode(deptCode.value)
    const directoryDoctors = Array.isArray(directoryResponse.data.data) ? directoryResponse.data.data : []

    const recommendationResponse = await patientApi.recommendDoctors({
      dept_code: deptCode.value,
      symptoms: symptoms.value,
      gender_preference: flow.triageData?.gender_preference || '不限',
      limit: Math.max(directoryDoctors.length, 5),
    })
    const recommendations = Array.isArray(recommendationResponse.data.data) ? recommendationResponse.data.data : []
    const recommendationMap = new Map(recommendations.map((item) => [item.doctor_uuid, item] as const))

    doctors.value = directoryDoctors
      .map((doctor) => normalizeDoctorCard(doctor, recommendationMap.get(doctor.uuid) || null))
      .sort(sortDoctorCards)

    flow.setRecommendations(recommendations)
  } catch (error) {
    doctors.value = []
    flow.setRecommendations([])
    errorMessage.value = '医生列表加载失败，请检查后端服务后重试。'
  } finally {
    loading.value = false
  }
}

function normalizeDoctorCard(doctor: DoctorDirectoryItem, recommendation: DoctorRecommendation | null): DoctorDirectoryCard {
  const specialties = doctor.expertise
    ? doctor.expertise
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean)
    : ['暂未维护专长信息']

  return {
    doctor_uuid: doctor.uuid,
    doctor_name: doctor.realname,
    specialties,
    gender: doctor.gender,
    isAvailable: Boolean(recommendation),
    recommendation,
  }
}

function sortDoctorCards(a: DoctorDirectoryCard, b: DoctorDirectoryCard) {
  if (a.isAvailable !== b.isAvailable) return a.isAvailable ? -1 : 1
  const aScore = a.recommendation?.match_score ?? -1
  const bScore = b.recommendation?.match_score ?? -1
  if (aScore !== bScore) return bScore - aScore
  return a.doctor_name.localeCompare(b.doctor_name, 'zh-CN')
}

function goBack() {
  router.push(flow.triageResult ? '/patient/triage' : '/patient/departments')
}

function chooseDoctor(doctor: DoctorDirectoryCard) {
  if (!doctor.recommendation) {
    ElMessage.info('该医生当前暂无可挂号源，请选择其他医生')
    return
  }
  flow.selectDoctor(doctor.recommendation)
  router.push('/patient/confirm-register')
}
</script>

<template>
  <div class="patient-doctors">
    <PatientFlowHeader
      title="医生推荐"
      :subtitle="`推荐科室：${departmentLabel}`"
      back-label="返回科室选择"
      @back="goBack"
    />

    <main class="patient-doctors__content">
      <SectionCard title="科室医生" subtitle="先展示本科室全量医生，再区分当前可挂号与暂无号源。">
        <el-skeleton :loading="loading" animated>
          <template #template>
            <div class="patient-doctors__list">
              <el-skeleton-item v-for="item in 3" :key="item" variant="rect" class="patient-doctors__skeleton" />
            </div>
          </template>
          <template #default>
            <div class="patient-doctors__list">
              <div v-if="errorMessage" class="patient-doctors__feedback is-error">
                <strong>{{ errorMessage }}</strong>
                <el-button :loading="loading" @click="loadDoctors">重新加载</el-button>
              </div>

              <article
                v-for="doctor in doctors"
                :key="doctor.doctor_uuid"
                :class="['patient-doctors__card', { 'is-disabled': !doctor.isAvailable }]"
              >
                <div class="patient-doctors__head">
                  <div>
                    <h3>{{ doctor.doctor_name }}</h3>
                    <p v-if="doctor.recommendation">
                      {{ doctor.recommendation.schedule_date }} · {{ doctor.recommendation.noon }} · 最早
                      {{ doctor.recommendation.earliest_time_slot }}
                    </p>
                    <p v-else>当前 7 天内暂无可预约号源</p>
                  </div>
                  <strong :class="['patient-doctors__status', { 'is-unavailable': !doctor.isAvailable }]">
                    {{ doctor.isAvailable ? '可挂号' : '暂无号源' }}
                  </strong>
                </div>

                <div class="patient-doctors__tags">
                  <el-tag v-for="tag in doctor.specialties" :key="tag" size="small">{{ tag }}</el-tag>
                </div>

                <div v-if="doctor.recommendation" class="patient-doctors__meta">
                  <span>余号 {{ doctor.recommendation.remaining_quota }}</span>
                  <span>挂号费 ¥{{ doctor.recommendation.regist_fee }}</span>
                  <span>匹配度 {{ doctor.recommendation.match_score }}</span>
                </div>
                <div v-else class="patient-doctors__meta is-muted">
                  <span>当前不可预约</span>
                  <span>可保留用于改日挂号</span>
                </div>

                <el-button type="primary" :disabled="!doctor.isAvailable" @click="chooseDoctor(doctor)">
                  {{ doctor.isAvailable ? '选择医生' : '暂无可挂号源' }}
                </el-button>
              </article>

              <el-empty v-if="!errorMessage && !doctors.length" description="当前科室暂无医生信息" :image-size="90">
                <el-button :loading="loading" @click="loadDoctors">重新加载</el-button>
              </el-empty>
              <el-empty
                v-else-if="!errorMessage && doctors.length && !availableDoctors.length"
                description="本科室医生已展示，但当前都暂无可挂号源"
                :image-size="90"
              >
                <el-button :loading="loading" @click="loadDoctors">刷新号源</el-button>
              </el-empty>
            </div>
          </template>
        </el-skeleton>
      </SectionCard>
    </main>
  </div>
</template>

<style scoped>
.patient-doctors {
  min-height: 100vh;
  padding-bottom: 24px;
  background:
    radial-gradient(circle at 88% 4%, rgba(78, 167, 255, 0.2), transparent 30%),
    linear-gradient(180deg, #eaf4ff 0%, #f7fbff 44%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-doctors__content {
  margin-top: -22px;
  padding: 0 var(--patient-page-gutter) 24px;
}

.patient-doctors__list {
  display: grid;
  gap: 12px;
}

.patient-doctors__skeleton {
  width: 100%;
  height: 150px;
  border-radius: 14px;
}

.patient-doctors__card {
  display: grid;
  gap: 12px;
  padding: 14px;
  border: 1px solid #dbeafe;
  border-radius: 14px;
  background: #ffffff;
}

.patient-doctors__card.is-disabled {
  border-color: #d7dee8;
  background: #f8fafc;
}

.patient-doctors__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.patient-doctors__head h3,
.patient-doctors__head p {
  margin: 0;
}

.patient-doctors__head h3 {
  font-size: 17px;
  letter-spacing: 0;
}

.patient-doctors__head p,
.patient-doctors__meta {
  color: #64748b;
  font-size: 13px;
}

.patient-doctors__status {
  flex: 0 0 auto;
  color: #0f766e;
  font-size: 14px;
}

.patient-doctors__status.is-unavailable {
  color: #94a3b8;
}

.patient-doctors__tags,
.patient-doctors__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.patient-doctors__meta.is-muted {
  color: #94a3b8;
}

.patient-doctors__feedback {
  display: grid;
  gap: 12px;
  padding: 16px;
  border-radius: 14px;
}

.patient-doctors__feedback.is-error {
  border: 1px solid #fca5a5;
  background: #fff1f2;
}

.patient-doctors__card :deep(.el-button) {
  width: 100%;
  min-height: 42px;
}
</style>
