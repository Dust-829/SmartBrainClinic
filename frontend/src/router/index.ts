import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import PatientLayout from '@/layouts/PatientLayout.vue'
import DoctorLayout from '@/layouts/DoctorLayout.vue'
import AdminLayout from '@/layouts/AdminLayout.vue'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/patient',
  },
  {
    path: '/patient',
    component: PatientLayout,
    children: [
      {
        path: '',
        name: 'patient-login',
        component: () => import('@/views/patient/PatientLoginView.vue'),
      },
      {
        path: 'home',
        name: 'patient-home',
        component: () => import('@/views/patient/PatientHomeView.vue'),
      },
      {
        path: 'profile',
        name: 'patient-profile',
        component: () => import('@/views/patient/PatientProfileView.vue'),
      },
      {
        path: 'registers',
        name: 'patient-registers',
        component: () => import('@/views/patient/PatientRegisterHistoryView.vue'),
      },
      {
        path: 'departments',
        name: 'patient-departments',
        component: () => import('@/views/patient/PatientDepartmentSelectView.vue'),
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
      },
      {
        path: 'doctors',
        name: 'patient-doctors',
        component: () => import('@/views/patient/PatientDoctorRecommendView.vue'),
      },
      {
        path: 'confirm-register',
        name: 'patient-confirm-register',
        component: () => import('@/views/patient/PatientRegisterConfirmView.vue'),
      },
      {
        path: 'payment',
        name: 'patient-payment',
        component: () => import('@/views/patient/PatientPaymentView.vue'),
      },
      {
        path: 'queue',
        name: 'patient-queue',
        component: () => import('@/views/patient/PatientQueueView.vue'),
      },
    ],
  },
  {
    path: '/doctor',
    component: DoctorLayout,
    children: [
      {
        path: '',
        name: 'doctor-home',
        component: () => import('@/views/doctor/DoctorWorkbenchView.vue'),
      },
    ],
  },
  {
    path: '/admin',
    component: AdminLayout,
    children: [
      {
        path: '',
        name: 'admin-home',
        component: () => import('@/views/admin/AdminConsoleView.vue'),
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
