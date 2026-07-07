<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { patientApi } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const loading = ref(false)

const deptCode = computed(() => flow.recommendedDeptCode)
const symptoms = computed(() => flow.symptoms)

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
  if (!flow.recommendations.length) await loadRecommendations()
})

async function loadRecommendations() {
  loading.value = true
  try {
    const response = await patientApi.recommendDoctors({
      dept_code: deptCode.value,
      symptoms: symptoms.value,
      gender_preference: flow.triageData?.gender_preference || '不限',
      limit: 5,
    })
    flow.setRecommendations(response.data.data || [])
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push(flow.triageResult ? '/patient/triage' : '/patient/departments')
}

function chooseDoctor(index: number) {
  const doctor = flow.recommendations[index]
  if (!doctor) return
  flow.selectDoctor(doctor)
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
      <SectionCard title="可预约医生" subtitle="根据科室、余号和症状匹配结果推荐">
        <el-skeleton :loading="loading" animated>
          <template #template>
            <div class="patient-doctors__list">
              <el-skeleton-item v-for="item in 3" :key="item" variant="rect" class="patient-doctors__skeleton" />
            </div>
          </template>
          <template #default>
            <div class="patient-doctors__list">
              <article
                v-for="(doctor, index) in flow.recommendations"
                :key="doctor.doctor_uuid"
                class="patient-doctors__card"
              >
                <div class="patient-doctors__head">
                  <div>
                    <h3>{{ doctor.doctor_name }}</h3>
                    <p>{{ doctor.schedule_date }} · {{ doctor.noon }} · 最早 {{ doctor.earliest_time_slot }}</p>
                  </div>
                  <strong>{{ doctor.match_score }}</strong>
                </div>
                <div class="patient-doctors__tags">
                  <el-tag v-for="tag in doctor.specialties" :key="tag" size="small">{{ tag }}</el-tag>
                </div>
                <div class="patient-doctors__meta">
                  <span>余号 {{ doctor.remaining_quota }}</span>
                  <span>挂号费 ¥{{ doctor.regist_fee }}</span>
                  <span>语义匹配 {{ doctor.similarity_score }}</span>
                </div>
                <el-button type="primary" @click="chooseDoctor(index)">选择医生</el-button>
              </article>
              <el-empty v-if="!flow.recommendations.length" description="暂无可挂号医生" :image-size="90">
                <el-button :loading="loading" @click="loadRecommendations">重新推荐</el-button>
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

.patient-doctors__head strong {
  flex: 0 0 auto;
  color: #0f766e;
  font-size: 22px;
}

.patient-doctors__tags,
.patient-doctors__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.patient-doctors__card :deep(.el-button) {
  width: 100%;
  min-height: 42px;
}
</style>
