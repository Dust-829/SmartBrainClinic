<script setup lang="ts">
import { useRouter } from 'vue-router'

defineProps<{
  title: string
  subtitle?: string
  backLabel?: string
}>()

const emit = defineEmits<{ back: [] }>()
const router = useRouter()

function goHome() {
  router.push('/patient/home')
}
</script>

<template>
  <header class="patient-flow-header">
    <button
      type="button"
      class="patient-flow-header__back"
      :aria-label="backLabel || '返回上一级'"
      :title="backLabel || '返回上一级'"
      @click="emit('back')"
    >
      <span aria-hidden="true"></span>
    </button>
    <div class="patient-flow-header__copy">
      <h1>{{ title }}</h1>
      <p v-if="subtitle">{{ subtitle }}</p>
    </div>
    <button type="button" class="patient-flow-header__home" aria-label="返回首页" title="返回首页" @click="goHome">
      <span class="patient-flow-header__home-icon" aria-hidden="true"></span>
      <strong>首页</strong>
    </button>
  </header>
</template>

<style scoped>
.patient-flow-header {
  display: grid;
  grid-template-columns: 42px minmax(0, 1fr) auto;
  align-items: center;
  gap: 10px;
  min-height: 154px;
  padding: 32px var(--patient-page-gutter) 42px;
  color: #ffffff;
  background: var(--patient-header-gradient);
}

.patient-flow-header button {
  border: 1px solid rgba(255, 255, 255, 0.42);
  background: rgba(255, 255, 255, 0.16);
  color: #ffffff;
  cursor: pointer;
}

.patient-flow-header__back {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border-radius: 50%;
}

.patient-flow-header__back span {
  width: 10px;
  height: 10px;
  border-left: 2px solid currentColor;
  border-bottom: 2px solid currentColor;
  transform: translateX(2px) rotate(45deg);
}

.patient-flow-header__copy {
  min-width: 0;
}

.patient-flow-header__copy h1,
.patient-flow-header__copy p {
  margin: 0;
}

.patient-flow-header__copy h1 {
  font-size: 28px;
  font-weight: 900;
  line-height: 1.18;
  letter-spacing: 0;
  text-wrap: balance;
}

.patient-flow-header__copy p {
  margin-top: 7px;
  overflow: hidden;
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  line-height: 1.45;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.patient-flow-header__home {
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 68px;
  height: 38px;
  padding: 0 11px;
  border-radius: 19px;
}

.patient-flow-header__home strong {
  font-size: 13px;
  font-weight: 800;
  white-space: nowrap;
}

.patient-flow-header__home-icon {
  position: relative;
  width: 15px;
  height: 13px;
  border: 2px solid currentColor;
  border-top: 0;
  border-radius: 2px;
}

.patient-flow-header__home-icon::before {
  position: absolute;
  top: -5px;
  left: 1px;
  width: 9px;
  height: 9px;
  border-top: 2px solid currentColor;
  border-left: 2px solid currentColor;
  transform: rotate(45deg);
  content: '';
}

.patient-flow-header button:focus-visible {
  outline: 3px solid rgba(255, 255, 255, 0.8);
  outline-offset: 2px;
}

@media (max-width: 360px) {
  .patient-flow-header {
    grid-template-columns: 40px minmax(0, 1fr) 42px;
  }

  .patient-flow-header__home {
    justify-content: center;
    min-width: 38px;
    width: 38px;
    padding: 0;
  }

  .patient-flow-header__home strong {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip: rect(0 0 0 0);
  }
}

@media (max-width: 520px) {
  .patient-flow-header {
    min-height: 190px;
    padding-top: 72px;
  }
}
</style>
