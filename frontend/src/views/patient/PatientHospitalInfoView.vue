<script setup lang="ts">
import { nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'

const router = useRouter()

const specialistServices = [
  { title: '头痛与眩晕', icon: 'headache' },
  { title: '脑血管病', icon: 'vessel' },
  { title: '神经外科随访', icon: 'brain' },
]

const arrivalPreparation = [
  { title: '身份证件', description: '请携带本人有效身份证件', icon: 'identity' },
  { title: '医保凭证', description: '请携带医保电子凭证或社保卡', icon: 'insurance' },
  { title: '既往检查资料', description: '可帮助医生更快了解病情', icon: 'records' },
]

function goBackHome() {
  router.push('/patient/home')
}

async function scrollToSection(sectionId: string) {
  await nextTick()
  const section = document.getElementById(sectionId)
  if (!section) return

  section.scrollIntoView({ behavior: 'smooth', block: 'start' })
  section.setAttribute('tabindex', '-1')
  section.focus({ preventScroll: true })
}

function showMapBoundary() {
  ElMessage.info('地图导航服务暂未接入，请提前规划来院路线。')
}
</script>

<template>
  <div class="patient-hospital-shell">
    <header class="patient-hospital-header">
      <button type="button" class="patient-hospital-back" aria-label="返回患者端首页" @click="goBackHome">
        <span aria-hidden="true"></span>
      </button>
      <h1>医院信息</h1>
      <span aria-hidden="true"></span>
    </header>

    <main>
      <section class="patient-hospital-hero" aria-labelledby="hospital-name">
        <div class="patient-hospital-hero__copy">
          <span>概念展示</span>
          <h2 id="hospital-name">智慧云脑诊疗中心</h2>
          <p><i aria-hidden="true"></i>神经专科门诊服务</p>
        </div>
        <div class="patient-hospital-building" aria-hidden="true">
          <span class="patient-hospital-building__tower"></span>
          <span class="patient-hospital-building__main"></span>
          <span class="patient-hospital-building__entrance"></span>
          <span class="patient-hospital-building__cross">+</span>
        </div>
      </section>

      <section class="patient-hospital-content" aria-label="医院服务信息">
        <p class="patient-hospital-disclaimer">以下为产品概念信息，实际就诊安排请以院方公告为准。</p>

        <section id="hospital-intro" class="patient-hospital-section" aria-labelledby="hospital-intro-title">
          <div class="patient-hospital-section__heading">
            <span class="patient-hospital-line-icon is-document" aria-hidden="true"></span>
            <div>
              <h2 id="hospital-intro-title">医院简介</h2>
              <p>面向脑科与神经外科门诊场景，提供从预约、候诊到随访的连续服务体验。</p>
            </div>
          </div>
        </section>

        <section id="specialist-clinic" class="patient-hospital-section" aria-labelledby="specialist-clinic-title">
          <div class="patient-hospital-section__heading">
            <span class="patient-hospital-line-icon is-brain" aria-hidden="true"></span>
            <div>
              <h2 id="specialist-clinic-title">神经专科门诊</h2>
              <p>按症状与复诊需求选择合适的专科服务。</p>
            </div>
          </div>
          <div class="patient-hospital-specialties" aria-label="神经专科服务范围">
            <div v-for="service in specialistServices" :key="service.title">
              <span :class="['patient-hospital-specialties__icon', `is-${service.icon}`]" aria-hidden="true"></span>
              <strong>{{ service.title }}</strong>
            </div>
          </div>
        </section>

        <section id="visit-guide" class="patient-hospital-guide" aria-labelledby="visit-guide-title">
          <div class="patient-hospital-section__heading">
            <span class="patient-hospital-line-icon is-guide" aria-hidden="true"></span>
            <div>
              <h2 id="visit-guide-title">就诊指南</h2>
              <p>建议提前完成挂号，并按预约时间到院报到。</p>
            </div>
          </div>
          <ol>
            <li><span>1</span>携带有效证件，在服务台或自助设备完成报到。</li>
            <li><span>2</span>关注候诊状态，按叫号提示前往对应诊区。</li>
            <li><span>3</span>检查、检验或复诊时请准备既往资料供医生参考。</li>
          </ol>
        </section>

        <section class="patient-hospital-arrival" aria-labelledby="arrival-title">
          <h2 id="arrival-title">来院信息</h2>
          <dl>
            <div>
              <dt><span class="patient-hospital-line-icon is-clock" aria-hidden="true"></span>门诊时间</dt>
              <dd>周一至周日 08:00–17:30</dd>
            </div>
            <div>
              <dt><span class="patient-hospital-line-icon is-pin" aria-hidden="true"></span>院区地址</dt>
              <dd>东湖路 88 号</dd>
            </div>
            <div>
              <dt><span class="patient-hospital-line-icon is-phone" aria-hidden="true"></span>联系电话</dt>
              <dd>400-820-0120</dd>
            </div>
          </dl>
          <button type="button" class="patient-hospital-map" @click="showMapBoundary">
            <span class="patient-hospital-line-icon is-route" aria-hidden="true"></span>
            路线与地图
          </button>
        </section>

        <button type="button" class="patient-hospital-primary-action" @click="scrollToSection('visit-guide')">查看就诊指南</button>

        <section class="patient-hospital-preparation" aria-labelledby="preparation-title">
          <h2 id="preparation-title">来院前请准备</h2>
          <div>
            <article v-for="item in arrivalPreparation" :key="item.title">
              <span :class="['patient-hospital-preparation__icon', `is-${item.icon}`]" aria-hidden="true"></span>
              <strong>{{ item.title }}</strong>
              <p>{{ item.description }}</p>
            </article>
          </div>
        </section>
      </section>
    </main>

    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-hospital-shell {
  min-height: 100vh;
  padding-bottom: calc(var(--patient-nav-height) + 28px);
  background: linear-gradient(180deg, #eaf5ff 0%, #f7fbff 33%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-hospital-header {
  display: grid;
  grid-template-columns: 44px 1fr 44px;
  align-items: center;
  min-height: 64px;
  padding: max(10px, env(safe-area-inset-top)) var(--patient-page-gutter) 10px;
  background: var(--patient-header-gradient);
  color: #ffffff;
}

.patient-hospital-header h1 {
  margin: 0;
  font-size: 1.25rem;
  line-height: 1.2;
  font-weight: 800;
  text-align: center;
}

.patient-hospital-back {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: transparent;
  color: inherit;
  cursor: pointer;
}

.patient-hospital-back:focus-visible,
.patient-hospital-primary-action:focus-visible,
.patient-hospital-map:focus-visible {
  outline: 3px solid rgba(10, 189, 183, 0.8);
  outline-offset: 2px;
}

.patient-hospital-back span {
  width: 13px;
  height: 13px;
  border-bottom: 3px solid currentColor;
  border-left: 3px solid currentColor;
  transform: rotate(45deg);
}

.patient-hospital-hero {
  position: relative;
  min-height: 282px;
  overflow: hidden;
  padding: 52px var(--patient-page-gutter) 28px;
  background:
    radial-gradient(circle at 78% 2%, rgba(255, 255, 255, 0.76), transparent 24%),
    linear-gradient(145deg, #e1f3ff 0%, #f6fbff 62%, #d9f1f4 100%);
}

.patient-hospital-hero::after {
  position: absolute;
  left: -10%;
  right: -10%;
  bottom: -39px;
  height: 82px;
  border-radius: 50% 50% 0 0;
  background: #f7fbff;
  content: '';
}

.patient-hospital-hero__copy {
  position: relative;
  z-index: 1;
  max-width: 16rem;
}

.patient-hospital-hero__copy > span {
  display: inline-flex;
  padding: 4px 9px;
  border-radius: 999px;
  background: rgba(8, 124, 240, 0.1);
  color: var(--patient-primary-strong);
  font-size: 0.75rem;
  font-weight: 800;
}

.patient-hospital-hero h2 {
  margin: 12px 0 0;
  color: #12345b;
  font-size: 2rem;
  line-height: 1.16;
  letter-spacing: 0;
  text-wrap: balance;
}

.patient-hospital-hero p {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 12px 0 0;
  color: #315979;
  font-size: 1rem;
  font-weight: 700;
}

.patient-hospital-hero p i {
  width: 13px;
  height: 13px;
  border: 3px solid var(--patient-teal);
  border-radius: 5px 5px 7px 7px;
  transform: rotate(45deg);
}

.patient-hospital-building {
  position: absolute;
  right: -20px;
  bottom: 30px;
  width: 245px;
  height: 170px;
  opacity: 0.92;
}

.patient-hospital-building__tower,
.patient-hospital-building__main,
.patient-hospital-building__entrance {
  position: absolute;
  bottom: 0;
  border: 2px solid rgba(35, 130, 211, 0.38);
  background-color: rgba(255, 255, 255, 0.52);
  background-image: repeating-linear-gradient(90deg, transparent 0 20px, rgba(44, 137, 216, 0.35) 20px 24px);
}

.patient-hospital-building__tower {
  right: 12px;
  width: 78px;
  height: 142px;
  border-radius: 20px 20px 0 0;
}

.patient-hospital-building__main {
  right: 74px;
  width: 150px;
  height: 108px;
  border-radius: 16px 16px 0 0;
}

.patient-hospital-building__entrance {
  right: 92px;
  width: 71px;
  height: 48px;
  border-radius: 10px 10px 0 0;
  background-image: linear-gradient(90deg, rgba(34, 126, 205, 0.28) 2px, transparent 2px);
  background-size: 16px 100%;
}

.patient-hospital-building__cross {
  position: absolute;
  right: 41px;
  top: 34px;
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--patient-teal);
  color: #ffffff;
  font-size: 1.5rem;
  font-weight: 800;
  line-height: 1;
}

.patient-hospital-content {
  position: relative;
  z-index: 1;
  display: grid;
  gap: 18px;
  margin-top: -22px;
  padding: 0 var(--patient-page-gutter);
}

.patient-hospital-disclaimer {
  margin: 0;
  padding: 10px 12px;
  border-radius: 12px;
  background: #eef7ff;
  color: #496b88;
  font-size: 0.8125rem;
  line-height: 1.5;
}

.patient-hospital-section,
.patient-hospital-guide,
.patient-hospital-arrival,
.patient-hospital-preparation {
  scroll-margin-top: 18px;
}

.patient-hospital-section:focus,
.patient-hospital-guide:focus {
  outline: none;
}

.patient-hospital-section__heading {
  display: grid;
  grid-template-columns: 36px minmax(0, 1fr);
  align-items: start;
  gap: 12px;
}

.patient-hospital-section__heading h2,
.patient-hospital-arrival h2,
.patient-hospital-preparation h2 {
  margin: 0;
  color: var(--patient-text);
  font-size: 1.25rem;
  line-height: 1.3;
  font-weight: 800;
  text-wrap: balance;
}

.patient-hospital-section__heading p {
  max-width: 30ch;
  margin: 6px 0 0;
  color: var(--patient-text-muted);
  font-size: 0.9375rem;
  line-height: 1.55;
}

.patient-hospital-line-icon {
  position: relative;
  display: inline-block;
  width: 28px;
  height: 28px;
  color: var(--patient-teal);
}

.patient-hospital-line-icon::before,
.patient-hospital-line-icon::after {
  position: absolute;
  content: '';
}

.patient-hospital-line-icon.is-document {
  border: 2px solid currentColor;
  border-radius: 5px 8px 5px 5px;
}

.patient-hospital-line-icon.is-document::before {
  left: 6px;
  right: 6px;
  top: 8px;
  height: 2px;
  background: currentColor;
  box-shadow: 0 6px currentColor;
}

.patient-hospital-line-icon.is-brain {
  border: 2px solid currentColor;
  border-radius: 46% 54% 49% 51%;
}

.patient-hospital-line-icon.is-brain::before {
  left: 12px;
  top: 3px;
  width: 2px;
  height: 20px;
  background: currentColor;
  box-shadow: -6px 5px 0 -0.5px currentColor, 6px 5px 0 -0.5px currentColor;
}

.patient-hospital-line-icon.is-guide {
  border: 2px solid currentColor;
  border-radius: 4px 4px 6px 6px;
}

.patient-hospital-line-icon.is-guide::before {
  left: 12px;
  top: 0;
  width: 2px;
  height: 26px;
  background: currentColor;
}

.patient-hospital-line-icon.is-clock {
  border: 2px solid currentColor;
  border-radius: 50%;
}

.patient-hospital-line-icon.is-clock::before {
  left: 12px;
  top: 5px;
  width: 2px;
  height: 10px;
  background: currentColor;
  transform-origin: bottom;
  transform: rotate(-38deg);
}

.patient-hospital-line-icon.is-pin {
  border: 2px solid currentColor;
  border-radius: 50% 50% 50% 0;
  transform: rotate(-45deg) scale(0.84);
}

.patient-hospital-line-icon.is-pin::before {
  left: 7px;
  top: 7px;
  width: 8px;
  height: 8px;
  border: 2px solid currentColor;
  border-radius: 50%;
}

.patient-hospital-line-icon.is-phone::before {
  inset: 4px 7px;
  border: 3px solid currentColor;
  border-top-color: transparent;
  border-bottom-color: transparent;
  border-radius: 8px;
  transform: rotate(-42deg);
}

.patient-hospital-line-icon.is-route::before {
  left: 3px;
  top: 3px;
  width: 17px;
  height: 17px;
  border-top: 2px solid currentColor;
  border-right: 2px solid currentColor;
  transform: rotate(18deg) skew(-10deg);
}

.patient-hospital-specialties {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  margin: 16px 0 0;
  padding: 14px 0;
  border-radius: 18px;
  background: linear-gradient(90deg, #edf9f8 0%, #edf6ff 100%);
}

.patient-hospital-specialties > div {
  display: grid;
  justify-items: center;
  gap: 9px;
  min-width: 0;
  padding: 0 8px;
  text-align: center;
}

.patient-hospital-specialties > div + div {
  border-left: 1px solid #c8e3e8;
}

.patient-hospital-specialties strong {
  color: #24445f;
  font-size: 0.8125rem;
  line-height: 1.35;
}

.patient-hospital-specialties__icon,
.patient-hospital-preparation__icon {
  position: relative;
  display: inline-block;
  width: 34px;
  height: 34px;
  color: var(--patient-teal);
}

.patient-hospital-specialties__icon::before,
.patient-hospital-specialties__icon::after,
.patient-hospital-preparation__icon::before,
.patient-hospital-preparation__icon::after {
  position: absolute;
  content: '';
}

.patient-hospital-specialties__icon.is-headache {
  border: 3px solid currentColor;
  border-radius: 50% 50% 45% 45%;
}

.patient-hospital-specialties__icon.is-headache::after {
  left: 14px;
  top: -7px;
  width: 6px;
  height: 16px;
  border-radius: 3px;
  background: currentColor;
  transform: rotate(25deg);
}

.patient-hospital-specialties__icon.is-vessel::before {
  left: 14px;
  top: 1px;
  width: 5px;
  height: 32px;
  border-radius: 5px;
  background: currentColor;
  transform: rotate(25deg);
}

.patient-hospital-specialties__icon.is-vessel::after {
  left: 6px;
  top: 15px;
  width: 22px;
  height: 5px;
  border-radius: 5px;
  background: currentColor;
  transform: rotate(-25deg);
}

.patient-hospital-specialties__icon.is-brain {
  border: 3px solid currentColor;
  border-radius: 48% 52% 45% 55%;
}

.patient-hospital-specialties__icon.is-brain::before {
  left: 14px;
  top: 5px;
  width: 3px;
  height: 21px;
  background: currentColor;
}

.patient-hospital-guide {
  padding: 18px;
  border-radius: 18px;
  background: #f3f9ff;
}

.patient-hospital-guide ol {
  display: grid;
  gap: 12px;
  margin: 18px 0 0;
  padding: 0;
  list-style: none;
}

.patient-hospital-guide li {
  display: grid;
  grid-template-columns: 24px minmax(0, 1fr);
  gap: 10px;
  color: #3b5d7b;
  font-size: 0.875rem;
  line-height: 1.55;
}

.patient-hospital-guide li span {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: var(--patient-primary);
  color: #ffffff;
  font-size: 0.75rem;
  font-weight: 800;
}

.patient-hospital-arrival {
  position: relative;
  padding-top: 2px;
}

.patient-hospital-arrival dl {
  margin: 12px 0 0;
  border-top: 1px solid var(--patient-border);
}

.patient-hospital-arrival dl > div {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  min-height: 58px;
  border-bottom: 1px solid var(--patient-border);
}

.patient-hospital-arrival dt {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #31506d;
  font-size: 0.9375rem;
  font-weight: 700;
}

.patient-hospital-arrival dt .patient-hospital-line-icon {
  width: 23px;
  height: 23px;
}

.patient-hospital-arrival dd {
  margin: 0;
  color: var(--patient-text);
  font-size: 0.875rem;
  font-variant-numeric: tabular-nums;
  text-align: right;
}

.patient-hospital-map {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-height: 42px;
  margin-top: 15px;
  padding: 0 13px;
  border: 1px solid var(--patient-teal);
  border-radius: 10px;
  background: #ffffff;
  color: #078b86;
  font: inherit;
  font-size: 0.875rem;
  font-weight: 800;
  cursor: pointer;
}

.patient-hospital-map .patient-hospital-line-icon {
  width: 21px;
  height: 21px;
}

.patient-hospital-primary-action {
  min-height: 52px;
  border: 0;
  border-radius: 12px;
  background: var(--patient-primary);
  box-shadow: 0 12px 24px rgba(8, 124, 240, 0.2);
  color: #ffffff;
  font: inherit;
  font-size: 1rem;
  font-weight: 800;
  cursor: pointer;
  transition: background 180ms ease-out, transform 180ms ease-out;
}

.patient-hospital-primary-action:hover {
  background: var(--patient-primary-strong);
}

.patient-hospital-primary-action:active {
  transform: translateY(1px);
}

.patient-hospital-preparation {
  padding: 18px;
  border-radius: 18px;
  background: #f1f8ff;
}

.patient-hospital-preparation > div {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  margin-top: 17px;
}

.patient-hospital-preparation article {
  display: grid;
  justify-items: center;
  gap: 8px;
  min-width: 0;
  padding: 0 8px;
  text-align: center;
}

.patient-hospital-preparation article + article {
  border-left: 1px solid #c9dde9;
}

.patient-hospital-preparation__icon {
  color: var(--patient-primary);
}

.patient-hospital-preparation__icon.is-identity {
  border: 3px solid currentColor;
  border-radius: 6px;
}

.patient-hospital-preparation__icon.is-identity::before {
  left: 7px;
  top: 7px;
  width: 7px;
  height: 7px;
  border: 2px solid currentColor;
  border-radius: 50%;
  box-shadow: 14px 1px 0 -1px currentColor, 14px 8px 0 -1px currentColor;
}

.patient-hospital-preparation__icon.is-identity::after {
  left: 5px;
  bottom: 5px;
  width: 13px;
  height: 6px;
  border: 2px solid currentColor;
  border-radius: 8px 8px 2px 2px;
}

.patient-hospital-preparation__icon.is-insurance {
  border: 3px solid var(--patient-teal);
  border-radius: 6px;
  color: var(--patient-teal);
}

.patient-hospital-preparation__icon.is-insurance::before {
  left: 5px;
  right: 5px;
  top: 10px;
  height: 3px;
  background: currentColor;
  box-shadow: 0 7px currentColor;
}

.patient-hospital-preparation__icon.is-insurance::after {
  right: -5px;
  bottom: -5px;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--patient-teal);
  box-shadow: inset 0 0 0 4px #f1f8ff;
}

.patient-hospital-preparation__icon.is-records {
  border: 3px solid currentColor;
  border-radius: 4px 6px 4px 4px;
  box-shadow: 6px -6px 0 -2px #f1f8ff, 6px -6px 0 1px currentColor;
}

.patient-hospital-preparation__icon.is-records::before {
  left: 6px;
  right: 5px;
  top: 9px;
  height: 3px;
  background: currentColor;
  box-shadow: 0 7px currentColor;
}

.patient-hospital-preparation strong {
  color: #24435d;
  font-size: 0.875rem;
  line-height: 1.3;
}

.patient-hospital-preparation p {
  margin: 0;
  color: #5e7890;
  font-size: 0.6875rem;
  line-height: 1.45;
}

@media (max-width: 390px) {
  .patient-hospital-hero {
    min-height: 258px;
    padding-top: 40px;
  }

  .patient-hospital-hero h2 {
    font-size: 1.75rem;
  }

  .patient-hospital-building {
    right: -40px;
    transform: scale(0.88);
    transform-origin: bottom right;
  }

  .patient-hospital-section__heading p {
    font-size: 0.875rem;
  }

  .patient-hospital-specialties strong,
  .patient-hospital-preparation strong {
    font-size: 0.75rem;
  }

  .patient-hospital-preparation {
    padding: 16px 12px;
  }

  .patient-hospital-preparation article {
    padding: 0 5px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .patient-hospital-primary-action {
    transition: none;
  }
}
</style>
