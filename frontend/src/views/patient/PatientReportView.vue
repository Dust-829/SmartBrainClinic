<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { patientApi, type PatientPublishedReport } from '@/api/patient'
import PatientBottomNav from '@/components/patient/PatientBottomNav.vue'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { usePatientSessionStore } from '@/stores/patientSession'

const router = useRouter()
const session = usePatientSessionStore()
const loading = ref(false)
const loadError = ref('')
const reports = ref<PatientPublishedReport[]>([])
const expandedReportUuid = ref('')

const checkCount = computed(() => reports.value.filter((report) => report.report_type === 'check').length)
const inspectionCount = computed(() => reports.value.filter((report) => report.report_type === 'inspection').length)

onMounted(() => {
  if (!session.patient?.uuid) {
    router.replace('/patient/login')
    return
  }
  void loadReports()
})

function getErrorMessage(error: unknown, fallback: string) {
  const detail = (error as { response?: { data?: { detail?: string; message?: string } } })?.response?.data
  return String(detail?.detail || detail?.message || fallback)
}

function formatDate(value?: string | null) {
  if (!value) return '发布时间待确认'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false,
  }).format(date)
}

function reportTypeLabel(type: PatientPublishedReport['report_type']) {
  return type === 'check' ? '检查报告' : '检验报告'
}

function toggleReport(reportUuid: string) {
  expandedReportUuid.value = expandedReportUuid.value === reportUuid ? '' : reportUuid
}

async function loadReports() {
  const patientUuid = session.patient?.uuid
  if (!patientUuid || loading.value) return

  loading.value = true
  loadError.value = ''
  try {
    const response = await patientApi.getPublishedReports(patientUuid)
    reports.value = response.data.data?.reports ?? []
  } catch (error) {
    loadError.value = getErrorMessage(error, '报告加载失败，请稍后重试。')
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push('/patient/home')
}
</script>

<template>
  <div class="patient-report">
    <PatientFlowHeader title="报告查询" subtitle="仅展示医生审核并发布的检查、检验报告" back-label="返回首页" @back="goBack" />

    <main class="patient-report__content">
      <section class="patient-report__summary" aria-live="polite">
        <span class="patient-report__summary-icon" aria-hidden="true"></span>
        <div>
          <strong>已发布报告</strong>
          <p>{{ reports.length ? `共 ${reports.length} 份，可展开查看医生结论与检验结果` : '医生审核并发布后，报告会显示在这里' }}</p>
        </div>
        <button type="button" :disabled="loading" @click="loadReports">{{ loading ? '刷新中' : '刷新' }}</button>
      </section>

      <section class="patient-report__panel" aria-labelledby="patient-report-list-title">
        <div class="patient-report__heading">
          <div>
            <h2 id="patient-report-list-title">我的报告</h2>
            <p>检查 {{ checkCount }} 份 · 检验 {{ inspectionCount }} 份</p>
          </div>
          <span v-if="reports.length">{{ reports.length }} 份</span>
        </div>

        <div v-if="loading && !reports.length" class="patient-report__skeleton" aria-label="正在加载报告"><span v-for="index in 3" :key="index"></span></div>
        <div v-else-if="loadError && !reports.length" class="patient-report__empty is-error">
          <strong>暂时无法读取报告</strong><p>{{ loadError }}</p><button type="button" @click="loadReports">重新加载</button>
        </div>
        <div v-else-if="!reports.length" class="patient-report__empty">
          <span class="patient-report__empty-icon" aria-hidden="true"></span>
          <strong>暂时没有已发布报告</strong>
          <p>检查或检验完成后，需由医生审核发布；发布后的报告会在这里供您查看。</p>
          <button type="button" @click="goBack">返回首页</button>
        </div>
        <div v-else class="patient-report__list">
          <article v-for="report in reports" :key="report.uuid" :class="{ 'is-expanded': expandedReportUuid === report.uuid }">
            <button type="button" class="patient-report__card-head" :aria-expanded="expandedReportUuid === report.uuid" @click="toggleReport(report.uuid)">
              <span class="patient-report__type-icon" :class="`is-${report.report_type}`" aria-hidden="true"></span>
              <span class="patient-report__card-copy"><strong>{{ report.project_name }}</strong><small>{{ reportTypeLabel(report.report_type) }} · {{ formatDate(report.published_at) }}</small></span>
              <span class="patient-report__published">已发布</span><i aria-hidden="true">›</i>
            </button>
            <div v-if="expandedReportUuid === report.uuid" class="patient-report__detail">
              <section><h3>医生结论</h3><p>{{ report.conclusion || '暂无医生结论' }}</p></section>
              <section v-if="report.report_type === 'inspection' && report.structured_result?.length">
                <h3>检验结果</h3>
                <dl>
                  <div v-for="(item, index) in report.structured_result" :key="`${report.uuid}-${index}`"><dt>{{ item.item_name }}</dt><dd><strong>{{ item.value }}{{ item.unit ? ` ${item.unit}` : '' }}</strong><small v-if="item.reference_range">参考范围：{{ item.reference_range }}</small></dd></div>
                </dl>
              </section>
              <footer>报告版本 V{{ report.version }} · 发布于 {{ formatDate(report.published_at) }}</footer>
            </div>
          </article>
        </div>
      </section>
    </main>
    <PatientBottomNav />
  </div>
</template>

<style scoped>
.patient-report { min-height: 100vh; padding-bottom: calc(var(--patient-nav-height) + 24px); background: var(--patient-flow-page-bg); color: var(--patient-text); }
.patient-report__content { display: grid; gap: 14px; margin-top: -22px; padding: 0 var(--patient-page-gutter) 24px; }
.patient-report__summary { display: flex; align-items: center; gap: 11px; padding: 14px; border: 1px solid #d7e8f8; border-radius: 16px; background: #fff; box-shadow: 0 10px 24px rgba(28, 100, 162, .08); }
.patient-report__summary-icon, .patient-report__type-icon, .patient-report__empty-icon { position: relative; flex: 0 0 auto; }
.patient-report__summary-icon { width: 42px; height: 42px; border-radius: 13px; background: #eaf5ff; }
.patient-report__summary-icon::before, .patient-report__summary-icon::after { position: absolute; left: 12px; width: 18px; border: 2px solid #187de9; border-radius: 4px; content: ''; }
.patient-report__summary-icon::before { top: 8px; height: 24px; }
.patient-report__summary-icon::after { top: 16px; height: 0; box-shadow: 0 6px #187de9; }
.patient-report__summary div { min-width: 0; flex: 1; }
.patient-report__summary strong { display: block; color: #18395e; font-size: 16px; }
.patient-report__summary p { margin: 4px 0 0; color: #617f9f; font-size: 12px; line-height: 1.45; }
.patient-report__summary button { min-height: 32px; border: 0; background: transparent; color: #1478df; font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; }
.patient-report__summary button:disabled { cursor: default; opacity: .55; }
.patient-report__panel { min-height: 376px; padding: 18px; border: 1px solid #d7e6f4; border-radius: 18px; background: #fff; box-shadow: 0 10px 25px rgba(28, 100, 162, .06); }
.patient-report__heading { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding-bottom: 15px; border-bottom: 1px solid #e7f0f8; }
.patient-report__heading h2 { margin: 0; color: #18395e; font-size: 19px; }
.patient-report__heading p { margin: 5px 0 0; color: #718aa4; font-size: 12px; }
.patient-report__heading > span { padding: 4px 8px; border-radius: 999px; background: #eaf6ff; color: #1478df; font-size: 12px; font-weight: 800; }
.patient-report__list { display: grid; gap: 10px; padding-top: 14px; }
.patient-report__list article { overflow: hidden; border: 1px solid #dfeaf4; border-radius: 13px; background: #fbfdff; }
.patient-report__list article.is-expanded { border-color: #b8d8f5; background: #fff; }
.patient-report__card-head { display: grid; grid-template-columns: 38px minmax(0, 1fr) auto 14px; align-items: center; gap: 10px; width: 100%; min-height: 72px; padding: 12px; border: 0; background: transparent; color: inherit; font: inherit; text-align: left; cursor: pointer; }
.patient-report__card-head:focus-visible { outline: 3px solid #7dbdff; outline-offset: -3px; }
.patient-report__type-icon { width: 36px; height: 36px; border-radius: 11px; background: #e9f4ff; color: #197de6; }
.patient-report__type-icon.is-inspection { background: #e8fbf8; color: #16a49e; }
.patient-report__type-icon::before { position: absolute; inset: 9px 10px; border: 2px solid currentColor; border-radius: 3px; content: ''; }
.patient-report__type-icon.is-inspection::after { position: absolute; left: 17px; top: 11px; width: 2px; height: 14px; background: currentColor; box-shadow: -4px 4px 0 -0.4px currentColor, 4px 7px 0 -0.4px currentColor; content: ''; }
.patient-report__card-copy { min-width: 0; display: grid; gap: 4px; }
.patient-report__card-copy strong { overflow: hidden; color: #1d4166; font-size: 15px; text-overflow: ellipsis; white-space: nowrap; }
.patient-report__card-copy small { overflow: hidden; color: #6a86a3; font-size: 12px; text-overflow: ellipsis; white-space: nowrap; }
.patient-report__published { padding: 4px 8px; border-radius: 999px; background: #e9f8f2; color: #16835e; font-size: 11px; font-weight: 800; white-space: nowrap; }
.patient-report__card-head i { color: #7e9abb; font-size: 24px; font-style: normal; line-height: 1; transition: transform 180ms ease-out; }
.is-expanded .patient-report__card-head i { transform: rotate(90deg); }
.patient-report__detail { display: grid; gap: 13px; padding: 0 14px 14px; border-top: 1px solid #e6f0f8; }
.patient-report__detail section { padding-top: 13px; }
.patient-report__detail h3 { margin: 0; color: #486887; font-size: 13px; }
.patient-report__detail section > p { margin: 7px 0 0; color: #233e5b; font-size: 14px; line-height: 1.65; white-space: pre-wrap; }
.patient-report__detail dl { display: grid; gap: 8px; margin: 9px 0 0; }
.patient-report__detail dl div { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; padding: 9px 10px; border-radius: 9px; background: #f5f9fd; }
.patient-report__detail dt { color: #486887; font-size: 13px; }
.patient-report__detail dd { display: grid; justify-items: end; gap: 3px; margin: 0; color: #213e5c; text-align: right; }
.patient-report__detail dd strong { font-size: 13px; }.patient-report__detail dd small { color: #7890a9; font-size: 11px; }
.patient-report__detail footer { padding-top: 11px; border-top: 1px dashed #dce9f5; color: #7890a9; font-size: 11px; }
.patient-report__skeleton { display: grid; gap: 10px; padding-top: 15px; }.patient-report__skeleton span { height: 72px; border-radius: 13px; background: linear-gradient(90deg, #eef5fb 25%, #f8fbfe 37%, #eef5fb 63%); background-size: 400% 100%; animation: patient-report-loading 1.25s ease infinite; }
.patient-report__empty { display: grid; justify-items: center; gap: 10px; padding: 54px 20px 28px; color: #5e7d9c; text-align: center; }.patient-report__empty strong { color: #244766; font-size: 16px; }.patient-report__empty p { max-width: 27ch; margin: 0; font-size: 13px; line-height: 1.65; }.patient-report__empty button { min-height: 36px; padding: 0 13px; border: 1px solid #1681ed; border-radius: 9px; background: #fff; color: #1478df; font: inherit; font-size: 13px; font-weight: 800; cursor: pointer; }.patient-report__empty.is-error strong { color: #a84b36; }.patient-report__empty-icon { width: 50px; height: 50px; border-radius: 16px; background: #eaf5ff; }.patient-report__empty-icon::before { position: absolute; inset: 11px 13px; border: 2px solid #2585e9; border-radius: 4px; content: ''; }.patient-report__empty-icon::after { position: absolute; left: 20px; top: 25px; width: 11px; height: 2px; background: #2585e9; box-shadow: 0 5px #2585e9; content: ''; }
@keyframes patient-report-loading { 0% { background-position: 100% 0; } 100% { background-position: 0 0; } }
@media (prefers-reduced-motion: reduce) { .patient-report__skeleton span { animation: none; }.patient-report__card-head i { transition: none; } }
</style>
