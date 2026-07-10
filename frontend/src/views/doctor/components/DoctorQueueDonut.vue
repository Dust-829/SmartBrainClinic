<script setup lang="ts">
import { computed } from 'vue'

interface QueueStatusItem {
  key: 'waiting' | 'inReception'
  label: string
  count: number
  percentage: number
}

const props = defineProps<{
  total: number
  items: QueueStatusItem[]
}>()

const radius = 42
const circumference = 2 * Math.PI * radius
const segmentColors: Record<QueueStatusItem['key'], string> = {
  waiting: '#5eead4',
  inReception: '#fdba74',
}

const accessibleLabel = computed(() => {
  const detail = props.items.map((item) => `${item.label}${item.count}人`).join('，')
  return `今日挂号共${props.total}人，${detail}`
})

const segments = computed(() => {
  let cumulativeRatio = 0

  return props.items.map((item) => {
    const ratio = props.total > 0 ? item.count / props.total : 0
    const dashOffset = -cumulativeRatio * circumference
    cumulativeRatio += ratio

    return {
      ...item,
      color: segmentColors[item.key],
      dashArray: `${ratio * circumference} ${circumference}`,
      dashOffset,
    }
  })
})
</script>

<template>
  <section class="doctor-queue-donut" :aria-label="accessibleLabel">
    <div class="doctor-queue-donut__visual">
      <svg viewBox="0 0 100 100" role="img" :aria-label="accessibleLabel">
        <title>{{ accessibleLabel }}</title>
        <circle class="doctor-queue-donut__track" cx="50" cy="50" :r="radius" />
        <circle
          v-for="segment in segments"
          :key="segment.key"
          class="doctor-queue-donut__segment"
          cx="50"
          cy="50"
          :r="radius"
          :stroke="segment.color"
          :stroke-dasharray="segment.dashArray"
          :stroke-dashoffset="segment.dashOffset"
        />
      </svg>
      <div class="doctor-queue-donut__total" aria-hidden="true">
        <strong>{{ total }}</strong>
        <span>今日挂号</span>
      </div>
    </div>

    <div class="doctor-queue-donut__content">
      <p>今日挂号状态</p>
      <ul>
        <li v-for="item in items" :key="item.key">
          <span class="doctor-queue-donut__label">
            <i :style="{ backgroundColor: segmentColors[item.key] }" aria-hidden="true"></i>
            {{ item.label }}
          </span>
          <strong>{{ item.count }}</strong>
          <span>{{ item.percentage }}%</span>
        </li>
      </ul>
    </div>
  </section>
</template>

<style scoped>
.doctor-queue-donut {
  display: grid;
  grid-template-columns: 126px minmax(170px, 1fr);
  align-items: center;
  gap: 20px;
  min-width: 340px;
  padding-left: 24px;
  border-left: 1px solid rgba(255, 255, 255, 0.22);
}

.doctor-queue-donut__visual {
  position: relative;
  width: 126px;
  height: 126px;
}

.doctor-queue-donut__visual svg {
  display: block;
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.doctor-queue-donut__track,
.doctor-queue-donut__segment {
  fill: none;
  stroke-width: 11;
}

.doctor-queue-donut__track {
  stroke: rgba(255, 255, 255, 0.14);
}

.doctor-queue-donut__segment {
  transition: stroke-dasharray 180ms ease-out, stroke-dashoffset 180ms ease-out;
}

.doctor-queue-donut__total {
  position: absolute;
  inset: 0;
  display: grid;
  align-content: center;
  justify-items: center;
  gap: 2px;
}

.doctor-queue-donut__total strong {
  font-size: 28px;
  line-height: 1;
}

.doctor-queue-donut__total span {
  color: rgba(255, 255, 255, 0.84);
  font-size: 12px;
}

.doctor-queue-donut__content {
  display: grid;
  gap: 12px;
}

.doctor-queue-donut__content p {
  margin: 0;
  color: #ffffff;
  font-size: 14px;
  font-weight: 700;
}

.doctor-queue-donut__content ul {
  display: grid;
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.doctor-queue-donut__content li {
  display: grid;
  grid-template-columns: minmax(76px, 1fr) auto 38px;
  align-items: center;
  gap: 10px;
  font-size: 13px;
}

.doctor-queue-donut__content li > strong {
  font-size: 16px;
}

.doctor-queue-donut__content li > span:last-child {
  color: rgba(255, 255, 255, 0.78);
  text-align: right;
}

.doctor-queue-donut__label {
  display: flex;
  align-items: center;
  gap: 8px;
  color: rgba(255, 255, 255, 0.92);
}

.doctor-queue-donut__label i {
  width: 9px;
  height: 9px;
  border-radius: 50%;
}

@media (prefers-reduced-motion: reduce) {
  .doctor-queue-donut__segment {
    transition: none;
  }
}

@media (max-width: 1180px) {
  .doctor-queue-donut {
    width: 100%;
    min-width: 0;
    padding-top: 20px;
    padding-left: 0;
    border-top: 1px solid rgba(255, 255, 255, 0.22);
    border-left: 0;
  }
}

@media (max-width: 480px) {
  .doctor-queue-donut {
    grid-template-columns: 110px minmax(0, 1fr);
    gap: 14px;
  }

  .doctor-queue-donut__visual {
    width: 110px;
    height: 110px;
  }
}
</style>
