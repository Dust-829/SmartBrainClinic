<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { authApi, type DoctorDirectoryItem } from '@/api/auth'
import { patientApi, type DepartmentOption } from '@/api/patient'
import SectionCard from '@/components/common/SectionCard.vue'
import { useDoctorSessionStore } from '@/stores/doctorSession'

const route = useRoute()
const router = useRouter()
const session = useDoctorSessionStore()

const departments = ref<DepartmentOption[]>([])
const doctors = ref<Array<DoctorDirectoryItem & { deptCode: string; deptName: string }>>([])
const selectedDeptCode = ref('')
const selectedDoctorUuid = ref('')
const loading = ref(false)
const errorMessage = ref('')
const submitting = ref(false)

const redirectPath = computed(() => {
  const value = route.query.redirect
  return typeof value === 'string' && value.trim() ? value : '/doctor/workbench'
})

const availableDepartments = computed(() => {
  const doctorDeptCodes = new Set(doctors.value.map((doctor) => doctor.deptCode))
  return departments.value.filter((department) => doctorDeptCodes.has(department.code))
})

const currentDoctors = computed(() =>
  doctors.value.filter((doctor) => doctor.deptCode === selectedDeptCode.value),
)

const selectedDoctor = computed(() =>
  currentDoctors.value.find((doctor) => doctor.uuid === selectedDoctorUuid.value) ?? null,
)

async function loadDoctorDirectory() {
  loading.value = true
  errorMessage.value = ''

  try {
    const departmentResponse = await patientApi.getDepartments()
    const nextDepartments = departmentResponse.data.data ?? []
    departments.value = nextDepartments

    const doctorResponses = await Promise.all(
      nextDepartments.map(async (department) => {
        const response = await authApi.listDoctorsByDepartmentCode(department.code)
        return (response.data.data ?? []).map((doctor) => ({
          ...doctor,
          deptCode: department.code,
          deptName: department.name,
        }))
      }),
    )

    doctors.value = doctorResponses
      .flat()
      .sort((left, right) => left.realname.localeCompare(right.realname, 'zh-CN'))

    const firstDepartment = availableDepartments.value[0]
    selectedDeptCode.value = firstDepartment?.code ?? ''
    selectedDoctorUuid.value = currentDoctors.value[0]?.uuid ?? ''

    if (!doctors.value.length) {
      errorMessage.value = '当前没有可用于演示登录的真实医生数据。'
    }
  } catch {
    errorMessage.value = '医生目录加载失败，请稍后重试。'
  } finally {
    loading.value = false
  }
}

function syncDoctorSelection() {
  if (!currentDoctors.value.length) {
    selectedDoctorUuid.value = ''
    return
  }

  const exists = currentDoctors.value.some((doctor) => doctor.uuid === selectedDoctorUuid.value)
  if (!exists) {
    selectedDoctorUuid.value = currentDoctors.value[0].uuid
  }
}

function submit() {
  if (!selectedDoctor.value) return

  submitting.value = true
  try {
    session.login({
      displayName: selectedDoctor.value.realname,
      employeeUuid: selectedDoctor.value.uuid,
      deptCode: selectedDoctor.value.deptCode,
      deptName: selectedDoctor.value.deptName,
    })
    router.replace(redirectPath.value)
  } finally {
    submitting.value = false
  }
}

onMounted(loadDoctorDirectory)
</script>

<template>
  <div class="doctor-login">
    <div class="doctor-login__hero">
      <span class="doctor-login__eyebrow">智慧云脑诊疗平台</span>
      <h1>医生登录</h1>
      <p>当前阶段先用真实医生目录承载登录身份，确保工作台能拿到实际 `employee_uuid` 并读取候诊队列。</p>
    </div>

    <SectionCard title="登录工作台" subtitle="选择真实科室与医生后进入医生工作台。">
      <div class="doctor-login__form">
        <div v-if="errorMessage" class="doctor-login__state is-error">
          <strong>{{ errorMessage }}</strong>
          <button type="button" :disabled="loading" @click="loadDoctorDirectory">
            {{ loading ? '重试中...' : '重新加载' }}
          </button>
        </div>

        <template v-else-if="loading">
          <el-skeleton animated :rows="4" />
        </template>

        <template v-else>
          <label>
            <span>科室</span>
            <select v-model="selectedDeptCode" @change="syncDoctorSelection">
              <option v-for="department in availableDepartments" :key="department.code" :value="department.code">
                {{ department.name }}
              </option>
            </select>
          </label>

          <label>
            <span>医生</span>
            <select v-model="selectedDoctorUuid">
              <option v-for="doctor in currentDoctors" :key="doctor.uuid" :value="doctor.uuid">
                {{ doctor.realname }}
              </option>
            </select>
          </label>

          <div v-if="selectedDoctor" class="doctor-login__summary">
            <strong>{{ selectedDoctor.realname }}</strong>
            <p>{{ selectedDoctor.deptName }}</p>
            <span>{{ selectedDoctor.expertise || '暂未维护专长信息' }}</span>
          </div>

          <button type="button" :disabled="submitting || !selectedDoctor" @click="submit">
            {{ submitting ? '进入中...' : '进入医生工作台' }}
          </button>
        </template>
      </div>
    </SectionCard>
  </div>
</template>

<style scoped>
.doctor-login {
  display: grid;
  gap: 20px;
  max-width: 560px;
}

.doctor-login__hero {
  display: grid;
  gap: 10px;
}

.doctor-login__eyebrow {
  color: #0f766e;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.doctor-login__hero h1,
.doctor-login__hero p {
  margin: 0;
}

.doctor-login__hero h1 {
  color: #0f172a;
  font-size: 34px;
  line-height: 1.1;
}

.doctor-login__hero p {
  color: #475569;
  line-height: 1.7;
}

.doctor-login__form {
  display: grid;
  gap: 14px;
}

.doctor-login__form label {
  display: grid;
  gap: 8px;
}

.doctor-login__form span {
  color: #334155;
  font-size: 14px;
  font-weight: 600;
}

.doctor-login__form select {
  min-height: 46px;
  padding: 0 14px;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  outline: 0;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
}

.doctor-login__form select:focus {
  border-color: #0f766e;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.12);
}

.doctor-login__summary,
.doctor-login__state {
  display: grid;
  gap: 6px;
  padding: 14px;
  border-radius: 12px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}

.doctor-login__summary strong,
.doctor-login__state strong {
  color: #0f172a;
}

.doctor-login__summary p,
.doctor-login__summary span {
  margin: 0;
  color: #475569;
}

.doctor-login__state.is-error {
  background: #fff7ed;
  border-color: #fdba74;
}

.doctor-login__form button {
  min-height: 46px;
  border: 0;
  border-radius: 10px;
  background: linear-gradient(135deg, #0f766e, #0f9b8e);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.doctor-login__form button:disabled {
  opacity: 0.7;
}
</style>
