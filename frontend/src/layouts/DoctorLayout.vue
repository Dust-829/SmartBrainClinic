<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useDoctorSessionStore } from '@/stores/doctorSession'

const router = useRouter()
const route = useRoute()
const session = useDoctorSessionStore()

const doctor = computed(() => session.staff)

function logout() {
  session.logout()
  router.replace('/doctor/login')
}
</script>

<template>
  <div class="doctor-layout" :class="{ 'is-login': route.path === '/doctor/login' }">
    <aside v-if="route.path !== '/doctor/login'" class="doctor-layout__sidebar">
      <div class="doctor-layout__intro">
        <div class="doctor-layout__eyebrow">智慧云脑诊疗平台</div>
        <h1>医生端</h1>
        <p>登录后可查看今日候诊队列，并进入接诊工作台。</p>
      </div>

      <div v-if="doctor" class="doctor-layout__identity">
        <span>当前医生</span>
        <strong>{{ doctor.displayName }}</strong>
        <p>{{ doctor.deptName || '未绑定科室' }}</p>
        <button type="button" @click="logout">退出登录</button>
      </div>
    </aside>
    <main class="doctor-layout__main" :class="{ 'is-login': route.path === '/doctor/login' }">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.doctor-layout {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  background: #f8fafc;
}

.doctor-layout__sidebar {
  border-right: 1px solid #e2e8f0;
  padding: 88px 24px 24px;
  background: #ffffff;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.doctor-layout__intro {
  display: grid;
  gap: 10px;
}

.doctor-layout__eyebrow {
  font-size: 12px;
  color: #0f766e;
}

.doctor-layout__sidebar h1 {
  margin: 0;
  font-size: 30px;
  color: #0f172a;
}

.doctor-layout__sidebar p {
  margin: 0;
  color: #475569;
  line-height: 1.6;
}

.doctor-layout__identity {
  display: grid;
  gap: 6px;
  margin-top: auto;
  padding: 16px;
  border: 1px solid #dbeafe;
  border-radius: 16px;
  background: linear-gradient(180deg, #eff6ff 0%, #f8fbff 100%);
}

.doctor-layout__identity span {
  color: #0369a1;
  font-size: 12px;
  font-weight: 700;
}

.doctor-layout__identity strong {
  color: #0f172a;
  font-size: 20px;
}

.doctor-layout__identity button {
  min-height: 40px;
  margin-top: 8px;
  border: 0;
  border-radius: 10px;
  background: #0f766e;
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.doctor-layout__main {
  padding: 24px;
}

.doctor-layout__main.is-login {
  padding: 0;
}

.doctor-layout.is-login {
  grid-template-columns: 1fr;
}

@media (max-width: 1100px) {
  .doctor-layout {
    grid-template-columns: 1fr;
  }
}
</style>
