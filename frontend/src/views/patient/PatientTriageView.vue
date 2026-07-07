<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { patientApi, type TriageMessage } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const input = ref('')
const submitting = ref(false)

const messages = computed<TriageMessage[]>(() => flow.triageMessages)
const triage = computed(() => flow.triageData)

const examples = [
  '我有高血压应该挂什么科室的号',
  '最近经常心慌、手抖应该看什么科',
  '血糖偏高应该挂什么科',
]

const departmentNames: Record<string, string> = {
  SJWK: '神经外科',
  XNK: '心内科',
  GK: '骨科',
  EK: '儿科',
  FCK: '妇产科',
}

const patientLine = computed(() => {
  if (!session.patient) return '未登录患者'
  return `${session.patient.real_name} | ${session.patient.gender} | ${formatAge(session.patient.birthdate)}`
})

const recommendedDepartment = computed(() => {
  const code = triage.value?.recommended_dept_code
  if (!code) return '待确认'
  return departmentNames[code] || code
})

const aiSourceLabel = computed(() => {
  if (!flow.triageResult) return '未生成'
  if (flow.triageResult.source === 'llm') return `真实大模型 · ${flow.triageResult.model || 'DeepSeek'}`
  if (flow.triageResult.source === 'rule') return `规则校验 · ${flow.triageResult.model || 'rule'}`
  if (flow.triageResult.source === 'fallback') return `安全校验结果 · ${flow.triageResult.model || 'fallback'}`
  if (flow.triageResult.source === 'mock') return '模拟分诊结果'
  return flow.triageResult.source || '未知来源'
})

const confidenceLabel = computed(() => {
  const confidence = flow.triageResult?.confidence
  if (typeof confidence !== 'number') return '暂无'
  return `${Math.round(confidence * 100)}%`
})

const validationLabel = computed(() => {
  if (!flow.triageResult) return '未校验'
  return flow.triageResult.validated === false ? '需人工确认' : '已通过安全校验'
})

const resultWarnings = computed(() => {
  const warnings = flow.triageResult?.warnings || []
  const validatorMessages = flow.triageResult?.validator_messages || []
  return [...warnings, ...validatorMessages].filter(Boolean)
})

onMounted(() => {
  if (!session.patient) {
    router.replace('/patient/login')
  }
})

async function send(content = input.value) {
  const normalized = content.trim()
  if (!normalized) return

  const nextMessages: TriageMessage[] = [...messages.value, { role: 'user', content: normalized }]
  input.value = ''
  submitting.value = true

  try {
    const response = await patientApi.triage(nextMessages)
    const result = response.data.data
    const assistantReply = result.data.reply || '已完成本轮分诊。'
    flow.setTriage([...nextMessages, { role: 'assistant', content: assistantReply }], result)
  } catch {
    input.value = normalized
  } finally {
    submitting.value = false
  }
}

function useExample(value: string) {
  input.value = value
}

function goBack() {
  router.push('/patient/departments')
}

function goNext() {
  if (!triage.value?.recommended_dept_code) {
    ElMessage.warning('请先完成 AI 分诊，获得推荐科室后再继续')
    return
  }
  router.push('/patient/doctors')
}

function formatAge(birthdate?: string) {
  if (!birthdate) return '年龄未知'
  const birth = new Date(`${birthdate}T00:00:00`)
  if (Number.isNaN(birth.getTime())) return '年龄未知'

  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  const monthDiff = today.getMonth() - birth.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) age -= 1
  return `${Math.max(age, 0)}岁`
}
</script>

<template>
  <div class="triage-chat">
    <PatientFlowHeader
      title="智能分诊"
      subtitle="描述症状，获得就诊科室建议"
      back-label="返回科室选择"
      @back="goBack"
    />

    <div class="triage-chat__notice">AI 回复仅供参考，最终诊疗请以医生判断为准。</div>

    <section class="triage-chat__patient">
      <strong>{{ patientLine }}</strong>
      <span>系统将根据症状描述推荐合适科室</span>
    </section>

    <section class="triage-chat__hero">
      <h2>说说哪里不舒服</h2>
      <p>我来帮您快速确定就诊方向</p>
    </section>

    <main class="triage-chat__body">
      <section class="triage-chat__assistant-card">
        <p>请简单描述主要不适、持续时间、伴随症状和既往病史，系统会结合真实 AI 模型给出就诊建议。</p>
        <button v-for="example in examples" :key="example" type="button" @click="useExample(example)">
          <span>{{ example }}</span>
          <strong>›</strong>
        </button>
      </section>

      <div v-for="(message, index) in messages" :key="index" :class="['triage-chat__message', `is-${message.role}`]">
        {{ message.content }}
      </div>

      <section v-if="triage" class="triage-chat__result">
        <div>
          <span>推荐科室</span>
          <strong>{{ recommendedDepartment }}</strong>
        </div>
        <div>
          <span>症状摘要</span>
          <strong>{{ triage.symptom_summary || '暂无摘要' }}</strong>
        </div>
        <div>
          <span>AI 来源</span>
          <strong>{{ aiSourceLabel }}</strong>
        </div>
        <div class="triage-chat__result-row">
          <span>可信度</span>
          <strong>{{ confidenceLabel }}</strong>
        </div>
        <div class="triage-chat__result-row">
          <span>安全校验</span>
          <strong>{{ validationLabel }}</strong>
        </div>
        <p v-if="resultWarnings.length" class="triage-chat__warning">
          {{ resultWarnings.join('；') }}
        </p>
        <el-button type="primary" size="large" @click="goNext">查看推荐医生</el-button>
      </section>
    </main>

    <footer class="triage-chat__composer">
      <input v-model="input" type="text" placeholder="请输入症状或疾病" @keyup.enter="send()" />
      <el-button type="primary" :loading="submitting" :disabled="!input.trim()" @click="send()">发送</el-button>
    </footer>
  </div>
</template>

<style scoped>
.triage-chat {
  min-height: 100vh;
  margin: 0;
  padding-bottom: 92px;
  overflow: hidden;
  background:
    radial-gradient(circle at 70% 28%, rgba(147, 197, 253, 0.55), transparent 26%),
    linear-gradient(180deg, #dbeafe 0%, #eef6ff 42%, #f8fbff 100%);
  color: #172554;
}

.triage-chat__notice {
  padding: 9px 14px;
  color: #b7791f;
  background: #fff1d6;
  font-size: 14px;
  line-height: 1.45;
}

.triage-chat__patient {
  display: grid;
  gap: 8px;
  margin: 14px 12px 0;
  padding: 14px 16px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.82);
  box-shadow: 0 8px 28px rgba(30, 64, 175, 0.08);
}

.triage-chat__patient strong {
  color: #475569;
  font-size: 17px;
}

.triage-chat__patient span {
  color: #64748b;
  font-size: 14px;
}

.triage-chat__hero {
  padding: 28px 24px 24px;
}

.triage-chat__hero h2,
.triage-chat__hero p {
  margin: 0;
}

.triage-chat__hero h2 {
  color: #1e2a5a;
  font-size: 24px;
  line-height: 1.25;
}

.triage-chat__hero p {
  margin-top: 8px;
  color: #5b6478;
  font-size: 17px;
}

.triage-chat__body {
  display: grid;
  gap: 12px;
  padding: 0 14px;
}

.triage-chat__assistant-card {
  display: grid;
  gap: 12px;
  margin-left: 34px;
  padding: 20px 18px;
  border-radius: 16px;
  background: #ffffff;
  box-shadow: 0 14px 32px rgba(59, 130, 246, 0.1);
}

.triage-chat__assistant-card p {
  margin: 0;
  color: #3f3f46;
  font-size: 16px;
  line-height: 1.6;
}

.triage-chat__assistant-card button {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 52px;
  padding: 0 14px;
  border: 0;
  border-radius: 12px;
  background: #f5f8ff;
  color: #4b5563;
  font-size: 15px;
  text-align: left;
}

.triage-chat__assistant-card button::before {
  flex: 0 0 auto;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #315b99;
  content: '';
}

.triage-chat__assistant-card button span {
  flex: 1 1 auto;
}

.triage-chat__assistant-card button strong {
  color: #64748b;
  font-size: 24px;
  line-height: 1;
}

.triage-chat__message {
  max-width: 86%;
  padding: 12px 14px;
  border-radius: 12px;
  line-height: 1.55;
  word-break: break-word;
}

.triage-chat__message.is-user {
  justify-self: end;
  color: #ffffff;
  background: #4f8df7;
}

.triage-chat__message.is-assistant {
  justify-self: start;
  color: #172554;
  background: #ffffff;
}

.triage-chat__result {
  display: grid;
  gap: 10px;
  padding: 16px;
  border-radius: 16px;
  background: #ffffff;
  box-shadow: 0 14px 32px rgba(59, 130, 246, 0.1);
}

.triage-chat__result div {
  display: grid;
  gap: 4px;
  padding: 10px 12px;
  border-radius: 10px;
  background: #f8fafc;
}

.triage-chat__result span {
  color: #64748b;
  font-size: 13px;
}

.triage-chat__result strong {
  color: #0f172a;
}

.triage-chat__warning {
  margin: 0;
  padding: 10px 12px;
  border-radius: 10px;
  background: #fff7ed;
  color: #9a3412;
  font-size: 13px;
  line-height: 1.5;
  word-break: break-word;
}

.triage-chat__composer {
  position: fixed;
  left: 50%;
  bottom: 0;
  z-index: 5;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 72px;
  gap: 8px;
  width: min(100%, 430px);
  padding: 12px 14px 18px;
  background: #ffffff;
  box-shadow: 0 -8px 24px rgba(15, 23, 42, 0.06);
  transform: translateX(-50%);
}

.triage-chat__composer input {
  min-width: 0;
  height: 44px;
  padding: 0 14px;
  border: 0;
  border-radius: 12px;
  outline: 0;
  background: #eef6ff;
  color: #0f172a;
  font-size: 15px;
}

.triage-chat__composer :deep(.el-button) {
  height: 44px;
  border-radius: 12px;
}
</style>
