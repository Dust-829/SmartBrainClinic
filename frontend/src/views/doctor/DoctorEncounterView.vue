<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useRoute, useRouter } from 'vue-router'

import {
  medicalApi,
  type MedicalRecordDraft,
  type MedicalRecordDraftConfirmPayload,
  type MedicalRequestItem,
  type MedicalTechnologyOption,
  type MedicalTechnologyType,
  type RegisterMedicalRequests,
  type SimilarMedicalRecord,
} from '@/api/medical'
import { patientApi, type RegisterDetail } from '@/api/patient'
import SectionCard from '@/components/common/SectionCard.vue'
import { useDoctorSessionStore } from '@/stores/doctorSession'

type OrderType = MedicalTechnologyType

const route = useRoute()
const router = useRouter()
const session = useDoctorSessionStore()

const loading = ref(false)
const errorMessage = ref('')
const draftMissing = ref(false)
const initializingDraft = ref(false)
const savingDraft = ref(false)
const loadingSimilar = ref(false)
const similarCases = ref<SimilarMedicalRecord[]>([])
const assistantQuestion = ref('')
const assistantAnswer = ref('')
const assistantLoading = ref(false)
const registerDetail = ref<RegisterDetail | null>(null)
const technologyLoading = ref(false)
const technologyErrorMessage = ref('')
const queueLoading = ref(false)
const queueErrorMessage = ref('')

let queuePollTimer: number | null = null

const technologyOptions = reactive<Record<OrderType, MedicalTechnologyOption[]>>({
  check: [],
  inspection: [],
  disposal: [],
})

const requestQueue = reactive<RegisterMedicalRequests>({
  checks: [],
  inspections: [],
  disposals: [],
})

const submittingOrder = reactive<Record<OrderType, boolean>>({
  check: false,
  inspection: false,
  disposal: false,
})

const orderForms = reactive({
  check: {
    medicalTechnologyId: null as number | null,
    checkInfo: '',
    checkPosition: '',
  },
  inspection: {
    medicalTechnologyId: null as number | null,
  },
  disposal: {
    medicalTechnologyId: null as number | null,
  },
})

const encounterForm = reactive<MedicalRecordDraftConfirmPayload>({
  readme: '',
  present: '',
  history: '',
  physique: '',
  diagnosis: '',
  allergy: '',
  proposal: '',
  cure: '',
})

const registerId = computed(() => String(route.params.registerId ?? ''))
const doctor = computed(() => session.staff)
const pageTitle = computed(() => registerDetail.value?.patient_name || '接诊详情')
const doctorDisplay = computed(() => doctor.value?.displayName || '当前医生')
const canSubmitCheck = computed(() => Boolean(orderForms.check.medicalTechnologyId) && !submittingOrder.check)
const canSubmitInspection = computed(() => Boolean(orderForms.inspection.medicalTechnologyId) && !submittingOrder.inspection)
const canSubmitDisposal = computed(() => Boolean(orderForms.disposal.medicalTechnologyId) && !submittingOrder.disposal)
const totalRequestCount = computed(
  () => requestQueue.checks.length + requestQueue.inspections.length + requestQueue.disposals.length,
)
const flatRequestItems = computed(() => [...requestQueue.checks, ...requestQueue.inspections, ...requestQueue.disposals])
const unpaidRequestCount = computed(() => flatRequestItems.value.filter((item) => item.state.includes('未缴费')).length)
const paidRequestCount = computed(() => flatRequestItems.value.filter((item) => item.state.includes('已缴费')).length)
const doneRequestCount = computed(() => flatRequestItems.value.filter((item) => item.state.includes('已执行')).length)
const requestGroups = computed(() =>
  [
    { key: 'check', label: '检查', items: requestQueue.checks },
    { key: 'inspection', label: '检验', items: requestQueue.inspections },
    { key: 'disposal', label: '处置', items: requestQueue.disposals },
  ].filter((group) => group.items.length > 0),
)

const canConfirm = computed(
  () =>
    !draftMissing.value &&
    !savingDraft.value &&
    encounterForm.readme.trim() &&
    encounterForm.present.trim() &&
    encounterForm.history.trim() &&
    encounterForm.physique.trim() &&
    encounterForm.diagnosis.trim(),
)

function getErrorMessage(error: unknown, fallback: string) {
  const detail = (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data
  return String(detail?.detail || detail?.message || fallback)
}

function resetEncounterForm(detail: RegisterDetail | null, draft?: MedicalRecordDraft | null) {
  encounterForm.readme = draft?.readme ?? ''
  encounterForm.present = draft?.present ?? detail?.symptoms ?? ''
  encounterForm.history = draft?.history ?? ''
  encounterForm.physique = draft?.physique ?? ''
  encounterForm.diagnosis = draft?.diagnosis ?? ''
  encounterForm.allergy = draft?.allergy ?? ''
  encounterForm.proposal = draft?.proposal ?? ''
  encounterForm.cure = draft?.cure ?? ''
}

function syncOrderSelection(type: OrderType) {
  const selectedId =
    type === 'check'
      ? orderForms.check.medicalTechnologyId
      : type === 'inspection'
      ? orderForms.inspection.medicalTechnologyId
      : orderForms.disposal.medicalTechnologyId

  if (!selectedId) {
    return
  }

  const exists = technologyOptions[type].some((item) => item.id === selectedId)
  if (exists) {
    return
  }

  if (type === 'check') {
    orderForms.check.medicalTechnologyId = null
  } else if (type === 'inspection') {
    orderForms.inspection.medicalTechnologyId = null
  } else {
    orderForms.disposal.medicalTechnologyId = null
  }
}

async function loadMedicalTechnologies() {
  technologyLoading.value = true
  technologyErrorMessage.value = ''

  try {
    const [checks, inspections, disposals] = await Promise.all([
      medicalApi.listTechnologies('check'),
      medicalApi.listTechnologies('inspection'),
      medicalApi.listTechnologies('disposal'),
    ])

    technologyOptions.check = checks.data.data ?? []
    technologyOptions.inspection = inspections.data.data ?? []
    technologyOptions.disposal = disposals.data.data ?? []

    syncOrderSelection('check')
    syncOrderSelection('inspection')
    syncOrderSelection('disposal')
  } catch (error) {
    technologyOptions.check = []
    technologyOptions.inspection = []
    technologyOptions.disposal = []
    technologyErrorMessage.value = getErrorMessage(error, '医技项目加载失败，请稍后重试。')
  } finally {
    technologyLoading.value = false
  }
}

async function loadRequestQueue(options: { silent?: boolean } = {}) {
  if (!registerId.value) {
    return
  }

  if (!options.silent) {
    queueLoading.value = true
  }

  queueErrorMessage.value = ''
  try {
    const response = await medicalApi.getRegisterRequests(registerId.value)
    requestQueue.checks = response.data.data?.checks ?? []
    requestQueue.inspections = response.data.data?.inspections ?? []
    requestQueue.disposals = response.data.data?.disposals ?? []
  } catch (error) {
    requestQueue.checks = []
    requestQueue.inspections = []
    requestQueue.disposals = []
    queueErrorMessage.value = getErrorMessage(error, '本次挂号开单队列加载失败，请稍后重试。')
  } finally {
    if (!options.silent) {
      queueLoading.value = false
    }
  }
}

function stopQueuePolling() {
  if (queuePollTimer !== null) {
    window.clearInterval(queuePollTimer)
    queuePollTimer = null
  }
}

function startQueuePolling() {
  stopQueuePolling()
  if (!registerId.value) {
    return
  }

  queuePollTimer = window.setInterval(() => {
    void loadRequestQueue({ silent: true })
  }, 15000)
}

async function loadEncounter() {
  if (!registerId.value) return

  loading.value = true
  errorMessage.value = ''
  draftMissing.value = false
  similarCases.value = []
  assistantAnswer.value = ''
  assistantQuestion.value = ''

  try {
    const detailResponse = await patientApi.getRegisterDetail(registerId.value)
    const detail = detailResponse.data.data ?? null
    registerDetail.value = detail

    try {
      const draftResponse = await medicalApi.getRecordDraft(registerId.value)
      resetEncounterForm(detail, draftResponse.data.data)
    } catch (error) {
      const status = (error as { response?: { status?: number } }).response?.status
      if (status === 404) {
        draftMissing.value = true
        resetEncounterForm(detail, null)
      } else {
        throw error
      }
    }

    await Promise.all([loadMedicalTechnologies(), loadRequestQueue()])
  } catch (error) {
    registerDetail.value = null
    errorMessage.value = getErrorMessage(error, '接诊详情加载失败，请稍后重试。')
  } finally {
    loading.value = false
  }
}

async function initializeDraft() {
  if (!registerId.value || initializingDraft.value) return

  initializingDraft.value = true
  try {
    await medicalApi.createRecord({
      register_uuid: registerId.value,
      readme: registerDetail.value?.symptoms || '',
      present: registerDetail.value?.symptoms || '',
    })
    ElMessage.success('已初始化病历草稿。')
    await loadEncounter()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '初始化病历草稿失败，请稍后重试。'))
  } finally {
    initializingDraft.value = false
  }
}

async function confirmDraft() {
  if (!registerId.value || !canConfirm.value) return

  savingDraft.value = true
  try {
    await medicalApi.confirmRecordDraft(registerId.value, {
      readme: encounterForm.readme.trim(),
      present: encounterForm.present.trim(),
      history: encounterForm.history.trim(),
      physique: encounterForm.physique.trim(),
      diagnosis: encounterForm.diagnosis.trim(),
      allergy: encounterForm.allergy?.trim() || '',
      proposal: encounterForm.proposal?.trim() || '',
      cure: encounterForm.cure?.trim() || '',
    })
    ElMessage.success('病历已确认，本次接诊已结束。')
    await router.push({ name: 'doctor-home' })
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '确认病历失败，请稍后重试。'))
  } finally {
    savingDraft.value = false
  }
}

function similarQueryText() {
  return [encounterForm.present, encounterForm.history, encounterForm.diagnosis, registerDetail.value?.symptoms]
    .filter(Boolean)
    .join('\n')
    .trim()
}

async function loadSimilarCases() {
  const queryText = similarQueryText()
  if (!queryText || loadingSimilar.value) {
    if (!queryText) {
      ElMessage.warning('请先补充现病史或诊断信息，再召回相似病历。')
    }
    return
  }

  loadingSimilar.value = true
  try {
    const response = await medicalApi.searchSimilarRecords(queryText, 5)
    similarCases.value = response.data.data ?? []
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '相似病历召回失败，请稍后重试。'))
  } finally {
    loadingSimilar.value = false
  }
}

async function askAssistant() {
  const question = assistantQuestion.value.trim()
  if (!question || assistantLoading.value) return

  assistantLoading.value = true
  try {
    const response = await medicalApi.askAssistant({
      patient_uuid: registerDetail.value?.patient_uuid,
      employee_uuid: doctor.value?.employeeUuid,
      question,
      top_k: 5,
      confirm_action: false,
    })
    assistantAnswer.value = response.data.data?.answer ?? ''
  } catch (error) {
    ElMessage.error(getErrorMessage(error, 'AI 助手调用失败，请稍后重试。'))
  } finally {
    assistantLoading.value = false
  }
}

function resetCheckOrderForm() {
  orderForms.check.medicalTechnologyId = null
  orderForms.check.checkInfo = ''
  orderForms.check.checkPosition = ''
}

function resetInspectionOrderForm() {
  orderForms.inspection.medicalTechnologyId = null
}

function resetDisposalOrderForm() {
  orderForms.disposal.medicalTechnologyId = null
}

async function submitCheckOrder() {
  if (!registerId.value || !orderForms.check.medicalTechnologyId || submittingOrder.check) {
    return
  }

  submittingOrder.check = true
  try {
    await medicalApi.createCheck({
      register_uuid: registerId.value,
      medical_technology_id: orderForms.check.medicalTechnologyId,
      check_info: orderForms.check.checkInfo.trim() || undefined,
      check_position: orderForms.check.checkPosition.trim() || undefined,
    })
    ElMessage.success('检查单已开立。')
    resetCheckOrderForm()
    await loadRequestQueue()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '检查单开立失败，请稍后重试。'))
  } finally {
    submittingOrder.check = false
  }
}

async function submitInspectionOrder() {
  if (!registerId.value || !orderForms.inspection.medicalTechnologyId || submittingOrder.inspection) {
    return
  }

  submittingOrder.inspection = true
  try {
    await medicalApi.createInspection({
      register_uuid: registerId.value,
      medical_technology_id: orderForms.inspection.medicalTechnologyId,
    })
    ElMessage.success('检验单已开立。')
    resetInspectionOrderForm()
    await loadRequestQueue()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '检验单开立失败，请稍后重试。'))
  } finally {
    submittingOrder.inspection = false
  }
}

async function submitDisposalOrder() {
  if (!registerId.value || !orderForms.disposal.medicalTechnologyId || submittingOrder.disposal) {
    return
  }

  submittingOrder.disposal = true
  try {
    await medicalApi.createDisposal({
      register_uuid: registerId.value,
      medical_technology_id: orderForms.disposal.medicalTechnologyId,
    })
    ElMessage.success('处置单已开立。')
    resetDisposalOrderForm()
    await loadRequestQueue()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '处置单开立失败，请稍后重试。'))
  } finally {
    submittingOrder.disposal = false
  }
}

function goBack() {
  router.push({ name: 'doctor-home' })
}

function formatPrice(price?: string | null) {
  const value = Number(price || 0)
  return `¥${value.toFixed(2)}`
}

function formatCreationTime(value?: string | null) {
  if (!value) {
    return '刚刚开立'
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return new Intl.DateTimeFormat('zh-CN', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(date)
}

function buildRequestSummary(item: MedicalRequestItem) {
  const parts: string[] = []

  if (item.item_type === 'check') {
    if (item.check_position) {
      parts.push(item.check_position)
    }
    if (item.check_info) {
      parts.push(item.check_info)
    }
  }

  if (item.result) {
    parts.push('已回传结果')
  }

  return parts.join(' · ') || '等待缴费后继续流转'
}

function stateClass(state: string) {
  if (state.includes('已执行')) {
    return 'is-done'
  }
  if (state.includes('已缴费')) {
    return 'is-paid'
  }
  if (state.includes('退')) {
    return 'is-muted'
  }
  return 'is-pending'
}

watch(
  () => registerId.value,
  () => {
    stopQueuePolling()
    void loadEncounter().finally(() => {
      startQueuePolling()
    })
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  stopQueuePolling()
})
</script>

<template>
  <div class="doctor-encounter">
    <section class="doctor-encounter__hero">
      <div class="doctor-encounter__hero-main">
        <span class="doctor-encounter__eyebrow">接诊详情</span>
        <h2>{{ pageTitle }}</h2>
        <p>{{ doctorDisplay }} · {{ registerDetail?.dept_name || doctor?.deptName || '未绑定科室' }}</p>
      </div>
      <div class="doctor-encounter__hero-actions">
        <button type="button" class="doctor-encounter__secondary" @click="goBack">返回工作台</button>
        <button type="button" class="doctor-encounter__primary" :disabled="!canConfirm" @click="confirmDraft">
          {{ savingDraft ? '确认中...' : '确认病历并结束接诊' }}
        </button>
      </div>
    </section>

    <el-skeleton :loading="loading" animated :rows="12">
      <template #default>
        <div v-if="errorMessage" class="doctor-encounter__state is-error">
          <strong>{{ errorMessage }}</strong>
          <button type="button" class="doctor-encounter__secondary" @click="loadEncounter()">重新加载</button>
        </div>

        <template v-else-if="registerDetail">
          <SectionCard title="患者摘要" subtitle="先把挂号、时间段、诊室与主诉收口到同一屏。">
            <div class="doctor-encounter__summary-grid">
              <div>
                <span>患者姓名</span>
                <strong>{{ registerDetail.patient_name || '-' }}</strong>
              </div>
              <div>
                <span>病案号</span>
                <strong>{{ registerDetail.patient_case_number || '-' }}</strong>
              </div>
              <div>
                <span>当前状态</span>
                <strong>{{ registerDetail.visit_state_text || registerDetail.visit_state_str || '-' }}</strong>
              </div>
              <div>
                <span>就诊时间</span>
                <strong>
                  {{ registerDetail.actual_schedule_date || registerDetail.visit_date || '-' }}
                  {{ registerDetail.actual_time_range || '' }}
                </strong>
              </div>
              <div>
                <span>接诊诊室</span>
                <strong>{{ registerDetail.clinic_room_name || '待分配' }}</strong>
              </div>
              <div>
                <span>诊室位置</span>
                <strong>{{ registerDetail.clinic_room_location || '到院导诊屏查看' }}</strong>
              </div>
            </div>
            <div class="doctor-encounter__summary-symptom">
              <span>挂号主诉</span>
              <p>{{ registerDetail.symptoms || '当前挂号未填写症状信息。' }}</p>
            </div>
          </SectionCard>

          <div class="doctor-encounter__workspace">
            <div class="doctor-encounter__main">
              <SectionCard title="检查检验处置" subtitle="左侧主工作区先收口真实开单和已开单状态回看。">
                <template #extra>
                  <div class="doctor-encounter__card-extra">
                    <span class="doctor-encounter__badge is-progress">计划推进中</span>
                    <button type="button" class="doctor-encounter__secondary" :disabled="queueLoading" @click="loadRequestQueue()">
                      {{ queueLoading ? '刷新中...' : '刷新开单队列' }}
                    </button>
                  </div>
                </template>

                <div class="doctor-encounter__order-workspace">
                  <div v-if="technologyErrorMessage" class="doctor-encounter__state is-error">
                    <strong>{{ technologyErrorMessage }}</strong>
                    <button type="button" class="doctor-encounter__secondary" @click="loadMedicalTechnologies()">
                      重试加载项目
                    </button>
                  </div>

                  <div class="doctor-encounter__order-grid">
                    <article class="doctor-encounter__order-panel">
                      <div class="doctor-encounter__order-panel-head">
                        <strong>检查开单</strong>
                        <span>适合影像、功能检查等项目。</span>
                      </div>
                      <label class="doctor-encounter__field">
                        <span>检查项目</span>
                        <select v-model.number="orderForms.check.medicalTechnologyId" :disabled="technologyLoading || !technologyOptions.check.length">
                          <option :value="null">请选择检查项目</option>
                          <option v-for="item in technologyOptions.check" :key="item.uuid" :value="item.id">
                            {{ item.tech_name }} · {{ formatPrice(item.price) }}
                          </option>
                        </select>
                      </label>
                      <label class="doctor-encounter__field">
                        <span>检查部位</span>
                        <input v-model="orderForms.check.checkPosition" type="text" placeholder="例如：头部" />
                      </label>
                      <label class="doctor-encounter__field">
                        <span>检查目的</span>
                        <textarea v-model="orderForms.check.checkInfo" rows="3" placeholder="例如：排查颅内占位性病变。"></textarea>
                      </label>
                      <button type="button" class="doctor-encounter__primary" :disabled="!canSubmitCheck" @click="submitCheckOrder">
                        {{ submittingOrder.check ? '开立中...' : '开立检查单' }}
                      </button>
                    </article>

                    <article class="doctor-encounter__order-panel">
                      <div class="doctor-encounter__order-panel-head">
                        <strong>检验开单</strong>
                        <span>适合血液、生化等基础检验。</span>
                      </div>
                      <label class="doctor-encounter__field">
                        <span>检验项目</span>
                        <select
                          v-model.number="orderForms.inspection.medicalTechnologyId"
                          :disabled="technologyLoading || !technologyOptions.inspection.length"
                        >
                          <option :value="null">请选择检验项目</option>
                          <option v-for="item in technologyOptions.inspection" :key="item.uuid" :value="item.id">
                            {{ item.tech_name }} · {{ formatPrice(item.price) }}
                          </option>
                        </select>
                      </label>
                      <div class="doctor-encounter__hint">
                        当前版本先聚焦真实接口下单，具体检验结果由后续检验端或模拟流程回填。
                      </div>
                      <button type="button" class="doctor-encounter__primary" :disabled="!canSubmitInspection" @click="submitInspectionOrder">
                        {{ submittingOrder.inspection ? '开立中...' : '开立检验单' }}
                      </button>
                    </article>

                    <article class="doctor-encounter__order-panel">
                      <div class="doctor-encounter__order-panel-head">
                        <strong>处置开单</strong>
                        <span>适合门诊即时治疗和观察性处置。</span>
                      </div>
                      <label class="doctor-encounter__field">
                        <span>处置项目</span>
                        <select
                          v-model.number="orderForms.disposal.medicalTechnologyId"
                          :disabled="technologyLoading || !technologyOptions.disposal.length"
                        >
                          <option :value="null">请选择处置项目</option>
                          <option v-for="item in technologyOptions.disposal" :key="item.uuid" :value="item.id">
                            {{ item.tech_name }} · {{ formatPrice(item.price) }}
                          </option>
                        </select>
                      </label>
                      <div class="doctor-encounter__hint">
                        开立后将进入收费与执行链路，当前接诊页先承担医生端入口和状态回显。
                      </div>
                      <button type="button" class="doctor-encounter__primary" :disabled="!canSubmitDisposal" @click="submitDisposalOrder">
                        {{ submittingOrder.disposal ? '开立中...' : '开立处置单' }}
                      </button>
                    </article>
                  </div>

                  <div class="doctor-encounter__queue-summary">
                    <div>
                      <strong>本次挂号已开单 {{ totalRequestCount }} 项</strong>
                      <p>刷新后仍会按挂号重新回查，避免只依赖前端暂存状态。</p>
                    </div>
                    <div class="doctor-encounter__queue-pills">
                      <span class="doctor-encounter__queue-pill">待缴费 {{ unpaidRequestCount }}</span>
                      <span class="doctor-encounter__queue-pill">已缴费 {{ paidRequestCount }}</span>
                      <span class="doctor-encounter__queue-pill">已执行 {{ doneRequestCount }}</span>
                    </div>
                  </div>

                  <div v-if="queueErrorMessage" class="doctor-encounter__state is-error">
                    <strong>{{ queueErrorMessage }}</strong>
                    <button type="button" class="doctor-encounter__secondary" @click="loadRequestQueue()">重新拉取队列</button>
                  </div>

                  <div v-else-if="!totalRequestCount && !queueLoading" class="doctor-encounter__state">
                    <strong>当前还没有已开单项目</strong>
                    <p>可以先从检查、检验或处置中开立一项，随后这里会展示本次挂号的真实开单队列。</p>
                  </div>

                  <div v-else class="doctor-encounter__request-groups">
                    <section v-for="group in requestGroups" :key="group.key" class="doctor-encounter__request-group">
                      <header>
                        <strong>{{ group.label }}</strong>
                        <span>{{ group.items.length }} 项</span>
                      </header>
                      <div class="doctor-encounter__request-list">
                        <article v-for="item in group.items" :key="item.uuid" class="doctor-encounter__request-item">
                          <div class="doctor-encounter__request-header">
                            <div>
                              <strong>{{ item.tech_name || '未命名项目' }}</strong>
                              <p>{{ buildRequestSummary(item) }}</p>
                            </div>
                            <span class="doctor-encounter__request-state" :class="stateClass(item.state)">
                              {{ item.state }}
                            </span>
                          </div>
                          <div class="doctor-encounter__request-footer">
                            <span>{{ formatPrice(item.price) }}</span>
                            <span>{{ formatCreationTime(item.creation_time) }}</span>
                          </div>
                        </article>
                      </div>
                    </section>
                  </div>
                </div>
              </SectionCard>

              <SectionCard title="AI 病历草稿" subtitle="医生最终确认后生效，本次接诊结束时回写病历。">
                <template #extra>
                  <span class="doctor-encounter__badge is-live">已实现</span>
                </template>

                <div v-if="draftMissing" class="doctor-encounter__state">
                  <strong>当前挂号还没有可编辑的病历草稿</strong>
                  <p>这通常是支付后的异步草稿尚未生成，或者演示数据还未初始化。</p>
                  <button type="button" class="doctor-encounter__primary" :disabled="initializingDraft" @click="initializeDraft">
                    {{ initializingDraft ? '初始化中...' : '初始化病历草稿' }}
                  </button>
                </div>

                <div v-else class="doctor-encounter__form">
                  <label>
                    <span>主诉</span>
                    <textarea v-model="encounterForm.readme" rows="3" placeholder="例如：头痛伴恶心两周。"></textarea>
                  </label>
                  <label>
                    <span>现病史</span>
                    <textarea
                      v-model="encounterForm.present"
                      rows="5"
                      placeholder="补充症状演变、持续时间、伴随症状与外院检查情况。"
                    ></textarea>
                  </label>
                  <label>
                    <span>病史</span>
                    <textarea v-model="encounterForm.history" rows="4" placeholder="补充既往相关病史、用药史、家族史等。"></textarea>
                  </label>
                  <label>
                    <span>查体</span>
                    <textarea v-model="encounterForm.physique" rows="4" placeholder="补充神经系统查体、生命体征与阳性体征。"></textarea>
                  </label>
                  <label>
                    <span>诊断</span>
                    <textarea v-model="encounterForm.diagnosis" rows="3" placeholder="填写初步诊断或待排诊断。"></textarea>
                  </label>
                  <div class="doctor-encounter__form-grid">
                    <label>
                      <span>过敏史</span>
                      <textarea v-model="encounterForm.allergy" rows="3" placeholder="无则写无。"></textarea>
                    </label>
                    <label>
                      <span>检查建议</span>
                      <textarea v-model="encounterForm.proposal" rows="3" placeholder="例如：建议头颅增强 MRI、血管评估等。"></textarea>
                    </label>
                  </div>
                  <label>
                    <span>处置 / 治疗建议</span>
                    <textarea v-model="encounterForm.cure" rows="4" placeholder="填写对症处理、复诊或住院建议。"></textarea>
                  </label>
                </div>
              </SectionCard>
            </div>

            <aside class="doctor-encounter__sidebar">
              <SectionCard title="相似病历召回" subtitle="用当前症状与诊断去召回已确认的历史病历。">
                <template #extra>
                  <span class="doctor-encounter__badge is-live">已实现</span>
                </template>

                <div class="doctor-encounter__panel-actions">
                  <button type="button" class="doctor-encounter__secondary" :disabled="loadingSimilar || draftMissing" @click="loadSimilarCases">
                    {{ loadingSimilar ? '召回中...' : '召回相似病历' }}
                  </button>
                </div>

                <div v-if="similarCases.length" class="doctor-encounter__similar-list">
                  <article v-for="item in similarCases" :key="item.uuid" class="doctor-encounter__similar-item">
                    <strong>{{ item.diagnosis || '未填写诊断' }}</strong>
                    <p>{{ item.present || item.history || '该病例未保留足够摘要。' }}</p>
                    <span>相似度 {{ item.similarity_score.toFixed(1) }}</span>
                  </article>
                </div>
                <div v-else class="doctor-encounter__state is-plain">
                  <strong>暂无召回结果</strong>
                  <p>可能还没有已确认历史病历，或者当前症状信息还不够完整。</p>
                </div>
              </SectionCard>

              <SectionCard title="AI 医生助手" subtitle="右侧只保留辅助位，不再和主工作区抢层级。">
                <template #extra>
                  <span class="doctor-encounter__badge is-live">已实现</span>
                </template>

                <div class="doctor-encounter__assistant">
                  <textarea
                    v-model="assistantQuestion"
                    rows="4"
                    placeholder="例如：当前症状更需要优先排查占位性病变还是脑血管问题？"
                  ></textarea>
                  <div class="doctor-encounter__panel-actions">
                    <button type="button" class="doctor-encounter__primary" :disabled="assistantLoading || !assistantQuestion.trim()" @click="askAssistant">
                      {{ assistantLoading ? '分析中...' : '询问 AI 助手' }}
                    </button>
                  </div>
                  <div v-if="assistantAnswer" class="doctor-encounter__assistant-answer">
                    <strong>助手回复</strong>
                    <p>{{ assistantAnswer }}</p>
                  </div>
                </div>
              </SectionCard>
            </aside>
          </div>
        </template>
      </template>
    </el-skeleton>
  </div>
</template>

<style scoped>
.doctor-encounter {
  display: grid;
  gap: 20px;
}

.doctor-encounter__hero {
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  gap: 18px;
  padding: 24px;
  border-radius: 18px;
  background: linear-gradient(135deg, #0f766e 0%, #115e59 100%);
  color: #ffffff;
}

.doctor-encounter__hero-main {
  display: grid;
  gap: 8px;
}

.doctor-encounter__eyebrow {
  color: rgba(255, 255, 255, 0.82);
  font-size: 13px;
  font-weight: 700;
}

.doctor-encounter__hero h2,
.doctor-encounter__hero p {
  margin: 0;
}

.doctor-encounter__hero h2 {
  font-size: 30px;
  line-height: 1.1;
}

.doctor-encounter__hero p {
  color: rgba(255, 255, 255, 0.86);
  line-height: 1.6;
}

.doctor-encounter__hero-actions,
.doctor-encounter__panel-actions,
.doctor-encounter__card-extra {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}

.doctor-encounter__primary,
.doctor-encounter__secondary,
.doctor-encounter__state button {
  min-height: 40px;
  padding: 0 16px;
  border: 0;
  border-radius: 10px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

.doctor-encounter__primary {
  background: #0f172a;
  color: #ffffff;
}

.doctor-encounter__secondary,
.doctor-encounter__state button {
  background: #e2e8f0;
  color: #0f172a;
}

.doctor-encounter__primary:disabled,
.doctor-encounter__secondary:disabled,
.doctor-encounter__state button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.doctor-encounter__badge {
  display: inline-flex;
  align-items: center;
  min-height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
}

.doctor-encounter__badge.is-live {
  background: #ecfdf5;
  color: #047857;
}

.doctor-encounter__badge.is-progress {
  background: #eff6ff;
  color: #1d4ed8;
}

.doctor-encounter__summary-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.doctor-encounter__summary-grid div,
.doctor-encounter__summary-symptom {
  display: grid;
  gap: 6px;
  padding: 14px;
  border-radius: 14px;
  background: #f8fafc;
}

.doctor-encounter__summary-grid span,
.doctor-encounter__summary-symptom span {
  color: #64748b;
  font-size: 12px;
}

.doctor-encounter__summary-grid strong,
.doctor-encounter__summary-symptom p {
  margin: 0;
  color: #0f172a;
}

.doctor-encounter__summary-symptom {
  margin-top: 14px;
}

.doctor-encounter__workspace {
  display: grid;
  grid-template-columns: minmax(0, 1.72fr) minmax(300px, 0.68fr);
  gap: 20px;
  align-items: start;
}

.doctor-encounter__main,
.doctor-encounter__sidebar,
.doctor-encounter__order-workspace,
.doctor-encounter__request-groups,
.doctor-encounter__request-list,
.doctor-encounter__similar-list,
.doctor-encounter__form {
  display: grid;
  gap: 16px;
}

.doctor-encounter__order-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.doctor-encounter__order-panel,
.doctor-encounter__request-group,
.doctor-encounter__similar-item,
.doctor-encounter__request-item {
  display: grid;
  gap: 12px;
  padding: 16px;
  border: 1px solid #dbe5f0;
  border-radius: 16px;
  background: #f8fafc;
}

.doctor-encounter__order-panel-head,
.doctor-encounter__queue-summary,
.doctor-encounter__request-header,
.doctor-encounter__request-footer,
.doctor-encounter__request-group header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.doctor-encounter__order-panel-head {
  align-items: flex-start;
  flex-direction: column;
}

.doctor-encounter__order-panel-head strong,
.doctor-encounter__queue-summary strong,
.doctor-encounter__request-header strong,
.doctor-encounter__request-group strong,
.doctor-encounter__similar-item strong,
.doctor-encounter__assistant-answer strong,
.doctor-encounter__state strong {
  color: #0f172a;
}

.doctor-encounter__order-panel-head span,
.doctor-encounter__queue-summary p,
.doctor-encounter__request-header p,
.doctor-encounter__request-group span,
.doctor-encounter__hint,
.doctor-encounter__similar-item p,
.doctor-encounter__assistant-answer p,
.doctor-encounter__state p {
  margin: 0;
  color: #64748b;
  font-size: 13px;
  line-height: 1.6;
}

.doctor-encounter__field,
.doctor-encounter__form label,
.doctor-encounter__assistant {
  display: grid;
  gap: 8px;
}

.doctor-encounter__field span,
.doctor-encounter__form span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.doctor-encounter__field input,
.doctor-encounter__field select,
.doctor-encounter__field textarea,
.doctor-encounter__form textarea,
.doctor-encounter__assistant textarea {
  width: 100%;
  padding: 12px 14px;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  line-height: 1.6;
  box-sizing: border-box;
}

.doctor-encounter__field textarea,
.doctor-encounter__form textarea,
.doctor-encounter__assistant textarea {
  resize: vertical;
}

.doctor-encounter__field input:focus,
.doctor-encounter__field select:focus,
.doctor-encounter__field textarea:focus,
.doctor-encounter__form textarea:focus,
.doctor-encounter__assistant textarea:focus {
  outline: none;
  border-color: #0f766e;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.12);
}

.doctor-encounter__queue-summary {
  padding: 14px 16px;
  border-radius: 16px;
  background: #f0fdfa;
  border: 1px solid #99f6e4;
}

.doctor-encounter__queue-summary p {
  margin-top: 6px;
}

.doctor-encounter__queue-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.doctor-encounter__queue-pill {
  display: inline-flex;
  align-items: center;
  min-height: 32px;
  padding: 0 12px;
  border-radius: 999px;
  background: rgba(15, 118, 110, 0.12);
  color: #115e59;
  font-size: 12px;
  font-weight: 700;
}

.doctor-encounter__request-item {
  background: #ffffff;
}

.doctor-encounter__request-header {
  align-items: flex-start;
}

.doctor-encounter__request-footer {
  color: #475569;
  font-size: 12px;
  font-weight: 600;
}

.doctor-encounter__request-state {
  display: inline-flex;
  align-items: center;
  min-height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  white-space: nowrap;
}

.doctor-encounter__request-state.is-pending {
  background: #fff7ed;
  color: #c2410c;
}

.doctor-encounter__request-state.is-paid {
  background: #eff6ff;
  color: #1d4ed8;
}

.doctor-encounter__request-state.is-done {
  background: #ecfdf5;
  color: #047857;
}

.doctor-encounter__request-state.is-muted {
  background: #f1f5f9;
  color: #475569;
}

.doctor-encounter__form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.doctor-encounter__similar-item span {
  color: #0369a1;
  font-size: 12px;
  font-weight: 700;
}

.doctor-encounter__assistant-answer {
  display: grid;
  gap: 8px;
  padding: 14px;
  border-radius: 14px;
  background: #ecfeff;
  border: 1px solid #99f6e4;
}

.doctor-encounter__state {
  display: grid;
  gap: 10px;
  justify-items: start;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.doctor-encounter__state.is-error {
  background: #fff7ed;
  border-color: #fdba74;
}

.doctor-encounter__state.is-plain {
  padding: 0;
  border: 0;
  background: transparent;
}

@media (max-width: 1180px) {
  .doctor-encounter__workspace,
  .doctor-encounter__order-grid,
  .doctor-encounter__summary-grid {
    grid-template-columns: 1fr;
  }

  .doctor-encounter__hero {
    flex-direction: column;
  }
}

@media (max-width: 720px) {
  .doctor-encounter__hero-actions,
  .doctor-encounter__panel-actions,
  .doctor-encounter__card-extra,
  .doctor-encounter__queue-summary,
  .doctor-encounter__request-header,
  .doctor-encounter__request-footer,
  .doctor-encounter__request-group header {
    flex-direction: column;
    align-items: stretch;
  }

  .doctor-encounter__hero-actions button,
  .doctor-encounter__panel-actions button,
  .doctor-encounter__card-extra button {
    width: 100%;
  }

  .doctor-encounter__form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
