<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'

import { adminApi, type SchedulingApplicationRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const applications = ref<SchedulingApplicationRecord[]>([])
const loading = ref(false)
const workingUuid = ref('')
const rejectReasons = ref<Record<string, string>>({})

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
    await adminApi.approveSchedulingApplication(uuid)
    ElMessage.success('审批通过，已触发后续排班处理')
    await loadApplications()
  } finally {
    workingUuid.value = ''
  }
}

async function reject(uuid: string) {
  if (workingUuid.value) return
  workingUuid.value = uuid
  try {
    await adminApi.rejectSchedulingApplication(uuid, rejectReasons.value[uuid] || '')
    ElMessage.success('申请已驳回')
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
              <strong>{{ item.employee_uuid }}</strong>
              <span>{{ item.created_at?.replace('T', ' ').slice(0, 16) || '暂无创建时间' }}</span>
            </div>
            <em>{{ item.status }}</em>
          </div>

          <p>{{ item.prompt }}</p>

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
