<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'

import { adminApi, type PatientAdminDetail, type PatientAdminListItem } from '@/api/admin'
import { authApi, type DoctorDirectoryItem } from '@/api/auth'
import SectionCard from '@/components/common/SectionCard.vue'

type AccountTab = 'doctor' | 'patient'
type PatientGender = 'male' | 'female'
type DoctorDialogMode = 'create' | 'edit'

const DEFAULT_PAGE_LIMIT = 20

const activeTab = ref<AccountTab>('doctor')

const loadingDoctors = ref(false)
const doctorError = ref('')
const doctorKeyword = ref('')
const doctors = ref<DoctorDirectoryItem[]>([])
const doctorPagination = reactive({ total: 0, limit: DEFAULT_PAGE_LIMIT, offset: 0 })
const doctorLoaded = ref(false)
const doctorDialogVisible = ref(false)
const doctorDialogMode = ref<DoctorDialogMode>('create')
const savingDoctor = ref(false)
const editingDoctorUuid = ref('')

const doctorForm = reactive({
  realname: '',
  dept_code: 'SJWK',
  regist_level_code: '',
  gender: '男',
  expertise: '',
  ai_eval_score: 5,
  score_adjustment: 0,
})

const loadingPatients = ref(false)
const patientError = ref('')
const patientKeyword = ref('')
const patients = ref<PatientAdminListItem[]>([])
const patientPagination = reactive({ total: 0, limit: DEFAULT_PAGE_LIMIT, offset: 0 })
const patientLoaded = ref(false)
const patientDialogVisible = ref(false)
const patientDialogMode = ref<'create' | 'edit'>('create')
const savingPatient = ref(false)
const loadingPatientDetail = ref(false)
const editingPatientUuid = ref('')

const patientForm = reactive({
  real_name: '',
  gender: 'male' as PatientGender,
  card_number: '',
  birthdate: '',
  home_address: '',
})

const doctorDialogTitle = computed(() => (doctorDialogMode.value === 'create' ? '新增医生资料' : '编辑医生资料'))
const patientDialogTitle = computed(() => (patientDialogMode.value === 'create' ? '新增患者资料' : '编辑患者资料'))
const doctorPageStart = computed(() => (doctorPagination.total ? doctorPagination.offset + 1 : 0))
const doctorPageEnd = computed(() => Math.min(doctorPagination.offset + doctors.value.length, doctorPagination.total))
const patientPageStart = computed(() => (patientPagination.total ? patientPagination.offset + 1 : 0))
const patientPageEnd = computed(() => Math.min(patientPagination.offset + patients.value.length, patientPagination.total))
const canGoPreviousDoctorPage = computed(() => doctorPagination.offset > 0)
const canGoNextDoctorPage = computed(() => doctorPagination.offset + doctors.value.length < doctorPagination.total)
const canGoPreviousPatientPage = computed(() => patientPagination.offset > 0)
const canGoNextPatientPage = computed(() => patientPagination.offset + patients.value.length < patientPagination.total)

function normalizePatientGender(value?: string | null): PatientGender {
  if (!value) return 'male'
  const normalized = value.trim().toLowerCase()
  if (normalized === 'female' || normalized === '女') return 'female'
  return 'male'
}

function formatPatientGender(value?: string | null) {
  return normalizePatientGender(value) === 'female' ? '女' : '男'
}

function formatDoctorGender(value?: string | null) {
  if (!value) return '未知'
  const normalized = value.trim().toLowerCase()
  if (normalized === 'female' || normalized === '女') return '女'
  if (normalized === 'male' || normalized === '男') return '男'
  return value
}

async function loadDoctors() {
  loadingDoctors.value = true
  doctorError.value = ''
  try {
    const response = await authApi.listDoctorAccounts({
      keyword: doctorKeyword.value.trim() || undefined,
      limit: doctorPagination.limit,
      offset: doctorPagination.offset,
    })
    const page = response.data.data
    doctors.value = page?.items ?? []
    doctorPagination.total = page?.pagination?.total ?? doctors.value.length
    doctorPagination.limit = page?.pagination?.limit ?? doctorPagination.limit
    doctorPagination.offset = page?.pagination?.offset ?? doctorPagination.offset
    doctorLoaded.value = true
  } catch {
    doctorError.value = '医生账号列表加载失败，请检查服务后重试。'
  } finally {
    loadingDoctors.value = false
  }
}

function searchDoctors() {
  doctorPagination.offset = 0
  loadDoctors()
}

function changeDoctorPage(direction: 'previous' | 'next') {
  const nextOffset = direction === 'previous'
    ? Math.max(0, doctorPagination.offset - doctorPagination.limit)
    : doctorPagination.offset + doctorPagination.limit
  if (nextOffset === doctorPagination.offset) return
  doctorPagination.offset = nextOffset
  loadDoctors()
}

function updateDoctorLimit(event: Event) {
  doctorPagination.limit = Number((event.target as HTMLSelectElement).value) || DEFAULT_PAGE_LIMIT
  doctorPagination.offset = 0
  loadDoctors()
}

function resetDoctorForm() {
  doctorForm.realname = ''
  doctorForm.dept_code = 'SJWK'
  doctorForm.regist_level_code = ''
  doctorForm.gender = '男'
  doctorForm.expertise = ''
  doctorForm.ai_eval_score = 5
  doctorForm.score_adjustment = 0
  editingDoctorUuid.value = ''
}

function openCreateDoctorDialog() {
  doctorDialogMode.value = 'create'
  resetDoctorForm()
  doctorDialogVisible.value = true
}

function openEditDoctorDialog(doctor: DoctorDirectoryItem) {
  doctorDialogMode.value = 'edit'
  editingDoctorUuid.value = doctor.uuid
  doctorForm.realname = doctor.realname
  doctorForm.dept_code = doctor.dept_code || 'SJWK'
  doctorForm.regist_level_code = doctor.regist_level_code || ''
  doctorForm.gender = formatDoctorGender(doctor.gender)
  doctorForm.expertise = doctor.expertise || ''
  doctorForm.ai_eval_score = Number(doctor.ai_eval_score ?? 5)
  doctorForm.score_adjustment = 0
  doctorDialogVisible.value = true
}

async function submitDoctorForm() {
  if (!doctorForm.realname.trim() || !doctorForm.dept_code.trim()) {
    ElMessage.warning('请补全医生基础资料')
    return
  }

  savingDoctor.value = true
  try {
    if (doctorDialogMode.value === 'create') {
      await authApi.createEmployee({
        realname: doctorForm.realname.trim(),
        password: '123456',
        dept_code: doctorForm.dept_code.trim(),
        regist_level_code: doctorForm.regist_level_code.trim() || undefined,
        gender: doctorForm.gender,
        expertise: doctorForm.expertise.trim() || undefined,
        ai_eval_score: doctorForm.ai_eval_score,
      })
      ElMessage.success('医生资料已创建')
    } else {
      await authApi.updateEmployeeProfile(editingDoctorUuid.value, {
        realname: doctorForm.realname.trim(),
        dept_code: doctorForm.dept_code.trim() || undefined,
        regist_level_code: doctorForm.regist_level_code.trim() || undefined,
        gender: doctorForm.gender,
        expertise: doctorForm.expertise.trim() || undefined,
      })

      if (doctorForm.score_adjustment !== 0) {
        await authApi.adjustEmployeeScore(editingDoctorUuid.value, Number(doctorForm.score_adjustment))
      }
      ElMessage.success('医生资料已更新')
    }

    doctorDialogVisible.value = false
    resetDoctorForm()
    await loadDoctors()
  } finally {
    savingDoctor.value = false
  }
}

async function loadPatients() {
  loadingPatients.value = true
  patientError.value = ''
  try {
    const response = await adminApi.listPatients({
      keyword: patientKeyword.value.trim() || undefined,
      limit: patientPagination.limit,
      offset: patientPagination.offset,
    })
    const page = response.data.data
    patients.value = page?.items ?? []
    patientPagination.total = page?.pagination?.total ?? patients.value.length
    patientPagination.limit = page?.pagination?.limit ?? patientPagination.limit
    patientPagination.offset = page?.pagination?.offset ?? patientPagination.offset
    patientLoaded.value = true
  } catch {
    patientError.value = '患者档案列表加载失败，请检查服务后重试。'
  } finally {
    loadingPatients.value = false
  }
}

function searchPatients() {
  patientPagination.offset = 0
  loadPatients()
}

function changePatientPage(direction: 'previous' | 'next') {
  const nextOffset = direction === 'previous'
    ? Math.max(0, patientPagination.offset - patientPagination.limit)
    : patientPagination.offset + patientPagination.limit
  if (nextOffset === patientPagination.offset) return
  patientPagination.offset = nextOffset
  loadPatients()
}

function updatePatientLimit(event: Event) {
  patientPagination.limit = Number((event.target as HTMLSelectElement).value) || DEFAULT_PAGE_LIMIT
  patientPagination.offset = 0
  loadPatients()
}

function resetPatientForm() {
  patientForm.real_name = ''
  patientForm.gender = 'male'
  patientForm.card_number = ''
  patientForm.birthdate = ''
  patientForm.home_address = ''
  editingPatientUuid.value = ''
}

function openCreatePatientDialog() {
  patientDialogMode.value = 'create'
  resetPatientForm()
  patientDialogVisible.value = true
}

async function openEditPatientDialog(patient: PatientAdminListItem) {
  patientDialogMode.value = 'edit'
  editingPatientUuid.value = patient.uuid
  loadingPatientDetail.value = true
  try {
    const response = await adminApi.getPatientDetail(patient.uuid)
    const detail: PatientAdminDetail | undefined = response.data.data
    if (!detail) throw new Error('患者档案详情为空')
    patientForm.real_name = detail.real_name
    patientForm.gender = normalizePatientGender(detail.gender)
    patientForm.card_number = detail.card_number
    patientForm.birthdate = detail.birthdate
    patientForm.home_address = detail.home_address || ''
    patientDialogVisible.value = true
  } catch {
    ElMessage.error('患者完整档案加载失败，请稍后重试')
  } finally {
    loadingPatientDetail.value = false
  }
}

async function submitPatientForm() {
  if (!patientForm.real_name.trim() || !patientForm.card_number.trim() || !patientForm.birthdate.trim()) {
    ElMessage.warning('请补全患者基础资料')
    return
  }

  savingPatient.value = true
  try {
    if (patientDialogMode.value === 'create') {
      await adminApi.createPatient({
        real_name: patientForm.real_name.trim(),
        gender: patientForm.gender,
        card_number: patientForm.card_number.trim(),
        birthdate: patientForm.birthdate,
        home_address: patientForm.home_address.trim() || undefined,
      })
      ElMessage.success('患者资料已创建')
    } else {
      await adminApi.updatePatient(editingPatientUuid.value, {
        real_name: patientForm.real_name.trim(),
        gender: patientForm.gender,
        birthdate: patientForm.birthdate,
        home_address: patientForm.home_address.trim() || undefined,
      })
      ElMessage.success('患者资料已更新')
    }

    patientDialogVisible.value = false
    resetPatientForm()
    await loadPatients()
  } finally {
    savingPatient.value = false
  }
}

onMounted(() => {
  loadDoctors()
})

watch(activeTab, (tab) => {
  if (tab === 'patient' && !patientLoaded.value && !loadingPatients.value) {
    loadPatients()
  }
})
</script>

<template>
  <div class="accounts-page">
    <section class="accounts-page__hero">
      <div>
        <span>账号管理</span>
        <h2>统一管理 doctor 与 patient</h2>
        <p>把原基础资料域收口到一个页面内，按账号域组织后台操作。</p>
      </div>
    </section>

    <div class="accounts-page__tabs">
      <button type="button" :class="['accounts-page__tab', { 'is-active': activeTab === 'doctor' }]" @click="activeTab = 'doctor'">
        doctor
      </button>
      <button type="button" :class="['accounts-page__tab', { 'is-active': activeTab === 'patient' }]" @click="activeTab = 'patient'">
        patient
      </button>
    </div>

    <template v-if="activeTab === 'doctor'">
      <SectionCard title="医生账号检索" subtitle="支持按姓名或科室编码搜索 doctor 账号。">
        <div class="toolbar">
          <form class="toolbar__search" @submit.prevent="searchDoctors">
            <input v-model="doctorKeyword" type="text" placeholder="输入医生姓名或科室编码" />
            <button type="submit" :disabled="loadingDoctors">
              {{ loadingDoctors ? '查询中...' : '查询医生' }}
            </button>
          </form>
          <button type="button" class="toolbar__create" @click="openCreateDoctorDialog">新增医生</button>
        </div>
      </SectionCard>

      <SectionCard title="医生账号列表" subtitle="支持新增、编辑基础资料与调整 AI 评分。">
        <div class="accounts-list-status" aria-live="polite">
          <span v-if="doctorLoaded">显示 {{ doctorPageStart }}–{{ doctorPageEnd }} / 共 {{ doctorPagination.total }} 条</span>
          <span v-else>正在准备医生账号列表</span>
          <label>
            <span>每页</span>
            <select :value="doctorPagination.limit" :disabled="loadingDoctors" @change="updateDoctorLimit">
              <option :value="20">20 条</option>
              <option :value="50">50 条</option>
              <option :value="100">100 条</option>
            </select>
          </label>
        </div>

        <div v-if="doctorError" class="accounts-feedback accounts-feedback--error" role="alert">
          <p>{{ doctorError }}</p>
          <button type="button" @click="loadDoctors">重新加载</button>
        </div>
        <template v-if="loadingDoctors && !doctors.length">
          <div class="accounts-skeleton" aria-label="医生账号列表加载中">
            <span v-for="index in 3" :key="index"></span>
          </div>
        </template>
        <div v-else-if="doctors.length" class="account-list">
          <article v-for="doctor in doctors" :key="doctor.uuid" class="account-card">
            <div class="account-card__head">
              <div>
                <strong>{{ doctor.realname }}</strong>
                <p>{{ formatDoctorGender(doctor.gender) }} | AI 评分 {{ doctor.ai_eval_score ?? '未记录' }}</p>
              </div>
              <span>{{ doctor.uuid }}</span>
            </div>

            <div class="account-meta">
              <p>科室编码：{{ doctor.dept_code || '未配置' }}</p>
              <p>挂号级别：{{ doctor.regist_level_code || '未配置' }}</p>
              <p>专长：{{ doctor.expertise || '未填写' }}</p>
            </div>

            <div class="account-card__actions">
              <button type="button" @click="openEditDoctorDialog(doctor)">编辑资料</button>
            </div>
          </article>
        </div>
        <div v-else-if="!doctorError" class="accounts-empty">{{ doctorKeyword ? '没有匹配当前检索条件的医生账号。' : '当前尚无医生账号。' }}</div>

        <div v-if="doctorLoaded" class="accounts-pagination">
          <button type="button" :disabled="loadingDoctors || !canGoPreviousDoctorPage" @click="changeDoctorPage('previous')">上一页</button>
          <span>第 {{ Math.floor(doctorPagination.offset / doctorPagination.limit) + 1 }} 页</span>
          <button type="button" :disabled="loadingDoctors || !canGoNextDoctorPage" @click="changeDoctorPage('next')">下一页</button>
        </div>
      </SectionCard>
    </template>

    <template v-else>
      <SectionCard title="患者账号检索" subtitle="支持按姓名或身份证号搜索 patient 账号。">
        <div class="toolbar">
          <form class="toolbar__search" @submit.prevent="searchPatients">
            <input v-model="patientKeyword" type="text" placeholder="输入姓名或身份证号" />
            <button type="submit" :disabled="loadingPatients">
              {{ loadingPatients ? '查询中...' : '查询患者' }}
            </button>
          </form>
          <button type="button" class="toolbar__create" @click="openCreatePatientDialog">新增患者</button>
        </div>
      </SectionCard>

      <SectionCard title="患者档案列表" subtitle="列表仅显示脱敏证件号；完整地址只在受控编辑操作中按需读取。">
        <div class="accounts-list-status" aria-live="polite">
          <span v-if="patientLoaded">显示 {{ patientPageStart }}–{{ patientPageEnd }} / 共 {{ patientPagination.total }} 条</span>
          <span v-else>正在准备患者档案列表</span>
          <label>
            <span>每页</span>
            <select :value="patientPagination.limit" :disabled="loadingPatients" @change="updatePatientLimit">
              <option :value="20">20 条</option>
              <option :value="50">50 条</option>
              <option :value="100">100 条</option>
            </select>
          </label>
        </div>

        <div v-if="patientError" class="accounts-feedback accounts-feedback--error" role="alert">
          <p>{{ patientError }}</p>
          <button type="button" @click="loadPatients">重新加载</button>
        </div>
        <template v-if="loadingPatients && !patients.length">
          <div class="accounts-skeleton" aria-label="患者档案列表加载中">
            <span v-for="index in 3" :key="index"></span>
          </div>
        </template>
        <div v-else-if="patients.length" class="account-list">
          <article v-for="patient in patients" :key="patient.uuid" class="account-card">
            <div class="account-card__head">
              <div>
                <strong>{{ patient.real_name }}</strong>
                <p>{{ formatPatientGender(patient.gender) }} | 证件号 {{ patient.card_number }}</p>
              </div>
              <span>{{ patient.case_number }}</span>
            </div>

            <div class="account-meta">
              <p>出生日期：{{ patient.birthdate }}</p>
              <p>家庭住址：受控查看</p>
              <p>建档时间：{{ patient.created_at?.replace('T', ' ').slice(0, 16) || '未记录' }}</p>
            </div>

            <div class="account-card__actions">
              <button type="button" :disabled="loadingPatientDetail" @click="openEditPatientDialog(patient)">
                {{ loadingPatientDetail ? '正在读取详情...' : '编辑资料' }}
              </button>
            </div>
          </article>
        </div>
        <div v-else-if="!patientError" class="accounts-empty">{{ patientKeyword ? '没有匹配当前检索条件的患者档案。' : '当前尚无患者档案。' }}</div>

        <div v-if="patientLoaded" class="accounts-pagination">
          <button type="button" :disabled="loadingPatients || !canGoPreviousPatientPage" @click="changePatientPage('previous')">上一页</button>
          <span>第 {{ Math.floor(patientPagination.offset / patientPagination.limit) + 1 }} 页</span>
          <button type="button" :disabled="loadingPatients || !canGoNextPatientPage" @click="changePatientPage('next')">下一页</button>
        </div>
      </SectionCard>
    </template>

    <el-dialog v-model="doctorDialogVisible" :title="doctorDialogTitle" width="560px">
      <form class="dialog-form" @submit.prevent="submitDoctorForm">
        <label>
          <span>姓名</span>
          <input v-model="doctorForm.realname" type="text" placeholder="请输入医生姓名" />
        </label>
        <label>
          <span>性别</span>
          <select v-model="doctorForm.gender">
            <option value="男">男</option>
            <option value="女">女</option>
          </select>
        </label>
        <label>
          <span>科室编码</span>
          <input v-model="doctorForm.dept_code" type="text" placeholder="如 SJWK" />
        </label>
        <label>
          <span>挂号级别编码</span>
          <input v-model="doctorForm.regist_level_code" type="text" placeholder="可选，如 ZJ / PT" />
        </label>
        <label>
          <span>专长</span>
          <textarea v-model="doctorForm.expertise" rows="3" placeholder="请输入医生专长" />
        </label>
        <label v-if="doctorDialogMode === 'create'">
          <span>AI 评分</span>
          <input v-model.number="doctorForm.ai_eval_score" type="number" min="0" max="5" step="0.1" />
        </label>
        <label v-else>
          <span>AI 评分调整值</span>
          <input v-model.number="doctorForm.score_adjustment" type="number" min="-5" max="5" step="0.1" />
        </label>
      </form>

      <template #footer>
        <div class="dialog-actions">
          <button type="button" class="dialog-actions__secondary" @click="doctorDialogVisible = false">取消</button>
          <button type="button" class="dialog-actions__primary" :disabled="savingDoctor" @click="submitDoctorForm">
            {{ savingDoctor ? '保存中...' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <el-dialog v-model="patientDialogVisible" :title="patientDialogTitle" width="520px">
      <form class="dialog-form" @submit.prevent="submitPatientForm">
        <label>
          <span>姓名</span>
          <input v-model="patientForm.real_name" type="text" placeholder="请输入患者姓名" />
        </label>
        <label>
          <span>性别</span>
          <select v-model="patientForm.gender">
            <option value="male">男</option>
            <option value="female">女</option>
          </select>
        </label>
        <label>
          <span>身份证号</span>
          <input
            v-model="patientForm.card_number"
            type="text"
            placeholder="请输入身份证号"
            :disabled="patientDialogMode === 'edit'"
          />
        </label>
        <label>
          <span>出生日期</span>
          <input v-model="patientForm.birthdate" type="date" />
        </label>
        <label>
          <span>家庭住址</span>
          <textarea v-model="patientForm.home_address" rows="3" placeholder="选填" />
        </label>
      </form>

      <template #footer>
        <div class="dialog-actions">
          <button type="button" class="dialog-actions__secondary" @click="patientDialogVisible = false">取消</button>
          <button type="button" class="dialog-actions__primary" :disabled="savingPatient" @click="submitPatientForm">
            {{ savingPatient ? '保存中...' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>
