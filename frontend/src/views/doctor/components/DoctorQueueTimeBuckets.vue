<script setup lang="ts">
import { computed } from 'vue'

interface QueueTimeBucket {
  label: string
  count: number
}

const props = defineProps<{
  items: QueueTimeBucket[]
}>()

const maxRows = 6
const unknownTimeLabel = '时间待确认'

const visibleItems = computed<QueueTimeBucket[]>(() => {
  const knownItems = props.items.filter((item) => item.label !== unknownTimeLabel && item.count > 0)
  const unknownItem = props.items.find((item) => item.label === unknownTimeLabel && item.count > 0)
  const availableKnownRows = unknownItem ? maxRows - 1 : maxRows

  if (knownItems.length <= availableKnownRows) {
    return unknownItem ? [...knownItems, unknownItem] : knownItems
  }

  const visibleKnownCount = availableKnownRows - 1
  const visibleKnownItems = knownItems.slice(0, visibleKnownCount)
  const remainingCount = knownItems
    .slice(visibleKnownCount)
    .reduce((total, item) => total + item.count, 0)
  const summarizedItems = [...visibleKnownItems, { label: '其他时段', count: remainingCount }]

  return unknownItem ? [...summarizedItems, unknownItem] : summarizedItems
})

const maxCount = computed(() => Math.max(0, ...visibleItems.value.map((item) => item.count)))
const accessibleLabel = computed(() => {
  if (!visibleItems.value.length) return '分时段挂号，今日暂无挂号时段'
  return `分时段挂号，${visibleItems.value.map((item) => `${item.label}${item.count}人`).join('，')}`
})

function barWidth(count: number) {
  return maxCount.value > 0 ? `${Math.round((count / maxCount.value) * 100)}%` : '0%'
}
</script>

<template>
  <section class="doctor-queue-time-buckets" :aria-label="accessibleLabel">
    <p class="doctor-queue-time-buckets__title">分时段挂号</p>

    <ul v-if="visibleItems.length">
      <li v-for="item in visibleItems" :key="item.label">
        <span class="doctor-queue-time-buckets__label">{{ item.label }}</span>
        <span class="doctor-queue-time-buckets__track" aria-hidden="true">
          <i :style="{ width: barWidth(item.count) }"></i>
        </span>
        <strong>{{ item.count }}</strong>
      </li>
    </ul>

    <p v-else class="doctor-queue-time-buckets__empty">今日暂无挂号时段</p>
  </section>
</template>

<style scoped>
.doctor-queue-time-buckets {
  display: grid;
  align-content: center;
  gap: 12px;
  min-width: 280px;
  padding-left: 24px;
  border-left: 1px solid rgba(255, 255, 255, 0.22);
}

.doctor-queue-time-buckets__title,
.doctor-queue-time-buckets__empty {
  margin: 0;
}

.doctor-queue-time-buckets__title {
  color: #ffffff;
  font-size: 14px;
  font-weight: 700;
}

.doctor-queue-time-buckets ul {
  display: grid;
  gap: 9px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.doctor-queue-time-buckets li {
  display: grid;
  grid-template-columns: 82px minmax(80px, 1fr) 24px;
  align-items: center;
  gap: 10px;
  font-size: 12px;
}

.doctor-queue-time-buckets__label {
  overflow: hidden;
  color: rgba(255, 255, 255, 0.9);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.doctor-queue-time-buckets__track {
  height: 8px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.14);
}

.doctor-queue-time-buckets__track i {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: #5eead4;
  transition: width 180ms ease-out;
}

.doctor-queue-time-buckets li strong {
  color: #ffffff;
  font-size: 13px;
  text-align: right;
}

.doctor-queue-time-buckets__empty {
  display: grid;
  min-height: 92px;
  place-items: center;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.82);
  font-size: 13px;
}

@media (prefers-reduced-motion: reduce) {
  .doctor-queue-time-buckets__track i {
    transition: none;
  }
}

@media (max-width: 1180px) {
  .doctor-queue-time-buckets {
    width: 100%;
    min-width: 0;
    padding-top: 20px;
    padding-left: 0;
    border-top: 1px solid rgba(255, 255, 255, 0.22);
    border-left: 0;
  }
}
</style>
