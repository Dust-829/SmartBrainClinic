import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

import type { PatientRecord } from '@/api/patient'
import { readSessionState, writeSessionState } from '@/stores/sessionStorage'

interface LoginDraft {
  realName: string
  cardNumber: string
}

interface PatientSessionState {
  patient: PatientRecord | null
  loginDraft: LoginDraft
}

const STORAGE_KEY = 'smartbrainclinic.patient-session'

function defaultState(): PatientSessionState {
  return {
    patient: null,
    loginDraft: {
      realName: '',
      cardNumber: '',
    },
  }
}

export const usePatientSessionStore = defineStore('patientSession', () => {
  const initialState = readSessionState(STORAGE_KEY, defaultState())

  const patient = ref<PatientRecord | null>(initialState.patient)
  const loginDraft = ref<LoginDraft>(initialState.loginDraft)
  const isLoggedIn = computed(() => Boolean(patient.value?.uuid))

  function persist() {
    writeSessionState(STORAGE_KEY, {
      patient: patient.value,
      loginDraft: loginDraft.value,
    })
  }

  function setLoginDraft(value: Partial<LoginDraft>) {
    loginDraft.value = {
      realName: value.realName ?? loginDraft.value.realName,
      cardNumber: value.cardNumber ?? loginDraft.value.cardNumber,
    }
  }

  function login(value: PatientRecord) {
    patient.value = value
    loginDraft.value = {
      realName: value.real_name,
      cardNumber: value.card_number,
    }
  }

  function logout() {
    patient.value = null
    loginDraft.value = defaultState().loginDraft
  }

  watch([patient, loginDraft], persist, { deep: true })

  return {
    patient,
    loginDraft,
    isLoggedIn,
    setLoginDraft,
    login,
    logout,
  }
})
