<script setup lang="ts">
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'

type NotificationTone = 'blue' | 'teal'

interface DemonstrationNotification {
  id: string
  title: string
  summary: string
  time: string
  tone: NotificationTone
  icon: 'calendar' | 'clock' | 'report'
  unread: boolean
}

const notifications: DemonstrationNotification[] = [
  {
    id: 'registration-reminder',
    title: '挂号提醒',
    summary: '您有一条即将就诊的提醒，请提前安排出行时间。',
    time: '今天 09:30',
    tone: 'blue',
    icon: 'calendar',
    unread: true,
  },
  {
    id: 'queue-progress',
    title: '候诊进度',
    summary: '当前排队进度已更新，请留意候诊状态。',
    time: '今天 09:10',
    tone: 'teal',
    icon: 'clock',
    unread: true,
  },
  {
    id: 'report-ready',
    title: '检查报告',
    summary: '有新的报告状态更新，后续可在报告查询中查看。',
    time: '昨天 16:45',
    tone: 'blue',
    icon: 'report',
    unread: true,
  },
]
</script>

<template>
  <div class="patient-message-center-shell">
    <header class="patient-message-center-hero">
      <div class="patient-message-center-brand">
        <p>智慧云脑诊疗平台</p>
        <span class="patient-message-center-bell" aria-hidden="true"></span>
      </div>

      <div class="patient-message-center-heading">
        <div>
          <h1>通知中心</h1>
          <p>及时掌握就诊动态，合理安排就诊行程</p>
        </div>
        <span>3 条未读</span>
      </div>
    </header>

    <main class="patient-message-center-content">
      <div class="patient-message-center-filter" aria-label="当前显示全部通知">
        <span class="patient-message-center-filter__icon" aria-hidden="true"></span>
        <strong>全部通知</strong>
        <i aria-hidden="true"></i>
        <span class="patient-message-center-filter__action">筛选</span>
        <span class="patient-message-center-filter__funnel" aria-hidden="true"></span>
      </div>

      <section class="patient-message-center-list" aria-label="演示通知列表">
        <article v-for="notification in notifications" :key="notification.id" class="patient-message-center-item">
          <span
            :class="[
              'patient-message-center-item__icon',
              `is-${notification.tone}`,
              `is-${notification.icon}`,
            ]"
            aria-hidden="true"
          ></span>

          <div class="patient-message-center-item__copy">
            <div>
              <strong>{{ notification.title }}</strong>
              <time>{{ notification.time }}</time>
            </div>
            <p>{{ notification.summary }}</p>
          </div>

          <span v-if="notification.unread" class="patient-message-center-item__unread">
            <span class="sr-only">未读</span>
          </span>
          <span class="patient-message-center-item__arrow" aria-hidden="true">›</span>
        </article>
      </section>

    </main>

    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-message-center-shell {
  min-height: 100vh;
  padding-bottom: calc(var(--patient-nav-height) + 28px);
  overflow: hidden;
  background:
    radial-gradient(circle at 84% 3%, rgba(94, 179, 255, 0.24), transparent 28%),
    linear-gradient(180deg, #eaf5ff 0%, #f7fbff 42%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-message-center-hero {
  position: relative;
  min-height: 278px;
  padding: 34px var(--patient-page-gutter) 88px;
  overflow: hidden;
  background: var(--patient-header-gradient);
  color: #ffffff;
}

.patient-message-center-hero::after {
  position: absolute;
  left: -12%;
  right: -12%;
  bottom: -50px;
  height: 102px;
  border-radius: 50% 50% 0 0;
  background: #eaf5ff;
  content: '';
}

.patient-message-center-brand,
.patient-message-center-heading {
  position: relative;
  z-index: 1;
}

.patient-message-center-brand {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.patient-message-center-brand p {
  margin: 0;
  font-size: 16px;
  font-weight: 800;
  letter-spacing: 0.01em;
}

.patient-message-center-bell {
  position: relative;
  width: 24px;
  height: 25px;
  border: 2px solid #ffffff;
  border-bottom: 0;
  border-radius: 13px 13px 7px 7px;
}

.patient-message-center-bell::before,
.patient-message-center-bell::after {
  position: absolute;
  left: 50%;
  background: #ffffff;
  transform: translateX(-50%);
  content: '';
}

.patient-message-center-bell::before {
  bottom: -5px;
  width: 28px;
  height: 2px;
  border-radius: 2px;
}

.patient-message-center-bell::after {
  bottom: -9px;
  width: 5px;
  height: 4px;
  border-radius: 50%;
}

.patient-message-center-heading {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  margin-top: 58px;
}

.patient-message-center-heading h1,
.patient-message-center-heading p {
  margin: 0;
}

.patient-message-center-heading h1 {
  font-size: 34px;
  line-height: 1.12;
  letter-spacing: 0;
  text-wrap: balance;
}

.patient-message-center-heading p {
  max-width: 18em;
  margin-top: 10px;
  color: rgba(255, 255, 255, 0.9);
  font-size: 16px;
  line-height: 1.55;
}

.patient-message-center-heading > span {
  flex: 0 0 auto;
  margin-top: 8px;
  padding: 8px 13px;
  border-radius: 999px;
  background: rgba(0, 91, 209, 0.55);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.14);
  font-size: 14px;
  font-weight: 800;
  white-space: nowrap;
}

.patient-message-center-content {
  position: relative;
  z-index: 1;
  display: grid;
  gap: 16px;
  margin-top: -68px;
  padding: 0 var(--patient-page-gutter);
}

.patient-message-center-filter {
  display: grid;
  grid-template-columns: 24px minmax(0, 1fr) 10px auto 22px;
  align-items: center;
  gap: 10px;
  min-height: 58px;
  padding: 0 18px;
  border: 1px solid rgba(222, 234, 246, 0.9);
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.96);
  box-shadow: 0 14px 34px rgba(27, 91, 155, 0.12);
}

.patient-message-center-filter strong {
  font-size: 16px;
}

.patient-message-center-filter i {
  width: 7px;
  height: 7px;
  margin-top: -3px;
  border-right: 2px solid var(--patient-text-muted);
  border-bottom: 2px solid var(--patient-text-muted);
  transform: rotate(45deg);
}

.patient-message-center-filter__icon {
  position: relative;
  width: 22px;
  height: 22px;
  border: 2px solid var(--patient-text-muted);
  border-radius: 6px;
}

.patient-message-center-filter__icon::before,
.patient-message-center-filter__icon::after {
  position: absolute;
  background: var(--patient-text-muted);
  content: '';
}

.patient-message-center-filter__icon::before {
  left: 4px;
  right: 4px;
  top: 6px;
  height: 2px;
  box-shadow: 0 5px var(--patient-text-muted);
}

.patient-message-center-filter__icon::after {
  left: 4px;
  top: -4px;
  width: 2px;
  height: 6px;
  box-shadow: 10px 0 var(--patient-text-muted);
}

.patient-message-center-filter__action {
  color: var(--patient-text-muted);
  font-size: 14px;
  font-weight: 700;
}

.patient-message-center-filter__funnel {
  position: relative;
  width: 18px;
  height: 18px;
  border: 2px solid var(--patient-text-muted);
  border-top: 0;
  clip-path: polygon(0 0, 100% 0, 62% 46%, 62% 100%, 38% 100%, 38% 46%);
  background: var(--patient-text-muted);
}

.patient-message-center-list {
  display: grid;
  overflow: hidden;
  border: 1px solid rgba(222, 234, 246, 0.9);
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.97);
  box-shadow: 0 18px 38px rgba(27, 91, 155, 0.1);
}

.patient-message-center-item {
  display: grid;
  grid-template-columns: 52px minmax(0, 1fr) 8px 14px;
  align-items: center;
  gap: 13px;
  min-height: 104px;
  padding: 18px;
}

.patient-message-center-item + .patient-message-center-item {
  border-top: 1px solid var(--patient-border);
}

.patient-message-center-item__icon {
  position: relative;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: var(--patient-primary);
}

.patient-message-center-item__icon.is-teal {
  background: var(--patient-teal);
}

.patient-message-center-item__icon::before,
.patient-message-center-item__icon::after {
  position: absolute;
  content: '';
}

.patient-message-center-item__icon.is-calendar::before {
  inset: 13px 12px 11px;
  border: 3px solid #ffffff;
  border-top-width: 7px;
  border-radius: 4px;
}

.patient-message-center-item__icon.is-calendar::after {
  left: 20px;
  top: 28px;
  width: 13px;
  height: 7px;
  border-left: 3px solid #ffffff;
  border-bottom: 3px solid #ffffff;
  transform: rotate(-45deg);
}

.patient-message-center-item__icon.is-clock::before {
  inset: 12px;
  border: 4px solid #ffffff;
  border-radius: 50%;
}

.patient-message-center-item__icon.is-clock::after {
  left: 25px;
  top: 18px;
  width: 3px;
  height: 16px;
  border-radius: 3px;
  background: #ffffff;
  box-shadow: 6px 10px 0 -1px #ffffff;
  transform-origin: bottom;
  transform: rotate(-42deg);
}

.patient-message-center-item__icon.is-report::before {
  left: 16px;
  top: 11px;
  width: 20px;
  height: 29px;
  border-radius: 3px 7px 3px 3px;
  background: #ffffff;
}

.patient-message-center-item__icon.is-report::after {
  left: 21px;
  top: 22px;
  width: 10px;
  height: 2px;
  border-radius: 2px;
  background: var(--patient-primary);
  box-shadow: 0 6px var(--patient-primary);
}

.patient-message-center-item__copy {
  min-width: 0;
}

.patient-message-center-item__copy > div {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
}

.patient-message-center-item__copy strong {
  font-size: 18px;
  line-height: 1.3;
}

.patient-message-center-item__copy time,
.patient-message-center-item__copy p {
  color: var(--patient-text-muted);
  font-size: 13px;
}

.patient-message-center-item__copy time {
  flex: 0 0 auto;
  white-space: nowrap;
}

.patient-message-center-item__copy p {
  margin: 7px 0 0;
  line-height: 1.55;
}

.patient-message-center-item__unread {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--patient-primary);
}

.patient-message-center-item__arrow {
  color: #97a7b9;
  font-size: 28px;
  line-height: 1;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

@media (max-width: 390px) {
  .patient-message-center-heading h1 {
    font-size: 30px;
  }

  .patient-message-center-item {
    grid-template-columns: 46px minmax(0, 1fr) 8px 12px;
    gap: 10px;
    padding: 16px;
  }

  .patient-message-center-item__icon {
    width: 46px;
    height: 46px;
  }

  .patient-message-center-item__copy strong {
    font-size: 17px;
  }

  .patient-message-center-item__copy p {
    font-size: 12px;
  }
}
</style>
