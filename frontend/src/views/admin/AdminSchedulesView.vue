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
import { authApi, type DoctorDirectoryItem } from '@/api/auth'
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
  clinic_room_uuid: '',
})

const actualForm = reactive({
  schedule_date: new Date().toISOString().slice(0, 10),
  noon: '上午',
  regist_quota: 20,
  clinic_room_uuid: '',
})

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

function formatDateTime(value?: string | null) {
  if (!value) return '暂无时间'
  return value.replace('T', ' ').slice(0, 16)
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

function formatRuleResult(result: ScheduleRuleResult) {
  return [
    `排班规则已更新：${result.employee_uuid}`,
    `week_rule：${result.week_rule ?? '未返回'}`,
    `quota：${result.regist_quota ?? '未返回'}`,
    `clinic_room_uuid：${result.clinic_room_uuid ?? '未设置'}`,
  ].join('\n')
}

function formatActualResult(result: ScheduleActualResult) {
  return [
    `实际排班已处理：${result.employee_uuid}`,
    `日期：${result.schedule_date ?? '-'}`,
    `午别：${result.noon ?? '-'}`,
    `状态：${result.status ?? '-'}`,
    `最终 quota：${result.regist_quota ?? '-'}`,
    `已挂号人数：${result.registered_count ?? '-'}`,
    `产生 disruption：${result.disruptions_created ?? 0}`,
    `clinic_room_uuid：${result.clinic_room_uuid ?? '未设置'}`,
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
    const response = await adminApi.updateSchedulingRule({
      employee_uuid: employeeUuid,
      rule_name: ruleForm.rule_name,
      week_rule: ruleForm.week_rule,
      llm_text_rule: ruleForm.llm_text_rule,
      regist_quota: ruleForm.regist_quota,
      clinic_room_uuid: ruleForm.clinic_room_uuid.trim() || undefined,
    })
    lastResult.value = formatRuleResult(response.data.data)
    ElMessage.success('排班规则已更新')
  } finally {
    updatingRule.value = false
  }
}

async function submitActualUpdate() {
  updatingActual.value = true
  try {
    const employeeUuid = ensureSelectedDoctorUuid()
    const response = await adminApi.updateSchedulingActual({
      employee_uuid: employeeUuid,
      schedule_date: actualForm.schedule_date,
      noon: actualForm.noon,
      regist_quota: actualForm.regist_quota,
      clinic_room_uuid: actualForm.clinic_room_uuid.trim() || undefined,
    })
    const result = response.data.data
    lastResult.value = formatActualResult(result)
    ElMessage.success(`实际排班已处理，状态：${result.status ?? 'success'}`)
  } finally {
    updatingActual.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadDoctorDirectory(), loadApplications()])
})
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>管理员端主打模块</span>
        <h2>智能排班中心</h2>
        <p>突出 AI 生成建议、人工规则干预、实际排班调整和审批链路。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="医生选择" subtitle="先选科室和医生，后续排班动作都复用该医生。">
        <div v-if="doctorDirectoryError" class="admin-empty">
          <p>{{ doctorDirectoryError }}</p>
          <button type="button" class="admin-inline-button" :disabled="loadingDoctorDirectory" @click="loadDoctorDirectory">
            {{ loadingDoctorDirectory ? '重新加载中...' : '重新加载医生目录' }}
          </button>
        </div>
        <form v-else class="admin-form" @submit.prevent>
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
          <div v-if="selectedDoctor" class="admin-empty">
            <p>当前医生：{{ selectedDoctor.realname }}</p>
            <p>科室：{{ selectedDoctor.deptName }}</p>
            <p>专长：{{ selectedDoctor.expertise || '暂无专长信息' }}</p>
          </div>
        </form>
      </SectionCard>

      <SectionCard title="常规排班生成" subtitle="按时间范围批量生成门诊实际排班。">
        <form class="admin-form" @submit.prevent="submitGenerate">
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
      </SectionCard>

      <SectionCard title="AI 排班微调" subtitle="基于已选医生和自然语言指令执行排班微调。">
        <form class="admin-form" @submit.prevent="submitAiAdjust">
          <label>
            <span>当前医生</span>
            <input :value="selectedDoctor ? `${selectedDoctor.realname} (${selectedDoctor.deptName})` : '请先选择医生'" type="text" disabled />
          </label>
          <label>
            <span>微调指令</span>
            <textarea
              v-model="aiForm.prompt"
              rows="4"
              placeholder="例如：该医生下周三下午有手术，请改到周四下午坐诊"
            />
          </label>
          <button type="submit" :disabled="adjustingAi || !selectedDoctor">
            {{ adjustingAi ? '提交中...' : '提交 AI 微调' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="管理员规则干预" subtitle="直接覆盖已选医生的排班规则和号源配置。">
        <form class="admin-form" @submit.prevent="submitRuleUpdate">
          <label>
            <span>当前医生</span>
            <input :value="selectedDoctor ? `${selectedDoctor.realname} (${selectedDoctor.deptName})` : '请先选择医生'" type="text" disabled />
          </label>
          <label>
            <span>规则名称</span>
            <input v-model="ruleForm.rule_name" type="text" />
          </label>
          <label>
            <span>周规则</span>
            <input v-model="ruleForm.week_rule" type="text" placeholder="1,2,3,4,5" />
          </label>
          <label>
            <span>自然语言规则</span>
            <textarea v-model="ruleForm.llm_text_rule" rows="3" />
          </label>
          <label>
            <span>号源数量</span>
            <input v-model.number="ruleForm.regist_quota" type="number" min="0" />
          </label>
          <label>
            <span>诊室 UUID（可选）</span>
            <input v-model="ruleForm.clinic_room_uuid" type="text" />
          </label>
          <button type="submit" :disabled="updatingRule || !selectedDoctor">
            {{ updatingRule ? '保存中...' : '保存规则' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="实际排班调整" subtitle="用于停诊、缩容、加号和诊室变更。">
        <form class="admin-form" @submit.prevent="submitActualUpdate">
          <label>
            <span>当前医生</span>
            <input :value="selectedDoctor ? `${selectedDoctor.realname} (${selectedDoctor.deptName})` : '请先选择医生'" type="text" disabled />
          </label>
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
          <label>
            <span>号源数量</span>
            <input v-model.number="actualForm.regist_quota" type="number" min="0" />
          </label>
          <label>
            <span>诊室 UUID（可选）</span>
            <input v-model="actualForm.clinic_room_uuid" type="text" />
          </label>
          <button type="submit" :disabled="updatingActual || !selectedDoctor">
            {{ updatingActual ? '更新中...' : '更新实际排班' }}
          </button>
        </form>
      </SectionCard>
    </div>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="待审批排班申请" subtitle="与审批中心保持联通，便于这里先看到排班压力。">
        <template #extra>
          <button type="button" class="admin-inline-button" :disabled="loadingApplications" @click="loadApplications">
            {{ loadingApplications ? '刷新中...' : '刷新申请' }}
          </button>
        </template>

        <div v-if="applications.length" class="admin-list">
          <article v-for="item in applications" :key="item.uuid" class="admin-list__item">
            <strong>{{ item.employee_uuid }}</strong>
            <p>{{ item.prompt }}</p>
            <span>{{ formatDateTime(item.created_at) }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有待审批排班申请。</div>
      </SectionCard>

      <SectionCard title="最近操作结果" subtitle="直接展示后端真实返回，便于验证动作是否生效。">
        <pre class="admin-result">{{ lastResult }}</pre>
      </SectionCard>
    </div>
  </div>
</template>
