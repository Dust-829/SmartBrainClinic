import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

import { readSessionState, writeSessionState } from '@/stores/sessionStorage'

export interface StaffSessionRecord {
  displayName: string
  employeeUuid: string
  deptCode?: string
  deptName?: string
}

interface DoctorSessionState {
  staff: StaffSessionRecord | null
}

const STORAGE_KEY = 'smartbrainclinic.doctor-session'

function defaultState(): DoctorSessionState {
  return {
    staff: null,
  }
}

export const useDoctorSessionStore = defineStore('doctorSession', () => {
  const initialState = readSessionState(STORAGE_KEY, defaultState())

  const staff = ref<StaffSessionRecord | null>(initialState.staff)
  const isLoggedIn = computed(() => Boolean(staff.value?.employeeUuid))

  function persist() {
    writeSessionState(STORAGE_KEY, {
      staff: staff.value,
    })
  }

  function login(value: StaffSessionRecord) {
    staff.value = {
      displayName: value.displayName.trim(),
      employeeUuid: value.employeeUuid.trim(),
      deptCode: value.deptCode?.trim() || undefined,
      deptName: value.deptName?.trim() || undefined,
    }
  }

  function logout() {
    staff.value = null
  }

  watch(staff, persist, { deep: true })

  return {
    staff,
    isLoggedIn,
    login,
    logout,
  }
})
