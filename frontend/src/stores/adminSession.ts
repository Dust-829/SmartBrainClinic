import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

import { readSessionState, writeSessionState } from '@/stores/sessionStorage'

export interface AdminSessionRecord {
  displayName: string
  staffCode: string
}

interface AdminSessionState {
  staff: AdminSessionRecord | null
}

const STORAGE_KEY = 'smartbrainclinic.admin-session'

function defaultState(): AdminSessionState {
  return {
    staff: null,
  }
}

export const useAdminSessionStore = defineStore('adminSession', () => {
  const initialState = readSessionState(STORAGE_KEY, defaultState())

  const staff = ref<AdminSessionRecord | null>(initialState.staff)
  const isLoggedIn = computed(() => Boolean(staff.value?.staffCode))

  function persist() {
    writeSessionState(STORAGE_KEY, {
      staff: staff.value,
    })
  }

  function login(value: AdminSessionRecord) {
    staff.value = {
      displayName: value.displayName.trim(),
      staffCode: value.staffCode.trim(),
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
