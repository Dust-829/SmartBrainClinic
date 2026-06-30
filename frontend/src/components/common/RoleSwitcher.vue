<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAppStore, type RoleKey } from '@/stores/app'

const appStore = useAppStore()
const router = useRouter()

const options: Array<{ key: RoleKey; label: string }> = [
  { key: 'patient', label: '患者端' },
  { key: 'doctor', label: '医生端' },
  { key: 'admin', label: '管理员端' },
]

function handleSwitch(role: RoleKey) {
  appStore.switchRole(role)
  router.push(`/${role}`)
}
</script>

<template>
  <div class="role-switcher">
    <button
      v-for="option in options"
      :key="option.key"
      class="role-switcher__button"
      :class="{ 'is-active': appStore.activeRole === option.key }"
      type="button"
      @click="handleSwitch(option.key)"
    >
      {{ option.label }}
    </button>
  </div>
</template>

<style scoped>
.role-switcher {
  display: inline-flex;
  gap: 8px;
  padding: 6px;
  border: 1px solid rgba(148, 163, 184, 0.3);
  border-radius: 14px;
  background: rgba(15, 23, 42, 0.04);
}

.role-switcher__button {
  border: 0;
  background: transparent;
  color: #475569;
  padding: 8px 14px;
  font-size: 13px;
  cursor: pointer;
  border-radius: 10px;
}

.role-switcher__button.is-active {
  background: #0f172a;
  color: #fff;
}
</style>
