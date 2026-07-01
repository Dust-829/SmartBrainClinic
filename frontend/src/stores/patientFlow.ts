import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import type {
  DoctorRecommendation,
  DoctorSchedule,
  OnlineRegisterResult,
  PatientRecord,
  PaymentResult,
  QueueStatus,
  TriageMessage,
  TriageResult,
} from '@/api/patient'

export const usePatientFlowStore = defineStore('patientFlow', () => {
  const patient = ref<PatientRecord | null>(null)
  const loginDraft = ref({ realName: '', cardNumber: '' })
  const triageMessages = ref<TriageMessage[]>([])
  const triageResult = ref<TriageResult | null>(null)
  const manualDeptCode = ref('')
  const manualDeptName = ref('')
  const recommendations = ref<DoctorRecommendation[]>([])
  const selectedDoctor = ref<DoctorRecommendation | null>(null)
  const doctorSchedules = ref<DoctorSchedule[]>([])
  const selectedTimeSlotUuid = ref<string>('')
  const onlineRegister = ref<OnlineRegisterResult | null>(null)
  const payment = ref<PaymentResult | null>(null)
  const queueStatus = ref<QueueStatus | null>(null)
  const triagePromptShown = ref(false)

  const triageData = computed(() => triageResult.value?.data ?? null)
  const symptoms = computed(() => triageData.value?.symptom_summary || lastUserMessage.value)
  const lastUserMessage = computed(() => {
    const message = [...triageMessages.value].reverse().find((item) => item.role === 'user')
    return message?.content || ''
  })
  const recommendedDeptCode = computed(() => triageData.value?.recommended_dept_code || manualDeptCode.value)
  const canRecommendDoctors = computed(() => Boolean(patient.value && recommendedDeptCode.value))
  const canConfirmRegister = computed(() => Boolean(patient.value && selectedDoctor.value && selectedTimeSlotUuid.value))
  const canPay = computed(() => Boolean(onlineRegister.value?.register_uuid))
  const canViewQueue = computed(() => Boolean(payment.value?.register_uuid || onlineRegister.value?.register_uuid))

  function setPatient(value: PatientRecord) {
    patient.value = value
    loginDraft.value = { realName: value.real_name, cardNumber: value.card_number }
  }

  function setLoginDraft(value: { realName?: string; cardNumber?: string }) {
    loginDraft.value = {
      realName: value.realName ?? loginDraft.value.realName,
      cardNumber: value.cardNumber ?? loginDraft.value.cardNumber,
    }
  }

  function setTriage(messages: TriageMessage[], result: TriageResult) {
    triageMessages.value = messages
    triageResult.value = result
    manualDeptCode.value = ''
    manualDeptName.value = ''
  }

  function setManualDepartment(value: { code: string; name: string }) {
    manualDeptCode.value = value.code
    manualDeptName.value = value.name
    triageResult.value = null
    recommendations.value = []
    selectedDoctor.value = null
    doctorSchedules.value = []
    selectedTimeSlotUuid.value = ''
    onlineRegister.value = null
    payment.value = null
    queueStatus.value = null
  }

  function setRecommendations(value: DoctorRecommendation[]) {
    recommendations.value = value
  }

  function selectDoctor(value: DoctorRecommendation) {
    selectedDoctor.value = value
    doctorSchedules.value = []
    selectedTimeSlotUuid.value = ''
    onlineRegister.value = null
    payment.value = null
    queueStatus.value = null
  }

  function setDoctorSchedules(value: DoctorSchedule[]) {
    doctorSchedules.value = value
  }

  function selectTimeSlot(uuid: string) {
    selectedTimeSlotUuid.value = uuid
  }

  function setOnlineRegister(value: OnlineRegisterResult) {
    onlineRegister.value = value
    payment.value = null
    queueStatus.value = null
  }

  function setPayment(value: PaymentResult) {
    payment.value = value
  }

  function setQueueStatus(value: QueueStatus) {
    queueStatus.value = value
  }

  function markTriagePromptShown() {
    triagePromptShown.value = true
  }

  function resetRegisterDraft() {
    triagePromptShown.value = false
    triageMessages.value = []
    triageResult.value = null
    manualDeptCode.value = ''
    manualDeptName.value = ''
    recommendations.value = []
    selectedDoctor.value = null
    doctorSchedules.value = []
    selectedTimeSlotUuid.value = ''
    onlineRegister.value = null
    payment.value = null
    queueStatus.value = null
  }

  function resetAfterPatient() {
    resetRegisterDraft()
  }

  function resetAll() {
    patient.value = null
    loginDraft.value = { realName: '', cardNumber: '' }
    resetAfterPatient()
  }

  return {
    patient,
    loginDraft,
    triageMessages,
    triageResult,
    manualDeptCode,
    manualDeptName,
    triageData,
    symptoms,
    recommendedDeptCode,
    recommendations,
    selectedDoctor,
    doctorSchedules,
    selectedTimeSlotUuid,
    onlineRegister,
    payment,
    queueStatus,
    triagePromptShown,
    canRecommendDoctors,
    canConfirmRegister,
    canPay,
    canViewQueue,
    setPatient,
    setLoginDraft,
    setTriage,
    setManualDepartment,
    setRecommendations,
    selectDoctor,
    setDoctorSchedules,
    selectTimeSlot,
    setOnlineRegister,
    setPayment,
    setQueueStatus,
    markTriagePromptShown,
    resetRegisterDraft,
    resetAfterPatient,
    resetAll,
  }
})
