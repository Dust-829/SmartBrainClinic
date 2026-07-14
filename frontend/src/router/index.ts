import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import PatientLayout from '@/layouts/PatientLayout.vue'
import DoctorLayout from '@/layouts/DoctorLayout.vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import {
  type AppRole,
  getRoleSessionAccess,
  isRoleLoggedIn,
  resolveRoleHomePath,
} from '@/router/sessionGuard'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'portal-entry',
    component: () => import('@/views/PortalEntryView.vue'),
  },
  {
    path: '/patient',
    component: PatientLayout,
    meta: {
      role: 'patient',
    },
    children: [
      {
        path: '',
        redirect: { name: 'patient-home' },
      },
      {
        path: 'login',
        name: 'patient-login',
        component: () => import('@/views/patient/PatientLoginView.vue'),
      },
      {
        path: 'home',
        name: 'patient-home',
        component: () => import('@/views/patient/PatientHomeView.vue'),
      },
      {
        path: 'hospital',
        name: 'patient-hospital',
        component: () => import('@/views/patient/PatientHospitalInfoView.vue'),
      },
      {
        path: 'profile',
        name: 'patient-profile',
        component: () => import('@/views/patient/PatientProfileView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'messages',
        name: 'patient-messages',
        component: () => import('@/views/patient/PatientMessageCenterView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'visit-code',
        name: 'patient-visit-code',
        component: () => import('@/views/patient/PatientVisitCodeView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'registers',
        name: 'patient-registers',
        component: () => import('@/views/patient/PatientRegisterHistoryView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'departments',
        name: 'patient-departments',
        component: () => import('@/views/patient/PatientDepartmentSelectView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'register',
        name: 'patient-register',
        component: () => import('@/views/patient/PatientRegisterView.vue'),
      },
      {
        path: 'triage',
        name: 'patient-triage',
        component: () => import('@/views/patient/PatientTriageView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'doctors',
        name: 'patient-doctors',
        component: () => import('@/views/patient/PatientDoctorRecommendView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'confirm-register',
        name: 'patient-confirm-register',
        component: () => import('@/views/patient/PatientRegisterConfirmView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'payment',
        name: 'patient-payment',
        component: () => import('@/views/patient/PatientPaymentView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'payments',
        name: 'patient-payments',
        component: () => import('@/views/patient/PatientPaymentCenterView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'payment-records',
        name: 'patient-payment-records',
        component: () => import('@/views/patient/PatientPaymentRecordView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'reports',
        name: 'patient-reports',
        component: () => import('@/views/patient/PatientReportView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'queue',
        name: 'patient-queue',
        component: () => import('@/views/patient/PatientQueueView.vue'),
        meta: { requiresAuth: true },
      },
    ],
  },
  {
    path: '/doctor',
    component: DoctorLayout,
    meta: {
      role: 'doctor',
    },
    children: [
      {
        path: 'login',
        name: 'doctor-login',
        component: () => import('@/views/doctor/DoctorLoginView.vue'),
      },
      {
        path: '',
        redirect: { name: 'doctor-login' },
      },
      {
        path: 'workbench',
        name: 'doctor-home',
        component: () => import('@/views/doctor/DoctorWorkbenchView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'encounter/:registerId',
        name: 'doctor-encounter',
        component: () => import('@/views/doctor/DoctorEncounterView.vue'),
        meta: { requiresAuth: true },
      },
    ],
  },
  {
    path: '/admin',
    component: AdminLayout,
    meta: {
      role: 'admin',
    },
    children: [
      {
        path: 'login',
        name: 'admin-login',
        component: () => import('@/views/admin/AdminLoginView.vue'),
      },
      {
        path: '',
        redirect: { name: 'admin-login' },
      },
      {
        path: 'dashboard',
        name: 'admin-home',
        component: () => import('@/views/admin/AdminDashboardView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'accounts',
        name: 'admin-accounts',
        component: () => import('@/views/admin/AdminAccountsView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'schedules',
        name: 'admin-schedules',
        component: () => import('@/views/admin/AdminSchedulesView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'approvals',
        name: 'admin-approvals',
        component: () => import('@/views/admin/AdminApprovalsView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'audit',
        name: 'admin-audit',
        component: () => import('@/views/admin/AdminAuditView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'pharmacy',
        name: 'admin-pharmacy',
        component: () => import('@/views/admin/AdminPharmacyView.vue'),
        meta: { requiresAuth: true },
      },
      {
        path: 'billing',
        name: 'admin-billing',
        component: () => import('@/views/admin/AdminBillingView.vue'),
        meta: { requiresAuth: true },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const role = to.meta.role as AppRole | undefined
  const requiresAuth = Boolean(to.meta.requiresAuth)

  if (!role) return true

  const access = getRoleSessionAccess(role)

  if (requiresAuth && !access.isLoggedIn) {
    return {
      path: access.loginPath,
      query: {
        redirect: to.fullPath,
      },
    }
  }

  if (!requiresAuth && isRoleLoggedIn(role) && to.path === access.loginPath) {
    return resolveRoleHomePath(role)
  }

  return true
})

export default router
