<script setup lang="ts">
import RoleSwitcher from '@/components/common/RoleSwitcher.vue'
</script>

<template>
  <div class="app-shell">
    <div class="app-shell__role-switcher">
      <RoleSwitcher />
    </div>
    <router-view />
  </div>
</template>

<style scoped>
.app-shell__role-switcher {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 1000;
}

@media (max-width: 768px) {
  .app-shell__role-switcher {
    top: 16px;
    right: 16px;
  }
}
</style>