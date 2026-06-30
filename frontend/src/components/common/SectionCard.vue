<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
}>()
</script>

<template>
  <section class="section-card">
    <header class="section-card__header">
      <div>
        <h3>{{ title }}</h3>
        <p v-if="subtitle">{{ subtitle }}</p>
      </div>
      <slot name="extra" />
    </header>
    <div class="section-card__body">
      <slot />
    </div>
  </section>
</template>

<style scoped>
.section-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
}

.section-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 18px 20px 0;
}

.section-card__header h3 {
  margin: 0;
  font-size: 16px;
  color: #0f172a;
}

.section-card__header p {
  margin: 6px 0 0;
  font-size: 13px;
  color: #64748b;
}

.section-card__body {
  padding: 18px 20px 20px;
}
</style>
