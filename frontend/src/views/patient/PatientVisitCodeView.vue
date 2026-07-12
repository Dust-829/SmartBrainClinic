<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const session = usePatientSessionStore()

const patientName = computed(() => session.patient?.real_name || '当前患者')
const caseNumber = computed(() => session.patient?.case_number || '--')
</script>

<template>
  <div class="patient-visit-code-shell">
    <header class="patient-visit-code-header">
      <button type="button" aria-label="返回个人中心" @click="router.push('/patient/profile')">‹</button>
      <h1>就诊码</h1>
      <span aria-hidden="true"></span>
    </header>

    <main class="patient-visit-code-content">
      <section class="patient-visit-code-card" aria-labelledby="visit-code-title">
        <div class="patient-visit-code-card__title">
          <span aria-hidden="true"></span>
          <div>
            <p>智慧云脑诊疗平台</p>
            <h2 id="visit-code-title">患者就诊码</h2>
          </div>
        </div>

        <div class="patient-visit-code-qr" role="img" aria-label="演示用就诊二维码，不支持实际扫码核验">
          <svg viewBox="0 0 210 210" aria-hidden="true">
            <rect width="210" height="210" fill="#fff" />
            <g fill="#123057">
              <path d="M8 8h56v56H8zm8 8v40h40V16zM24 24h24v24H24zM146 8h56v56h-56zm8 8v40h40V16zM162 24h24v24h-24zM8 146h56v56H8zm8 8v40h40v-40zM24 162h24v24H24z" />
              <path d="M80 8h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm8 8h8v8h-8zM72 24h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zm16 0h8v8h-8zM80 40h8v8h-8zm16 0h8v8h-8zm8 8h8v8h-8zm16 0h8v8h-8zM72 56h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zm16 0h8v8h-8zM80 72h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zM8 80h8v8H8zm16 0h8v8h-8zm32 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zM8 96h8v8H8zm24 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm8 8h8v8h-8zm16-8h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zM8 112h8v8H8zm16 0h8v8h-8zm16 0h8v8h-8zm32 0h8v8h-8zm16 0h8v8h-8zm8 8h8v8h-8zm24-8h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zM8 128h8v8H8zm24 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zm8 8h8v8h-8zm16-8h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zM72 146h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zM72 162h8v8h-8zm16 0h8v8h-8zm8 8h8v8h-8zm16-8h8v8h-8zm24 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zM72 178h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zm16 0h8v8h-8zM72 194h8v8h-8zm16 0h8v8h-8zm24 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8zm16 0h8v8h-8z" />
            </g>
          </svg>
        </div>

        <p class="patient-visit-code-card__hint">请向导诊台或诊室工作人员出示</p>

        <dl class="patient-visit-code-info">
          <div>
            <dt>就诊人</dt>
            <dd>{{ patientName }} <em>本人</em></dd>
          </div>
          <div>
            <dt>门诊号</dt>
            <dd>{{ caseNumber }}</dd>
          </div>
        </dl>
      </section>

      <aside class="patient-visit-code-notice">
        <span aria-hidden="true">i</span>
        <p>演示用就诊码，仅用于展示患者端就医流程，不支持实际扫码核验。</p>
      </aside>
    </main>

    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-visit-code-shell {
  min-height: 100vh;
  padding-bottom: calc(var(--patient-nav-height) + 28px);
  background:
    radial-gradient(circle at 84% 4%, rgba(101, 184, 255, 0.28), transparent 28%),
    linear-gradient(180deg, #eaf5ff 0%, #f7fbff 45%, #fff 100%);
  color: var(--patient-text);
}

.patient-visit-code-header {
  display: grid;
  grid-template-columns: 44px 1fr 44px;
  align-items: center;
  min-height: 104px;
  padding: 28px var(--patient-page-gutter) 12px;
}

.patient-visit-code-header button {
  width: 38px;
  height: 38px;
  border: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.82);
  color: var(--patient-primary);
  font-size: 36px;
  line-height: 28px;
  cursor: pointer;
}

.patient-visit-code-header h1 {
  margin: 0;
  font-size: 23px;
  text-align: center;
}

.patient-visit-code-content {
  display: grid;
  gap: 18px;
  padding: 20px var(--patient-page-gutter);
}

.patient-visit-code-card {
  overflow: hidden;
  border: 1px solid rgba(214, 228, 244, 0.92);
  border-radius: 24px;
  background: rgba(255, 255, 255, 0.96);
  box-shadow: 0 20px 46px rgba(35, 100, 165, 0.14);
}

.patient-visit-code-card__title {
  display: flex;
  align-items: center;
  gap: 13px;
  padding: 22px 22px 18px;
  color: #fff;
  background: linear-gradient(135deg, #087df6 0%, #36a6ff 100%);
}

.patient-visit-code-card__title > span {
  position: relative;
  width: 43px;
  height: 43px;
  border: 3px solid #fff;
  border-radius: 12px;
}

.patient-visit-code-card__title > span::before,
.patient-visit-code-card__title > span::after {
  position: absolute;
  left: 50%;
  top: 50%;
  background: #fff;
  content: '';
  transform: translate(-50%, -50%);
}

.patient-visit-code-card__title > span::before { width: 23px; height: 5px; border-radius: 4px; }
.patient-visit-code-card__title > span::after { width: 5px; height: 23px; border-radius: 4px; }

.patient-visit-code-card__title p,
.patient-visit-code-card__title h2 { margin: 0; }
.patient-visit-code-card__title p { font-size: 12px; font-weight: 700; opacity: 0.86; }
.patient-visit-code-card__title h2 { margin-top: 3px; font-size: 21px; }

.patient-visit-code-qr {
  width: min(100%, 270px);
  margin: 28px auto 16px;
  padding: 14px;
  border: 1px solid #deebf8;
  border-radius: 16px;
  background: #fff;
}

.patient-visit-code-qr svg { display: block; width: 100%; height: auto; }

.patient-visit-code-card__hint {
  margin: 0;
  color: var(--patient-text-muted);
  font-size: 14px;
  text-align: center;
}

.patient-visit-code-info {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin: 23px 22px 22px;
  padding-top: 18px;
  border-top: 1px dashed #d7e4f1;
}

.patient-visit-code-info div { min-width: 0; }
.patient-visit-code-info dt { color: var(--patient-text-muted); font-size: 12px; }
.patient-visit-code-info dd { margin: 7px 0 0; overflow-wrap: anywhere; font-size: 16px; font-weight: 800; }
.patient-visit-code-info em { margin-left: 4px; padding: 2px 7px; border-radius: 999px; background: var(--patient-primary-soft); color: var(--patient-primary); font-size: 11px; font-style: normal; }

.patient-visit-code-notice {
  display: grid;
  grid-template-columns: 24px minmax(0, 1fr);
  gap: 10px;
  padding: 14px;
  border-radius: 14px;
  background: #fff8e8;
  color: #8a5a13;
}

.patient-visit-code-notice span { display: grid; place-items: center; width: 20px; height: 20px; border: 2px solid currentColor; border-radius: 50%; font-size: 12px; font-weight: 800; }
.patient-visit-code-notice p { margin: 0; font-size: 13px; line-height: 1.6; }

@media (min-width: 720px) {
  .patient-visit-code-shell { max-width: var(--patient-page-width); margin: 0 auto; box-shadow: var(--patient-page-shadow); }
}
</style>
