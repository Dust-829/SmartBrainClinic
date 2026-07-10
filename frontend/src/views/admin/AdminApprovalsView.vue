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

<style scoped>
.admin-page {
  display: grid;
  gap: 20px;
}

.admin-page__hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  padding: 24px;
  border-radius: 24px;
  border: 1px solid rgba(251, 191, 36, 0.24);
  background: linear-gradient(135deg, #fffbeb, #ffffff 68%);
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
  color: #b45309;
  font-size: 13px;
  font-weight: 700;
}

.admin-page__hero p {
  margin-top: 8px;
  color: #475569;
}

.admin-page__hero button,
.approval-card__actions button {
  min-height: 42px;
  padding: 0 16px;
  border: 0;
  border-radius: 12px;
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.admin-page__hero button,
.approval-card__actions .is-approve {
  background: linear-gradient(135deg, #2563eb, #4338ca);
}

.approval-list {
  display: grid;
  gap: 14px;
}

.approval-card {
  display: grid;
  gap: 12px;
  padding: 18px;
  border-radius: 16px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.approval-card__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.approval-card__head strong,
.approval-card__head span,
.approval-card p {
  display: block;
  margin: 0;
}

.approval-card__head span {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
}

.approval-card__head em {
  color: #92400e;
  font-style: normal;
  font-weight: 700;
}

.approval-card p {
  color: #475569;
  line-height: 1.7;
}

.approval-card__field {
  display: grid;
  gap: 8px;
}

.approval-card__field span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.approval-card__field textarea {
  min-height: 88px;
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  resize: vertical;
  font: inherit;
}

.approval-card__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.approval-card__actions .is-reject {
  background: linear-gradient(135deg, #dc2626, #b91c1c);
}

.admin-empty {
  padding: 18px;
  border-radius: 14px;
  background: #f8fafc;
  color: #64748b;
}

@media (max-width: 760px) {
  .admin-page__hero {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
