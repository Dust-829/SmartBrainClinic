<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const immersiveRoutes = [
  'patient-login',
  'patient-register',
  'patient-home',
  'patient-hospital',
  'patient-profile',
  'patient-messages',
  'patient-visit-code',
  'patient-registers',
  'patient-departments',
  'patient-triage',
  'patient-doctors',
  'patient-confirm-register',
  'patient-payment',
  'patient-payments',
  'patient-payment-records',
  'patient-queue',
]
const isImmersive = computed(() => immersiveRoutes.includes(String(route.name)))
</script>

<template>
  <div :class="['patient-layout', { 'patient-layout--immersive': isImmersive }]">
    <header v-if="!isImmersive" class="patient-layout__header">
      <p>&#26234;&#24935;&#20113;&#33041;&#35786;&#30103;&#24179;&#21488;</p>
      <h1>&#24739;&#32773;&#31471;</h1>
    </header>
    <main class="patient-layout__main">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.patient-layout {
  min-height: 100vh;
  background: var(--patient-page-bg);
  color: var(--patient-text);
}

.patient-layout__header {
  width: min(100%, var(--patient-page-width));
  min-height: 170px;
  margin: 0 auto;
  padding: 70px var(--patient-page-gutter) 28px;
  color: #ffffff;
  background: var(--patient-header-gradient);
}

.patient-layout__header p,
.patient-layout__header h1 {
  margin: 0;
}

.patient-layout__header p {
  font-size: 13px;
  font-weight: 700;
  opacity: 0.9;
}

.patient-layout__header h1 {
  margin-top: 5px;
  font-size: 28px;
  line-height: 1.2;
  letter-spacing: 0;
}

.patient-layout__main {
  width: min(100%, var(--patient-page-width));
  margin: 0 auto;
  padding: 16px var(--patient-page-gutter) 30px;
}

.patient-layout--immersive .patient-layout__main {
  width: min(100%, var(--patient-page-width));
  min-height: 100vh;
  margin: 0 auto;
  padding: 0;
}

@media (min-width: 720px) {
  .patient-layout__header,
  .patient-layout__main,
  .patient-layout--immersive .patient-layout__main {
    border-radius: var(--patient-page-radius);
    box-shadow: var(--patient-page-shadow);
    overflow: hidden;
  }
}
</style>
