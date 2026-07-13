<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const session = usePatientSessionStore()

const isLoggedIn = computed(() => session.isLoggedIn)
const patientName = computed(() => (isLoggedIn.value ? session.patient?.real_name || '当前患者' : '请先登录'))
const visitMeta = computed(() => (isLoggedIn.value ? `门诊号：${session.patient?.case_number || '暂未建档'}` : '登录后查看个人档案与就诊码'))
const visitCardActionLabel = computed(() => (isLoggedIn.value ? '出示就诊码' : '去登录'))

function openVisitCard() {
  if (!isLoggedIn.value) {
    router.push('/patient/login')
    return
  }

  router.push('/patient/visit-code')
}

const features = [
  {
    key: 'visit-code',
    title: '\u5c31\u8bca\u7801',
    subtitle: '\u51fa\u793a\u4e8c\u7ef4\u7801\uff0c\u5c31\u8bca\u6838\u9a8c',
    icon: 'code',
    tone: 'blue',
    action: () => router.push('/patient/visit-code'),
  },
  {
    key: 'departments',
    title: '\u6309\u79d1\u5ba4\u6302\u53f7',
    subtitle: '\u9009\u62e9\u79d1\u5ba4\uff0c\u5728\u7ebf\u6392\u53f7',
    icon: 'calendar-plus',
    tone: 'teal',
    action: () => router.push({ path: '/patient/departments', query: { askAi: '1' } }),
  },
  {
    key: 'queue',
    title: '\u5019\u8bca\u72b6\u6001',
    subtitle: '\u67e5\u770b\u6392\u961f\u8fdb\u5ea6',
    icon: 'clock',
    tone: 'blue',
    action: () => router.push('/patient/queue'),
  },
  {
    key: 'payments',
    title: '\u7f34\u8d39\u4e2d\u5fc3',
    subtitle: '\u68c0\u67e5\u68c0\u9a8c\u3001\u5904\u7f6e\u7f34\u8d39',
    icon: 'payment',
    tone: 'teal',
    action: () => router.push('/patient/payments'),
  },
  {
    key: 'reports',
    title: '\u62a5\u544a\u67e5\u8be2',
    subtitle: '\u68c0\u67e5\u68c0\u9a8c\u62a5\u544a',
    icon: 'report',
    tone: 'blue',
    action: () => undefined,
  },
  {
    key: 'hospital',
    title: '\u533b\u9662\u4fe1\u606f',
    subtitle: '\u79d1\u5ba4\u4ecb\u7ecd\u3001\u5c31\u8bca\u6307\u5357',
    icon: 'building',
    tone: 'teal',
    action: () => router.push('/patient/hospital'),
  },
]
</script>

<template>
  <div class="patient-home-shell">
    <section class="patient-home-hero patient-flow-hero">
      <div class="patient-home-hero__title-row">
        <div>
          <h1>&#26234;&#24935;&#20113;&#33041;&#35786;&#30103;&#24179;&#21488;</h1>
          <p>&#24739;&#32773;&#31471;</p>
        </div>
        <div class="patient-home-mini-program" aria-hidden="true">
          <span>&#8226;&#8226;&#8226;</span>
          <i></i>
        </div>
      </div>

      <label class="patient-home-search">
        <span aria-hidden="true"></span>
        <input type="search" placeholder="&#25628;&#32034;&#31185;&#23460;&#12289;&#21307;&#29983;" />
      </label>
    </section>

    <main class="patient-home-content">
      <button type="button" class="patient-home-card patient-home-card--visit" @click="openVisitCard">
        <span class="patient-home-avatar" aria-hidden="true"></span>
        <span class="patient-home-identity">
          <strong>{{ patientName }}</strong>
          <em v-if="isLoggedIn">&#26412;&#20154;</em>
          <small>{{ visitMeta }}</small>
        </span>
        <span class="patient-home-code" aria-hidden="true">
          <span></span>
          <small>{{ visitCardActionLabel }}</small>
        </span>
        <span class="patient-home-card__arrow" aria-hidden="true">&#8250;</span>
      </button>

      <button type="button" class="patient-home-notice">
        <span aria-hidden="true">i</span>
        <strong>AI&#22238;&#22797;&#20165;&#20379;&#21442;&#32771;&#65292;&#26368;&#32456;&#35786;&#30103;&#30001;&#21307;&#29983;&#30830;&#35748;</strong>
        <i aria-hidden="true">&#8250;</i>
      </button>

      <section class="patient-home-grid" aria-label="&#24120;&#29992;&#21151;&#33021;">
        <button
          v-for="feature in features"
          :key="feature.key"
          type="button"
          class="patient-home-feature"
          @click="feature.action"
        >
          <span :class="['patient-home-feature__icon', `is-${feature.tone}`, `is-${feature.icon}`]" aria-hidden="true">
            <i></i>
          </span>
          <strong>{{ feature.title }}</strong>
          <small>{{ feature.subtitle }}</small>
          <em aria-hidden="true">&#8250;</em>
        </button>
      </section>
    </main>
    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-home-shell {
  position: relative;
  min-height: 100vh;
  margin: 0 auto;
  padding-bottom: calc(var(--patient-nav-height) + 28px);
  overflow: hidden;
  background: var(--patient-flow-page-bg);
  color: #16233a;
}

.patient-home-hero {
  padding: 42px 20px 92px;
  background:
    radial-gradient(circle at 82% 22%, rgba(255, 255, 255, 0.24), transparent 22%),
    linear-gradient(135deg, #0573ff 0%, #1597ff 54%, #4eb9ff 100%);
  color: #ffffff;
}

.patient-home-hero::before {
  position: absolute;
  content: '';
  pointer-events: none;
}

.patient-home-hero::before {
  right: 34px;
  top: 70px;
  width: 250px;
  height: 150px;
  border: 22px solid rgba(255, 255, 255, 0.08);
  border-radius: 40px;
  transform: rotate(-22deg);
}

.patient-home-hero__title-row,
.patient-home-search {
  position: relative;
  z-index: 1;
}

.patient-home-hero__title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 18px;
}

.patient-home-hero__title-row p {
  margin: 9px 0 0;
  font-size: 19px;
  font-weight: 700;
}

.patient-home-hero__title-row h1 {
  margin: 0;
  font-size: 32px;
  line-height: 1.12;
  font-weight: 900;
  letter-spacing: 0;
}

.patient-home-mini-program {
  display: flex;
  align-items: center;
  gap: 14px;
  flex: 0 0 auto;
  height: 46px;
  padding: 0 16px 0 18px;
  border-radius: 24px;
  background: rgba(31, 98, 188, 0.48);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.12);
}

.patient-home-mini-program span {
  font-size: 22px;
  letter-spacing: 2px;
  line-height: 1;
}

.patient-home-mini-program i {
  width: 23px;
  height: 23px;
  border: 4px solid #ffffff;
  border-radius: 50%;
  box-shadow: inset 0 0 0 5px rgba(255, 255, 255, 0.22);
}

.patient-home-search {
  display: flex;
  align-items: center;
  gap: 13px;
  height: 54px;
  margin-top: 22px;
  padding: 0 18px;
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 16px 34px rgba(27, 95, 165, 0.16);
}

.patient-home-search span {
  position: relative;
  width: 20px;
  height: 20px;
  border: 3px solid #7c8899;
  border-radius: 50%;
}

.patient-home-search span::after {
  position: absolute;
  right: -7px;
  bottom: -6px;
  width: 9px;
  height: 3px;
  border-radius: 2px;
  background: #7c8899;
  transform: rotate(45deg);
  content: '';
}

.patient-home-search input {
  min-width: 0;
  width: 100%;
  border: 0;
  outline: 0;
  color: #16233a;
  font-size: 20px;
  background: transparent;
}

.patient-home-search input::placeholder {
  color: #8793a3;
}

.patient-home-content {
  position: relative;
  z-index: 2;
  display: grid;
  gap: 16px;
  margin-top: var(--patient-flow-hero-content-offset);
  padding: 0 20px;
}

.patient-home-card,
.patient-home-notice,
.patient-home-feature {
  border: 0;
  font: inherit;
  color: inherit;
}

.patient-home-card--visit {
  display: grid;
  position: relative;
  grid-template-columns: 64px minmax(0, 1fr) 78px 18px;
  align-items: center;
  column-gap: 12px;
  min-height: 116px;
  padding: 22px 16px 22px 20px;
  border-radius: 18px;
  text-align: left;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 18px 38px rgba(30, 92, 156, 0.12);
  backdrop-filter: blur(14px);
}

.patient-home-avatar {
  position: relative;
  width: 62px;
  height: 62px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3f83ff, #7bb5ff);
}

.patient-home-avatar::before,
.patient-home-avatar::after {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  background: #ffffff;
  content: '';
}

.patient-home-avatar::before {
  top: 16px;
  width: 18px;
  height: 18px;
  border-radius: 50%;
}

.patient-home-avatar::after {
  bottom: 14px;
  width: 36px;
  height: 20px;
  border-radius: 18px 18px 9px 9px;
}

.patient-home-identity {
  min-width: 0;
}

.patient-home-identity strong {
  display: inline-block;
  margin-right: 8px;
  font-size: 28px;
  line-height: 1.1;
  font-weight: 900;
}

.patient-home-identity em {
  display: inline-flex;
  align-items: center;
  height: 26px;
  padding: 0 12px;
  border-radius: 13px;
  background: #e9f2ff;
  color: #2080ff;
  font-style: normal;
  font-size: 15px;
  font-weight: 700;
  vertical-align: 5px;
}

.patient-home-identity small {
  display: block;
  margin-top: 8px;
  max-width: 100%;
  overflow: hidden;
  color: #66758b;
  font-size: 16px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.patient-home-code {
  display: grid;
  justify-items: center;
  gap: 8px;
  color: #253247;
}

.patient-home-code span {
  width: 66px;
  height: 66px;
  border-radius: 17px;
  background:
    linear-gradient(#1976db, #1976db) 14px 14px / 18px 18px no-repeat,
    linear-gradient(#1976db, #1976db) 42px 14px / 18px 18px no-repeat,
    linear-gradient(#1976db, #1976db) 14px 42px / 18px 18px no-repeat,
    linear-gradient(#1976db, #1976db) 46px 46px / 10px 10px no-repeat,
    #ffffff;
  box-shadow: inset 0 0 0 10px #eef6ff;
}

.patient-home-code small {
  width: 78px;
  font-size: 12px;
  line-height: 1.2;
  text-align: center;
  white-space: nowrap;
}

.patient-home-card__arrow {
  position: static;
  color: #9aa6b5;
  font-size: 34px;
  line-height: 1;
}

.patient-home-notice {
  display: grid;
  grid-template-columns: 28px minmax(0, 1fr) 18px;
  align-items: center;
  gap: 12px;
  min-height: 55px;
  padding: 0 18px;
  border-radius: 12px;
  text-align: left;
  background: rgba(229, 243, 255, 0.86);
  color: #7b8797;
}

.patient-home-notice span {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  border: 3px solid #1885ff;
  border-radius: 50%;
  color: #1885ff;
  font-weight: 900;
  font-style: normal;
}

.patient-home-notice strong {
  min-width: 0;
  overflow: hidden;
  font-size: 16px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.patient-home-notice i {
  color: #8f9bad;
  font-style: normal;
  font-size: 28px;
}

.patient-home-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  padding: 16px 14px;
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 18px 40px rgba(33, 94, 151, 0.1);
}

.patient-home-feature {
  position: relative;
  display: grid;
  justify-items: center;
  align-content: start;
  min-height: 116px;
  padding: 10px 6px 7px;
  background: #ffffff;
}

.patient-home-feature:nth-child(1),
.patient-home-feature:nth-child(2),
.patient-home-feature:nth-child(4),
.patient-home-feature:nth-child(5) {
  border-right: 1px solid #e3ebf4;
}

.patient-home-feature:nth-child(-n + 3) {
  border-bottom: 1px solid #e3ebf4;
}

.patient-home-feature__icon {
  position: relative;
  display: grid;
  place-items: center;
  width: 46px;
  height: 54px;
  margin-bottom: 7px;
  border-radius: 50%;
  background: #eef6ff;
}

.patient-home-feature__icon::before {
  position: absolute;
  inset: 10px;
  border-radius: 9px;
  background: linear-gradient(135deg, #247cff, #5aa4ff);
  content: '';
}

.patient-home-feature__icon.is-teal {
  background: #ecfbfb;
}

.patient-home-feature__icon.is-teal::before {
  background: linear-gradient(135deg, #10c3bc, #37d5cc);
}

.patient-home-feature__icon i {
  position: relative;
  z-index: 1;
  display: block;
}

.patient-home-feature__icon.is-code i {
  width: 30px;
  height: 30px;
  background:
    linear-gradient(#fff, #fff) 0 0 / 10px 10px no-repeat,
    linear-gradient(#fff, #fff) 20px 0 / 10px 10px no-repeat,
    linear-gradient(#fff, #fff) 0 20px / 10px 10px no-repeat,
    linear-gradient(#fff, #fff) 20px 20px / 10px 10px no-repeat;
}

.patient-home-feature__icon.is-calendar-plus i,
.patient-home-feature__icon.is-calendar-list i {
  width: 30px;
  height: 32px;
  border-radius: 3px;
  border: 3px solid #ffffff;
  border-top-width: 7px;
}

.patient-home-feature__icon.is-calendar-plus i::before,
.patient-home-feature__icon.is-calendar-plus i::after {
  position: absolute;
  left: 50%;
  top: 50%;
  width: 18px;
  height: 4px;
  border-radius: 2px;
  background: #ffffff;
  transform: translate(-50%, -50%);
  content: '';
}

.patient-home-feature__icon.is-calendar-plus i::after {
  width: 4px;
  height: 18px;
}

.patient-home-feature__icon.is-payment i {
  position: relative;
  width: 24px;
  height: 18px;
  border: 3px solid currentColor;
  border-radius: 5px;
}

.patient-home-feature__icon.is-payment i::before,
.patient-home-feature__icon.is-payment i::after {
  position: absolute;
  height: 3px;
  border-radius: 2px;
  background: currentColor;
  content: '';
}

.patient-home-feature__icon.is-payment i::before {
  top: 4px;
  left: 3px;
  right: 3px;
}

.patient-home-feature__icon.is-payment i::after {
  right: 3px;
  bottom: 4px;
  width: 8px;
}

.patient-home-feature__icon.is-clock i {
  width: 30px;
  height: 30px;
  border: 5px solid #ffffff;
  border-radius: 50%;
}

.patient-home-feature__icon.is-clock i::before {
  position: absolute;
  left: 13px;
  top: 6px;
  width: 4px;
  height: 12px;
  border-radius: 2px;
  background: #ffffff;
  transform-origin: bottom center;
  transform: rotate(0deg);
  content: '';
}

.patient-home-feature__icon.is-report i {
  width: 28px;
  height: 34px;
  border-radius: 4px 9px 4px 4px;
  background: #ffffff;
}

.patient-home-feature__icon.is-report i::before,
.patient-home-feature__icon.is-report i::after {
  position: absolute;
  left: 6px;
  width: 15px;
  height: 3px;
  border-radius: 2px;
  background: #247cff;
  content: '';
}

.patient-home-feature__icon.is-report i::before { top: 10px; }
.patient-home-feature__icon.is-report i::after { top: 18px; }

.patient-home-feature__icon.is-building i {
  width: 32px;
  height: 34px;
  border-radius: 4px 4px 2px 2px;
  background:
    linear-gradient(#10c3bc, #10c3bc) 8px 8px / 5px 5px no-repeat,
    linear-gradient(#10c3bc, #10c3bc) 20px 8px / 5px 5px no-repeat,
    linear-gradient(#10c3bc, #10c3bc) 8px 20px / 5px 5px no-repeat,
    linear-gradient(#10c3bc, #10c3bc) 20px 20px / 5px 5px no-repeat,
    #ffffff;
}

.patient-home-feature strong {
  margin-bottom: 8px;
  color: #172238;
  font-size: 16px;
  line-height: 1.15;
  font-weight: 900;
  letter-spacing: 0;
  text-align: center;
}

.patient-home-feature small {
  color: #8a96a7;
  font-size: 12px;
  line-height: 1.35;
  text-align: center;
}

.patient-home-feature em {
  margin-top: 8px;
  color: #8b97a8;
  font-size: 28px;
  font-style: normal;
  line-height: 1;
}


@media (max-width: 390px) {
  .patient-home-card--visit {
    grid-template-columns: 54px minmax(0, 1fr) 64px 12px;
    gap: 8px;
    padding: 18px 14px;
  }

  .patient-home-avatar {
    width: 54px;
    height: 54px;
  }

  .patient-home-identity strong {
    font-size: 24px;
  }

  .patient-home-identity small,
  .patient-home-code small {
    font-size: 12px;
  }

  .patient-home-code span {
    width: 46px;
    height: 54px;
    border-radius: 14px;
  }

  .patient-home-hero__title-row h1 {
    font-size: 28px;
  }

  .patient-home-feature strong {
    font-size: 16px;
  }

  .patient-home-feature small {
    font-size: 12px;
  }

  .patient-home-feature {
    min-height: 112px;
    padding-left: 6px;
    padding-right: 6px;
  }
}
</style>
