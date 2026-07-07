<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { patientApi } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const submitting = ref(false)
const payMethod = ref('微信')

const amount = computed(() => Number(flow.onlineRegister?.regist_money || flow.selectedDoctor?.regist_fee || 0))

onMounted(() => {
  if (!session.patient) {
    router.replace('/patient/login')
    return
  }
  if (!flow.onlineRegister) router.replace('/patient/confirm-register')
})

function goBack() {
  router.push('/patient/confirm-register')
}

async function pay() {
  if (!flow.onlineRegister) return
  submitting.value = true
  try {
    const response = await patientApi.payOnlineRegister({
      register_uuid: flow.onlineRegister.register_uuid,
      pay_method: payMethod.value,
      amount: amount.value,
      idempotency_key: `pay-${flow.onlineRegister.register_uuid}-${Date.now()}`,
    })
    flow.setPayment(response.data.data)
    ElMessage.success('支付成功，已进入候诊队列')
    router.push('/patient/queue')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="patient-payment">
    <PatientFlowHeader
      title="线上支付"
      subtitle="核对挂号信息并完成缴费"
      back-label="返回确认挂号"
      @back="goBack"
    />
    <main class="patient-payment__content">
      <SectionCard title="支付挂号费" subtitle="当前为后端模拟支付接口，不接第三方支付网关。">
      <div v-if="flow.onlineRegister" class="patient-payment__bill">
        <span>应付金额</span>
        <strong>¥{{ amount.toFixed(2) }}</strong>
        <p>挂号单：{{ flow.onlineRegister.register_uuid }}</p>
      </div>

      <div class="patient-payment__method">
        <span>支付方式</span>
        <el-segmented v-model="payMethod" :options="['微信', '支付宝']" />
      </div>

      <div v-if="flow.onlineRegister?.qr_code_url" class="patient-payment__mock">
        <span>模拟支付链接</span>
        <p>{{ flow.onlineRegister.qr_code_url }}</p>
      </div>

      <el-button type="primary" size="large" :loading="submitting" @click="pay">
        确认支付
      </el-button>
      </SectionCard>
    </main>
  </div>
</template>

<style scoped>
.patient-payment {
  min-height: 100vh;
  padding-bottom: 24px;
  background: linear-gradient(180deg, #eaf4ff 0%, #f7fbff 46%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-payment__content {
  margin-top: -22px;
  padding: 0 var(--patient-page-gutter) 24px;
}

.patient-payment__bill,
.patient-payment__method,
.patient-payment__mock {
  display: grid;
  gap: 8px;
  padding: 14px;
  border-radius: 8px;
  background: #f8fafc;
  margin-bottom: 12px;
}

.patient-payment__bill span,
.patient-payment__method span,
.patient-payment__mock span {
  color: #64748b;
  font-size: 13px;
}

.patient-payment__bill strong {
  color: #0f766e;
  font-size: 30px;
  line-height: 1;
}

.patient-payment__bill p,
.patient-payment__mock p {
  margin: 0;
  color: #64748b;
  font-size: 12px;
  word-break: break-all;
}

.patient-payment :deep(.el-segmented),
.patient-payment :deep(.el-button) {
  width: 100%;
}

.patient-payment :deep(.el-button) {
  min-height: 44px;
}
</style>
