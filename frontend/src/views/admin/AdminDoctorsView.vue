<script setup lang="ts">
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import { authApi, type DoctorDirectoryItem } from '@/api/auth'
import SectionCard from '@/components/common/SectionCard.vue'

const loadingDoctors = ref(false)
const creatingDoctor = ref(false)
const updatingExpertise = ref('')
const adjustingScore = ref('')

const doctors = ref<DoctorDirectoryItem[]>([])
const selectedDeptCode = ref('SJWK')

const createForm = reactive({
  realname: '',
  dept_code: 'SJWK',
  regist_level_code: '',
  gender: '男',
  expertise: '',
  ai_eval_score: 5,
})

const expertiseDrafts = ref<Record<string, string>>({})
const scoreAdjustments = ref<Record<string, number>>({})

async function loadDoctors() {
  loadingDoctors.value = true
  try {
    const response = await authApi.listDoctorsByDepartmentCode(selectedDeptCode.value.trim())
    doctors.value = response.data.data ?? []
    expertiseDrafts.value = Object.fromEntries(doctors.value.map((doctor) => [doctor.uuid, doctor.expertise || '']))
    scoreAdjustments.value = Object.fromEntries(doctors.value.map((doctor) => [doctor.uuid, 0]))
  } catch {
    doctors.value = []
  } finally {
    loadingDoctors.value = false
  }
}

async function createDoctor() {
  creatingDoctor.value = true
  try {
    await authApi.createEmployee({
      ...createForm,
      password: '123456',
      regist_level_code: createForm.regist_level_code || undefined,
      expertise: createForm.expertise || undefined,
    })
    ElMessage.success('医生已创建')
    createForm.realname = ''
    createForm.regist_level_code = ''
    createForm.expertise = ''
    createForm.ai_eval_score = 5
    await loadDoctors()
  } finally {
    creatingDoctor.value = false
  }
}

async function saveExpertise(doctor: DoctorDirectoryItem) {
  updatingExpertise.value = doctor.uuid
  try {
    await authApi.updateEmployeeExpertise(doctor.uuid, expertiseDrafts.value[doctor.uuid] || '')
    ElMessage.success(`已更新 ${doctor.realname} 的专长`)
    await loadDoctors()
  } finally {
    updatingExpertise.value = ''
  }
}

async function adjustScore(doctor: DoctorDirectoryItem) {
  adjustingScore.value = doctor.uuid
  try {
    await authApi.adjustEmployeeScore(doctor.uuid, Number(scoreAdjustments.value[doctor.uuid] || 0))
    ElMessage.success(`已调整 ${doctor.realname} 的 AI 评分`)
    scoreAdjustments.value[doctor.uuid] = 0
    await loadDoctors()
  } finally {
    adjustingScore.value = ''
  }
}

loadDoctors()
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>基础资料中心</span>
        <h2>医生管理</h2>
        <p>当前接入医生列表、新增医生、专长维护和 AI 评分调整，满足管理员端基础资料域最小闭环。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="按科室查看医生" subtitle="先按科室编码读取医生列表。">
        <form class="admin-form" @submit.prevent="loadDoctors">
          <label>
            <span>科室编码</span>
            <input v-model="selectedDeptCode" type="text" placeholder="如 SJWK" />
          </label>
          <button type="submit" :disabled="loadingDoctors">
            {{ loadingDoctors ? '加载中...' : '加载医生列表' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="新增医生" subtitle="用于管理员端演示基础资料维护。">
        <form class="admin-form" @submit.prevent="createDoctor">
          <label>
            <span>医生姓名</span>
            <input v-model="createForm.realname" type="text" placeholder="请输入姓名" />
          </label>
          <label>
            <span>科室编码</span>
            <input v-model="createForm.dept_code" type="text" placeholder="如 SJWK" />
          </label>
          <label>
            <span>挂号级别编码</span>
            <input v-model="createForm.regist_level_code" type="text" placeholder="可选，如 ZJ" />
          </label>
          <label>
            <span>性别</span>
            <select v-model="createForm.gender">
              <option value="男">男</option>
              <option value="女">女</option>
            </select>
          </label>
          <label>
            <span>专长</span>
            <textarea v-model="createForm.expertise" rows="3" placeholder="如：脑部肿瘤、头痛、神经影像判读" />
          </label>
          <label>
            <span>AI 评分</span>
            <input v-model.number="createForm.ai_eval_score" type="number" min="0" max="5" step="0.1" />
          </label>
          <button type="submit" :disabled="creatingDoctor">
            {{ creatingDoctor ? '创建中...' : '创建医生' }}
          </button>
        </form>
      </SectionCard>
    </div>

    <SectionCard title="医生列表" subtitle="支持修改专长和调整 AI 评分。">
      <div v-if="doctors.length" class="doctor-list">
        <article v-for="doctor in doctors" :key="doctor.uuid" class="doctor-card">
          <div class="doctor-card__head">
            <div>
              <strong>{{ doctor.realname }}</strong>
              <p>{{ doctor.gender || '未知性别' }} | AI 评分 {{ doctor.ai_eval_score ?? '未记录' }}</p>
            </div>
            <span>{{ doctor.uuid }}</span>
          </div>

          <label class="doctor-card__field">
            <span>专长</span>
            <textarea v-model="expertiseDrafts[doctor.uuid]" rows="3" />
          </label>

          <div class="doctor-card__actions">
            <button type="button" :disabled="updatingExpertise === doctor.uuid" @click="saveExpertise(doctor)">
              {{ updatingExpertise === doctor.uuid ? '保存中...' : '保存专长' }}
            </button>

            <div class="doctor-card__score">
              <input v-model.number="scoreAdjustments[doctor.uuid]" type="number" step="0.1" min="-5" max="5" />
              <button type="button" :disabled="adjustingScore === doctor.uuid" @click="adjustScore(doctor)">
                {{ adjustingScore === doctor.uuid ? '调整中...' : '调整评分' }}
              </button>
            </div>
          </div>
        </article>
      </div>
      <div v-else class="admin-empty">当前科室下没有查到医生数据。</div>
    </SectionCard>
  </div>
</template>
