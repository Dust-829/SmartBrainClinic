<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientAuthHeader from '@/components/patient/PatientAuthHeader.vue'
import { patientApi } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const formRef = ref<FormInstance>()
const loading = ref(false)

const form = reactive({
  real_name: session.loginDraft.realName,
  card_number: session.loginDraft.cardNumber,
})

const rules: FormRules = {
  real_name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  card_number: [
    { required: true, message: '请输入证件号', trigger: 'blur' },
    { max: 18, message: '证件号最多 18 位', trigger: 'blur' },
  ],
}

async function login() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  try {
    const response = await patientApi.getPatientByCard(form.card_number)
    const patient = response.data.data
    if (patient.real_name !== form.real_name.trim()) {
      ElMessage.warning('姓名与证件号不匹配')
      return
    }
    session.login(patient)
    flow.resetAfterPatient()
    ElMessage.success('登录成功')
    router.push('/patient/home')
  } finally {
    loading.value = false
  }
}

function goRegister() {
  session.setLoginDraft({ realName: form.real_name, cardNumber: form.card_number })
  router.push('/patient/register')
}

function goBack() {
  router.push('/patient/home')
}
</script>

<template>
  <div class="patient-auth-page">
    <PatientAuthHeader
      title="&#24739;&#32773;&#30331;&#24405;"
      subtitle="&#20351;&#29992;&#24050;&#24314;&#26723;&#22995;&#21517;&#21644;&#36523;&#20221;&#35777;&#21495;&#36827;&#20837;&#38382;&#35786;&#12289;&#25346;&#21495;&#19982;&#20505;&#35786;&#27969;&#31243;&#12290;"
    />
    <main class="patient-auth-content">
      <SectionCard title="&#30331;&#24405;" subtitle="&#24050;&#27880;&#20876;&#24739;&#32773;&#21487;&#30452;&#25509;&#36827;&#20837;&#24739;&#32773;&#31471;&#12290;">
        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          class="patient-auth-form"
          @keyup.enter="login"
        >
          <el-form-item label="&#22995;&#21517;" prop="real_name">
            <el-input v-model="form.real_name" placeholder="&#35831;&#36755;&#20837;&#24314;&#26723;&#22995;&#21517;" autocomplete="name" />
          </el-form-item>
          <el-form-item label="&#36523;&#20221;&#35777;&#21495;" prop="card_number">
            <el-input
              v-model="form.card_number"
              maxlength="18"
              show-word-limit
              placeholder="&#35831;&#36755;&#20837;&#36523;&#20221;&#35777;&#21495;"
              autocomplete="username"
            />
          </el-form-item>
          <el-button type="primary" size="large" :loading="loading" @click="login">&#30331;&#24405;</el-button>
          <el-button size="large" plain @click="goRegister">&#27809;&#26377;&#36134;&#21495;&#65292;&#21435;&#27880;&#20876;&#24314;&#26723;</el-button>
        </el-form>
      </SectionCard>
    </main>
  </div>
</template>

<style scoped>
.patient-auth-page {
  min-height: 100vh;
  max-width: var(--patient-page-width);
  margin: 0 auto;
  background: var(--patient-page-bg);
}

.patient-auth-content {
  position: relative;
  z-index: 1;
  margin-top: -54px;
  padding: 0 var(--patient-page-gutter) 32px;
}

.patient-auth-form {
  display: grid;
  gap: 2px;
}

.patient-auth-form :deep(.el-button) {
  width: 100%;
  margin: 4px 0 0;
}

@media (min-width: 720px) {
  .patient-auth-page {
    box-shadow: var(--patient-page-shadow);
  }
}
</style>