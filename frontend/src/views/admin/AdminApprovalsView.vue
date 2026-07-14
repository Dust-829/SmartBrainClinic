<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'

import { adminApi, type SchedulingApplicationRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const applications = ref<SchedulingApplicationRecord[]>([])
const loading = ref(false)
const workingUuid = ref('')
const rejectReasons = ref<Record<string, string>>({})

function formatDateTime(value?: string | null) {
  if (!value) return '暂无创建时间'
  return value.replace('T', ' ').slice(0, 16)
}

function formatApplicant(item: SchedulingApplicationRecord) {
  return [item.employee_name, item.dept_name].filter(Boolean).join(' · ') || item.employee_uuid
}

async function loadApplications() {
  loading.value = true
  try {
    const response = await adminApi.listPendingApplications()
    applications.value = response.data.data ?? []
  } catch {
    applications.value = []
  } finally {
    loading.value = false
  }
}

async function approve(uuid: string) {
  if (workingUuid.value) return
  workingUuid.value = uuid
  try {
    const response = await adminApi.approveSchedulingApplication(uuid)
    const result = response.data.data
    const applied = typeof result.ai_result === 'object' && result.ai_result && 'actions_applied' in result.ai_result
      ? (result.ai_result as { actions_applied?: number }).actions_applied ?? 0
      : 0
    ElMessage.success(`审批通过，已应用 ${applied} 个排班动作`)
    await loadApplications()
  } finally {
    workingUuid.value = ''
  }
}

async function reject(uuid: string) {
  if (workingUuid.value) return
  workingUuid.value = uuid
  try {
    const response = await adminApi.rejectSchedulingApplication(uuid, rejectReasons.value[uuid] || '')
    const result = response.data.data
    ElMessage.success(`申请已驳回${result.reject_reason ? `：${result.reject_reason}` : ''}`)
    await loadApplications()
  } finally {
    workingUuid.value = ''
  }
}

loadApplications()
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>人工审核入口</span>
        <h2>审批中心</h2>
        <p>集中处理排班申请，体现 AI 建议和人工确认分离的后台职责。</p>
      </div>
      <button type="button" :disabled="loading" @click="loadApplications">
        {{ loading ? '刷新中...' : '刷新审批列表' }}
      </button>
    </section>

    <SectionCard title="待审批排班申请" subtitle="当前基于真实待审批接口构建。">
      <div v-if="applications.length" class="approval-list">
        <article v-for="item in applications" :key="item.uuid" class="approval-card">
          <div class="approval-card__head">
            <div>
              <strong>{{ item.prompt_title || '排班调整申请' }}</strong>
              <span>{{ formatApplicant(item) }}</span>
            </div>
            <em>{{ item.status_text || item.status }}</em>
          </div>

          <p>{{ item.prompt_excerpt || item.prompt_display || item.prompt }}</p>
          <p class="approval-card__meta">
            {{ [item.time_hint, formatDateTime(item.created_at)].filter(Boolean).join(' | ') }}
          </p>
          <p class="approval-card__raw">原始请求：{{ item.prompt_display || item.prompt }}</p>

          <label class="approval-card__field">
            <span>驳回原因</span>
            <textarea
              v-model="rejectReasons[item.uuid]"
              rows="3"
              placeholder="如需驳回，可填写手术冲突、诊室冲突、排班过密等原因"
            />
          </label>

          <div class="approval-card__actions">
            <button type="button" class="is-approve" :disabled="workingUuid === item.uuid" @click="approve(item.uuid)">
              {{ workingUuid === item.uuid ? '处理中...' : '审批通过' }}
            </button>
            <button type="button" class="is-reject" :disabled="workingUuid === item.uuid" @click="reject(item.uuid)">
              {{ workingUuid === item.uuid ? '处理中...' : '驳回申请' }}
            </button>
          </div>
        </article>
      </div>
      <div v-else class="admin-empty">当前没有待审批申请。</div>
    </SectionCard>
  </div>
</template>
