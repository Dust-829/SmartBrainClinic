<script setup lang="ts">
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

import { adminApi, type SchedulingApplicationRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const generating = ref(false)
const adjustingAi = ref(false)
const updatingRule = ref(false)
const updatingActual = ref(false)
const loadingApplications = ref(false)
const applications = ref<SchedulingApplicationRecord[]>([])
const lastResult = ref('')

const generateForm = reactive({
  start_date: new Date().toISOString().slice(0, 10),
  end_date: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
})

const aiForm = reactive({
  employee_uuid: '',
  prompt: '',
})

const ruleForm = reactive({
  employee_uuid: '',
  rule_name: '管理员人工规则',
  week_rule: '1,2,3,4,5',
  llm_text_rule: '管理员后台人工干预排班规则',
  regist_quota: 20,
  clinic_room_uuid: '',
})

const actualForm = reactive({
  employee_uuid: '',
  schedule_date: new Date().toISOString().slice(0, 10),
  noon: '上午',
  regist_quota: 20,
  clinic_room_uuid: '',
})

async function loadApplications() {
  loadingApplications.value = true
  try {
    const response = await adminApi.listPendingApplications()
    applications.value = response.data.data ?? []
  } catch {
    applications.value = []
  } finally {
    loadingApplications.value = false
  }
}

async function submitGenerate() {
  generating.value = true
  try {
    const response = await adminApi.generateSchedule(generateForm)
    const result = response.data.data
    lastResult.value = `已生成 ${result.generated_count} 条排班记录，时间范围 ${result.start_date} 至 ${result.end_date}`
    ElMessage.success('常规排班生成完成')
  } finally {
    generating.value = false
  }
}

async function submitAiAdjust() {
  adjustingAi.value = true
  try {
    const response = await adminApi.adjustScheduleWithAi(aiForm)
    const result = response.data.data
    lastResult.value = `AI 微调已执行：${JSON.stringify(result, null, 2)}`
    ElMessage.success('AI 排班微调已提交')
  } finally {
    adjustingAi.value = false
  }
}

async function submitRuleUpdate() {
  updatingRule.value = true
  try {
    await adminApi.updateSchedulingRule({
      ...ruleForm,
      clinic_room_uuid: ruleForm.clinic_room_uuid.trim() || undefined,
    })
    lastResult.value = `已更新医生 ${ruleForm.employee_uuid} 的排班规则`
    ElMessage.success('排班规则已更新')
  } finally {
    updatingRule.value = false
  }
}

async function submitActualUpdate() {
  updatingActual.value = true
  try {
    await adminApi.updateSchedulingActual({
      ...actualForm,
      clinic_room_uuid: actualForm.clinic_room_uuid.trim() || undefined,
    })
    lastResult.value = `已调整 ${actualForm.schedule_date} ${actualForm.noon} 的实际排班`
    ElMessage.success('实际排班已调整')
  } finally {
    updatingActual.value = false
  }
}

loadApplications()
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>管理员端主打模块</span>
        <h2>智能排班中心</h2>
        <p>突出 AI 生成建议、人工规则干预、实际排班调整和审批链路。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="常规排班生成" subtitle="按时间范围批量生成门诊实际排班。">
        <form class="admin-form" @submit.prevent="submitGenerate">
          <label>
            <span>开始日期</span>
            <input v-model="generateForm.start_date" type="date" />
          </label>
          <label>
            <span>结束日期</span>
            <input v-model="generateForm.end_date" type="date" />
          </label>
          <button type="submit" :disabled="generating">
            {{ generating ? '生成中...' : '生成排班' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="AI 排班微调" subtitle="基于医生工号和文本规则触发 AI 调整。">
        <form class="admin-form" @submit.prevent="submitAiAdjust">
          <label>
            <span>医生 UUID</span>
            <input v-model="aiForm.employee_uuid" type="text" placeholder="请输入 employee_uuid" />
          </label>
          <label>
            <span>微调指令</span>
            <textarea
              v-model="aiForm.prompt"
              rows="4"
              placeholder="例如：该医生本周三下午有手术，请改到周四下午坐诊"
            />
          </label>
          <button type="submit" :disabled="adjustingAi">
            {{ adjustingAi ? '提交中...' : '提交 AI 微调' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="管理员规则干预" subtitle="直接覆盖医生排班规则和号源配置。">
        <form class="admin-form" @submit.prevent="submitRuleUpdate">
          <label>
            <span>医生 UUID</span>
            <input v-model="ruleForm.employee_uuid" type="text" />
          </label>
          <label>
            <span>规则名称</span>
            <input v-model="ruleForm.rule_name" type="text" />
          </label>
          <label>
            <span>周规则</span>
            <input v-model="ruleForm.week_rule" type="text" placeholder="1,2,3,4,5" />
          </label>
          <label>
            <span>自然语言规则</span>
            <textarea v-model="ruleForm.llm_text_rule" rows="3" />
          </label>
          <label>
            <span>号源数量</span>
            <input v-model.number="ruleForm.regist_quota" type="number" min="0" />
          </label>
          <label>
            <span>诊室 UUID（可选）</span>
            <input v-model="ruleForm.clinic_room_uuid" type="text" />
          </label>
          <button type="submit" :disabled="updatingRule">
            {{ updatingRule ? '保存中...' : '保存规则' }}
          </button>
        </form>
      </SectionCard>

      <SectionCard title="实际排班调整" subtitle="用于当天排班修正、停诊或诊室变更。">
        <form class="admin-form" @submit.prevent="submitActualUpdate">
          <label>
            <span>医生 UUID</span>
            <input v-model="actualForm.employee_uuid" type="text" />
          </label>
          <label>
            <span>日期</span>
            <input v-model="actualForm.schedule_date" type="date" />
          </label>
          <label>
            <span>午别</span>
            <select v-model="actualForm.noon">
              <option value="上午">上午</option>
              <option value="下午">下午</option>
            </select>
          </label>
          <label>
            <span>号源数量</span>
            <input v-model.number="actualForm.regist_quota" type="number" min="0" />
          </label>
          <label>
            <span>诊室 UUID（可选）</span>
            <input v-model="actualForm.clinic_room_uuid" type="text" />
          </label>
          <button type="submit" :disabled="updatingActual">
            {{ updatingActual ? '更新中...' : '更新实际排班' }}
          </button>
        </form>
      </SectionCard>
    </div>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="待审批排班申请" subtitle="和审批中心保持联通，便于这里先看到排班压力。">
        <template #extra>
          <button type="button" class="admin-inline-button" :disabled="loadingApplications" @click="loadApplications">
            {{ loadingApplications ? '刷新中...' : '刷新申请' }}
          </button>
        </template>

        <div v-if="applications.length" class="admin-list">
          <article v-for="item in applications" :key="item.uuid" class="admin-list__item">
            <strong>{{ item.employee_uuid }}</strong>
            <p>{{ item.prompt }}</p>
            <span>{{ item.created_at?.replace('T', ' ').slice(0, 16) || '暂无创建时间' }}</span>
          </article>
        </div>
        <div v-else class="admin-empty">当前没有待审批排班申请。</div>
      </SectionCard>

      <SectionCard title="最近操作结果" subtitle="便于演示时直接看到管理员动作是否生效。">
        <pre class="admin-result">{{ lastResult || '尚未执行排班类操作。' }}</pre>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.admin-page {
  display: grid;
  gap: 20px;
}

.admin-page__hero {
  padding: 24px;
  border-radius: 24px;
  background: linear-gradient(135deg, #e0e7ff, #ffffff 68%);
  border: 1px solid rgba(129, 140, 248, 0.2);
}

.admin-page__hero h2,
.admin-page__hero p {
  margin: 0;
}

.admin-page__hero h2 {
  margin-top: 6px;
  font-size: 28px;
}

.admin-page__hero span {
  color: #4f46e5;
  font-size: 13px;
  font-weight: 700;
}

.admin-page__hero p {
  margin-top: 8px;
  color: #475569;
  line-height: 1.7;
}

.admin-page__grid {
  display: grid;
  gap: 16px;
}

.admin-page__grid.is-two-column {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.admin-form {
  display: grid;
  gap: 12px;
}

.admin-form label {
  display: grid;
  gap: 8px;
}

.admin-form span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.admin-form input,
.admin-form textarea,
.admin-form select,
.admin-form button,
.admin-inline-button {
  min-height: 42px;
  padding: 0 14px;
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
}

.admin-form textarea {
  min-height: 108px;
  padding-top: 12px;
  padding-bottom: 12px;
  resize: vertical;
}

.admin-form button,
.admin-inline-button {
  border: 0;
  background: linear-gradient(135deg, #4338ca, #2563eb);
  color: #ffffff;
  font-weight: 700;
}

.admin-list {
  display: grid;
  gap: 12px;
}

.admin-list__item {
  display: grid;
  gap: 6px;
  padding: 14px;
  border-radius: 14px;
  border: 1px solid #dbeafe;
  background: #f8fbff;
}

.admin-list__item p,
.admin-list__item span,
.admin-result {
  margin: 0;
  color: #475569;
  line-height: 1.6;
}

.admin-list__item span {
  font-size: 12px;
}

.admin-empty,
.admin-result {
  padding: 16px;
  border-radius: 14px;
  background: #f8fafc;
}

.admin-result {
  min-height: 180px;
  white-space: pre-wrap;
  word-break: break-word;
}

@media (max-width: 960px) {
  .admin-page__grid.is-two-column {
    grid-template-columns: 1fr;
  }
}
</style>
