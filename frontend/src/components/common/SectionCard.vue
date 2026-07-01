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
  border: 1px solid var(--patient-border, #e2e8f0);
  border-radius: var(--patient-radius, 8px);
  background: var(--patient-surface, #ffffff);
  box-shadow: var(--patient-shadow, none);
}

.section-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 20px 20px 0;
}

.section-card__header h3 {
  margin: 0;
  color: var(--patient-text, #0f172a);
  font-size: 18px;
  line-height: 1.3;
  letter-spacing: 0;
}

.section-card__header p {
  margin: 6px 0 0;
  color: var(--patient-text-muted, #64748b);
  font-size: 13px;
}

.section-card__body {
  padding: 18px 20px 20px;
}
</style>
