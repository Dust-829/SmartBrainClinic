<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import PatientFlowHeader from '@/components/patient/PatientFlowHeader.vue'
import { patientApi, type DepartmentOption } from '@/api/patient'
import { usePatientFlowStore } from '@/stores/patientFlow'

interface DepartmentCategory {
  key: string
  label: string
  matcher: (department: DepartmentOption) => boolean
}

const route = useRoute()
const router = useRouter()
const flow = usePatientFlowStore()
const departments = ref<DepartmentOption[]>([])
const loading = ref(false)
const errorMessage = ref('')
const activeCategory = ref('featured')
const keyword = ref('')
const aiPromptOpen = ref(false)

const categories: DepartmentCategory[] = [
  {
    key: 'featured',
    label: '推荐门诊',
    matcher: (department) => /专家|特需|全科|神经|心内/.test(department.name),
  },
  {
    key: 'internal',
    label: '内科',
    matcher: (department) => /内科|心内|神经内|呼吸|消化|肾|内分泌/.test(department.name),
  },
  {
    key: 'surgery',
    label: '外科',
    matcher: (department) => /外科|神经外|骨科|普外|泌尿/.test(department.name),
  },
  {
    key: 'womenChildren',
    label: '妇产儿科',
    matcher: (department) => /妇|产|儿科|小儿/.test(department.name),
  },
  {
    key: 'all',
    label: '全部科室',
    matcher: () => true,
  },
]

const activeCategoryMeta = computed(() => categories.find((item) => item.key === activeCategory.value) || categories[0])

const visibleDepartments = computed(() => {
  const normalizedKeyword = keyword.value.trim()
  const matched = departments.value.filter((department) => activeCategoryMeta.value.matcher(department))
  const source = matched.length ? matched : departments.value
  if (!normalizedKeyword) return source
  return source.filter((department) => department.name.includes(normalizedKeyword))
})

function normalizeDepartment(raw: DepartmentOption & { dept_code?: string; dept_name?: string }) {
  return {
    code: raw.code || raw.dept_code || '',
    name: raw.name || raw.dept_name || '',
  }
}

onMounted(async () => {
  if (!flow.patient) {
    router.replace('/patient')
    return
  }

  const shouldAskAi = route.query.askAi === '1'
  if (shouldAskAi) flow.resetRegisterDraft()

  await nextTick()
  if (shouldAskAi && !flow.triagePromptShown) showTriagePrompt()
  await loadDepartments()
})

async function loadDepartments() {
  loading.value = true
  errorMessage.value = ''
  try {
    const response = await patientApi.getDepartments()
    const source = Array.isArray(response.data.data) ? response.data.data : []
    departments.value = source.map((item) => normalizeDepartment(item)).filter((item) => item.code && item.name)
    if (!departments.value.length) errorMessage.value = '暂未获取到可挂号科室，请确认后端科室接口已有数据。'
  } catch (error) {
    departments.value = []
    errorMessage.value = '科室列表加载失败，请检查 8000 网关和 patient 服务后重试。'
  } finally {
    loading.value = false
  }
}

function showTriagePrompt() {
  if (aiPromptOpen.value || flow.triagePromptShown) return

  aiPromptOpen.value = true
  flow.markTriagePromptShown()
  ElMessageBox.confirm('不知道挂什么科室？智能分诊可以根据症状帮您推荐科室。', '智能分诊', {
    confirmButtonText: '帮我',
    cancelButtonText: '暂不需要',
    distinguishCancelAndClose: true,
    closeOnClickModal: false,
    customClass: 'patient-ai-dialog',
    autofocus: false,
    showClose: false,
    center: true,
  })
    .then(() => router.push('/patient/triage'))
    .catch(() => {
      if (route.query.askAi) router.replace('/patient/departments')
    })
    .finally(() => {
      aiPromptOpen.value = false
    })
}

function goBack() {
  router.push('/patient/home')
}

function goTriage() {
  flow.markTriagePromptShown()
  router.push('/patient/triage')
}

function chooseDepartment(department: DepartmentOption) {
  flow.setManualDepartment({ code: department.code, name: department.name })
  router.push('/patient/doctors')
}
</script>

<template>
  <div class="patient-register-entry">
    <PatientFlowHeader
      title="按科室挂号"
      subtitle="选择科室后进入医生推荐与号源选择"
      back-label="返回首页"
      @back="goBack"
    />

    <main class="patient-register-entry__main">
      <button type="button" class="patient-register-entry__ai" @click="goTriage">
        <span aria-hidden="true">i</span>
        <strong>不确定科室？可使用智能分诊辅助推荐</strong>
        <i aria-hidden="true">›</i>
      </button>

      <label class="patient-register-entry__search">
        <span aria-hidden="true"></span>
        <input v-model="keyword" type="search" placeholder="搜索科室名称" />
      </label>

      <el-skeleton :loading="loading" animated>
        <template #template>
          <div class="patient-register-entry__skeleton">
            <el-skeleton-item variant="rect" />
            <el-skeleton-item variant="rect" />
            <el-skeleton-item variant="rect" />
          </div>
        </template>
        <template #default>
          <section class="patient-register-entry__panel">
            <aside class="patient-register-entry__categories" aria-label="科室分类">
              <button
                v-for="category in categories"
                :key="category.key"
                type="button"
                :class="['patient-register-entry__category', { 'is-active': activeCategory === category.key }]"
                @click="activeCategory = category.key"
              >
                {{ category.label }}
              </button>
            </aside>

            <div class="patient-register-entry__departments" aria-label="科室列表">
              <button
                v-for="department in visibleDepartments"
                :key="department.code"
                type="button"
                class="patient-register-entry__department"
                @click="chooseDepartment(department)"
              >
                <span>{{ department.name }}</span>
                <small>在线挂号</small>
                <i aria-hidden="true">›</i>
              </button>
              <div v-if="errorMessage" class="patient-register-entry__empty is-error">
                <strong>{{ errorMessage }}</strong>
                <button type="button" @click="loadDepartments">重新加载</button>
              </div>
              <el-empty v-else-if="!visibleDepartments.length" description="暂无匹配科室" :image-size="88" />
            </div>
          </section>
        </template>
      </el-skeleton>
    </main>
  </div>
</template>

<style scoped>
.patient-register-entry {
  min-height: 100vh;
  overflow: hidden;
  background:
    radial-gradient(circle at 88% 4%, rgba(78, 167, 255, 0.2), transparent 30%),
    linear-gradient(180deg, #eaf4ff 0%, #f7fbff 48%, #ffffff 100%);
  color: var(--patient-text);
}

.patient-register-entry__main {
  display: grid;
  gap: 14px;
  margin-top: -28px;
  padding: 0 var(--patient-page-gutter) 28px;
}

.patient-register-entry__ai {
  display: grid;
  grid-template-columns: 26px minmax(0, 1fr) 18px;
  align-items: center;
  gap: 10px;
  min-height: 52px;
  padding: 0 14px;
  border: 0;
  border-radius: 14px;
  background: rgba(229, 243, 255, 0.94);
  color: #66758b;
  text-align: left;
  box-shadow: 0 12px 28px rgba(31, 92, 153, 0.09);
}

.patient-register-entry__ai span {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  border: 3px solid var(--patient-primary);
  border-radius: 50%;
  color: var(--patient-primary);
  font-weight: 900;
}

.patient-register-entry__ai strong {
  min-width: 0;
  overflow: hidden;
  font-size: 14px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.patient-register-entry__ai i {
  color: #8f9bad;
  font-size: 24px;
  font-style: normal;
}

.patient-register-entry__search {
  display: flex;
  align-items: center;
  gap: 12px;
  height: 50px;
  padding: 0 16px;
  border-radius: 16px;
  background: #ffffff;
  box-shadow: 0 12px 28px rgba(31, 92, 153, 0.08);
}

.patient-register-entry__search span {
  position: relative;
  width: 18px;
  height: 18px;
  border: 3px solid #7c8899;
  border-radius: 50%;
}

.patient-register-entry__search span::after {
  position: absolute;
  right: -7px;
  bottom: -5px;
  width: 9px;
  height: 3px;
  border-radius: 2px;
  background: #7c8899;
  transform: rotate(45deg);
  content: '';
}

.patient-register-entry__search input {
  min-width: 0;
  width: 100%;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--patient-text);
  font-size: 16px;
}

.patient-register-entry__search input::placeholder {
  color: #8793a3;
}

.patient-register-entry__panel {
  display: grid;
  grid-template-columns: 118px minmax(0, 1fr);
  min-height: 520px;
  overflow: hidden;
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 18px 40px rgba(33, 94, 151, 0.1);
}

.patient-register-entry__categories {
  background: #f1f7ff;
}

.patient-register-entry__category,
.patient-register-entry__department {
  width: 100%;
  border: 0;
  background: transparent;
  color: inherit;
  text-align: left;
}

.patient-register-entry__category {
  position: relative;
  min-height: 66px;
  padding: 12px 12px 12px 16px;
  color: #66758b;
  font-size: 15px;
  line-height: 1.35;
}

.patient-register-entry__category.is-active {
  background: #ffffff;
  color: var(--patient-primary);
  font-weight: 800;
}

.patient-register-entry__category.is-active::before {
  position: absolute;
  left: 0;
  top: 18px;
  bottom: 18px;
  width: 4px;
  border-radius: 0 4px 4px 0;
  background: var(--patient-primary);
  content: '';
}

.patient-register-entry__departments {
  min-width: 0;
  background: #ffffff;
}

.patient-register-entry__department {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 18px;
  gap: 5px 10px;
  min-height: 72px;
  padding: 13px 16px;
  border-bottom: 1px solid #e3ebf4;
}

.patient-register-entry__department span {
  min-width: 0;
  overflow: hidden;
  color: #16233a;
  font-size: 17px;
  font-weight: 800;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.patient-register-entry__department small {
  color: var(--patient-text-muted);
  font-size: 12px;
}

.patient-register-entry__department i {
  grid-row: 1 / 3;
  grid-column: 2;
  align-self: center;
  color: #9aa6b5;
  font-size: 26px;
  font-style: normal;
}

.patient-register-entry__empty {
  display: grid;
  justify-items: center;
  gap: 12px;
  padding: 48px 16px;
  color: var(--patient-text-muted);
  text-align: center;
}

.patient-register-entry__empty strong {
  color: var(--patient-text);
  font-size: 14px;
  line-height: 1.5;
}

.patient-register-entry__empty button {
  min-height: 38px;
  padding: 0 16px;
  border: 0;
  border-radius: 19px;
  background: var(--patient-primary);
  color: #ffffff;
  font: inherit;
  font-weight: 800;
}

.patient-register-entry__skeleton {
  display: grid;
  gap: 10px;
  padding: 14px;
}

.patient-register-entry__skeleton :deep(.el-skeleton__item) {
  height: 72px;
  border-radius: 14px;
}

:global(.patient-ai-dialog) {
  width: min(82vw, 360px);
  max-width: calc(var(--patient-page-width) - 48px);
  border-radius: 14px;
  padding: 26px 0 0;
  overflow: hidden;
}

:global(.patient-ai-dialog .el-message-box__header) {
  padding: 0 24px 8px;
}

:global(.patient-ai-dialog .el-message-box__title) {
  justify-content: center;
  font-size: 18px;
  font-weight: 900;
  color: var(--patient-text);
}

:global(.patient-ai-dialog .el-message-box__content) {
  padding: 18px 30px 28px;
  text-align: center;
  color: #7b8797;
  font-size: 16px;
  line-height: 1.6;
}

:global(.patient-ai-dialog .el-message-box__btns) {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  padding: 0;
  border-top: 1px solid #e5e7eb;
}

:global(.patient-ai-dialog .el-message-box__btns .el-button) {
  min-height: 56px;
  margin: 0;
  border: 0;
  border-radius: 0;
  background: #ffffff;
  color: #111827;
  font-size: 16px;
  font-weight: 800;
}

:global(.patient-ai-dialog .el-message-box__btns .el-button--primary) {
  border-left: 1px solid #e5e7eb;
  color: var(--patient-primary);
}
</style>
