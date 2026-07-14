<script setup lang="ts">
import HalftoneTrailCanvas from '@/components/common/HalftoneTrailCanvas.vue'
import SimplexNoiseBackdrop from '@/components/common/SimplexNoiseBackdrop.vue'

const entries = [
  {
    key: 'patient',
    title: '患者端',
    label: '患者首页',
    subtitle: '登录、建档、AI 分诊、挂号与候诊',
    route: '/patient',
    tone: 'patient',
  },
  {
    key: 'doctor',
    title: '医生端',
    label: '医生工作台',
    subtitle: '登录后进入候诊、接诊与病历处理',
    route: '/doctor/login',
    tone: 'doctor',
  },
  {
    key: 'admin',
    title: '管理员端',
    label: '管理控制台',
    subtitle: '登录后进入排班、审批与审计',
    route: '/admin/login',
    tone: 'admin',
  },
] as const

function openEntry(route: string) {
  window.open(route, '_blank', 'noopener')
}
</script>

<template>
  <main class="portal-entry">
    <SimplexNoiseBackdrop
      class-name="portal-entry__noise"
      base-color="#d7dde4"
      glow-color-a="#c8d0db"
      glow-color-b="#c8d4d1"
    />

    <HalftoneTrailCanvas
      class-name="portal-entry__trail"
      color="rgba(23, 23, 35, 0.92)"
      :cell-size="10"
      :decay="0.965"
      :brush-size="0.03"
      :hover-brush-size="0.0035"
      :opacity="0.72"
      :hover-opacity="0.18"
      :speed-scale="38"
      hover-selector=".portal-entry__entry"
    />

    <section class="portal-entry__stage" aria-label="系统入口">
      <button
        v-for="entry in entries"
        :key="entry.key"
        type="button"
        :class="['portal-entry__entry', `is-${entry.tone}`]"
        :aria-label="`${entry.title}：${entry.subtitle}`"
        @click="openEntry(entry.route)"
      >
        <strong class="portal-entry__title">{{ entry.title }}</strong>
        <div class="portal-entry__detail">
          <span class="portal-entry__label">{{ entry.label }}</span>
          <p>{{ entry.subtitle }}</p>
        </div>
      </button>
    </section>

  </main>
</template>

<style scoped>
.portal-entry {
  position: relative;
  min-height: 100vh;
  overflow: hidden;
  padding: clamp(24px, 3vw, 38px) clamp(18px, 3.6vw, 44px);
  background: linear-gradient(135deg, #d9dee5 0%, #d4d9e1 48%, #d1d7df 100%);
  color: #171723;
}

.portal-entry::before,
.portal-entry::after {
  content: '';
  position: absolute;
  border-radius: 999px;
  pointer-events: none;
  filter: blur(18px);
  opacity: 0.6;
}

.portal-entry::before {
  inset: auto auto 12% -4%;
  width: clamp(180px, 24vw, 320px);
  height: clamp(180px, 24vw, 320px);
  background: radial-gradient(circle, rgba(255, 226, 235, 0.78) 0%, rgba(255, 226, 235, 0) 72%);
}

.portal-entry::after {
  inset: 8% -8% auto auto;
  width: clamp(220px, 28vw, 380px);
  height: clamp(220px, 28vw, 380px);
  background: radial-gradient(circle, rgba(215, 234, 255, 0.8) 0%, rgba(215, 234, 255, 0) 74%);
}

.portal-entry__stage {
  position: relative;
  z-index: 1;
  width: min(1320px, 100%);
  margin: 0 auto;
}

:deep(.portal-entry__trail) {
  mix-blend-mode: multiply;
  opacity: 0.52;
}

:deep(.portal-entry__noise) {
  opacity: 0.98;
}

.portal-entry::before {
  filter: blur(42px);
  opacity: 0.28;
  background: radial-gradient(circle, rgba(194, 204, 220, 0.62) 0%, rgba(194, 204, 220, 0) 74%);
}

.portal-entry::after {
  filter: blur(30px);
  opacity: 0.22;
  background: radial-gradient(circle, rgba(194, 210, 205, 0.56) 0%, rgba(194, 210, 205, 0) 76%);
}

.portal-entry__stage {
  display: grid;
  gap: clamp(10px, 2vw, 20px);
  min-height: 100vh;
  align-content: center;
  padding: clamp(24px, 6vw, 72px) 0;
  transform: translateX(clamp(0px, 6vw, 96px));
}

.portal-entry__entry {
  --entry-accent: #171723;
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(280px, 0.85fr);
  align-items: end;
  gap: clamp(24px, 3vw, 42px);
  width: 100%;
  padding: clamp(16px, 2vw, 22px) 0 clamp(18px, 2.8vw, 28px);
  border: 0;
  border-bottom: 1px solid rgba(23, 23, 35, 0.12);
  background: transparent;
  text-align: left;
  color: inherit;
  font: inherit;
  cursor: pointer;
  transition:
    transform 180ms ease-out,
    border-color 180ms ease-out;
}

.portal-entry__entry.is-patient {
  --entry-accent: #0569d8;
}

.portal-entry__entry.is-doctor {
  --entry-accent: #0f766e;
}

.portal-entry__entry.is-admin {
  --entry-accent: #4338ca;
}

.portal-entry__entry.is-admin .portal-entry__title {
  font-size: clamp(3.8rem, 7.6vw, 6.65rem);
  letter-spacing: -0.07em;
}

.portal-entry__entry:hover,
.portal-entry__entry:focus-visible {
  border-color: rgba(23, 23, 35, 0.26);
}

.portal-entry__entry:focus-visible {
  outline: 3px solid color-mix(in srgb, var(--entry-accent) 24%, white);
  outline-offset: 8px;
}

.portal-entry__title {
  margin: 0;
  color: #171723;
  font-size: clamp(4rem, 9.4vw, 8rem);
  font-weight: 800;
  line-height: 0.92;
  letter-spacing: -0.08em;
  transform: skewX(-11deg);
  transform-origin: left center;
  text-shadow: 0 18px 32px rgba(255, 255, 255, 0.34);
  text-wrap: balance;
  transition:
    transform 220ms ease-out,
    color 220ms ease-out,
    text-shadow 220ms ease-out;
}

.portal-entry__entry:hover .portal-entry__title,
.portal-entry__entry:focus-visible .portal-entry__title {
  color: var(--entry-accent);
  transform: translateX(12px) skewX(-11deg);
  text-shadow: 0 18px 32px rgba(255, 255, 255, 0.52);
}

.portal-entry__detail {
  display: grid;
  gap: 10px;
  align-self: center;
  max-width: 28ch;
  padding-bottom: 6px;
}

.portal-entry__label {
  color: var(--entry-accent);
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.portal-entry__detail p {
  margin: 0;
  color: rgba(23, 23, 35, 0.72);
  font-size: 17px;
  line-height: 1.65;
  text-wrap: pretty;
}

@media (max-width: 980px) {
  .portal-entry__stage {
    transform: none;
  }

  .portal-entry__entry,
  .portal-entry__entry.is-doctor,
  .portal-entry__entry.is-admin {
    grid-template-columns: 1fr;
    padding-left: 0;
  }

  .portal-entry__detail {
    max-width: 32ch;
    padding-bottom: 0;
  }
}

@media (max-width: 640px) {
  .portal-entry {
    padding: 18px 16px 24px;
  }

  .portal-entry__label {
    letter-spacing: 0.05em;
  }

  .portal-entry__detail p {
    font-size: 14px;
  }

  .portal-entry__title {
    font-size: clamp(3rem, 18vw, 4.8rem);
  }

  .portal-entry__entry.is-admin .portal-entry__title {
    font-size: clamp(3rem, 15vw, 4.05rem);
  }
}

@media (prefers-reduced-motion: reduce) {
  .portal-entry__entry,
  .portal-entry__title {
    transition: none;
  }

  .portal-entry__entry:hover .portal-entry__title,
  .portal-entry__entry:focus-visible .portal-entry__title {
    transform: skewX(-11deg);
  }
}
</style>
