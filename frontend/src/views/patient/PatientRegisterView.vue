<script setup lang="ts">
import axios from 'axios'
import { reactive, ref, watch } from 'vue'
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
const submitting = ref(false)

const form = reactive({
  real_name: session.loginDraft.realName || '张三',
  gender: '男',
  card_number: session.loginDraft.cardNumber,
  birthdate: '',
  home_address: '',
})

const idCardWeights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
const idCardChecks = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2']

function parseIdCard(cardNumber: string) {
  const normalized = cardNumber.trim().toUpperCase()
  if (!/^\d{17}[\dX]$/.test(normalized)) {
    return { valid: false, birthdate: '', message: '请输入有效的 18 位身份证号' }
  }

  const birth = normalized.slice(6, 14)
  const year = Number(birth.slice(0, 4))
  const month = Number(birth.slice(4, 6))
  const day = Number(birth.slice(6, 8))
  const date = new Date(Date.UTC(year, month - 1, day))
  const isRealDate =
    year >= 1900 &&
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day &&
    date.getTime() <= Date.now()

  if (!isRealDate) {
    return { valid: false, birthdate: '', message: '身份证中的出生日期不正确' }
  }

  const checksum = normalized
    .slice(0, 17)
    .split('')
    .reduce((sum, digit, index) => sum + Number(digit) * idCardWeights[index], 0)
  if (idCardChecks[checksum % 11] !== normalized[17]) {
    return { valid: false, birthdate: '', message: '身份证校验码不正确' }
  }

  return {
    valid: true,
    birthdate: `${birth.slice(0, 4)}-${birth.slice(4, 6)}-${birth.slice(6, 8)}`,
    message: '',
  }
}

watch(
  () => form.card_number,
  (value) => {
    const normalized = value.trim().toUpperCase()
    if (normalized !== value) {
      form.card_number = normalized
      return
    }

    const result = parseIdCard(normalized)
    form.birthdate = result.valid ? result.birthdate : ''
    if (result.valid) {
      formRef.value?.clearValidate(['card_number', 'birthdate'])
    }
  },
  { immediate: true },
)

const rules: FormRules = {
  real_name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  gender: [{ required: true, message: '请选择性别', trigger: 'change' }],
  card_number: [
    { required: true, message: '请输入身份证号', trigger: 'blur' },
    {
      validator: (_rule, value: string, callback) => {
        const result = parseIdCard(value || '')
        result.valid ? callback() : callback(new Error(result.message))
      },
      trigger: 'blur',
    },
  ],
  birthdate: [
    {
      validator: (_rule, value: string, callback) => {
        const result = parseIdCard(form.card_number)
        if (!result.valid) return callback(new Error('请先输入有效的身份证号'))
        return value === result.birthdate
          ? callback()
          : callback(new Error('出生日期与身份证不一致'))
      },
      trigger: 'change',
    },
  ],
}

async function submit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    const response = await patientApi.createPatient({ ...form })
    session.login(response.data.data)
    flow.resetAfterPatient()
    ElMessage.success('注册成功，已自动登录')
    router.push('/patient/home')
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const detail = String(error.response?.data?.detail || error.response?.data?.message || '')
      if (detail.includes('已注册')) {
        session.setLoginDraft({ realName: form.real_name, cardNumber: form.card_number })
        ElMessage.info('该账号已注册，请直接登录')
        router.push('/patient/login')
      }
    }
  } finally {
    submitting.value = false
  }
}
function goBack() {
  router.push('/patient/home')
}
</script>

<template>
  <div class="patient-auth-page">
    <PatientAuthHeader
      title="&#27880;&#20876;&#24314;&#26723;"
      subtitle="&#22635;&#20889;&#30495;&#23454;&#24739;&#32773;&#36164;&#26009;&#65292;&#23436;&#25104;&#21518;&#33258;&#21160;&#36827;&#20837;&#24739;&#32773;&#31471;&#12290;"
    />
    <main class="patient-auth-content">
      <SectionCard title="&#24739;&#32773;&#36164;&#26009;" subtitle="&#36523;&#20221;&#35777;&#21495;&#23558;&#29992;&#20110;&#30331;&#24405;&#21644;&#21305;&#37197;&#20986;&#29983;&#26085;&#26399;&#12290;">
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" class="patient-auth-form">
          <el-form-item label="&#22995;&#21517;" prop="real_name">
            <el-input
              v-model="form.real_name"
              placeholder="&#35831;&#36755;&#20837;&#30495;&#23454;&#22995;&#21517;"
              autocomplete="name"
            />
          </el-form-item>
          <el-form-item label="&#24615;&#21035;" prop="gender">
            <el-segmented v-model="form.gender" :options="['男', '女']" />
          </el-form-item>
          <el-form-item label="&#36523;&#20221;&#35777;&#21495;" prop="card_number">
            <el-input
              v-model="form.card_number"
              maxlength="18"
              show-word-limit
              placeholder="&#35831;&#36755;&#20837; 18 &#20301;&#36523;&#20221;&#35777;&#21495;"
              autocomplete="username"
            />
          </el-form-item>
          <el-form-item label="&#20986;&#29983;&#26085;&#26399;" prop="birthdate">
            <el-date-picker
              v-model="form.birthdate"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="&#36755;&#20837;&#36523;&#20221;&#35777;&#21518;&#33258;&#21160;&#35782;&#21035;"
              disabled
            />
            <p class="patient-auth-hint">
              &#20986;&#29983;&#26085;&#26399;&#23558;&#26681;&#25454;&#36523;&#20221;&#35777;&#21495;&#33258;&#21160;&#22635;&#20889;&#12290;
            </p>
          </el-form-item>
          <el-form-item label="&#23478;&#24237;&#20303;&#22336;">
            <el-input v-model="form.home_address" type="textarea" :rows="3" placeholder="&#36873;&#22635;" />
          </el-form-item>
          <el-button type="primary" size="large" :loading="submitting" @click="submit">&#27880;&#20876;</el-button>
          <el-button size="large" plain @click="router.push('/patient/login')">&#24050;&#26377;&#36134;&#21495;&#65292;&#21435;&#30331;&#24405;</el-button>
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

.patient-auth-form :deep(.el-date-editor.el-input),
.patient-auth-form :deep(.el-segmented) {
  width: 100%;
}

.patient-auth-hint {
  margin: 6px 0 0;
  color: var(--patient-text-muted);
  font-size: 13px;
  line-height: 1.5;
}

@media (min-width: 720px) {
  .patient-auth-page {
    box-shadow: var(--patient-page-shadow);
  }
}
</style>
