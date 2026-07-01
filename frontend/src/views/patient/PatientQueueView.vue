<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import SectionCard from '@/components/common/SectionCard.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { patientApi, type RegisterDetail } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'

const router = useRouter()
const flow = usePatientFlowStore()
const loading = ref(false)
const historyLoading = ref(false)
const history = ref<RegisterDetail[]>([])

const registerUuid = computed(() => flow.payment?.register_uuid || flow.onlineRegister?.register_uuid || '')
const statusText = computed(() => {
  if (flow.queueStatus?.status === 2) return '接诊中'
  if (flow.queueStatus?.status === 1) return '已挂号'
  if (flow.queueStatus?.status === 3) return '已结束'
  if (flow.queueStatus?.status === 4) return '已退号'
  return '待确认'
})

onMounted(async () => {
  if (!registerUuid.value) {
    router.replace('/patient/payment')
    return
  }
  await refresh()
  await loadHistory()
})

function goBack() {
  router.push('/patient/payment')
}

async function refresh() {
  if (!registerUuid.value) return
  loading.value = true
  try {
    const response = await patientApi.getQueueStatus(registerUuid.value)
    flow.setQueueStatus(response.data.data)
  } finally {
    loading.value = false
  }
}

async function loadHistory() {
  if (!flow.patient?.uuid) return
  historyLoading.value = true
  try {
    const response = await patientApi.getRegisterHistory(flow.patient.uuid)
    history.value = response.data.data || []
  } finally {
    historyLoading.value = false
  }
}
</script>

<template>
  <div class="patient-queue">
    <PatientFlowHeader
      title="候诊状态"
      subtitle="支付完成后查看排队与诊室信息"
      back-label="返回支付"
      @back="goBack"
    />
    <main class="patient-queue__content">
      <SectionCard title="当前候诊" subtitle="支付完成后进入医生候诊队列。">
      <div class="patient-queue__status">
        <span>{{ statusText }}</span>
        <strong>{{ flow.queueStatus?.ahead_of_you ?? '-' }}</strong>
        <p>前方等待人数</p>
      </div>
      <div class="patient-queue__room">
        <div>
          <span>诊室</span>
          <strong>{{ flow.queueStatus?.clinic_room_name || '待分配' }}</strong>
        </div>
        <div>
          <span>位置</span>
          <strong>{{ flow.queueStatus?.clinic_room_location || '到院后查看导诊屏' }}</strong>
        </div>
      </div>
      <el-button type="primary" size="large" :loading="loading" @click="refresh">刷新候诊状态</el-button>
      </SectionCard>

      <SectionCard title="本次挂号" :subtitle="registerUuid">
      <div class="patient-queue__summary">
        <div>
          <span>医生</span>
          <strong>{{ flow.selectedDoctor?.doctor_name || '已选择医生' }}</strong>
        </div>
        <div>
          <span>支付流水</span>
          <strong>{{ flow.payment?.transaction_id || '暂无' }}</strong>
        </div>
        <div>
          <span>症状</span>
          <strong>{{ flow.symptoms || '未填写' }}</strong>
        </div>
      </div>
      </SectionCard>

      <SectionCard title="历史挂号" subtitle="来自 /registers/detail">
      <el-skeleton :loading="historyLoading" animated>
        <template #template>
          <el-skeleton-item variant="rect" style="height: 100px; border-radius: 8px" />
        </template>
        <template #default>
          <div class="patient-queue__history">
            <article v-for="item in history" :key="item.uuid" class="patient-queue__history-item">
              <strong>{{ item.dept_name || '未知科室' }} · {{ item.employee_name || '未知医生' }}</strong>
              <span>{{ item.actual_schedule_date || item.visit_date }} {{ item.actual_time_range || item.noon || '' }}</span>
              <span>{{ item.visit_state_str || `状态 ${item.visit_state}` }}</span>
            </article>
            <el-empty v-if="!history.length" description="暂无历史挂号" :image-size="80" />
          </div>
        </template>
      </el-skeleton>
      </SectionCard>
    </main>
  </div>
</template>

<style scoped>
.patient-queue {
  min-height: 100vh;
  padding-bottom: 24px;
  background: linear-gradient(180deg, #eaf4ff 0%, #f7fbff 46%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-queue__content {
  display: grid;
  gap: 14px;
  margin-top: -22px;
  padding: 0 var(--patient-page-gutter) 24px;
}

.patient-queue__status {
  display: grid;
  place-items: center;
  gap: 6px;
  padding: 22px 14px;
  border-radius: 8px;
  color: #ffffff;
  background: linear-gradient(135deg, #0f766e, #1d4ed8);
  margin-bottom: 12px;
}

.patient-queue__status span,
.patient-queue__status p {
  margin: 0;
  opacity: 0.86;
}

.patient-queue__status strong {
  font-size: 48px;
  line-height: 1;
}

.patient-queue__room,
.patient-queue__summary,
.patient-queue__history {
  display: grid;
  gap: 10px;
  margin-bottom: 12px;
}

.patient-queue__room div,
.patient-queue__summary div,
.patient-queue__history-item {
  display: grid;
  gap: 4px;
  padding: 12px 14px;
  border-radius: 8px;
  background: #f8fafc;
}

.patient-queue__room span,
.patient-queue__summary span,
.patient-queue__history-item span {
  color: #64748b;
  font-size: 13px;
}

.patient-queue__summary strong,
.patient-queue__history-item strong {
  word-break: break-word;
}

.patient-queue :deep(.el-button) {
  width: 100%;
  min-height: 44px;
}
</style>
