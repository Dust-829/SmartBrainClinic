Exit code: 0
Wall time: 0.3 seconds
Output:
<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'

import type { RegisterDetail } from '@/api/patient'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import { usePatientRegisterHistoryStore } from '@/stores/patientRegisterHistory'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const session = usePatientSessionStore()
const historyStore = usePatientRegisterHistoryStore()

const patient = computed(() => session.patient)
const isLoggedIn = computed(() => Boolean(patient.value?.uuid))
const records = computed(() => historyStore.records)
const loading = computed(() => historyStore.loading && !historyStore.records.length)
const errorMessage = computed(() => (historyStore.records.length ? '' : historyStore.errorMessage))
const recordCountText = computed(() => (records.value.length ? `共 ${records.value.length} 条` : ''))

function field(value: string | null | undefined, fallback = '待确认') {
  return value && value.trim() ? value : fallback
}

function visitTime(record: RegisterDetail) {
  const date = record.actual_schedule_date || record.visit_date
  const range = record.actual_time_range || record.noon
  if (!date && !range) return '就诊时间待确认'
  return [date, range].filter(Boolean).join(' ')
}

function feeText(value: number | undefined) {
  if (value === undefined || value === null) return '费用待确认'
  return `${value} 元`
}

async function loadRecords(force = false) {
  await historyStore.fetchHistory({ force })
}

function goLogin() {
  router.push('/patient/login')
}

function goRegister() {
  router.push('/patient/register')
}

function goDepartments() {
  router.push('/patient/departments')
}

onMounted(() => {
  void loadRecords()
})

watch(
  () => patient.value?.uuid,
  () => {
    void loadRecords()
  },
)
</script>

<template>
  <div class="patient-register-history-shell">
    <header class="patient-register-history-hero">
      <h1>挂号记录</h1>
      <p>{{ isLoggedIn ? '查看当前患者的线上挂号与候诊信息' : '登录后查看个人挂号历史' }}</p>
    </header>

    <main class="patient-register-history-content">
      <section v-if="!isLoggedIn" class="patient-register-history-login">
        <span class="patient-register-history-login__icon" aria-hidden="true"></span>
        <h2>请先登录后查看挂号记录</h2>
        <p>登录后可查看线上挂号、缴费状态、候诊进度和历史就诊安排。</p>
        <div>
          <button type="button" class="is-primary" @click="goLogin">去登录</button>
          <button type="button" @click="goRegister">注册</button>
        </div>
      </section>

      <template v-else>
        <section class="patient-register-history-profile">
          <span class="patient-register-history-avatar" aria-hidden="true"></span>
          <div>
            <strong>{{ field(patient?.real_name, '当前患者') }}</strong>
            <p>门诊号：{{ field(patient?.case_number, '暂未建档') }}</p>
          </div>
        </section>

        <section class="patient-register-history-panel">
          <div class="patient-register-history-title">
            <div>
              <h2>全部挂号记录</h2>
            </div>
            <span v-if="recordCountText">{{ recordCountText }}</span>
          </div>

          <el-skeleton :loading="loading" animated :rows="6">
            <template #default>
              <div v-if="errorMessage" class="patient-register-history-empty is-error">
                <strong>{{ errorMessage }}</strong>
                <button type="button" @click="loadRecords(true)">重新加载</button>
              </div>

              <div v-else-if="records.length" class="patient-register-history-list">
                <article v-for="record in records" :key="record.uuid">
                  <div class="patient-register-history-card-head">
                    <div>
                      <strong>{{ field(record.dept_name, '科室待确认') }}</strong>
                      <p>{{ field(record.employee_name, '医生待确认') }}</p>
                    </div>
                    <span>{{ field(record.visit_state_str, '状态待确认') }}</span>
                  </div>

                  <dl>
                    <div>
                      <dt>就诊时间</dt>
                      <dd>{{ visitTime(record) }}</dd>
                    </div>
                    <div>
                      <dt>挂号费用</dt>
                      <dd>{{ feeText(record.regist_money) }}</dd>
                    </div>
                    <div>
                      <dt>诊室</dt>
                      <dd>{{ field(record.clinic_room_name) }}</dd>
                    </div>
                  </dl>

                  <p v-if="record.symptoms" class="patient-register-history-symptom">
                    症状：{{ record.symptoms }}
                  </p>
                </article>
              </div>

              <div v-else class="patient-register-history-empty">
                <span aria-hidden="true"></span>
                <strong>暂无挂号记录</strong>
                <p>完成线上挂号后，记录会显示在这里。</p>
                <button type="button" @click="goDepartments">去按科室挂号</button>
              </div>
            </template>
          </el-skeleton>
        </section>
      </template>
    </main>

    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-register-history-shell {
  min-height: 100vh;
  padding-bottom: calc(var(--patient-nav-height) + 24px);
  background:
    radial-gradient(circle at 88% 4%, rgba(78, 167, 255, 0.22), transparent 30%),
    linear-gradient(180deg, #eaf4ff 0%, #f7fbff 42%, #f8fbff 100%);
}

.patient-register-history-hero {
  min-height: 230px;
  padding: 42px var(--patient-page-gutter) 76px;
  background: linear-gradient(135deg, #087df6 0%, #35a7ff 100%);
  color: #fff;
}

.patient-register-history-hero h1 {
  margin: 0 0 8px;
  font-size: 30px;
  line-height: 1.2;
  text-wrap: balance;
}

.patient-register-history-hero p {
  max-width: 28em;
  margin: 0;
  color: rgba(255, 255, 255, 0.9);
  font-size: 16px;
  line-height: 1.7;
}

.patient-register-history-content {
  display: grid;
  gap: 14px;
  margin-top: -50px;
  padding: 0 var(--patient-page-gutter);
}

.patient-register-history-login,
.patient-register-history-profile,
.patient-register-history-panel {
  border: 1px solid var(--patient-border);
  border-radius: var(--patient-radius);
  background: rgba(255, 255, 255, 0.96);
  box-shadow: 0 14px 36px rgba(54, 121, 190, 0.12);
}

.patient-register-history-login {
  display: grid;
  justify-items: center;
  gap: 12px;
  padding: 34px 22px 24px;
  text-align: center;
}

.patient-register-history-login__icon,
.patient-register-history-empty > span {
  position: relative;
  width: 62px;
  height: 62px;
  border-radius: 50%;
  background: var(--patient-blue-soft);
}

.patient-register-history-login__icon::before,
.patient-register-history-login__icon::after,
.patient-register-history-empty > span::before,
.patient-register-history-empty > span::after {
  position: absolute;
  left: 50%;
  background: var(--patient-primary);
  transform: translateX(-50%);
  content: '';
}

.patient-register-history-login__icon::before,
.patient-register-history-empty > span::before {
  top: 15px;
  width: 17px;
  height: 17px;
  border-radius: 50%;
}

.patient-register-history-login__icon::after,
.patient-register-history-empty > span::after {
  bottom: 13px;
  width: 34px;
  height: 17px;
  border-radius: 18px 18px 8px 8px;
}

.patient-register-history-login h2,
.patient-register-history-login p,
.patient-register-history-empty strong,
.patient-register-history-empty p {
  margin: 0;
}

.patient-register-history-login h2 {
  font-size: 20px;
}

.patient-register-history-login p,
.patient-register-history-empty p,
.patient-register-history-card-head p,
.patient-register-history-symptom {
  color: var(--patient-text-muted);
  line-height: 1.65;
}

.patient-register-history-login div {
  display: grid;
  width: 100%;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-top: 8px;
}

.patient-register-history-login button,
.patient-register-history-empty button {
  min-height: var(--patient-control-height);
  border: 1px solid var(--patient-border);
  border-radius: 10px;
  background: #fff;
  color: var(--patient-text);
  font: inherit;
  font-weight: 700;
}

.patient-register-history-login button.is-primary,
.patient-register-history-empty button {
  border-color: transparent;
  background: var(--patient-primary);
  color: #fff;
}

.patient-register-history-profile {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px;
}

.patient-register-history-avatar {
  position: relative;
  flex: 0 0 58px;
  width: 58px;
  height: 58px;
  border-radius: 50%;
  background: linear-gradient(135deg, #4d8fff, #77a5ff);
}

.patient-register-history-avatar::before,
.patient-register-history-avatar::after {
  position: absolute;
  left: 50%;
  background: #fff;
  transform: translateX(-50%);
  content: '';
}

.patient-register-history-avatar::before {
  top: 12px;
  width: 17px;
  height: 17px;
  border-radius: 50%;
}

.patient-register-history-avatar::after {
  bottom: 11px;
  width: 34px;
  height: 17px;
  border-radius: 17px 17px 8px 8px;
}

.patient-register-history-profile strong {
  font-size: 22px;
}

.patient-register-history-profile p {
  margin: 5px 0 0;
  color: var(--patient-text-muted);
}

.patient-register-history-panel {
  padding: 20px;
}

.patient-register-history-title {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.patient-register-history-title h2 {
  margin: 0;
  font-size: 20px;
}

.patient-register-history-title > span,
.patient-register-history-card-head > span {
  flex: 0 0 auto;
  border-radius: 999px;
  background: var(--patient-blue-soft);
  color: var(--patient-primary);
  font-size: 13px;
  font-weight: 800;
}

.patient-register-history-title > span {
  padding: 5px 10px;
}

.patient-register-history-list {
  display: grid;
  gap: 12px;
}

.patient-register-history-list article {
  padding: 16px;
  border: 1px solid rgba(212, 226, 241, 0.9);
  border-radius: 14px;
  background: linear-gradient(180deg, #fff 0%, #f8fbff 100%);
}

.patient-register-history-card-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.patient-register-history-card-head strong {
  font-size: 18px;
}

.patient-register-history-card-head p {
  margin: 4px 0 0;
}

.patient-register-history-card-head > span {
  padding: 4px 9px;
  white-space: nowrap;
}

.patient-register-history-list dl {
  display: grid;
  grid-template-columns: 1fr;
  gap: 10px;
  margin: 14px 0 0;
}

.patient-register-history-list dl div {
  display: grid;
  gap: 3px;
  padding: 10px 12px;
  border-radius: 10px;
  background: #f4f8fd;
}

.patient-register-history-list dt {
  color: var(--patient-text-muted);
  font-size: 12px;
}

.patient-register-history-list dd {
  margin: 0;
  color: var(--patient-text);
  font-weight: 800;
}

.patient-register-history-symptom {
  margin: 12px 0 0;
  padding-top: 12px;
  border-top: 1px solid var(--patient-border);
  font-size: 14px;
}

.patient-register-history-empty {
  display: grid;
  justify-items: center;
  gap: 10px;
  padding: 26px 12px 10px;
  text-align: center;
}

.patient-register-history-empty.is-error {
  padding-top: 18px;
}

.patient-register-history-empty.is-error strong {
  color: #c2410c;
}

.patient-register-history-empty button {
  width: min(100%, 260px);
  margin-top: 6px;
}

@media (min-width: 720px) {
  .patient-register-history-shell {
    max-width: var(--patient-page-width);
    margin: 0 auto;
  }
}
</style>
. : File C:\Users\Twilight\Documents\WindowsPowerShell\profile.ps1 cannot be loaded because running scripts is disabled
 on this system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:3
+ . 'C:\Users\Twilight\Documents\WindowsPowerShell\profile.ps1'
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
