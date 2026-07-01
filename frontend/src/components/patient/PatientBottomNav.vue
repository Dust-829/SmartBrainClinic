<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const router = useRouter()
const route = useRoute()

const activeTab = computed(() => {
  if (route.name === 'patient-registers') return 'records'
  if (route.name === 'patient-profile') return 'profile'
  if (String(route.name).includes('department') || String(route.name).includes('doctor')) return 'register'
  return 'home'
})

const tabs = [
  { key: 'home', label: '\u9996\u9875', icon: 'home', path: '/patient/home' },
  { key: 'records', label: '\u6302\u53f7\u8bb0\u5f55', icon: 'records', path: '/patient/registers' },
  { key: 'message', label: '\u6d88\u606f', icon: 'message', path: '' },
  { key: 'profile', label: '\u6211\u7684', icon: 'profile', path: '/patient/profile' },
]

function navigate(path: string) {
  if (path) router.push(path)
}
</script>

<template>
  <nav class="patient-bottom-nav" aria-label="&#24739;&#32773;&#31471;&#24213;&#37096;&#23548;&#33322;">
    <button
      v-for="tab in tabs"
      :key="tab.key"
      type="button"
      :class="{ 'is-active': activeTab === tab.key }"
      :disabled="!tab.path"
      @click="navigate(tab.path)"
    >
      <span :class="`patient-bottom-nav__icon is-${tab.icon}`" aria-hidden="true"></span>
      <strong>{{ tab.label }}</strong>
    </button>
  </nav>
</template>

<style scoped>
.patient-bottom-nav {
  position: fixed;
  left: max(0px, calc((100vw - var(--patient-page-width)) / 2));
  right: max(0px, calc((100vw - var(--patient-page-width)) / 2));
  bottom: 0;
  z-index: var(--patient-z-nav);
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  min-height: var(--patient-nav-height);
  padding: 8px 8px max(8px, env(safe-area-inset-bottom));
  border-top: 1px solid var(--patient-border);
  background: rgba(255, 255, 255, 0.98);
  box-shadow: 0 -8px 24px rgba(27, 80, 132, 0.08);
}

.patient-bottom-nav button {
  display: grid;
  place-items: center;
  align-content: center;
  gap: 5px;
  min-width: 0;
  min-height: 52px;
  padding: 0;
  border: 0;
  background: transparent;
  color: var(--patient-text-muted);
  font: inherit;
  cursor: pointer;
}

.patient-bottom-nav button:disabled {
  cursor: default;
  opacity: 0.55;
}

.patient-bottom-nav button:not(:disabled):focus-visible {
  outline: 2px solid var(--patient-primary);
  outline-offset: -2px;
  border-radius: var(--patient-radius);
}

.patient-bottom-nav button.is-active {
  color: var(--patient-primary);
}

.patient-bottom-nav strong {
  font-size: 13px;
  font-weight: 700;
}

.patient-bottom-nav__icon {
  position: relative;
  width: 26px;
  height: 26px;
}

.patient-bottom-nav__icon.is-home::before {
  position: absolute;
  inset: 7px 4px 3px;
  border: 2px solid currentColor;
  border-radius: 3px;
  content: '';
}

.patient-bottom-nav__icon.is-home::after {
  position: absolute;
  left: 6px;
  top: 3px;
  width: 14px;
  height: 14px;
  border-left: 2px solid currentColor;
  border-top: 2px solid currentColor;
  transform: rotate(45deg);
  content: '';
}

.patient-bottom-nav__icon.is-records {
  border: 2px solid currentColor;
  border-radius: 5px;
}

.patient-bottom-nav__icon.is-records::before,
.patient-bottom-nav__icon.is-records::after {
  position: absolute;
  left: 6px;
  width: 14px;
  height: 2px;
  border-radius: 2px;
  background: currentColor;
  content: '';
}

.patient-bottom-nav__icon.is-records::before {
  top: 8px;
  box-shadow: 0 5px currentColor;
}

.patient-bottom-nav__icon.is-records::after {
  top: 18px;
}

.patient-bottom-nav__icon.is-message {
  border: 2px solid currentColor;
  border-radius: 50%;
}

.patient-bottom-nav__icon.is-message::before {
  position: absolute;
  left: 5px;
  top: 10px;
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: currentColor;
  box-shadow: 6px 0 currentColor, 12px 0 currentColor;
  content: '';
}

.patient-bottom-nav__icon.is-profile::before {
  position: absolute;
  left: 8px;
  top: 2px;
  width: 10px;
  height: 10px;
  border: 2px solid currentColor;
  border-radius: 50%;
  content: '';
}

.patient-bottom-nav__icon.is-profile::after {
  position: absolute;
  left: 4px;
  bottom: 1px;
  width: 18px;
  height: 10px;
  border: 2px solid currentColor;
  border-radius: 10px 10px 4px 4px;
  content: '';
}
</style>
