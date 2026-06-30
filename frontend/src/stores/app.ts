import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

export type RoleKey = 'patient' | 'doctor' | 'admin'

export const useAppStore = defineStore('app', () => {
  const activeRole = ref<RoleKey>('patient')

  const roleLabel = computed(() => {
    if (activeRole.value === 'doctor') return '医生端'
    if (activeRole.value === 'admin') return '管理员端'
    return '患者端'
  })

  function switchRole(role: RoleKey) {
    activeRole.value = role
  }

  return {
    activeRole,
    roleLabel,
    switchRole,
  }
})
