import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

import { patientApi, type RegisterDetail } from '@/api/patient'
import { usePatientSessionStore } from '@/stores/patientSession'
import { readSessionState, writeSessionState } from '@/stores/sessionStorage'

interface PatientRegisterHistoryState {
  patientUuid: string
  records: RegisterDetail[]
  fetchedAt: number
}

const STORAGE_KEY = 'smartbrainclinic.patient-register-history'
const DEFAULT_TTL_MS = 60_000

function defaultState(): PatientRegisterHistoryState {
  return {
    patientUuid: '',
    records: [],
    fetchedAt: 0,
  }
}

export const usePatientRegisterHistoryStore = defineStore('patientRegisterHistory', () => {
  const session = usePatientSessionStore()
  const initialState = readSessionState(STORAGE_KEY, defaultState())

  const patientUuid = ref(initialState.patientUuid)
  const records = ref<RegisterDetail[]>(initialState.records)
  const fetchedAt = ref(initialState.fetchedAt)
  const loading = ref(false)
  const errorMessage = ref('')

  let inflight: Promise<RegisterDetail[]> | null = null

  const currentPatientUuid = computed(() => session.patient?.uuid || '')
  const hasCurrentPatientCache = computed(
    () => Boolean(currentPatientUuid.value) && patientUuid.value === currentPatientUuid.value && fetchedAt.value > 0,
  )

  function persist() {
    writeSessionState(STORAGE_KEY, {
      patientUuid: patientUuid.value,
      records: records.value,
      fetchedAt: fetchedAt.value,
    })
  }

  function resetState() {
    patientUuid.value = ''
    records.value = []
    fetchedAt.value = 0
    errorMessage.value = ''
  }

  async function fetchHistory(options: { force?: boolean; ttlMs?: number } = {}) {
    const targetPatientUuid = currentPatientUuid.value
    if (!targetPatientUuid) {
      resetState()
      return []
    }

    const ttlMs = options.ttlMs ?? DEFAULT_TTL_MS
    const force = Boolean(options.force)
    const isFresh = patientUuid.value === targetPatientUuid && fetchedAt.value > 0 && Date.now() - fetchedAt.value < ttlMs

    if (!force && isFresh) {
      errorMessage.value = ''
      return records.value
    }

    if (inflight) return inflight

    loading.value = true
    errorMessage.value = ''
    inflight = patientApi
      .getRegisterHistory(targetPatientUuid)
      .then((response) => {
        if (currentPatientUuid.value !== targetPatientUuid) {
          return records.value
        }
        records.value = response.data.data ?? []
        patientUuid.value = targetPatientUuid
        fetchedAt.value = Date.now()
        return records.value
      })
      .catch(() => {
        if (currentPatientUuid.value !== targetPatientUuid) {
          return records.value
        }
        errorMessage.value = '挂号记录加载失败，请稍后重试'
        if (patientUuid.value !== targetPatientUuid) {
          records.value = []
          fetchedAt.value = 0
          patientUuid.value = targetPatientUuid
        }
        return records.value
      })
      .finally(() => {
        loading.value = false
        inflight = null
      })

    return inflight
  }

  function invalidate(targetPatientUuid = currentPatientUuid.value) {
    if (!targetPatientUuid) {
      resetState()
      return
    }
    if (patientUuid.value === targetPatientUuid) {
      fetchedAt.value = 0
      errorMessage.value = ''
    }
  }

  watch([patientUuid, records, fetchedAt], persist, { deep: true })
  watch(currentPatientUuid, (next, prev) => {
    if (!next) {
      resetState()
      return
    }
    if (prev && next !== prev) {
      resetState()
    }
  })

  return {
    records,
    fetchedAt,
    loading,
    errorMessage,
    hasCurrentPatientCache,
    fetchHistory,
    invalidate,
    resetState,
  }
})
