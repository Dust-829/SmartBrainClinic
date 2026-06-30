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
        name: 'patient-home',
        component: () => import('@/views/patient/PatientHomeView.vue'),
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
