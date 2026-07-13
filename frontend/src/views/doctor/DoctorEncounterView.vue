<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useRoute, useRouter } from 'vue-router'

import {
  type ArtifactInferenceTask,
  type ArtifactInputSource,
  type InspectionReportResultItem,
  type MedicalReport,
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

interface PendingOrder {
  localId: number
  type: OrderType
  medicalTechnologyId: number
  technologyName: string
  price: string
  checkInfo?: string
  checkPosition?: string
}

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
const signingOrders = ref(false)
const artifactSources = ref<ArtifactInputSource[]>([])
const artifactSourcesLoading = ref(false)
const artifactSourcesError = ref('')
const expandedArtifactCheckUuid = ref<string | null>(null)
const artifactTaskByCheck = reactive<Record<string, ArtifactInferenceTask | null>>({})
const artifactSourceByCheck = reactive<Record<string, string>>({})
const artifactSubmittingByCheck = reactive<Record<string, boolean>>({})
const expandedReportCheckUuid = ref<string | null>(null)
const reportByCheck = reactive<Record<string, MedicalReport | null>>({})
const reportDraftByCheck = reactive<Record<string, string>>({})
const reportSavingByCheck = reactive<Record<string, boolean>>({})
const reportPublishingByCheck = reactive<Record<string, boolean>>({})
const reportCorrectingByCheck = reactive<Record<string, boolean>>({})
const expandedReportInspectionUuid = ref<string | null>(null)
const reportByInspection = reactive<Record<string, MedicalReport | null>>({})
const reportDraftByInspection = reactive<Record<string, string>>({})
const reportResultsByInspection = reactive<Record<string, InspectionReportResultItem[]>>({})
const reportSavingByInspection = reactive<Record<string, boolean>>({})
const reportPublishingByInspection = reactive<Record<string, boolean>>({})
const reportCorrectingByInspection = reactive<Record<string, boolean>>({})

let queuePollTimer: number | null = null
let artifactTaskPollTimer: number | null = null
let pendingOrderSequence = 0

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

const orderDraft = reactive({
  medicalTechnologyId: null as number | null,
  checkInfo: '',
  checkPosition: '',
})
const pendingOrders = ref<PendingOrder[]>([])

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
const allTechnologyOptions = computed(() => [
  ...technologyOptions.check.map((item) => ({ ...item, orderType: 'check' as const })),
  ...technologyOptions.inspection.map((item) => ({ ...item, orderType: 'inspection' as const })),
  ...technologyOptions.disposal.map((item) => ({ ...item, orderType: 'disposal' as const })),
])
const selectedTechnology = computed(
  () => allTechnologyOptions.value.find((item) => item.id === orderDraft.medicalTechnologyId) ?? null,
)
const selectedOrderType = computed(() => selectedTechnology.value?.orderType ?? null)
const canAddPendingOrder = computed(() => {
  if (!selectedTechnology.value || signingOrders.value) return false
  if (selectedOrderType.value !== 'check') return true
  return Boolean(orderDraft.checkPosition.trim() && orderDraft.checkInfo.trim())
})
const canSignOrders = computed(() => pendingOrders.value.length > 0 && !signingOrders.value)
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

function resetOrderDraft() {
  orderDraft.medicalTechnologyId = null
  orderDraft.checkInfo = ''
  orderDraft.checkPosition = ''
}

function syncOrderSelection() {
  if (!orderDraft.medicalTechnologyId) return
  if (!allTechnologyOptions.value.some((item) => item.id === orderDraft.medicalTechnologyId)) {
    resetOrderDraft()
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

    syncOrderSelection()
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
    await Promise.all([loadArtifactTasks(), loadCheckReports(), loadInspectionReports()])
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

async function loadArtifactSources() {
  artifactSourcesLoading.value = true
  artifactSourcesError.value = ''
  try {
    const response = await medicalApi.listArtifactInputSources()
    artifactSources.value = response.data.data ?? []
  } catch (error) {
    artifactSources.value = []
    artifactSourcesError.value = getErrorMessage(error, '本地影像序列暂时不可读取。')
  } finally {
    artifactSourcesLoading.value = false
  }
}

async function loadArtifactTasks() {
  const checks = requestQueue.checks
  await Promise.all(
    checks.map(async (item) => {
      try {
        const response = await medicalApi.getLatestArtifactInferenceTask(item.uuid)
        artifactTaskByCheck[item.uuid] = response.data.data ?? null
      } catch (error) {
        const status = (error as { response?: { status?: number } }).response?.status
        if (status === 404) {
          artifactTaskByCheck[item.uuid] = null
        }
      }
    }),
  )
  syncArtifactTaskPolling()
}

async function loadCheckReports() {
  await Promise.all(
    requestQueue.checks.map(async (item) => {
      try {
        const response = await medicalApi.getLatestCheckReport(item.uuid)
        const report = response.data.data ?? null
        reportByCheck[item.uuid] = report
        if (report && (reportDraftByCheck[item.uuid] === undefined || report.report_state === 'published')) {
          reportDraftByCheck[item.uuid] = report.conclusion ?? ''
        }
      } catch (error) {
        const status = (error as { response?: { status?: number } }).response?.status
        if (status === 404) {
          reportByCheck[item.uuid] = null
          if (reportDraftByCheck[item.uuid] === undefined) {
            reportDraftByCheck[item.uuid] = ''
          }
        }
      }
    }),
  )
}

function emptyInspectionResult(): InspectionReportResultItem {
  return { item_name: '', value: '', unit: '', reference_range: '' }
}

function normalizeInspectionResults(value: MedicalReport['structured_result']): InspectionReportResultItem[] {
  if (!Array.isArray(value) || !value.length) return [emptyInspectionResult()]
  return value.map((item) => ({
    item_name: String(item.item_name ?? ''),
    value: String(item.value ?? ''),
    unit: item.unit ?? '',
    reference_range: item.reference_range ?? '',
  }))
}

async function loadInspectionReports() {
  await Promise.all(
    requestQueue.inspections.map(async (item) => {
      try {
        const response = await medicalApi.getLatestInspectionReport(item.uuid)
        const report = response.data.data ?? null
        reportByInspection[item.uuid] = report
        if (report && (reportDraftByInspection[item.uuid] === undefined || report.report_state === 'published')) {
          reportDraftByInspection[item.uuid] = report.conclusion ?? ''
          reportResultsByInspection[item.uuid] = normalizeInspectionResults(report.structured_result)
        }
      } catch (error) {
        const status = (error as { response?: { status?: number } }).response?.status
        if (status === 404) {
          reportByInspection[item.uuid] = null
          reportDraftByInspection[item.uuid] ??= ''
          reportResultsByInspection[item.uuid] ??= [emptyInspectionResult()]
        }
      }
    }),
  )
}

function stopQueuePolling() {
  if (queuePollTimer !== null) {
    window.clearInterval(queuePollTimer)
    queuePollTimer = null
  }
}

function stopArtifactTaskPolling() {
  if (artifactTaskPollTimer !== null) {
    window.clearInterval(artifactTaskPollTimer)
    artifactTaskPollTimer = null
  }
}

function syncArtifactTaskPolling() {
  const hasActiveTask = requestQueue.checks.some((item) => {
    const task = artifactTaskByCheck[item.uuid]
    return task?.task_state === 'queued' || task?.task_state === 'running'
  })

  if (!hasActiveTask) {
    stopArtifactTaskPolling()
    return
  }

  if (artifactTaskPollTimer !== null) return
  artifactTaskPollTimer = window.setInterval(() => {
    void loadArtifactTasks()
  }, 5000)
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

    await Promise.all([loadMedicalTechnologies(), loadRequestQueue(), loadArtifactSources()])
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

function addPendingOrder() {
  const technology = selectedTechnology.value
  if (!technology || !canAddPendingOrder.value) return

  pendingOrders.value.push({
    localId: ++pendingOrderSequence,
    type: technology.orderType,
    medicalTechnologyId: technology.id,
    technologyName: technology.tech_name,
    price: technology.price,
    checkInfo: technology.orderType === 'check' ? orderDraft.checkInfo.trim() : undefined,
    checkPosition: technology.orderType === 'check' ? orderDraft.checkPosition.trim() : undefined,
  })
  resetOrderDraft()
}

function removePendingOrder(localId: number) {
  if (signingOrders.value) return
  pendingOrders.value = pendingOrders.value.filter((item) => item.localId !== localId)
}

function editPendingOrder(localId: number) {
  if (signingOrders.value) return
  const index = pendingOrders.value.findIndex((item) => item.localId === localId)
  if (index < 0) return

  const [item] = pendingOrders.value.splice(index, 1)
  orderDraft.medicalTechnologyId = item.medicalTechnologyId
  orderDraft.checkInfo = item.checkInfo ?? ''
  orderDraft.checkPosition = item.checkPosition ?? ''
}

async function signPendingOrders() {
  if (!registerId.value || !canSignOrders.value) return

  signingOrders.value = true
  try {
    const response = await medicalApi.signOrders({
      register_uuid: registerId.value,
      items: pendingOrders.value.map((item) => ({
        type: item.type,
        medical_technology_id: item.medicalTechnologyId,
        check_info: item.checkInfo,
        check_position: item.checkPosition,
      })),
    })
    const count = response.data.data?.count ?? pendingOrders.value.length
    pendingOrders.value = []
    ElMessage.success(`已一次签署并开立 ${count} 项医疗项目。`)
    await loadRequestQueue()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '统一签署失败，待签清单已保留，请修正后重试。'))
  } finally {
    signingOrders.value = false
  }
}

function goBack() {
  router.push({ name: 'doctor-home' })
}

function medicalTypeLabel(type: OrderType | string) {
  if (type === 'check') return '检查'
  if (type === 'inspection') return '检验'
  return '处置'
}

function pendingOrderSummary(item: PendingOrder) {
  if (item.type !== 'check') return '无需补充信息'
  return [item.checkPosition, item.checkInfo].filter(Boolean).join(' · ')
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

function toggleArtifactAnalysis(checkUuid: string) {
  expandedArtifactCheckUuid.value = expandedArtifactCheckUuid.value === checkUuid ? null : checkUuid
}

function isArtifactAnalysisEligible(item: MedicalRequestItem) {
  return item.state.includes('已缴费') || item.state.includes('已执行')
}

function artifactTaskStateLabel(state?: ArtifactInferenceTask['task_state']) {
  if (state === 'queued') return '等待分析'
  if (state === 'running') return '分析中'
  if (state === 'succeeded') return '分析已完成'
  if (state === 'failed') return '分析暂未完成'
  return '尚未分析'
}

function artifactTaskStateClass(state?: ArtifactInferenceTask['task_state']) {
  if (state === 'succeeded') return 'is-complete'
  if (state === 'running' || state === 'queued') return 'is-processing'
  if (state === 'failed') return 'is-idle'
  return 'is-idle'
}

function selectedArtifactSource(checkUuid: string) {
  const sourceRef = artifactSourceByCheck[checkUuid]
  return artifactSources.value.find((item) => item.source_ref === sourceRef) ?? null
}

function canSubmitArtifactTask(item: MedicalRequestItem) {
  return Boolean(
    doctor.value?.employeeUuid &&
      isArtifactAnalysisEligible(item) &&
      selectedArtifactSource(item.uuid) &&
      !artifactSubmittingByCheck[item.uuid],
  )
}

async function submitArtifactTask(item: MedicalRequestItem) {
  const source = selectedArtifactSource(item.uuid)
  const employeeUuid = doctor.value?.employeeUuid
  if (!source || !employeeUuid || !canSubmitArtifactTask(item)) return

  artifactSubmittingByCheck[item.uuid] = true
  try {
    const response = await medicalApi.submitArtifactInferenceTask(item.uuid, {
      source_image_ref: source.source_ref,
      source_format: source.source_format,
      submitted_by_employee_uuid: employeeUuid,
    })
    artifactTaskByCheck[item.uuid] = response.data.data ?? null
    expandedArtifactCheckUuid.value = item.uuid
    ElMessage.success('伪影分析任务已提交。')
    syncArtifactTaskPolling()
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '伪影分析任务提交失败，请稍后重试。'))
  } finally {
    artifactSubmittingByCheck[item.uuid] = false
  }
}

function artifactOverlayUrl(task: ArtifactInferenceTask) {
  return task.overlay_object_ref ? medicalApi.getArtifactInferenceOverlayUrl(task.uuid) : ''
}

function toggleCheckReport(checkUuid: string) {
  expandedReportCheckUuid.value = expandedReportCheckUuid.value === checkUuid ? null : checkUuid
}

function isCheckReportEligible(item: MedicalRequestItem) {
  return item.state.includes('已执行')
}

function checkReportStateLabel(report?: MedicalReport | null) {
  if (report?.report_state === 'published') return '已发布'
  if (report?.report_state === 'draft') return '草稿待审核'
  return '尚未填写'
}

function checkReportStateClass(report?: MedicalReport | null) {
  if (report?.report_state === 'published') return 'is-complete'
  if (report?.report_state === 'draft') return 'is-processing'
  return 'is-idle'
}

function canSaveCheckReport(item: MedicalRequestItem) {
  const report = reportByCheck[item.uuid]
  return Boolean(
    doctor.value?.employeeUuid &&
    isCheckReportEligible(item) &&
      report?.report_state !== 'published' &&
      reportDraftByCheck[item.uuid]?.trim() &&
      !reportSavingByCheck[item.uuid],
  )
}

async function saveCheckReportDraft(item: MedicalRequestItem, silent = false) {
  if (!canSaveCheckReport(item)) return null

  reportSavingByCheck[item.uuid] = true
  try {
    const task = artifactTaskByCheck[item.uuid]
    const response = await medicalApi.saveCheckReportDraft(item.uuid, {
      conclusion: reportDraftByCheck[item.uuid].trim(),
      artifact_task_uuid: task?.task_state === 'succeeded' ? task.uuid : undefined,
      author_employee_uuid: doctor.value?.employeeUuid ?? '',
    })
    const report = response.data.data ?? null
    reportByCheck[item.uuid] = report
    if (!silent) ElMessage.success('检查报告草稿已保存。')
    return report
  } catch (error) {
    if (!silent) ElMessage.error(getErrorMessage(error, '检查报告草稿保存失败，请稍后重试。'))
    return null
  } finally {
    reportSavingByCheck[item.uuid] = false
  }
}

function canCreateCheckReportCorrection(item: MedicalRequestItem) {
  return Boolean(
    doctor.value?.employeeUuid &&
      isCheckReportEligible(item) &&
      reportByCheck[item.uuid]?.report_state === 'published' &&
      !reportCorrectingByCheck[item.uuid],
  )
}

async function createCheckReportCorrectionDraft(item: MedicalRequestItem) {
  const report = reportByCheck[item.uuid]
  const employeeUuid = doctor.value?.employeeUuid
  if (!report || !employeeUuid || !canCreateCheckReportCorrection(item)) return

  reportCorrectingByCheck[item.uuid] = true
  try {
    const response = await medicalApi.createCheckReportCorrectionDraft(report.uuid, employeeUuid)
    const correction = response.data.data ?? null
    reportByCheck[item.uuid] = correction
    reportDraftByCheck[item.uuid] = correction?.conclusion ?? ''
    ElMessage.success('已创建更正草稿，可继续调整结论后审核发布。')
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '创建报告更正草稿失败，请稍后重试。'))
  } finally {
    reportCorrectingByCheck[item.uuid] = false
  }
}

function canPublishCheckReport(item: MedicalRequestItem) {
  const report = reportByCheck[item.uuid]
  return Boolean(
    doctor.value?.employeeUuid &&
      isCheckReportEligible(item) &&
      report?.report_state !== 'published' &&
      reportDraftByCheck[item.uuid]?.trim() &&
      !reportPublishingByCheck[item.uuid],
  )
}

async function publishCheckReport(item: MedicalRequestItem) {
  const employeeUuid = doctor.value?.employeeUuid
  if (!employeeUuid || !canPublishCheckReport(item)) return

  reportPublishingByCheck[item.uuid] = true
  try {
    let report = reportByCheck[item.uuid]
    if (!report) {
      report = await saveCheckReportDraft(item, true)
    }
    if (!report) return

    const response = await medicalApi.publishCheckReport(report.uuid, employeeUuid)
    reportByCheck[item.uuid] = response.data.data ?? null
    ElMessage.success('检查报告已审核发布。')
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '检查报告发布失败，请稍后重试。'))
  } finally {
    reportPublishingByCheck[item.uuid] = false
  }
}

function toggleInspectionReport(inspectionUuid: string) {
  expandedReportInspectionUuid.value = expandedReportInspectionUuid.value === inspectionUuid ? null : inspectionUuid
}

function isInspectionReportEligible(item: MedicalRequestItem) {
  return item.state.includes('已执行')
}

function canSaveInspectionReport(item: MedicalRequestItem) {
  const results = reportResultsByInspection[item.uuid] ?? []
  return Boolean(
    doctor.value?.employeeUuid &&
      isInspectionReportEligible(item) &&
      reportByInspection[item.uuid]?.report_state !== 'published' &&
      reportDraftByInspection[item.uuid]?.trim() &&
      results.some((result) => result.item_name.trim() && result.value.trim()) &&
      !reportSavingByInspection[item.uuid],
  )
}

async function saveInspectionReportDraft(item: MedicalRequestItem, silent = false) {
  if (!canSaveInspectionReport(item)) return null

  reportSavingByInspection[item.uuid] = true
  try {
    const response = await medicalApi.saveInspectionReportDraft(item.uuid, {
      conclusion: reportDraftByInspection[item.uuid].trim(),
      structured_result: (reportResultsByInspection[item.uuid] ?? [])
        .filter((result) => result.item_name.trim() && result.value.trim())
        .map((result) => ({
          item_name: result.item_name.trim(),
          value: result.value.trim(),
          unit: result.unit?.trim() || undefined,
          reference_range: result.reference_range?.trim() || undefined,
        })),
      author_employee_uuid: doctor.value?.employeeUuid ?? '',
    })
    const report = response.data.data ?? null
    reportByInspection[item.uuid] = report
    if (!silent) ElMessage.success('检验报告草稿已保存。')
    return report
  } catch (error) {
    if (!silent) ElMessage.error(getErrorMessage(error, '检验报告草稿保存失败，请稍后重试。'))
    return null
  } finally {
    reportSavingByInspection[item.uuid] = false
  }
}

function canCreateInspectionReportCorrection(item: MedicalRequestItem) {
  return Boolean(
    doctor.value?.employeeUuid &&
      isInspectionReportEligible(item) &&
      reportByInspection[item.uuid]?.report_state === 'published' &&
      !reportCorrectingByInspection[item.uuid],
  )
}

async function createInspectionReportCorrectionDraft(item: MedicalRequestItem) {
  const report = reportByInspection[item.uuid]
  const employeeUuid = doctor.value?.employeeUuid
  if (!report || !employeeUuid || !canCreateInspectionReportCorrection(item)) return

  reportCorrectingByInspection[item.uuid] = true
  try {
    const response = await medicalApi.createInspectionReportCorrectionDraft(report.uuid, employeeUuid)
    const correction = response.data.data ?? null
    reportByInspection[item.uuid] = correction
    reportDraftByInspection[item.uuid] = correction?.conclusion ?? ''
    reportResultsByInspection[item.uuid] = normalizeInspectionResults(correction?.structured_result)
    ElMessage.success('已创建检验报告更正草稿。')
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '创建检验报告更正草稿失败，请稍后重试。'))
  } finally {
    reportCorrectingByInspection[item.uuid] = false
  }
}

function canPublishInspectionReport(item: MedicalRequestItem) {
  return Boolean(
    doctor.value?.employeeUuid &&
      isInspectionReportEligible(item) &&
      reportByInspection[item.uuid]?.report_state !== 'published' &&
      reportDraftByInspection[item.uuid]?.trim() &&
      (reportResultsByInspection[item.uuid] ?? []).some((result) => result.item_name.trim() && result.value.trim()) &&
      !reportPublishingByInspection[item.uuid],
  )
}

async function publishInspectionReport(item: MedicalRequestItem) {
  const employeeUuid = doctor.value?.employeeUuid
  if (!employeeUuid || !canPublishInspectionReport(item)) return

  reportPublishingByInspection[item.uuid] = true
  try {
    let report = reportByInspection[item.uuid]
    if (!report) report = await saveInspectionReportDraft(item, true)
    if (!report) return

    const response = await medicalApi.publishInspectionReport(report.uuid, employeeUuid)
    reportByInspection[item.uuid] = response.data.data ?? null
    ElMessage.success('检验报告已审核发布。')
  } catch (error) {
    ElMessage.error(getErrorMessage(error, '检验报告发布失败，请稍后重试。'))
  } finally {
    reportPublishingByInspection[item.uuid] = false
  }
}

function addInspectionResultRow(inspectionUuid: string) {
  reportResultsByInspection[inspectionUuid] ??= []
  reportResultsByInspection[inspectionUuid].push(emptyInspectionResult())
}

function removeInspectionResultRow(inspectionUuid: string, index: number) {
  const results = reportResultsByInspection[inspectionUuid]
  if (!results || results.length <= 1) return
  results.splice(index, 1)
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
  stopArtifactTaskPolling()
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
              <SectionCard title="统一开单" subtitle="连续添加医疗项目，确认后一次签署；后续按类型进入各自业务链路。">
                <template #extra>
                  <div class="doctor-encounter__card-extra">
                    <span class="doctor-encounter__badge is-progress">待签 {{ pendingOrders.length }} 项</span>
                    <button type="button" class="doctor-encounter__secondary" :disabled="queueLoading" @click="loadRequestQueue()">
                      {{ queueLoading ? '刷新中...' : '刷新已开项目' }}
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

                  <section class="doctor-encounter__order-composer" aria-label="添加医疗项目">
                    <label class="doctor-encounter__field doctor-encounter__technology-field">
                      <span>医疗项目</span>
                      <el-select
                        v-model="orderDraft.medicalTechnologyId"
                        filterable
                        clearable
                        placeholder="搜索医疗项目、拼音或编码"
                        :disabled="technologyLoading || !allTechnologyOptions.length || signingOrders"
                      >
                        <el-option
                          v-for="item in allTechnologyOptions"
                          :key="item.uuid"
                          :label="`${medicalTypeLabel(item.orderType)} · ${item.tech_name} · ${formatPrice(item.price)}`"
                          :value="item.id"
                        >
                          <div class="doctor-encounter__technology-option">
                            <span>{{ item.tech_name }}</span>
                            <span class="doctor-encounter__type-tag" :class="`is-${item.orderType}`">
                              {{ medicalTypeLabel(item.orderType) }}
                            </span>
                            <small>{{ formatPrice(item.price) }}</small>
                          </div>
                        </el-option>
                      </el-select>
                    </label>

                    <div v-if="selectedOrderType === 'check'" class="doctor-encounter__order-detail-grid">
                      <label class="doctor-encounter__field">
                        <span>检查部位</span>
                        <input v-model="orderDraft.checkPosition" type="text" placeholder="例如：头部" :disabled="signingOrders" />
                      </label>
                      <label class="doctor-encounter__field">
                        <span>检查目的</span>
                        <input
                          v-model="orderDraft.checkInfo"
                          type="text"
                          placeholder="例如：排查颅内占位性病变"
                          :disabled="signingOrders"
                        />
                      </label>
                    </div>

                    <div class="doctor-encounter__composer-actions">
                      <span v-if="selectedTechnology" class="doctor-encounter__type-tag" :class="`is-${selectedOrderType}`">
                        {{ medicalTypeLabel(selectedOrderType || '') }}
                      </span>
                      <button type="button" class="doctor-encounter__add-order" :disabled="!canAddPendingOrder" @click="addPendingOrder">
                        + 加入待签清单
                      </button>
                    </div>
                  </section>

                  <section class="doctor-encounter__pending-orders" aria-label="本次待签医嘱">
                    <header class="doctor-encounter__pending-header">
                      <div>
                        <strong>本次待签医嘱 {{ pendingOrders.length }} 项</strong>
                        <p>加入清单后不会立即开立，确认签署时才会统一提交。</p>
                      </div>
                    </header>

                    <div v-if="!pendingOrders.length" class="doctor-encounter__pending-empty">
                      请选择医疗项目后加入待签清单。
                    </div>
                    <div v-else class="doctor-encounter__pending-list">
                      <article v-for="item in pendingOrders" :key="item.localId" class="doctor-encounter__pending-item">
                        <div>
                          <div class="doctor-encounter__pending-title">
                            <span class="doctor-encounter__type-tag" :class="`is-${item.type}`">{{ medicalTypeLabel(item.type) }}</span>
                            <strong>{{ item.technologyName }}</strong>
                          </div>
                          <p>{{ pendingOrderSummary(item) }} · {{ formatPrice(item.price) }}</p>
                        </div>
                        <div class="doctor-encounter__pending-actions">
                          <button type="button" :disabled="signingOrders" @click="editPendingOrder(item.localId)">编辑</button>
                          <button type="button" :disabled="signingOrders" @click="removePendingOrder(item.localId)">删除</button>
                        </div>
                      </article>
                    </div>

                    <button type="button" class="doctor-encounter__primary doctor-encounter__sign-order" :disabled="!canSignOrders" @click="signPendingOrders">
                      {{ signingOrders ? '签署中...' : `确认签署并开立（${pendingOrders.length} 项）` }}
                    </button>
                    <p class="doctor-encounter__sign-hint">一次签署，分型留痕；检查、检验、处置分别进入后续流程。</p>
                  </section>

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
                          <section v-if="group.key === 'check'" class="doctor-encounter__artifact-analysis">
                            <button
                              type="button"
                              class="doctor-encounter__artifact-toggle"
                              :aria-expanded="expandedArtifactCheckUuid === item.uuid"
                              @click="toggleArtifactAnalysis(item.uuid)"
                            >
                              <span>CT 伪影分析</span>
                              <span
                                class="doctor-encounter__artifact-status"
                                :class="artifactTaskStateClass(artifactTaskByCheck[item.uuid]?.task_state)"
                              >
                                {{ artifactTaskStateLabel(artifactTaskByCheck[item.uuid]?.task_state) }}
                              </span>
                            </button>

                            <div v-if="expandedArtifactCheckUuid === item.uuid" class="doctor-encounter__artifact-panel">
                              <template v-if="artifactTaskByCheck[item.uuid]">
                                <div class="doctor-encounter__artifact-meta">
                                  <div>
                                    <span>模型</span>
                                    <strong>{{ artifactTaskByCheck[item.uuid]?.model_name || 'attention-unet2d' }}</strong>
                                  </div>
                                  <div>
                                    <span>阈值</span>
                                    <strong>{{ artifactTaskByCheck[item.uuid]?.threshold || '0.5' }}</strong>
                                  </div>
                                  <div>
                                    <span>状态</span>
                                    <strong>{{ artifactTaskStateLabel(artifactTaskByCheck[item.uuid]?.task_state) }}</strong>
                                  </div>
                                </div>

                                <div v-if="artifactTaskByCheck[item.uuid]?.task_state === 'succeeded'" class="doctor-encounter__artifact-result">
                                  <img
                                    :src="artifactOverlayUrl(artifactTaskByCheck[item.uuid]!)"
                                    alt="CT 伪影掩码叠加预览"
                                    class="doctor-encounter__artifact-preview"
                                  />
                                  <div class="doctor-encounter__artifact-findings">
                                    <strong>掩码叠加预览</strong>
                                    <p>
                                      第 {{ (artifactTaskByCheck[item.uuid]?.result_metadata?.selected_slice ?? 0) + 1 }} 层，
                                      共 {{ artifactTaskByCheck[item.uuid]?.result_metadata?.artifact_pixel_count ?? 0 }} 个伪影像素。
                                    </p>
                                    <span>分析结果仅在医生端当前检查项目内查看。</span>
                                  </div>
                                </div>
                                <div v-else class="doctor-encounter__artifact-waiting">
                                  <strong>{{ artifactTaskStateLabel(artifactTaskByCheck[item.uuid]?.task_state) }}</strong>
                                  <p>页面会自动同步任务状态；完成后将在这里显示叠加预览。</p>
                                </div>
                              </template>

                              <template v-else>
                                <div class="doctor-encounter__artifact-setup">
                                  <label class="doctor-encounter__field">
                                    <span>选择影像序列</span>
                                    <el-select
                                      v-model="artifactSourceByCheck[item.uuid]"
                                      filterable
                                      placeholder="选择已导入的 CT 序列"
                                      :loading="artifactSourcesLoading"
                                      :disabled="!isArtifactAnalysisEligible(item) || !artifactSources.length"
                                    >
                                      <el-option
                                        v-for="source in artifactSources"
                                        :key="`${source.source_format}:${source.source_ref}`"
                                        :label="source.source_ref"
                                        :value="source.source_ref"
                                      >
                                        <div class="doctor-encounter__artifact-source-option">
                                          <span>{{ source.source_ref }}</span>
                                          <small>{{ source.source_format === 'dicom' ? 'DICOM 序列' : 'NIfTI 体数据' }}</small>
                                        </div>
                                      </el-option>
                                    </el-select>
                                  </label>
                                  <p v-if="artifactSourcesError" class="doctor-encounter__artifact-note">{{ artifactSourcesError }}</p>
                                  <p v-else-if="!isArtifactAnalysisEligible(item)" class="doctor-encounter__artifact-note">
                                    完成缴费后即可选择已导入影像并发起分析。
                                  </p>
                                  <p v-else class="doctor-encounter__artifact-note">
                                    分析完成后会在当前条目内生成掩码叠加预览。
                                  </p>
                                  <button
                                    type="button"
                                    class="doctor-encounter__artifact-submit"
                                    :disabled="!canSubmitArtifactTask(item)"
                                    @click="submitArtifactTask(item)"
                                  >
                                    {{ artifactSubmittingByCheck[item.uuid] ? '正在提交...' : '开始影像分析' }}
                                  </button>
                                </div>
                              </template>
                            </div>
                          </section>
                          <section v-if="group.key === 'check'" class="doctor-encounter__check-report">
                            <button
                              type="button"
                              class="doctor-encounter__report-toggle"
                              :aria-expanded="expandedReportCheckUuid === item.uuid"
                              @click="toggleCheckReport(item.uuid)"
                            >
                              <span>检查报告</span>
                              <span
                                class="doctor-encounter__report-status"
                                :class="checkReportStateClass(reportByCheck[item.uuid])"
                              >
                                {{ checkReportStateLabel(reportByCheck[item.uuid]) }}
                              </span>
                            </button>

                            <div v-if="expandedReportCheckUuid === item.uuid" class="doctor-encounter__report-panel">
                              <div v-if="reportByCheck[item.uuid]?.report_state === 'published'" class="doctor-encounter__report-published">
                                <div class="doctor-encounter__report-published-meta">
                                  <span>医生确认结论</span>
                                  <strong>已发布 · v{{ reportByCheck[item.uuid]?.version }}</strong>
                                </div>
                                <p>{{ reportByCheck[item.uuid]?.conclusion }}</p>
                                <small>发布时间：{{ formatCreationTime(reportByCheck[item.uuid]?.published_at) }}</small>
                                <div class="doctor-encounter__report-actions">
                                  <button
                                    type="button"
                                    class="doctor-encounter__report-save"
                                    :disabled="!canCreateCheckReportCorrection(item)"
                                    @click="createCheckReportCorrectionDraft(item)"
                                  >
                                    {{ reportCorrectingByCheck[item.uuid] ? '创建中...' : '创建更正版本' }}
                                  </button>
                                </div>
                              </div>

                              <template v-else>
                                <label class="doctor-encounter__field">
                                  <span>医生结论</span>
                                  <textarea
                                    v-model="reportDraftByCheck[item.uuid]"
                                    rows="4"
                                    :disabled="!isCheckReportEligible(item) || reportSavingByCheck[item.uuid] || reportPublishingByCheck[item.uuid]"
                                    placeholder="填写影像所见与医生确认结论"
                                  />
                                </label>
                                <p v-if="!isCheckReportEligible(item)" class="doctor-encounter__report-note">
                                  检查完成执行后可填写并审核报告。
                                </p>
                                <p v-else class="doctor-encounter__report-note">
                                  {{ reportByCheck[item.uuid]?.supersedes_report_uuid ? '当前为报告更正草稿，发布后将形成新的版本记录。' : '模型掩码仅作为当前检查项目的辅助信息，正式结论以医生填写内容为准。' }}
                                </p>
                                <div class="doctor-encounter__report-actions">
                                  <button
                                    type="button"
                                    class="doctor-encounter__report-save"
                                    :disabled="!canSaveCheckReport(item)"
                                    @click="saveCheckReportDraft(item)"
                                  >
                                    {{ reportSavingByCheck[item.uuid] ? '保存中...' : '保存草稿' }}
                                  </button>
                                  <button
                                    type="button"
                                    class="doctor-encounter__report-publish"
                                    :disabled="!canPublishCheckReport(item)"
                                    @click="publishCheckReport(item)"
                                  >
                                    {{ reportPublishingByCheck[item.uuid] ? '发布中...' : '审核并发布' }}
                                  </button>
                                </div>
                              </template>
                            </div>
                          </section>
                          <section v-if="group.key === 'inspection'" class="doctor-encounter__check-report">
                            <button
                              type="button"
                              class="doctor-encounter__report-toggle"
                              :aria-expanded="expandedReportInspectionUuid === item.uuid"
                              @click="toggleInspectionReport(item.uuid)"
                            >
                              <span>检验报告</span>
                              <span class="doctor-encounter__report-status" :class="checkReportStateClass(reportByInspection[item.uuid])">
                                {{ checkReportStateLabel(reportByInspection[item.uuid]) }}
                              </span>
                            </button>

                            <div v-if="expandedReportInspectionUuid === item.uuid" class="doctor-encounter__report-panel">
                              <div v-if="reportByInspection[item.uuid]?.report_state === 'published'" class="doctor-encounter__report-published">
                                <div class="doctor-encounter__report-published-meta">
                                  <span>医生确认结论</span>
                                  <strong>已发布 · v{{ reportByInspection[item.uuid]?.version }}</strong>
                                </div>
                                <p>{{ reportByInspection[item.uuid]?.conclusion }}</p>
                                <div class="doctor-encounter__inspection-result-readonly">
                                  <div v-for="(result, index) in reportByInspection[item.uuid]?.structured_result ?? []" :key="`${result.item_name}-${index}`">
                                    <strong>{{ result.item_name }}</strong>
                                    <span>{{ result.value }}{{ result.unit ? ` ${result.unit}` : '' }}</span>
                                    <small v-if="result.reference_range">参考范围：{{ result.reference_range }}</small>
                                  </div>
                                </div>
                                <small>发布时间：{{ formatCreationTime(reportByInspection[item.uuid]?.published_at) }}</small>
                                <div class="doctor-encounter__report-actions">
                                  <button type="button" class="doctor-encounter__report-save" :disabled="!canCreateInspectionReportCorrection(item)" @click="createInspectionReportCorrectionDraft(item)">
                                    {{ reportCorrectingByInspection[item.uuid] ? '创建中...' : '创建更正版本' }}
                                  </button>
                                </div>
                              </div>

                              <template v-else>
                                <label class="doctor-encounter__field">
                                  <span>医生结论</span>
                                  <textarea
                                    v-model="reportDraftByInspection[item.uuid]"
                                    rows="3"
                                    :disabled="!isInspectionReportEligible(item) || reportSavingByInspection[item.uuid] || reportPublishingByInspection[item.uuid]"
                                    placeholder="填写检验结果的临床解释与医生确认结论"
                                  />
                                </label>
                                <div class="doctor-encounter__inspection-results">
                                  <div class="doctor-encounter__inspection-results-heading"><strong>结构化检验结果</strong><button type="button" :disabled="!isInspectionReportEligible(item)" @click="addInspectionResultRow(item.uuid)">添加项目</button></div>
                                  <div v-for="(result, index) in reportResultsByInspection[item.uuid] ?? []" :key="index" class="doctor-encounter__inspection-result-row">
                                    <input v-model="result.item_name" :disabled="!isInspectionReportEligible(item)" placeholder="项目名称" />
                                    <input v-model="result.value" :disabled="!isInspectionReportEligible(item)" placeholder="结果" />
                                    <input v-model="result.unit" :disabled="!isInspectionReportEligible(item)" placeholder="单位（可选）" />
                                    <input v-model="result.reference_range" :disabled="!isInspectionReportEligible(item)" placeholder="参考范围（可选）" />
                                    <button type="button" :disabled="(reportResultsByInspection[item.uuid] ?? []).length <= 1 || !isInspectionReportEligible(item)" @click="removeInspectionResultRow(item.uuid, index)">删除</button>
                                  </div>
                                </div>
                                <p v-if="!isInspectionReportEligible(item)" class="doctor-encounter__report-note">检验完成执行后可填写并审核报告。</p>
                                <p v-else class="doctor-encounter__report-note">{{ reportByInspection[item.uuid]?.supersedes_report_uuid ? '当前为报告更正草稿，发布后将形成新的版本记录。' : '正式检验报告同时保存医生结论与结构化结果。' }}</p>
                                <div class="doctor-encounter__report-actions">
                                  <button type="button" class="doctor-encounter__report-save" :disabled="!canSaveInspectionReport(item)" @click="saveInspectionReportDraft(item)">{{ reportSavingByInspection[item.uuid] ? '保存中...' : '保存草稿' }}</button>
                                  <button type="button" class="doctor-encounter__report-publish" :disabled="!canPublishInspectionReport(item)" @click="publishInspectionReport(item)">{{ reportPublishingByInspection[item.uuid] ? '发布中...' : '审核并发布' }}</button>
                                </div>
                              </template>
                            </div>
                          </section>
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

.doctor-encounter__queue-summary,
.doctor-encounter__request-header,
.doctor-encounter__request-footer,
.doctor-encounter__request-group header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.doctor-encounter__queue-summary strong,
.doctor-encounter__request-header strong,
.doctor-encounter__request-group strong,
.doctor-encounter__similar-item strong,
.doctor-encounter__assistant-answer strong,
.doctor-encounter__state strong {
  color: #0f172a;
}

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

.doctor-encounter__order-composer,
.doctor-encounter__pending-orders {
  display: grid;
  gap: 14px;
  padding: 16px;
  border: 1px solid #dbe5f0;
  border-radius: 16px;
  background: #f8fafc;
}

.doctor-encounter__technology-field {
  max-width: 100%;
}

.doctor-encounter__technology-field :deep(.el-select) {
  width: 100%;
}

.doctor-encounter__technology-field :deep(.el-select__wrapper) {
  min-height: 46px;
  border-radius: 12px;
  box-shadow: 0 0 0 1px #cbd5e1 inset;
}

.doctor-encounter__technology-field :deep(.el-select__wrapper.is-focused) {
  box-shadow: 0 0 0 1px #0f766e inset, 0 0 0 3px rgba(15, 118, 110, 0.12);
}

.doctor-encounter__technology-option,
.doctor-encounter__composer-actions,
.doctor-encounter__pending-header,
.doctor-encounter__pending-item,
.doctor-encounter__pending-actions,
.doctor-encounter__pending-title {
  display: flex;
  align-items: center;
  gap: 10px;
}

.doctor-encounter__technology-option small {
  margin-left: auto;
  color: #64748b;
}

.doctor-encounter__order-detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.doctor-encounter__composer-actions {
  justify-content: space-between;
}

.doctor-encounter__type-tag {
  display: inline-flex;
  align-items: center;
  min-height: 26px;
  padding: 0 9px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  white-space: nowrap;
}

.doctor-encounter__type-tag.is-check {
  background: #e0f2fe;
  color: #0369a1;
}

.doctor-encounter__type-tag.is-inspection {
  background: #ecfdf5;
  color: #047857;
}

.doctor-encounter__type-tag.is-disposal {
  background: #f5f3ff;
  color: #6d28d9;
}

.doctor-encounter__add-order,
.doctor-encounter__pending-actions button {
  border: 1px solid #0f766e;
  border-radius: 10px;
  background: #ffffff;
  color: #0f766e;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

.doctor-encounter__add-order {
  min-height: 40px;
  padding: 0 16px;
}

.doctor-encounter__add-order:disabled,
.doctor-encounter__pending-actions button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.doctor-encounter__pending-header {
  align-items: flex-start;
  justify-content: space-between;
}

.doctor-encounter__pending-header strong {
  color: #0f172a;
}

.doctor-encounter__pending-header p,
.doctor-encounter__pending-item p,
.doctor-encounter__sign-hint {
  margin: 5px 0 0;
  color: #64748b;
  font-size: 13px;
  line-height: 1.6;
}

.doctor-encounter__pending-list {
  display: grid;
  overflow: hidden;
  border: 1px solid #dbe5f0;
  border-radius: 12px;
  background: #ffffff;
}

.doctor-encounter__pending-item {
  justify-content: space-between;
  padding: 12px 14px;
  border-bottom: 1px solid #e2e8f0;
}

.doctor-encounter__pending-item:last-child {
  border-bottom: 0;
}

.doctor-encounter__pending-actions button {
  min-height: 32px;
  padding: 0 10px;
  border-color: #cbd5e1;
  color: #475569;
}

.doctor-encounter__pending-actions button:last-child {
  color: #b45309;
}

.doctor-encounter__pending-empty {
  padding: 14px;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
  color: #64748b;
  font-size: 13px;
}

.doctor-encounter__sign-order {
  width: 100%;
  background: #0f766e;
}

.doctor-encounter__sign-hint {
  margin: -4px 0 0;
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

.doctor-encounter__artifact-analysis {
  display: grid;
  gap: 10px;
  padding-top: 2px;
}

.doctor-encounter__artifact-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  width: 100%;
  min-height: 42px;
  padding: 0 13px;
  border: 1px solid #cbdbe7;
  border-radius: 11px;
  background: #f8fbfd;
  color: #0f3f4a;
  font: inherit;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  text-align: left;
  transition: border-color 180ms ease-out, background-color 180ms ease-out, box-shadow 180ms ease-out;
}

.doctor-encounter__artifact-toggle:hover {
  border-color: #7bb7c4;
  background: #f0f8f9;
}

.doctor-encounter__artifact-toggle:focus-visible,
.doctor-encounter__artifact-submit:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.16);
}

.doctor-encounter__artifact-status {
  display: inline-flex;
  align-items: center;
  min-height: 25px;
  padding: 0 9px;
  border-radius: 999px;
  background: #eef2f6;
  color: #52616f;
  font-size: 12px;
  white-space: nowrap;
}

.doctor-encounter__artifact-status.is-processing {
  background: #e7f4f5;
  color: #0f6d72;
}

.doctor-encounter__artifact-status.is-complete {
  background: #e9f7ef;
  color: #19734a;
}

.doctor-encounter__artifact-panel {
  display: grid;
  gap: 14px;
  padding: 14px;
  border: 1px solid #d5e3eb;
  border-radius: 13px;
  background: #fbfdff;
}

.doctor-encounter__artifact-meta {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.doctor-encounter__artifact-meta div {
  display: grid;
  gap: 4px;
  min-width: 0;
  padding: 10px 11px;
  border-radius: 10px;
  background: #f2f7fa;
}

.doctor-encounter__artifact-meta span,
.doctor-encounter__artifact-findings span,
.doctor-encounter__artifact-note {
  color: #5c6f7e;
  font-size: 12px;
  line-height: 1.55;
}

.doctor-encounter__artifact-meta strong {
  overflow: hidden;
  color: #183746;
  font-size: 13px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.doctor-encounter__artifact-result {
  display: grid;
  grid-template-columns: minmax(180px, 0.9fr) minmax(180px, 1.1fr);
  gap: 14px;
  align-items: center;
}

.doctor-encounter__artifact-preview {
  display: block;
  width: 100%;
  max-height: 240px;
  object-fit: contain;
  border-radius: 10px;
  background: #0f172a;
}

.doctor-encounter__artifact-findings,
.doctor-encounter__artifact-waiting,
.doctor-encounter__artifact-setup {
  display: grid;
  gap: 8px;
}

.doctor-encounter__artifact-findings strong,
.doctor-encounter__artifact-waiting strong {
  color: #173d49;
}

.doctor-encounter__artifact-findings p,
.doctor-encounter__artifact-waiting p,
.doctor-encounter__artifact-note {
  margin: 0;
}

.doctor-encounter__artifact-waiting {
  padding: 3px 0;
}

.doctor-encounter__artifact-source-option {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.doctor-encounter__artifact-source-option span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.doctor-encounter__artifact-source-option small {
  margin-left: auto;
  color: #5c6f7e;
  font-size: 12px;
  white-space: nowrap;
}

.doctor-encounter__artifact-submit {
  justify-self: start;
  min-height: 40px;
  padding: 0 16px;
  border: 1px solid #0f766e;
  border-radius: 10px;
  background: #0f766e;
  color: #ffffff;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 180ms ease-out, border-color 180ms ease-out, transform 180ms ease-out;
}

.doctor-encounter__artifact-submit:hover:not(:disabled) {
  border-color: #0b615b;
  background: #0b615b;
  transform: translateY(-1px);
}

.doctor-encounter__artifact-submit:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.doctor-encounter__check-report {
  display: grid;
  gap: 10px;
}

.doctor-encounter__report-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  width: 100%;
  min-height: 42px;
  padding: 0 13px;
  border: 1px solid #d5dee7;
  border-radius: 11px;
  background: #ffffff;
  color: #263949;
  font: inherit;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  text-align: left;
  transition: border-color 180ms ease-out, background-color 180ms ease-out, box-shadow 180ms ease-out;
}

.doctor-encounter__report-toggle:hover {
  border-color: #a9bdcd;
  background: #f8fafc;
}

.doctor-encounter__report-toggle:focus-visible,
.doctor-encounter__report-save:focus-visible,
.doctor-encounter__report-publish:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.16);
}

.doctor-encounter__report-status {
  display: inline-flex;
  align-items: center;
  min-height: 25px;
  padding: 0 9px;
  border-radius: 999px;
  background: #eef2f6;
  color: #52616f;
  font-size: 12px;
  white-space: nowrap;
}

.doctor-encounter__report-status.is-processing {
  background: #fff5df;
  color: #98650f;
}

.doctor-encounter__report-status.is-complete {
  background: #e9f7ef;
  color: #19734a;
}

.doctor-encounter__report-panel {
  display: grid;
  gap: 11px;
  padding: 14px;
  border: 1px solid #dfe7ee;
  border-radius: 13px;
  background: #ffffff;
}

.doctor-encounter__report-note,
.doctor-encounter__report-published small {
  margin: 0;
  color: #5c6f7e;
  font-size: 12px;
  line-height: 1.55;
}

.doctor-encounter__report-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}

.doctor-encounter__report-save,
.doctor-encounter__report-publish {
  min-height: 40px;
  padding: 0 15px;
  border-radius: 10px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 180ms ease-out, border-color 180ms ease-out, transform 180ms ease-out;
}

.doctor-encounter__report-save {
  border: 1px solid #9eb5c4;
  background: #ffffff;
  color: #2f586c;
}

.doctor-encounter__report-publish {
  border: 1px solid #0f766e;
  background: #0f766e;
  color: #ffffff;
}

.doctor-encounter__report-save:hover:not(:disabled) {
  border-color: #638da4;
  background: #f3f8fb;
}

.doctor-encounter__report-publish:hover:not(:disabled) {
  border-color: #0b615b;
  background: #0b615b;
  transform: translateY(-1px);
}

.doctor-encounter__report-save:disabled,
.doctor-encounter__report-publish:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.doctor-encounter__report-published {
  display: grid;
  gap: 9px;
}

.doctor-encounter__report-published-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  color: #486272;
  font-size: 12px;
}

.doctor-encounter__report-published-meta strong {
  color: #19734a;
}

.doctor-encounter__report-published p {
  margin: 0;
  color: #183746;
  font-size: 14px;
  line-height: 1.72;
  white-space: pre-wrap;
}

.doctor-encounter__inspection-results {
  display: grid;
  gap: 9px;
  padding: 12px;
  border: 1px solid #dfe7ee;
  border-radius: 11px;
  background: #f8fbfd;
}

.doctor-encounter__inspection-results-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  color: #2b4a5b;
  font-size: 13px;
}

.doctor-encounter__inspection-results-heading button,
.doctor-encounter__inspection-result-row button {
  min-height: 32px;
  border: 1px solid #9eb5c4;
  border-radius: 8px;
  background: #ffffff;
  color: #2f586c;
  font: inherit;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
}

.doctor-encounter__inspection-results-heading button { padding: 0 10px; }

.doctor-encounter__inspection-result-row {
  display: grid;
  grid-template-columns: minmax(110px, 1fr) minmax(100px, 1fr) minmax(80px, .7fr) minmax(110px, 1fr) auto;
  gap: 8px;
}

.doctor-encounter__inspection-result-row input {
  min-width: 0;
  min-height: 36px;
  padding: 0 9px;
  border: 1px solid #cbd9e4;
  border-radius: 8px;
  background: #ffffff;
  color: #183746;
  font: inherit;
  font-size: 12px;
}

.doctor-encounter__inspection-result-row input:focus {
  outline: none;
  border-color: #4f9abb;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, .11);
}

.doctor-encounter__inspection-result-row button { padding: 0 9px; }

.doctor-encounter__inspection-results button:disabled,
.doctor-encounter__inspection-result-row input:disabled {
  cursor: not-allowed;
  opacity: .58;
}

.doctor-encounter__inspection-result-readonly {
  display: grid;
  gap: 7px;
  padding: 10px;
  border-radius: 10px;
  background: #f5f9fb;
}

.doctor-encounter__inspection-result-readonly div {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 3px 12px;
  align-items: baseline;
}

.doctor-encounter__inspection-result-readonly strong { color: #27495b; font-size: 13px; }
.doctor-encounter__inspection-result-readonly span { color: #0f766e; font-size: 13px; font-weight: 700; }
.doctor-encounter__inspection-result-readonly small { grid-column: 1 / -1; color: #64798a; font-size: 12px; }

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
  .doctor-encounter__request-group header,
  .doctor-encounter__composer-actions,
  .doctor-encounter__pending-item {
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

  .doctor-encounter__order-detail-grid {
    grid-template-columns: 1fr;
  }

  .doctor-encounter__artifact-meta,
  .doctor-encounter__artifact-result {
    grid-template-columns: 1fr;
  }

  .doctor-encounter__inspection-result-row {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .doctor-encounter__inspection-result-row button {
    grid-column: 1 / -1;
  }

  .doctor-encounter__artifact-submit {
    width: 100%;
  }

  .doctor-encounter__report-actions {
    align-items: stretch;
    flex-direction: column;
  }

  .doctor-encounter__report-save,
  .doctor-encounter__report-publish {
    width: 100%;
  }
}

@media (prefers-reduced-motion: reduce) {
  .doctor-encounter__artifact-toggle,
  .doctor-encounter__artifact-submit,
  .doctor-encounter__report-toggle,
  .doctor-encounter__report-save,
  .doctor-encounter__report-publish {
    transition: none;
  }
}
</style>
