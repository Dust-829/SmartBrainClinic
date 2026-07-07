<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { useRoute, useRouter } from 'vue-router'

import {
  medicalApi,
  type MedicalRecordDraft,
  type MedicalRecordDraftConfirmPayload,
  type SimilarMedicalRecord,
} from '@/api/medical'
import { patientApi, type RegisterDetail } from '@/api/patient'
import SectionCard from '@/components/common/SectionCard.vue'
import { useDoctorSessionStore } from '@/stores/doctorSession'

const route = useRoute()
const router = useRouter()
const session = useDoctorSessionStore()

const loading = ref(false)
const errorMessage = ref('')
const draftMissing = ref(false)
const initializingDraft = ref(false)
const savingDraft = ref(false)
const loadingSimilar = ref(false)
const similarCases = ref<SimilarMedicalRecord[]>([])
const assistantQuestion = ref('')
const assistantAnswer = ref('')
const assistantLoading = ref(false)
const registerDetail = ref<RegisterDetail | null>(null)

const encounterForm = reactive<MedicalRecordDraftConfirmPayload>({
  readme: '',
  present: '',
  history: '',
  physique: '',
  diagnosis: '',
  allergy: '',
  proposal: '',
  cure: '',
})

const registerId = computed(() => String(route.params.registerId ?? ''))
const doctor = computed(() => session.staff)
const pageTitle = computed(() => registerDetail.value?.patient_name || '接诊详情')
const doctorDisplay = computed(() => doctor.value?.displayName || '当前医生')

const canConfirm = computed(
  () =>
    !draftMissing.value &&
    !savingDraft.value &&
    encounterForm.readme.trim() &&
    encounterForm.present.trim() &&
    encounterForm.history.trim() &&
    encounterForm.physique.trim() &&
    encounterForm.diagnosis.trim(),
)

function resetEncounterForm(detail: RegisterDetail | null, draft?: MedicalRecordDraft | null) {
  encounterForm.readme = draft?.readme ?? ''
  encounterForm.present = draft?.present ?? detail?.symptoms ?? ''
  encounterForm.history = draft?.history ?? ''
  encounterForm.physique = draft?.physique ?? ''
  encounterForm.diagnosis = draft?.diagnosis ?? ''
  encounterForm.allergy = draft?.allergy ?? ''
  encounterForm.proposal = draft?.proposal ?? ''
  encounterForm.cure = draft?.cure ?? ''
}

async function loadEncounter() {
  if (!registerId.value) return

  loading.value = true
  errorMessage.value = ''
  draftMissing.value = false
  similarCases.value = []
  assistantAnswer.value = ''
  assistantQuestion.value = ''

  try {
    const detailResponse = await patientApi.getRegisterDetail(registerId.value)
    const detail = detailResponse.data.data ?? null
    registerDetail.value = detail

    try {
      const draftResponse = await medicalApi.getRecordDraft(registerId.value)
      resetEncounterForm(detail, draftResponse.data.data)
    } catch (error) {
      const status = (error as { response?: { status?: number } }).response?.status
      if (status === 404) {
        draftMissing.value = true
        resetEncounterForm(detail, null)
      } else {
        throw error
      }
    }
  } catch {
    registerDetail.value = null
    errorMessage.value = '接诊详情加载失败，请稍后重试。'
  } finally {
    loading.value = false
  }
}

async function initializeDraft() {
  if (!registerId.value || initializingDraft.value) return

  initializingDraft.value = true
  try {
    await medicalApi.createRecord({
      register_uuid: registerId.value,
      readme: registerDetail.value?.symptoms || '',
      present: registerDetail.value?.symptoms || '',
    })
    ElMessage.success('已初始化病历草稿。')
    await loadEncounter()
  } finally {
    initializingDraft.value = false
  }
}

async function confirmDraft() {
  if (!registerId.value || !canConfirm.value) return

  savingDraft.value = true
  try {
    await medicalApi.confirmRecordDraft(registerId.value, {
      readme: encounterForm.readme.trim(),
      present: encounterForm.present.trim(),
      history: encounterForm.history.trim(),
      physique: encounterForm.physique.trim(),
      diagnosis: encounterForm.diagnosis.trim(),
      allergy: encounterForm.allergy?.trim() || '',
      proposal: encounterForm.proposal?.trim() || '',
      cure: encounterForm.cure?.trim() || '',
    })
    ElMessage.success('病历已确认，接诊流程已提交完成。')
    await router.push({ name: 'doctor-home' })
  } finally {
    savingDraft.value = false
  }
}

function similarQueryText() {
  return [
    encounterForm.present,
    encounterForm.history,
    encounterForm.diagnosis,
    registerDetail.value?.symptoms,
  ]
    .filter(Boolean)
    .join('\n')
    .trim()
}

async function loadSimilarCases() {
  const queryText = similarQueryText()
  if (!queryText || loadingSimilar.value) {
    if (!queryText) {
      ElMessage.warning('请先补充现病史或诊断信息，再召回相似病历。')
    }
    return
  }

  loadingSimilar.value = true
  try {
    const response = await medicalApi.searchSimilarRecords(queryText, 5)
    similarCases.value = response.data.data ?? []
  } finally {
    loadingSimilar.value = false
  }
}

async function askAssistant() {
  const question = assistantQuestion.value.trim()
  if (!question || assistantLoading.value) return

  assistantLoading.value = true
  try {
    const response = await medicalApi.askAssistant({
      patient_uuid: registerDetail.value?.patient_uuid,
      employee_uuid: doctor.value?.employeeUuid,
      question,
      top_k: 5,
      confirm_action: false,
    })
    assistantAnswer.value = response.data.data?.answer ?? ''
  } finally {
    assistantLoading.value = false
  }
}

function goBack() {
  router.push({ name: 'doctor-home' })
}

watch(
  () => registerId.value,
  () => {
    loadEncounter()
  },
  { immediate: true },
)
</script>

<template>
  <div class="doctor-encounter">
    <section class="doctor-encounter__hero">
      <div>
        <span>接诊详情</span>
        <h2>{{ pageTitle }}</h2>
        <p>{{ doctorDisplay }} · {{ registerDetail?.dept_name || doctor?.deptName || '未绑定科室' }}</p>
      </div>
      <div class="doctor-encounter__hero-actions">
        <button type="button" class="doctor-encounter__secondary" @click="goBack">返回工作台</button>
        <button type="button" class="doctor-encounter__primary" :disabled="!canConfirm" @click="confirmDraft">
          {{ savingDraft ? '确认中...' : '确认病历并结束接诊' }}
        </button>
      </div>
    </section>

    <el-skeleton :loading="loading" animated :rows="10">
      <template #default>
        <div v-if="errorMessage" class="doctor-encounter__state is-error">
          <strong>{{ errorMessage }}</strong>
          <button type="button" @click="loadEncounter">重新加载</button>
        </div>

        <template v-else-if="registerDetail">
          <SectionCard title="患者摘要" subtitle="先把挂号、时间段、诊室与主诉收口到同一屏。">
            <div class="doctor-encounter__summary-grid">
              <div>
                <span>患者姓名</span>
                <strong>{{ registerDetail.patient_name || '-' }}</strong>
              </div>
              <div>
                <span>病案号</span>
                <strong>{{ registerDetail.patient_case_number || '-' }}</strong>
              </div>
              <div>
                <span>当前状态</span>
                <strong>{{ registerDetail.visit_state_text || registerDetail.visit_state_str || '-' }}</strong>
              </div>
              <div>
                <span>就诊时间</span>
                <strong>{{ registerDetail.actual_schedule_date || registerDetail.visit_date || '-' }} {{ registerDetail.actual_time_range || '' }}</strong>
              </div>
              <div>
                <span>接诊诊室</span>
                <strong>{{ registerDetail.clinic_room_name || '待分配' }}</strong>
              </div>
              <div>
                <span>诊室位置</span>
                <strong>{{ registerDetail.clinic_room_location || '到院导诊屏查看' }}</strong>
              </div>
            </div>
            <div class="doctor-encounter__symptom">
              <span>挂号主诉</span>
              <p>{{ registerDetail.symptoms || '当前挂号未填写症状信息。' }}</p>
            </div>
          </SectionCard>

          <div class="doctor-encounter__content">
            <SectionCard title="AI 病历草稿" subtitle="医生在这里做最后确认，确认后回写病历并结束本次接诊。">
              <div v-if="draftMissing" class="doctor-encounter__state">
                <strong>当前挂号还没有可编辑的病历草稿</strong>
                <p>这通常是支付后的异步草稿尚未生成，或者演示数据还未初始化。</p>
                <button type="button" :disabled="initializingDraft" @click="initializeDraft">
                  {{ initializingDraft ? '初始化中...' : '初始化病历草稿' }}
                </button>
              </div>

              <div v-else class="doctor-encounter__form">
                <label>
                  <span>主诉</span>
                  <textarea v-model="encounterForm.readme" rows="3" placeholder="例如：头痛伴恶心两周。" />
                </label>
                <label>
                  <span>现病史</span>
                  <textarea v-model="encounterForm.present" rows="5" placeholder="补充症状演变、持续时间、伴随症状与外院检查情况。" />
                </label>
                <label>
                  <span>既往史 / 病史</span>
                  <textarea v-model="encounterForm.history" rows="4" placeholder="补充既往相关病史、用药史、家族史等。" />
                </label>
                <label>
                  <span>查体</span>
                  <textarea v-model="encounterForm.physique" rows="4" placeholder="补充神经系统查体、生命体征与阳性体征。" />
                </label>
                <label>
                  <span>诊断</span>
                  <textarea v-model="encounterForm.diagnosis" rows="3" placeholder="填写初步诊断或待排诊断。" />
                </label>
                <div class="doctor-encounter__form-grid">
                  <label>
                    <span>过敏史</span>
                    <textarea v-model="encounterForm.allergy" rows="3" placeholder="无则写无。" />
                  </label>
                  <label>
                    <span>检查建议</span>
                    <textarea v-model="encounterForm.proposal" rows="3" placeholder="例如：建议头颅增强 MRI、血管评估等。" />
                  </label>
                </div>
                <label>
                  <span>处置 / 治疗建议</span>
                  <textarea v-model="encounterForm.cure" rows="4" placeholder="填写对症处理、复诊或住院建议。" />
                </label>
              </div>
            </SectionCard>

            <div class="doctor-encounter__sidebar">
              <SectionCard title="相似病历召回" subtitle="用当前症状与诊断去召回已确认历史病历。">
                <div class="doctor-encounter__panel-actions">
                  <button type="button" class="doctor-encounter__secondary" :disabled="loadingSimilar || draftMissing" @click="loadSimilarCases">
                    {{ loadingSimilar ? '召回中...' : '召回相似病历' }}
                  </button>
                </div>
                <div v-if="similarCases.length" class="doctor-encounter__similar-list">
                  <article v-for="item in similarCases" :key="item.uuid" class="doctor-encounter__similar-item">
                    <strong>{{ item.diagnosis || '未填写诊断' }}</strong>
                    <p>{{ item.present || item.history || '该病例未保留足够摘要。' }}</p>
                    <span>相似度 {{ item.similarity_score.toFixed(1) }}</span>
                  </article>
                </div>
                <div v-else class="doctor-encounter__state is-plain">
                  <strong>暂无召回结果</strong>
                  <p>可能还没有已确认历史病历，或者当前症状信息还不够完整。</p>
                </div>
              </SectionCard>

              <SectionCard title="AI 医生助手" subtitle="先做问答入口，后续再补处方、检查与病历审核动作。">
                <div class="doctor-encounter__assistant">
                  <textarea
                    v-model="assistantQuestion"
                    rows="4"
                    placeholder="例如：当前症状更需要优先排查占位性病变还是脑血管问题？"
                  />
                  <div class="doctor-encounter__panel-actions">
                    <button type="button" class="doctor-encounter__primary" :disabled="assistantLoading || !assistantQuestion.trim()" @click="askAssistant">
                      {{ assistantLoading ? '分析中...' : '询问 AI 助手' }}
                    </button>
                  </div>
                  <div v-if="assistantAnswer" class="doctor-encounter__assistant-answer">
                    <strong>助手回复</strong>
                    <p>{{ assistantAnswer }}</p>
                  </div>
                </div>
              </SectionCard>
            </div>
          </div>
        </template>
      </template>
    </el-skeleton>
  </div>
</template>

<style scoped>
.doctor-encounter {
  display: grid;
  gap: 20px;
}

.doctor-encounter__hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 20px;
  padding: 22px 24px;
  border-radius: 18px;
  background: linear-gradient(135deg, #0f766e, #134e4a);
  color: #ffffff;
}

.doctor-encounter__hero span,
.doctor-encounter__hero p {
  margin: 0;
  color: rgba(255, 255, 255, 0.8);
}

.doctor-encounter__hero h2 {
  margin: 8px 0 10px;
  font-size: 28px;
}

.doctor-encounter__hero-actions,
.doctor-encounter__panel-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
}

.doctor-encounter__primary,
.doctor-encounter__secondary,
.doctor-encounter__state button {
  min-height: 40px;
  padding: 0 16px;
  border: 0;
  border-radius: 10px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

.doctor-encounter__primary {
  background: #0f172a;
  color: #ffffff;
}

.doctor-encounter__secondary,
.doctor-encounter__state button {
  background: #e2e8f0;
  color: #0f172a;
}

.doctor-encounter__primary:disabled,
.doctor-encounter__secondary:disabled,
.doctor-encounter__state button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.doctor-encounter__summary-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.doctor-encounter__summary-grid div,
.doctor-encounter__symptom {
  display: grid;
  gap: 6px;
  padding: 14px;
  border-radius: 12px;
  background: #f8fafc;
}

.doctor-encounter__summary-grid span,
.doctor-encounter__symptom span {
  color: #64748b;
  font-size: 12px;
}

.doctor-encounter__summary-grid strong,
.doctor-encounter__symptom p {
  margin: 0;
  color: #0f172a;
}

.doctor-encounter__symptom {
  margin-top: 14px;
}

.doctor-encounter__content {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(320px, 0.85fr);
  gap: 20px;
}

.doctor-encounter__sidebar {
  display: grid;
  gap: 20px;
}

.doctor-encounter__form {
  display: grid;
  gap: 14px;
}

.doctor-encounter__form label,
.doctor-encounter__assistant {
  display: grid;
  gap: 8px;
}

.doctor-encounter__form span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.doctor-encounter__form textarea,
.doctor-encounter__assistant textarea {
  width: 100%;
  resize: vertical;
  padding: 12px 14px;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  line-height: 1.6;
  box-sizing: border-box;
}

.doctor-encounter__form textarea:focus,
.doctor-encounter__assistant textarea:focus {
  outline: none;
  border-color: #0f766e;
  box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.12);
}

.doctor-encounter__form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.doctor-encounter__similar-list {
  display: grid;
  gap: 12px;
}

.doctor-encounter__similar-item {
  display: grid;
  gap: 8px;
  padding: 14px;
  border: 1px solid #dbe5f0;
  border-radius: 12px;
  background: #f8fafc;
}

.doctor-encounter__similar-item strong,
.doctor-encounter__assistant-answer strong,
.doctor-encounter__state strong {
  color: #0f172a;
}

.doctor-encounter__similar-item p,
.doctor-encounter__assistant-answer p,
.doctor-encounter__state p {
  margin: 0;
  color: #64748b;
  line-height: 1.6;
}

.doctor-encounter__similar-item span {
  color: #0369a1;
  font-size: 12px;
  font-weight: 700;
}

.doctor-encounter__assistant-answer {
  display: grid;
  gap: 8px;
  padding: 14px;
  border-radius: 12px;
  background: #ecfeff;
  border: 1px solid #99f6e4;
}

.doctor-encounter__state {
  display: grid;
  gap: 10px;
  justify-items: start;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.doctor-encounter__state.is-error {
  background: #fff7ed;
  border-color: #fdba74;
}

.doctor-encounter__state.is-plain {
  padding: 0;
  border: 0;
  background: transparent;
}

@media (max-width: 1100px) {
  .doctor-encounter__content,
  .doctor-encounter__summary-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 720px) {
  .doctor-encounter__hero {
    align-items: stretch;
    flex-direction: column;
  }

  .doctor-encounter__hero-actions,
  .doctor-encounter__panel-actions {
    justify-content: stretch;
  }

  .doctor-encounter__hero-actions button,
  .doctor-encounter__panel-actions button {
    width: 100%;
  }

  .doctor-encounter__form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
