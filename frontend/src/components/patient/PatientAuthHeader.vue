<script setup lang="ts">
import { useRouter } from 'vue-router'

defineProps<{
  title: string
  subtitle: string
}>()

const router = useRouter()
</script>

<template>
  <header class="patient-auth-header">
    <button type="button" class="patient-back-button" aria-label="&#36820;&#22238;&#39318;&#39029;" @click="router.push('/patient/home')">
      <span aria-hidden="true"></span>
      &#36820;&#22238;
    </button>
    <p class="patient-auth-header__brand">&#26234;&#24935;&#20113;&#33041;&#35786;&#30103;&#24179;&#21488;</p>
    <h1>{{ title }}</h1>
    <p class="patient-auth-header__subtitle">{{ subtitle }}</p>
  </header>
</template>

<style scoped>
.patient-auth-header {
  min-height: var(--patient-auth-header-height);
  padding: 62px var(--patient-page-gutter) 72px;
  color: #ffffff;
  background: var(--patient-header-gradient);
}

.patient-auth-header__brand,
.patient-auth-header h1,
.patient-auth-header__subtitle {
  margin: 0;
}

.patient-auth-header__brand {
  margin-top: 24px;
  font-size: 14px;
  font-weight: 700;
  opacity: 0.9;
}

.patient-auth-header h1 {
  margin-top: 6px;
  font-size: 30px;
  line-height: 1.2;
  letter-spacing: 0;
}

.patient-auth-header__subtitle {
  max-width: 32em;
  margin-top: 8px;
  color: rgba(255, 255, 255, 0.88);
  font-size: 14px;
  line-height: 1.6;
}

.patient-back-button {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  min-height: 36px;
  padding: 0 10px 0 7px;
  border: 1px solid rgba(255, 255, 255, 0.58);
  border-radius: 18px;
  background: rgba(10, 93, 205, 0.2);
  color: #ffffff;
  font: inherit;
  font-size: 14px;
  cursor: pointer;
}

.patient-back-button span {
  width: 10px;
  height: 10px;
  border-left: 2px solid currentColor;
  border-bottom: 2px solid currentColor;
  transform: rotate(45deg);
}

.patient-back-button:focus-visible {
  outline: 2px solid #ffffff;
  outline-offset: 2px;
}
</style>
