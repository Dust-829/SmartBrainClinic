<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import {
  adminApi,
  type ScheduleActualResult,
  type ScheduleAiAdjustResult,
  type ScheduleGenerateResult,
  type ScheduleRuleResult,
  type SchedulingApplicationRecord,
} from '@/api/admin'
import { authApi, type ClinicRoomRecord, type DoctorDirectoryItem } from '@/api/auth'
import { patientApi, type DepartmentOption } from '@/api/patient'
import SectionCard from '@/components/common/SectionCard.vue'

type DoctorOption = DoctorDirectoryItem & {
  deptCode: string
  deptName: string
}

const generating = ref(false)
const adjustingAi = ref(false)
const updatingRule = ref(false)
const updatingActual = ref(false)
const loadingApplications = ref(false)
const loadingDoctorDirectory = ref(false)
const applications = ref<SchedulingApplicationRecord[]>([])
const departments = ref<DepartmentOption[]>([])
const doctors = ref<DoctorOption[]>([])
const selectedDeptCode = ref('')
const selectedDoctorUuid = ref('')
const lastResult = ref('尚未执行排班类操作。')
const doctorDirectoryError = ref('')
const clinicRoomNameCache = reactive<Record<string, string>>({})

const generateForm = reactive({
  start_date: new Date().toISOString().slice(0, 10),
  end_date: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
})

const aiForm = reactive({
  prompt: '',
})

const ruleForm = reactive({
  rule_name: '管理员人工规则',
  week_rule: '1,2,3,4,5',
  llm_text_rule: '管理员后台人工干预排班规则',
  regist_quota: 20,
  slot_duration_minutes: 10,
  clinic_room_name: '',
})

const actualForm = reactive({
  schedule_date: new Date().toISOString().slice(0, 10),
  noon: '上午',
  regist_quota: 20,
  slot_duration_minutes: 10,
  clinic_room_name: '',
})

function extractErrorMessage(error: unknown) {
  return (
    (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.detail ||
    (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.message ||
    (error instanceof Error ? error.message : '请求失败')
  )
}

const availableDepartments = computed(() => {
  const doctorDeptCodes = new Set(doctors.value.map((doctor) => doctor.deptCode))
  return departments.value.filter((department) => doctorDeptCodes.has(department.code))
})

const currentDoctors = computed(() =>
  doctors.value
    .filter((doctor) => doctor.deptCode === selectedDeptCode.value)
    .sort((left, right) => left.realname.localeCompare(right.realname, 'zh-CN')),
)

const selectedDoctor = computed(() =>
  currentDoctors.value.find((doctor) => doctor.uuid === selectedDoctorUuid.value) ?? null,
)

const doctorSummary = computed(() => {
  if (!selectedDoctor.value) return null
  return {
    name: selectedDoctor.value.realname,
    deptName: selectedDoctor.value.deptName,
    expertise: selectedDoctor.value.expertise || '暂无专长信息',
    score: selectedDoctor.value.ai_eval_score ?? '未评分',
    uuid: selectedDoctor.value.uuid,
  }
})

const doctorContextMetrics = computed(() => [
  { label: '默认号源', value: `${ruleForm.regist_quota}` },
  { label: '每号时长', value: `${ruleForm.slot_duration_minutes} 分钟` },
  { label: '周规则', value: ruleForm.week_rule },
])

function syncDoctorSelection() {
  if (!currentDoctors.value.length) {
    selectedDoctorUuid.value = ''
    return
  }
  if (!currentDoctors.value.some((doctor) => doctor.uuid === selectedDoctorUuid.value)) {
    selectedDoctorUuid.value = currentDoctors.value[0].uuid
  }
}

function ensureSelectedDoctorUuid() {
  if (!selectedDoctor.value?.uuid) {
    throw new Error('请先选择医生')
  }
  return selectedDoctor.value.uuid
}

async function resolveClinicRoomUuidByName(roomName: string) {
  const normalized = roomName.trim()
  if (!normalized) return undefined
  const response = await authApi.getClinicRoomByName(normalized)
  const room = response.data.data
  if (!room?.uuid) {
    throw new Error(`未找到诊室：${normalized}`)
  }
  clinicRoomNameCache[room.uuid] = room.room_name
  return room.uuid
}

async function resolveClinicRoomName(roomUuid?: string | null, fallbackName?: string) {
  if (!roomUuid) return fallbackName || '未设置'
  if (clinicRoomNameCache[roomUuid]) return clinicRoomNameCache[roomUuid]
  try {
    const response = await authApi.getClinicRoom(roomUuid)
    const room = response.data.data as ClinicRoomRecord | undefined
    const roomName = room?.room_name || fallbackName || roomUuid
    clinicRoomNameCache[roomUuid] = roomName
    return roomName
  } catch {
    return fallbackName || roomUuid
  }
}

function formatDateTime(value?: string | null) {
  if (!value) return '暂无时间'
  return value.replace('T', ' ').slice(0, 16)
}

function formatApplicant(item: SchedulingApplicationRecord) {
  return [item.employee_name, item.dept_name].filter(Boolean).join(' · ') || item.employee_uuid
}

function formatGenerateResult(result: ScheduleGenerateResult) {
  return [
    '常规排班生成完成',
    `时间范围：${result.start_date} -> ${result.end_date}`,
    `新生成排班：${result.generated_count}`,
    `跳过已有/不可生成排班：${result.skipped_count}`,
  ].join('\n')
}

function formatAiAdjustResult(result: ScheduleAiAdjustResult) {
  const header = [
    `AI 排班微调完成：${result.employee_name || result.employee_uuid}`,
    `规则摘要：${result.llm_text_rule || '无'}`,
    `已应用动作：${result.actions_applied}`,
    `生成 disruption：${result.disruptions_created}`,
  ]
  const details = result.action_summaries.map((item, index) => {
    const roomText = item.clinic_room_uuid ? ` | 诊室 ${item.clinic_room_uuid}` : ''
    const clampText = item.clamped_to_registered_count ? ' | 已按已挂号人数钳制 quota' : ''
    return `${index + 1}. ${item.action_type} ${item.target_date} ${item.noon} -> ${item.status} | quota ${item.final_regist_quota}${roomText}${clampText}`
  })
  return [...header, ...details].join('\n')
}

async function formatRuleResult(result: ScheduleRuleResult, fallbackRoomName?: string) {
  const roomName = await resolveClinicRoomName(result.clinic_room_uuid, fallbackRoomName)
  return [
    `排班规则已更新：${result.employee_uuid}`,
    `week_rule：${result.week_rule ?? '未返回'}`,
    `quota：${result.regist_quota ?? '未返回'}`,
    `每号时长：${result.slot_duration_minutes ?? '未返回'} 分钟`,
    `诊室：${roomName}`,
  ].join('\n')
}

async function formatActualResult(result: ScheduleActualResult, fallbackRoomName?: string) {
  const roomName = await resolveClinicRoomName(result.clinic_room_uuid, fallbackRoomName)
  return [
    `实际排班已处理：${result.employee_uuid}`,
    `日期：${result.schedule_date ?? '-'}`,
    `午别：${result.noon ?? '-'}`,
    `状态：${result.status ?? '-'}`,
    `最终 quota：${result.regist_quota ?? '-'}`,
    `每号时长：${result.slot_duration_minutes ?? '-'} 分钟`,
    `已挂号人数：${result.registered_count ?? '-'}`,
    `产生 disruption：${result.disruptions_created ?? 0}`,
    `诊室：${roomName}`,
  ].join('\n')
}

async function loadDoctorDirectory() {
  loadingDoctorDirectory.value = true
  doctorDirectoryError.value = ''
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

    doctors.value = doctorResponses.flat()
    selectedDeptCode.value = availableDepartments.value[0]?.code ?? ''
    syncDoctorSelection()

    if (!doctors.value.length) {
      doctorDirectoryError.value = '当前没有可用于排班操作的医生目录数据。'
    }
  } catch {
    doctors.value = []
    departments.value = []
    doctorDirectoryError.value = '医生目录加载失败，请稍后重试。'
  } finally {
    loadingDoctorDirectory.value = false
  }
}

async function loadApplications() {
  loadingApplications.value = true
  try {
    const response = await adminApi.listPendingApplications()
    applications.value = response.data.data ?? []
  } catch {
    applications.value = []
  } finally {
    loadingApplications.value = false
  }
}

async function submitGenerate() {
  generating.value = true
  try {
    const response = await adminApi.generateSchedule(generateForm)
    const result = response.data.data
    lastResult.value = formatGenerateResult(result)
    ElMessage.success(`常规排班生成完成，新增 ${result.generated_count} 条，跳过 ${result.skipped_count} 条`)
  } finally {
    generating.value = false
  }
}

async function submitAiAdjust() {
  adjustingAi.value = true
  try {
    const employeeUuid = ensureSelectedDoctorUuid()
    const response = await adminApi.adjustScheduleWithAi({
      employee_uuid: employeeUuid,
      prompt: aiForm.prompt,
    })
    const result = response.data.data
    lastResult.value = formatAiAdjustResult(result)
    ElMessage.success(`AI 排班微调完成，已应用 ${result.actions_applied} 个动作`)
  } finally {
    adjustingAi.value = false
  }
}

async function submitRuleUpdate() {
  updatingRule.value = true
  try {
    const employeeUuid = ensureSelectedDoctorUuid()
    const clinicRoomUuid = await resolveClinicRoomUuidByName(ruleForm.clinic_room_name)
    const response = await adminApi.updateSchedulingRule({
      employee_uuid: employeeUuid,
      rule_name: ruleForm.rule_name,
      week_rule: ruleForm.week_rule,
      llm_text_rule: ruleForm.llm_text_rule,
      regist_quota: ruleForm.regist_quota,
      slot_duration_minutes: ruleForm.slot_duration_minutes,
      clinic_room_uuid: clinicRoomUuid,
    })
    lastResult.value = await formatRuleResult(response.data.data, ruleForm.clinic_room_name.trim() || undefined)
    ElMessage.success('排班规则已更新')
  } catch (error) {
    lastResult.value = `排班规则更新失败：${extractErrorMessage(error)}`
  } finally {
    updatingRule.value = false
  }
}

async function submitActualUpdate() {
  updatingActual.value = true
  try {
    const employeeUuid = ensureSelectedDoctorUuid()
    const clinicRoomUuid = await resolveClinicRoomUuidByName(actualForm.clinic_room_name)
    const response = await adminApi.updateSchedulingActual({
      employee_uuid: employeeUuid,
      schedule_date: actualForm.schedule_date,
      noon: actualForm.noon,
      regist_quota: actualForm.regist_quota,
      slot_duration_minutes: actualForm.slot_duration_minutes,
      clinic_room_uuid: clinicRoomUuid,
    })
    const result = response.data.data
    lastResult.value = await formatActualResult(result, actualForm.clinic_room_name.trim() || undefined)
    ElMessage.success(`实际排班已处理，状态：${result.status ?? 'success'}`)
  } catch (error) {
    lastResult.value = `实际排班失败：${extractErrorMessage(error)}`
  } finally {
    updatingActual.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadDoctorDirectory(), loadApplications()])
})
</script>

<template>
  <div class="admin-page admin-schedules-workbench">
    <section class="admin-page__hero admin-schedules-workbench__hero">
      <div>
        <span>管理员端主打模块</span>
        <h2>智能排班中心</h2>
        <p>把排班生成、AI 微调、规则配置和实例调整收拢到同一条运营工作流里，而不是平铺多个孤立表单。</p>
      </div>
      <div class="admin-schedules-workbench__hero-tip">
        <strong>建议顺序</strong>
        <p>先选医生，再定规则，再生成未来排班，最后处理具体日期的异常调整。</p>
      </div>
    </section>

    <div class="admin-schedules-workbench__top">
      <SectionCard title="排班上下文" subtitle="先锁定科室和医生，后续所有排班动作都基于这一上下文执行。">
        <div v-if="doctorDirectoryError" class="admin-empty admin-schedules-workbench__context-empty">
          <p>{{ doctorDirectoryError }}</p>
          <button type="button" class="admin-inline-button" :disabled="loadingDoctorDirectory" @click="loadDoctorDirectory">
            {{ loadingDoctorDirectory ? '重新加载中...' : '重新加载医生目录' }}
          </button>
        </div>
        <div v-else class="admin-schedules-workbench__context">
          <form class="admin-form admin-schedules-workbench__context-form" @submit.prevent>
            <label>
              <span>科室</span>
              <select v-model="selectedDeptCode" :disabled="loadingDoctorDirectory" @change="syncDoctorSelection">
                <option v-for="department in availableDepartments" :key="department.code" :value="department.code">
                  {{ department.name }}（{{ department.code }}）
                </option>
              </select>
            </label>
            <label>
              <span>医生</span>
              <select v-model="selectedDoctorUuid" :disabled="loadingDoctorDirectory || !currentDoctors.length">
                <option v-for="doctor in currentDoctors" :key="doctor.uuid" :value="doctor.uuid">
                  {{ doctor.realname }}
                </option>
              </select>
            </label>
          </form>

          <div v-if="doctorSummary" class="admin-schedules-workbench__doctor-card">
            <div class="admin-schedules-workbench__doctor-head">
              <div>
                <strong>{{ doctorSummary.name }}</strong>
                <p>{{ doctorSummary.deptName }}</p>
              </div>
              <span>AI 评分 {{ doctorSummary.score }}</span>
            </div>
            <p class="admin-schedules-workbench__doctor-expertise">{{ doctorSummary.expertise }}</p>
            <div class="admin-schedules-workbench__metric-strip">
              <article v-for="metric in doctorContextMetrics" :key="metric.label">
                <span>{{ metric.label }}</span>
                <strong>{{ metric.value }}</strong>
              </article>
            </div>
          </div>
        </div>
      </SectionCard>

      <SectionCard title="最近操作结果" subtitle="优先展示结构化返回，便于快速判断这次排班动作有没有真正生效。">
        <pre class="admin-result admin-schedules-workbench__result">{{ lastResult }}</pre>
      </SectionCard>
    </div>

    <div class="admin-schedules-workbench__main">
      <SectionCard title="批量生成与 AI 微调" subtitle="先铺未来班表，再让 AI 做小范围微调。">
        <div class="admin-schedules-workbench__dual">
          <form class="admin-form admin-schedules-workbench__panel-form" @submit.prevent="submitGenerate">
            <div class="admin-schedules-workbench__panel-head">
              <strong>常规排班生成</strong>
              <p>按时间范围批量生成实际排班，适合每周或每月提前铺底。</p>
            </div>
            <label>
              <span>开始日期</span>
              <input v-model="generateForm.start_date" type="date" />
            </label>
            <label>
              <span>结束日期</span>
              <input v-model="generateForm.end_date" type="date" />
            </label>
            <button type="submit" :disabled="generating">
              {{ generating ? '生成中...' : '生成排班' }}
            </button>
          </form>

          <form class="admin-form admin-schedules-workbench__panel-form" @submit.prevent="submitAiAdjust">
            <div class="admin-schedules-workbench__panel-head">
              <strong>AI 排班微调</strong>
              <p>适合处理临时手术、培训、停诊、加号等自然语言级别的运营变更。</p>
            </div>
            <label>
              <span>当前医生</span>
              <input :value="doctorSummary ? `${doctorSummary.name} (${doctorSummary.deptName})` : '请先选择医生'" type="text" disabled />
            </label>
            <label>
              <span>微调指令</span>
              <textarea
                v-model="aiForm.prompt"
                rows="5"
                placeholder="例如：该医生下周三下午有手术，请改到周四下午坐诊"
              />
            </label>
            <button type="submit" :disabled="adjustingAi || !selectedDoctor">
              {{ adjustingAi ? '提交中...' : '提交 AI 微调' }}
            </button>
          </form>
        </div>
      </SectionCard>

      <SectionCard title="规则配置与实例调整" subtitle="长期策略放在规则层，某一天的临时异常放在实例层。">
        <div class="admin-schedules-workbench__dual">
          <form class="admin-form admin-schedules-workbench__panel-form" @submit.prevent="submitRuleUpdate">
            <div class="admin-schedules-workbench__panel-head">
              <strong>规则层</strong>
              <p>定义医生长期默认的出诊星期、号源数量和每号时长。</p>
            </div>
            <label>
              <span>当前医生</span>
              <input :value="doctorSummary ? `${doctorSummary.name} (${doctorSummary.deptName})` : '请先选择医生'" type="text" disabled />
            </label>
            <label>
              <span>规则名称</span>
              <input v-model="ruleForm.rule_name" type="text" />
            </label>
            <label>
              <span>周规则</span>
              <input v-model="ruleForm.week_rule" type="text" placeholder="1,2,3,4,5" />
            </label>
            <div class="admin-schedules-workbench__compact-grid">
              <label>
                <span>号源数量</span>
                <input v-model.number="ruleForm.regist_quota" type="number" min="0" />
              </label>
              <label>
                <span>每号时长（分钟）</span>
                <input v-model.number="ruleForm.slot_duration_minutes" type="number" min="5" max="60" />
              </label>
            </div>
            <label>
              <span>自然语言规则</span>
              <textarea v-model="ruleForm.llm_text_rule" rows="3" />
            </label>
            <label>
              <span>诊室名称（可选）</span>
              <input v-model="ruleForm.clinic_room_name" type="text" placeholder="例如：神外一诊室" />
            </label>
            <button type="submit" :disabled="updatingRule || !selectedDoctor">
              {{ updatingRule ? '保存中...' : '保存规则' }}
            </button>
          </form>

          <form class="admin-form admin-schedules-workbench__panel-form" @submit.prevent="submitActualUpdate">
            <div class="admin-schedules-workbench__panel-head">
              <strong>实例层</strong>
              <p>只处理某一天某个午别的真实排班。已有挂号时，禁止直接改每号时长。</p>
            </div>
            <label>
              <span>当前医生</span>
              <input :value="doctorSummary ? `${doctorSummary.name} (${doctorSummary.deptName})` : '请先选择医生'" type="text" disabled />
            </label>
            <div class="admin-schedules-workbench__compact-grid">
              <label>
                <span>日期</span>
                <input v-model="actualForm.schedule_date" type="date" />
              </label>
              <label>
                <span>午别</span>
                <select v-model="actualForm.noon">
                  <option value="上午">上午</option>
                  <option value="下午">下午</option>
                </select>
              </label>
            </div>
            <div class="admin-schedules-workbench__compact-grid">
              <label>
                <span>号源数量</span>
                <input v-model.number="actualForm.regist_quota" type="number" min="0" />
              </label>
              <label>
                <span>每号时长（分钟）</span>
                <input v-model.number="actualForm.slot_duration_minutes" type="number" min="5" max="60" />
              </label>
            </div>
            <label>
              <span>诊室名称（可选）</span>
              <input v-model="actualForm.clinic_room_name" type="text" placeholder="例如：神外一诊室" />
            </label>
            <button type="submit" :disabled="updatingActual || !selectedDoctor">
              {{ updatingActual ? '更新中...' : '更新实际排班' }}
            </button>
          </form>
        </div>
      </SectionCard>
    </div>

    <SectionCard title="待审批排班申请" subtitle="和审批中心联通，便于在排班工作台直接回看待处理压力。">
      <template #extra>
        <button type="button" class="admin-inline-button" :disabled="loadingApplications" @click="loadApplications">
          {{ loadingApplications ? '刷新中...' : '刷新申请' }}
        </button>
      </template>

      <div v-if="applications.length" class="admin-list">
        <article v-for="item in applications" :key="item.uuid" class="admin-list__item">
          <strong>{{ item.prompt_title || '排班调整申请' }}</strong>
          <p>{{ formatApplicant(item) }}</p>
          <p>{{ item.prompt_excerpt || item.prompt_display || item.prompt }}</p>
          <span>{{ [item.time_hint, formatDateTime(item.created_at)].filter(Boolean).join(' | ') }}</span>
        </article>
      </div>
      <div v-else class="admin-empty">当前没有待审批排班申请。</div>
    </SectionCard>
  </div>
</template>

<style scoped>
.admin-schedules-workbench {
  display: grid;
  gap: 18px;
}

.admin-schedules-workbench__hero {
  display: grid;
  grid-template-columns: minmax(0, 1.6fr) minmax(260px, 0.8fr);
  gap: 16px;
  align-items: stretch;
}

.admin-schedules-workbench__hero-tip {
  display: grid;
  align-content: start;
  gap: 8px;
  padding: 18px 20px;
  border-radius: 20px;
  background:
    linear-gradient(135deg, rgba(15, 118, 110, 0.12), rgba(14, 165, 233, 0.08)),
    #ffffff;
  border: 1px solid rgba(15, 118, 110, 0.16);
}

.admin-schedules-workbench__hero-tip strong {
  color: #0f172a;
}

.admin-schedules-workbench__hero-tip p {
  margin: 0;
  color: #475569;
  line-height: 1.7;
}

.admin-schedules-workbench__top {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(320px, 0.85fr);
  gap: 16px;
}

.admin-schedules-workbench__context {
  display: grid;
  gap: 16px;
}

.admin-schedules-workbench__context-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.admin-schedules-workbench__context-empty,
.admin-schedules-workbench__doctor-card {
  min-height: 100%;
}

.admin-schedules-workbench__doctor-card {
  display: grid;
  gap: 14px;
  padding: 16px 18px;
  border-radius: 18px;
  border: 1px solid rgba(15, 118, 110, 0.12);
  background:
    radial-gradient(circle at top right, rgba(56, 189, 248, 0.12), transparent 40%),
    linear-gradient(180deg, #f8fcff 0%, #f4fbf9 100%);
}

.admin-schedules-workbench__doctor-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: flex-start;
}

.admin-schedules-workbench__doctor-head strong {
  display: block;
  color: #0f172a;
  font-size: 18px;
}

.admin-schedules-workbench__doctor-head p,
.admin-schedules-workbench__doctor-expertise {
  margin: 0;
  color: #475569;
  line-height: 1.7;
}

.admin-schedules-workbench__doctor-head span {
  padding: 6px 10px;
  border-radius: 999px;
  background: rgba(15, 118, 110, 0.1);
  color: #0f766e;
  font-size: 12px;
  font-weight: 700;
  white-space: nowrap;
}

.admin-schedules-workbench__metric-strip {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.admin-schedules-workbench__metric-strip article {
  display: grid;
  gap: 6px;
  padding: 12px 14px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.85);
  border: 1px solid rgba(226, 232, 240, 0.9);
}

.admin-schedules-workbench__metric-strip span {
  color: #64748b;
  font-size: 12px;
}

.admin-schedules-workbench__metric-strip strong {
  color: #0f172a;
  font-size: 15px;
}

.admin-schedules-workbench__result {
  min-height: 220px;
}

.admin-schedules-workbench__main {
  display: grid;
  gap: 16px;
}

.admin-schedules-workbench__dual {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.admin-schedules-workbench__panel-form {
  height: 100%;
  align-content: start;
}

.admin-schedules-workbench__panel-head {
  display: grid;
  gap: 6px;
  padding: 2px 0 2px;
}

.admin-schedules-workbench__panel-head strong {
  color: #0f172a;
  font-size: 16px;
}

.admin-schedules-workbench__panel-head p {
  margin: 0;
  color: #64748b;
  line-height: 1.6;
}

.admin-schedules-workbench__compact-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

@media (max-width: 1080px) {
  .admin-schedules-workbench__hero,
  .admin-schedules-workbench__top,
  .admin-schedules-workbench__dual,
  .admin-schedules-workbench__context-form,
  .admin-schedules-workbench__compact-grid {
    grid-template-columns: 1fr;
  }

  .admin-schedules-workbench__metric-strip {
    grid-template-columns: 1fr;
  }
}
</style>
