import type { Pinia } from 'pinia'

import { useAdminSessionStore } from '@/stores/adminSession'
import { useDoctorSessionStore } from '@/stores/doctorSession'
import { usePatientSessionStore } from '@/stores/patientSession'
import { pinia } from '@/stores/pinia'

export type AppRole = 'patient' | 'doctor' | 'admin'

export interface RoleSessionAccess {
  role: AppRole
  homePath: string
  loginPath: string
  isLoggedIn: boolean
}

const rolePaths: Record<AppRole, { loginPath: string; homePath: string }> = {
  patient: {
    loginPath: '/patient/login',
    homePath: '/patient/home',
  },
  doctor: {
    loginPath: '/doctor/login',
    homePath: '/doctor/workbench',
  },
  admin: {
    loginPath: '/admin/login',
    homePath: '/admin/dashboard',
  },
}

export function resolveRoleLoginPath(role: AppRole) {
  return rolePaths[role].loginPath
}

export function resolveRoleHomePath(role: AppRole) {
  return rolePaths[role].homePath
}

export function getRoleSessionAccess(role: AppRole, targetPinia: Pinia = pinia): RoleSessionAccess {
  if (role === 'patient') {
    const session = usePatientSessionStore(targetPinia)
    return {
      role,
      loginPath: resolveRoleLoginPath(role),
      homePath: resolveRoleHomePath(role),
      isLoggedIn: session.isLoggedIn,
    }
  }

  if (role === 'doctor') {
    const session = useDoctorSessionStore(targetPinia)
    return {
      role,
      loginPath: resolveRoleLoginPath(role),
      homePath: resolveRoleHomePath(role),
      isLoggedIn: session.isLoggedIn,
    }
  }

  const session = useAdminSessionStore(targetPinia)
  return {
    role,
    loginPath: resolveRoleLoginPath(role),
    homePath: resolveRoleHomePath(role),
    isLoggedIn: session.isLoggedIn,
  }
}

export function isRoleLoggedIn(role: AppRole, targetPinia: Pinia = pinia) {
  return getRoleSessionAccess(role, targetPinia).isLoggedIn
}
