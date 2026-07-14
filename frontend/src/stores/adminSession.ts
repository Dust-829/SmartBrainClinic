import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

import { readSessionState, writeSessionState } from '@/stores/sessionStorage'

export interface AdminSessionRecord {
  uuid: string
  displayName: string
  staffCode: string
}

interface AdminSessionState {
  staff: AdminSessionRecord | null
  accessToken: string | null
}

export const ADMIN_SESSION_STORAGE_KEY = 'smartbrainclinic.admin-session'

function defaultState(): AdminSessionState {
  return {
    staff: null,
    accessToken: null,
  }
}

export const useAdminSessionStore = defineStore('adminSession', () => {
  const initialState = readSessionState(ADMIN_SESSION_STORAGE_KEY, defaultState())

  const staff = ref<AdminSessionRecord | null>(initialState.staff)
  const accessToken = ref<string | null>(initialState.accessToken)
  const isLoggedIn = computed(() => Boolean(staff.value?.staffCode && accessToken.value))

  function persist() {
    writeSessionState(ADMIN_SESSION_STORAGE_KEY, {
      staff: staff.value,
      accessToken: accessToken.value,
    })
  }

  function login(value: AdminSessionRecord, token: string) {
    staff.value = {
      uuid: value.uuid,
      displayName: value.displayName.trim(),
      staffCode: value.staffCode.trim(),
    }
    accessToken.value = token
  }

  function logout() {
    staff.value = null
    accessToken.value = null
  }

  watch([staff, accessToken], persist, { deep: true })

  return {
    staff,
    accessToken,
    isLoggedIn,
    login,
    logout,
  }
})
