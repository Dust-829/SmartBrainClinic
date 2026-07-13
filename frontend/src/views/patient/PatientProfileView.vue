<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import { usePatientFlowStore } from '@/stores/patientFlow'
import { usePatientRegisterHistoryStore } from '@/stores/patientRegisterHistory'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const flow = usePatientFlowStore()
const session = usePatientSessionStore()
const historyStore = usePatientRegisterHistoryStore()
const historyLoading = ref(false)

const patient = computed(() => session.patient)
const isLoggedIn = computed(() => Boolean(patient.value))
const patientDisplayName = computed(() => patient.value?.real_name || '\u5c1a\u672a\u767b\u5f55')
const history = computed(() => historyStore.records)
const maskedCardNumber = computed(() => {
  const value = patient.value?.card_number || ''
  if (!value) return '--'
  if (value.length <= 7) return value
  return `${value.slice(0, 3)}${'*'.repeat(value.length - 7)}${value.slice(-4)}`
})
const recentHistory = computed(() => history.value.slice(0, 3))

function displayText(value: string | null | undefined, fallback: string) {
  return value || fallback
}

onMounted(loadHistory)

async function loadHistory() {
  if (!patient.value?.uuid) return
  historyLoading.value = true
  try {
    await historyStore.fetchHistory()
  } finally {
    historyLoading.value = false
  }
}

function startRegistration() {
  if (!isLoggedIn.value) {
    router.push('/patient/login')
    return
  }
  router.push('/patient/departments')
}

function openQueue() {
  if (!isLoggedIn.value) {
    router.push('/patient/login')
    return
  }
  if (!flow.canViewQueue) {
    ElMessage.info('\u6682\u65e0\u6b63\u5728\u5019\u8bca\u7684\u6302\u53f7')
    return
  }
  router.push('/patient/queue')
}

function openVisitCode() {
  if (!isLoggedIn.value) {
    router.push('/patient/login')
    return
  }
  router.push('/patient/visit-code')
}

async function logout() {
  try {
    await ElMessageBox.confirm(
      '\u9000\u51fa\u540e\u9700\u8981\u91cd\u65b0\u8f93\u5165\u59d3\u540d\u548c\u8eab\u4efd\u8bc1\u53f7\u767b\u5f55\u3002',
      '\u786e\u8ba4\u9000\u51fa\u767b\u5f55\uff1f',
      {
        confirmButtonText: '\u9000\u51fa\u767b\u5f55',
        cancelButtonText: '\u53d6\u6d88',
        type: 'warning',
      },
    )
    flow.resetAll()
    router.replace('/patient/home')
  } catch {
    // User cancelled.
  }
}
</script>

<template>
  <div class="patient-profile-shell">
    <header class="patient-profile-hero">
      <h1>&#20010;&#20154;&#20013;&#24515;</h1>
      <div class="patient-profile-identity">
        <span class="patient-profile-avatar" aria-hidden="true"></span>
        <div>
          <p>
            <strong>{{ patientDisplayName }}</strong>
            <em v-if="patient">&#26412;&#20154;</em>
          </p>
          <span>{{ maskedCardNumber }}</span>
        </div>
      </div>
    </header>

    <main class="patient-profile-content">
      <section class="patient-profile-info" aria-label="&#24739;&#32773;&#26723;&#26696;">
        <div>
          <span>&#38376;&#35786;&#21495;</span>
          <strong>{{ patient?.case_number || '--' }}</strong>
        </div>
        <div>
          <span>&#24615;&#21035;</span>
          <strong>{{ patient?.gender || '--' }}</strong>
        </div>
        <div>
          <span>&#20986;&#29983;&#26085;&#26399;</span>
          <strong>{{ patient?.birthdate || '--' }}</strong>
        </div>
      </section>

      <section v-if="!isLoggedIn" class="patient-profile-login">
        <h2>&#30331;&#24405;&#21518;&#26597;&#30475;&#20010;&#20154;&#26723;&#26696;</h2>
        <p>&#20351;&#29992;&#24050;&#24314;&#26723;&#22995;&#21517;&#21644;&#36523;&#20221;&#35777;&#21495;&#30331;&#24405;&#12290;</p>
        <button type="button" @click="router.push('/patient/login')">&#21435;&#30331;&#24405;</button>
      </section>

      <section class="patient-profile-actions" aria-label="&#24120;&#29992;&#26381;&#21153;">
        <button type="button" @click="startRegistration">
          <span class="is-register" aria-hidden="true"></span>
          <strong>&#22312;&#32447;&#25346;&#21495;</strong>
        </button>
        <button type="button" @click="openQueue">
          <span class="is-queue" aria-hidden="true"></span>
          <strong>&#20505;&#35786;&#29366;&#24577;</strong>
        </button>
        <button type="button" @click="router.push('/patient/registers')">
          <span class="is-record" aria-hidden="true"></span>
          <strong>&#25346;&#21495;&#35760;&#24405;</strong>
        </button>
        <button type="button" @click="openVisitCode">
          <span class="is-code" aria-hidden="true"></span>
          <strong>&#23601;&#35786;&#30721;</strong>
        </button>
      </section>

      <section id="records" class="patient-profile-records">
        <div class="patient-profile-section-title">
          <h2>&#26368;&#36817;&#25346;&#21495;</h2>
          <span v-if="history.length">&#20849; {{ history.length }} &#26465;</span>
        </div>

        <el-skeleton :loading="historyLoading && !history.length" animated :rows="2">
          <template #default>
            <div v-if="recentHistory.length" class="patient-profile-record-list">
              <article v-for="item in recentHistory" :key="item.uuid">
                <div>
                  <strong>{{ displayText(item.dept_name, '\u672a\u77e5\u79d1\u5ba4') }}</strong>
                  <span>{{ displayText(item.visit_state_str, '\u72b6\u6001\u5f85\u786e\u8ba4') }}</span>
                </div>
                <p>{{ displayText(item.employee_name, '\u672a\u5206\u914d\u533b\u751f') }}</p>
                <small>{{ item.actual_schedule_date || item.visit_date || '--' }} {{ item.actual_time_range || item.noon || '' }}</small>
              </article>
            </div>
            <div v-else class="patient-profile-empty">
              <span aria-hidden="true"></span>
              <strong>&#26242;&#26080;&#25346;&#21495;&#35760;&#24405;</strong>
              <button type="button" @click="startRegistration">&#21435;&#25346;&#21495;</button>
            </div>
          </template>
        </el-skeleton>
      </section>

      <section v-if="isLoggedIn" class="patient-profile-account">
        <button type="button" @click="logout">
          <span aria-hidden="true"></span>
          <strong>&#36864;&#20986;&#30331;&#24405;</strong>
          <i aria-hidden="true">&#8250;</i>
        </button>
      </section>
    </main>

    <PatientBottomNav />

  </div>
</template>

<style scoped>
.patient-profile-shell {
  min-height: 100vh;
  padding-bottom: calc(var(--patient-nav-height) + 24px);
  overflow: hidden;
  background: var(--patient-page-bg);
  color: var(--patient-text);
}

.patient-profile-hero {
  min-height: 300px;
  padding: 58px var(--patient-page-gutter) 82px;
  color: #ffffff;
  background: var(--patient-header-gradient);
}

.patient-profile-hero h1 {
  margin: 0;
  font-size: 30px;
  line-height: 1.2;
  letter-spacing: 0;
  text-align: center;
}

.patient-profile-identity {
  display: flex;
  align-items: center;
  gap: 18px;
  margin-top: 50px;
}

.patient-profile-avatar {
  position: relative;
  flex: 0 0 72px;
  width: 72px;
  height: 72px;
  border: 4px solid rgba(255, 255, 255, 0.88);
  border-radius: 50%;
}

.patient-profile-avatar::before,
.patient-profile-avatar::after {
  position: absolute;
  left: 50%;
  background: #ffffff;
  transform: translateX(-50%);
  content: '';
}

.patient-profile-avatar::before {
  top: 14px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
}

.patient-profile-avatar::after {
  bottom: 12px;
  width: 40px;
  height: 22px;
  border-radius: 20px 20px 8px 8px;
}

.patient-profile-identity p {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0 0 8px;
}

.patient-profile-identity strong {
  font-size: 28px;
}

.patient-profile-identity em {
  padding: 3px 10px;
  border-radius: 13px;
  background: rgba(255, 255, 255, 0.18);
  font-size: 13px;
  font-style: normal;
  font-weight: 700;
}

.patient-profile-identity > div > span {
  color: rgba(255, 255, 255, 0.9);
  font-size: 15px;
}

.patient-profile-content {
  display: grid;
  gap: 14px;
  margin-top: -58px;
  padding: 0 var(--patient-page-gutter);
}

.patient-profile-info,
.patient-profile-actions,
.patient-profile-records,
.patient-profile-account,
.patient-profile-login {
  border: 1px solid var(--patient-border);
  border-radius: var(--patient-radius);
  background: var(--patient-surface);
  box-shadow: var(--patient-shadow);
}

.patient-profile-info {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  min-height: 116px;
  padding: 20px 8px;
}

.patient-profile-info div {
  display: grid;
  align-content: center;
  gap: 8px;
  min-width: 0;
  padding: 0 8px;
  text-align: center;
}

.patient-profile-info div + div {
  border-left: 1px solid var(--patient-border);
}

.patient-profile-info span {
  color: var(--patient-text-muted);
  font-size: 13px;
}

.patient-profile-info strong {
  overflow-wrap: anywhere;
  font-size: 16px;
}

.patient-profile-login {
  padding: 20px;
}

.patient-profile-login h2,
.patient-profile-login p {
  margin: 0;
}

.patient-profile-login h2 {
  font-size: 17px;
}

.patient-profile-login p {
  margin-top: 6px;
  color: var(--patient-text-muted);
  font-size: 13px;
}

.patient-profile-login button,
.patient-profile-empty button {
  min-height: var(--patient-control-height);
  margin-top: 16px;
  padding: 0 22px;
  border: 0;
  border-radius: var(--patient-radius);
  background: var(--patient-primary);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

.patient-profile-actions {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  padding: 12px;
}

.patient-profile-actions button {
  display: grid;
  place-items: center;
  align-content: center;
  gap: 10px;
  min-height: 124px;
  border: 0;
  background: transparent;
  color: var(--patient-text);
  font: inherit;
  cursor: pointer;
}

.patient-profile-actions button:nth-child(odd) {
  border-right: 1px solid var(--patient-border);
}

.patient-profile-actions button:nth-child(-n + 2) {
  border-bottom: 1px solid var(--patient-border);
}

.patient-profile-actions button:focus-visible,
.patient-profile-account button:focus-visible {
  outline: 2px solid var(--patient-primary);
  outline-offset: -2px;
}

.patient-profile-actions button > span {
  position: relative;
  width: 46px;
  height: 46px;
  border-radius: 50%;
  background: var(--patient-primary-soft);
}

.patient-profile-actions button:nth-child(even) > span {
  background: var(--patient-teal-soft);
}

.patient-profile-actions button > span::before {
  position: absolute;
  inset: 11px;
  border: 3px solid var(--patient-primary);
  border-radius: 5px;
  content: '';
}

.patient-profile-actions button:nth-child(even) > span::before {
  border-color: var(--patient-teal);
}

.patient-profile-actions .is-queue::before {
  border-radius: 50%;
}

.patient-profile-actions .is-queue::after {
  position: absolute;
  left: 22px;
  top: 14px;
  width: 3px;
  height: 13px;
  border-radius: 2px;
  background: var(--patient-teal);
  transform-origin: bottom;
  transform: rotate(-20deg);
  content: '';
}

.patient-profile-actions .is-code::before {
  border-style: dashed;
}

.patient-profile-actions .is-record::after,
.patient-profile-actions .is-register::after {
  position: absolute;
  left: 18px;
  top: 21px;
  width: 12px;
  height: 3px;
  background: var(--patient-primary);
  box-shadow: 0 6px var(--patient-primary);
  content: '';
}

.patient-profile-actions strong {
  font-size: 16px;
}

.patient-profile-records {
  padding: 20px;
  scroll-margin-top: 12px;
}

.patient-profile-section-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.patient-profile-section-title h2 {
  margin: 0;
  font-size: 19px;
}

.patient-profile-section-title span {
  color: var(--patient-text-muted);
  font-size: 13px;
}

.patient-profile-record-list {
  display: grid;
  gap: 10px;
  margin-top: 16px;
}

.patient-profile-record-list article {
  padding: 13px 14px;
  border-radius: var(--patient-radius);
  background: var(--patient-surface-muted);
}

.patient-profile-record-list article div {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.patient-profile-record-list article div span {
  color: var(--patient-primary);
  font-size: 13px;
}

.patient-profile-record-list p,
.patient-profile-record-list small {
  display: block;
  margin: 5px 0 0;
  color: var(--patient-text-muted);
  font-size: 13px;
}

.patient-profile-empty {
  display: grid;
  justify-items: center;
  padding: 30px 10px 12px;
  color: var(--patient-text-muted);
}

.patient-profile-empty > span {
  position: relative;
  width: 58px;
  height: 66px;
  margin-bottom: 14px;
  border: 3px solid #bdd6f5;
  border-radius: var(--patient-radius);
}

.patient-profile-empty > span::before {
  position: absolute;
  left: 12px;
  top: 17px;
  width: 28px;
  height: 3px;
  background: #bdd6f5;
  box-shadow: 0 10px #bdd6f5, 0 20px #bdd6f5;
  content: '';
}

.patient-profile-account button {
  display: grid;
  grid-template-columns: 28px minmax(0, 1fr) 18px;
  align-items: center;
  gap: 10px;
  width: 100%;
  min-height: 62px;
  padding: 0 18px;
  border: 0;
  background: transparent;
  color: var(--patient-text);
  font: inherit;
  text-align: left;
  cursor: pointer;
}

.patient-profile-account button > span {
  position: relative;
  width: 22px;
  height: 22px;
  border: 2px solid var(--patient-primary);
  border-radius: 4px;
}

.patient-profile-account button > span::after {
  position: absolute;
  right: -7px;
  top: 8px;
  width: 12px;
  height: 2px;
  background: var(--patient-primary);
  content: '';
}

.patient-profile-account i {
  color: var(--patient-text-muted);
  font-size: 26px;
  font-style: normal;
}

</style>
