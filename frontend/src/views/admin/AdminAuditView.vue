<script setup lang="ts">
import { computed, reactive, ref } from 'vue'

import { adminApi, type AuditLogPage, type AuditLogRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'
import { useAdminSessionStore } from '@/stores/adminSession'

const DEFAULT_LIMIT = 20
const session = useAdminSessionStore()

const loading = ref(false)
const detailLoading = ref(false)
const reviewSubmitting = ref(false)
const exporting = ref(false)
const logs = ref<AuditLogRecord[]>([])
const selectedDetail = ref<AuditLogRecord | null>(null)
const pagination = reactive({
  total: 0,
  limit: DEFAULT_LIMIT,
  offset: 0,
})
const summary = reactive({
  total_count: 0,
  validated_count: 0,
  pending_count: 0,
  review_pending_count: 0,
  review_approved_count: 0,
  review_rejected_count: 0,
})
const expandedUuid = ref<string | null>(null)
const configMessage = ref('')
const filters = reactive({
  module_name: '',
  source: '',
  validated: 'all',
  created_from: '',
  created_to: '',
})
const reviewForm = reactive({
  review_status: 'approved' as 'approved' | 'rejected',
  review_note: '',
})

const currentPage = computed(() => Math.floor(pagination.offset / pagination.limit) + 1)
const totalPages = computed(() => Math.max(1, Math.ceil(pagination.total / pagination.limit)))
const pageStart = computed(() => (pagination.total ? pagination.offset + 1 : 0))
const pageEnd = computed(() => Math.min(pagination.offset + logs.value.length, pagination.total))
const validatedRatio = computed(() => {
  const total = summary.total_count || pagination.total
  return total ? Math.round((summary.validated_count / total) * 100) : 0
})
const reviewApprovalRatio = computed(() => {
  const total = summary.total_count || pagination.total
  return total ? Math.round((summary.review_approved_count / total) * 100) : 0
})

async function search(resetPage = true) {
  if (resetPage) {
    pagination.offset = 0
  }

  loading.value = true
  try {
    const response = await adminApi.listAiAudits({
      module_name: filters.module_name.trim() || undefined,
      source: filters.source.trim() || undefined,
      validated: filters.validated === 'all' ? undefined : filters.validated === 'true',
      created_from: toApiDateTime(filters.created_from, false),
      created_to: toApiDateTime(filters.created_to, true),
      limit: pagination.limit,
      offset: pagination.offset,
    })
    applyAuditPage(response.data.data)
    configMessage.value = ''
  } catch {
    clearAuditState()
    configMessage.value = '审计日志查询失败，请检查 token 配置、后端服务或筛选条件。'
  } finally {
    loading.value = false
  }
}

function applyAuditPage(page: AuditLogPage | AuditLogRecord[] | undefined) {
  if (Array.isArray(page)) {
    logs.value = page
    pagination.total = page.length
    summary.total_count = page.length
    summary.validated_count = page.filter((item) => item.validated).length
    summary.pending_count = page.filter((item) => !item.validated).length
    return
  }

  logs.value = page?.items ?? []
  pagination.total = page?.pagination?.total ?? logs.value.length
  pagination.limit = page?.pagination?.limit ?? pagination.limit
  pagination.offset = page?.pagination?.offset ?? pagination.offset
  summary.total_count = page?.summary?.total_count ?? pagination.total
  summary.validated_count = page?.summary?.validated_count ?? logs.value.filter((item) => item.validated).length
  summary.pending_count = page?.summary?.pending_count ?? Math.max(summary.total_count - summary.validated_count, 0)
  summary.review_pending_count =
    page?.summary?.review_pending_count ?? logs.value.filter((item) => (item.review_status || 'pending') === 'pending').length
  summary.review_approved_count =
    page?.summary?.review_approved_count ?? logs.value.filter((item) => item.review_status === 'approved').length
  summary.review_rejected_count =
    page?.summary?.review_rejected_count ?? logs.value.filter((item) => item.review_status === 'rejected').length
}

function clearAuditState() {
  logs.value = []
  pagination.total = 0
  pagination.offset = 0
  summary.total_count = 0
  summary.validated_count = 0
  summary.pending_count = 0
  summary.review_pending_count = 0
  summary.review_approved_count = 0
  summary.review_rejected_count = 0
  expandedUuid.value = null
  selectedDetail.value = null
  reviewForm.review_status = 'approved'
  reviewForm.review_note = ''
}

function resetFilters() {
  filters.module_name = ''
  filters.source = ''
  filters.validated = 'all'
  filters.created_from = ''
  filters.created_to = ''
  search(true)
}

function changePage(direction: 'prev' | 'next') {
  const nextOffset =
    direction === 'prev'
      ? Math.max(pagination.offset - pagination.limit, 0)
      : Math.min(pagination.offset + pagination.limit, Math.max(pagination.total - 1, 0))

  if (nextOffset === pagination.offset) return
  pagination.offset = nextOffset
  search(false)
}

function updateLimit(event: Event) {
  const value = Number((event.target as HTMLSelectElement).value)
  pagination.limit = Number.isFinite(value) ? value : DEFAULT_LIMIT
  pagination.offset = 0
  search(false)
}

async function toggleDetail(item: AuditLogRecord) {
  if (expandedUuid.value === item.uuid) {
    expandedUuid.value = null
    selectedDetail.value = null
    reviewForm.review_note = ''
    return
  }

  expandedUuid.value = item.uuid
  selectedDetail.value = item
  detailLoading.value = true
  try {
    const response = await adminApi.getAiAuditDetail(item.uuid)
    selectedDetail.value = response.data.data
    primeReviewForm(response.data.data)
  } catch {
    selectedDetail.value = item
    primeReviewForm(item)
  } finally {
    detailLoading.value = false
  }
}

function asArray(value: unknown) {
  return Array.isArray(value) ? value : []
}

function formatDateTime(value?: string | null) {
  if (!value) return '暂无'
  return value.replace('T', ' ').slice(0, 19)
}

function toApiDateTime(value: string, endOfDay: boolean) {
  if (!value) return undefined
  return `${value}T${endOfDay ? '23:59:59' : '00:00:00'}`
}

function stringifyDetail(value: unknown) {
  if (value === null || value === undefined || value === '') return '无'
  if (typeof value === 'string') return value
  return JSON.stringify(value, null, 2)
}

function sourceLabel(source?: string | null) {
  const labels: Record<string, string> = {
    llm: '真实 LLM',
    rule: '规则引擎',
    mock: 'Mock',
    fallback: 'Fallback',
    embedding: 'Embedding',
  }
  return source ? labels[source] || source : '未知来源'
}

function reviewStatusLabel(status?: string | null) {
  const labels: Record<string, string> = {
    pending: '待人工复核',
    approved: '人工已通过',
    rejected: '人工已驳回',
  }
  return labels[status || 'pending'] || '待人工复核'
}

function primeReviewForm(item: AuditLogRecord) {
  reviewForm.review_status = item.review_status === 'rejected' ? 'rejected' : 'approved'
  reviewForm.review_note = item.review_note || ''
}

function currentReviewer() {
  return session.staff?.displayName?.trim() || session.staff?.staffCode?.trim() || 'ADMIN'
}

function currentFilters() {
  return {
    module_name: filters.module_name.trim() || undefined,
    source: filters.source.trim() || undefined,
    validated: filters.validated === 'all' ? undefined : filters.validated === 'true',
    created_from: toApiDateTime(filters.created_from, false),
    created_to: toApiDateTime(filters.created_to, true),
  }
}

async function submitReview() {
  if (!expandedUuid.value) return

  reviewSubmitting.value = true
  try {
    const response = await adminApi.reviewAiAudit(expandedUuid.value, {
      review_status: reviewForm.review_status,
      review_note: reviewForm.review_note.trim() || undefined,
      reviewer: currentReviewer(),
    })
    selectedDetail.value = response.data.data
    await search(false)
  } finally {
    reviewSubmitting.value = false
  }
}

async function exportCurrentAudits() {
  exporting.value = true
  try {
    const response = await adminApi.exportAiAudits(currentFilters())
    const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    const stamp = new Date().toISOString().replace(/[:T]/g, '-').slice(0, 19)
    link.href = url
    link.download = `ai-audits-${stamp}.csv`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
  } finally {
    exporting.value = false
  }
}

function detailValue(item: AuditLogRecord, field: keyof AuditLogRecord) {
  if (selectedDetail.value && selectedDetail.value.uuid === item.uuid) {
    return selectedDetail.value[field]
  }
  return item[field]
}

search()
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero audit-hero">
      <div>
        <span>证据链与可追溯</span>
        <h2>AI 审计与运行监控</h2>
        <p>只读查看 AI 输入输出摘要、模型来源、校验状态和运行上下文，不伪造审计记录。</p>
      </div>
      <div class="audit-hero__metrics">
        <div>
          <span>命中日志</span>
          <strong>{{ summary.total_count }}</strong>
        </div>
        <div>
          <span>待复核</span>
          <strong>{{ summary.pending_count }}</strong>
        </div>
        <div>
          <span>验证率</span>
          <strong>{{ validatedRatio }}%</strong>
        </div>
        <div>
          <span>人工通过率</span>
          <strong>{{ reviewApprovalRatio }}%</strong>
        </div>
      </div>
    </section>

    <SectionCard title="审计查询" subtitle="按模块、来源、校验状态和日期范围筛选 AI 运行证据。">
      <form class="audit-form" @submit.prevent="search(true)">
        <label>
          <span>模块名</span>
          <input
            v-model="filters.module_name"
            type="text"
            placeholder="patient.triage / medical.draft"
          />
        </label>
        <label>
          <span>来源</span>
          <input v-model="filters.source" type="text" placeholder="llm / rule / fallback" />
        </label>
        <label>
          <span>校验状态</span>
          <select v-model="filters.validated">
            <option value="all">全部</option>
            <option value="true">已验证</option>
            <option value="false">待复核</option>
          </select>
        </label>
        <label>
          <span>开始日期</span>
          <input v-model="filters.created_from" type="date" />
        </label>
        <label>
          <span>结束日期</span>
          <input v-model="filters.created_to" type="date" />
        </label>
        <div class="audit-form__actions">
          <button type="submit" :disabled="loading">
            {{ loading ? '查询中...' : '查询日志' }}
          </button>
          <button type="button" class="is-secondary" :disabled="exporting" @click="exportCurrentAudits">
            {{ exporting ? '导出中...' : '导出 CSV' }}
          </button>
          <button type="button" class="is-secondary" :disabled="loading" @click="resetFilters">
            重置
          </button>
        </div>
      </form>

      <p class="audit-note" :class="{ 'is-warning': Boolean(configMessage) }">
        {{
          configMessage ||
          '当前审计页直接使用管理员页面访问能力；后续再接真实后端登录鉴权。'
        }}
      </p>
    </SectionCard>

    <SectionCard title="审计记录" subtitle="点击单条记录查看脱敏后的上下文、warnings 和 validator messages。">
      <div class="audit-toolbar">
        <span>显示 {{ pageStart }}-{{ pageEnd }} / {{ pagination.total }}</span>
        <label>
          每页
          <select :value="pagination.limit" :disabled="loading" @change="updateLimit">
            <option :value="10">10</option>
            <option :value="20">20</option>
            <option :value="50">50</option>
            <option :value="100">100</option>
          </select>
        </label>
      </div>

      <div v-if="logs.length" class="audit-list">
        <article v-for="item in logs" :key="item.uuid" class="audit-card">
          <button type="button" class="audit-card__summary" @click="toggleDetail(item)">
            <div>
              <span class="audit-card__module">{{ item.module_name }}</span>
              <strong>{{ sourceLabel(item.source) }} · {{ item.model || '未记录模型' }}</strong>
              <p>{{ formatDateTime(item.created_at) }} · {{ item.latency_ms ? `${item.latency_ms} ms` : '未记录耗时' }}</p>
            </div>
            <div class="audit-card__badge-group">
              <span :class="['audit-card__badge', { 'is-pending': !item.validated }]">
                {{ item.validated ? '机器已验证' : '机器待校验' }}
              </span>
              <span :class="['audit-card__badge', 'is-review', `is-${item.review_status || 'pending'}`]">
                {{ reviewStatusLabel(item.review_status) }}
              </span>
            </div>
          </button>

          <div class="audit-card__content">
            <div>
              <span>输入摘要</span>
              <pre>{{ item.input_summary || '无' }}</pre>
            </div>
            <div>
              <span>输出摘要</span>
              <pre>{{ item.output_summary || '无' }}</pre>
            </div>
          </div>

          <div v-if="expandedUuid === item.uuid" class="audit-card__detail">
            <div v-if="detailLoading" class="audit-card__loading">详情加载中...</div>
            <div>
              <span>Warnings</span>
              <ul v-if="asArray(detailValue(item, 'warnings')).length">
                <li v-for="warning in asArray(detailValue(item, 'warnings'))" :key="String(warning)">{{ warning }}</li>
              </ul>
              <p v-else>无</p>
            </div>
            <div>
              <span>Validator Messages</span>
              <ul v-if="asArray(detailValue(item, 'validator_messages')).length">
                <li v-for="message in asArray(detailValue(item, 'validator_messages'))" :key="String(message)">{{ message }}</li>
              </ul>
              <p v-else>无</p>
            </div>
            <div class="audit-card__context">
              <span>Context</span>
              <pre>{{ stringifyDetail(detailValue(item, 'context')) }}</pre>
            </div>
            <div class="audit-card__review">
              <span>人工复核</span>
              <div class="audit-card__review-meta">
                <p>当前状态：{{ reviewStatusLabel(String(detailValue(item, 'review_status') || 'pending')) }}</p>
                <p>复核人：{{ detailValue(item, 'reviewer') || '未记录' }}</p>
                <p>复核时间：{{ formatDateTime(String(detailValue(item, 'reviewed_at') || '')) }}</p>
              </div>
              <div class="audit-card__review-actions">
                <label>
                  <span>复核结论</span>
                  <select v-model="reviewForm.review_status" :disabled="reviewSubmitting">
                    <option value="approved">通过</option>
                    <option value="rejected">驳回</option>
                  </select>
                </label>
                <label class="is-full">
                  <span>复核备注</span>
                  <textarea
                    v-model="reviewForm.review_note"
                    rows="4"
                    maxlength="1000"
                    placeholder="填写人工复核依据、风险结论或后续建议"
                    :disabled="reviewSubmitting"
                  />
                </label>
                <button type="button" :disabled="reviewSubmitting" @click="submitReview">
                  {{ reviewSubmitting ? '提交中...' : '提交复核' }}
                </button>
              </div>
            </div>
          </div>
        </article>
      </div>
      <div v-else class="admin-empty">当前没有命中的审计日志记录。</div>

      <div class="audit-pagination">
        <button type="button" :disabled="loading || currentPage <= 1" @click="changePage('prev')">上一页</button>
        <span>第 {{ currentPage }} / {{ totalPages }} 页</span>
        <button type="button" :disabled="loading || currentPage >= totalPages" @click="changePage('next')">下一页</button>
      </div>
    </SectionCard>
  </div>
</template>

<style scoped>
.audit-hero {
  display: flex;
  justify-content: space-between;
  gap: 20px;
}

.audit-hero__metrics {
  display: grid;
  grid-template-columns: repeat(4, minmax(96px, 1fr));
  gap: 10px;
  min-width: 460px;
}

.audit-hero__metrics div {
  padding: 14px;
  border-radius: var(--admin-radius-lg);
  border: 1px solid rgba(255, 255, 255, 0.28);
  background: rgba(255, 255, 255, 0.14);
}

.audit-hero__metrics span,
.audit-form span,
.audit-card__content span,
.audit-card__detail span {
  display: block;
  color: var(--admin-text-muted);
  font-size: 12px;
}

.audit-hero__metrics strong {
  display: block;
  margin-top: 6px;
  color: #ffffff;
  font-size: 24px;
}

.audit-form {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr)) auto;
  gap: 12px;
  align-items: end;
}

.audit-form label {
  display: grid;
  gap: 6px;
}

.audit-form input,
.audit-form select,
.audit-toolbar select {
  width: 100%;
  min-height: 38px;
  border: 1px solid var(--admin-border);
  border-radius: var(--admin-radius-sm);
  padding: 0 10px;
  color: var(--admin-text);
  background: #ffffff;
  font: inherit;
}

.audit-form__actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.audit-form button,
.audit-pagination button,
.audit-card__review-actions button {
  min-height: 38px;
  border: 0;
  border-radius: var(--admin-radius-sm);
  padding: 0 14px;
  background: var(--admin-accent);
  color: #ffffff;
  font: inherit;
  cursor: pointer;
}

.audit-form button.is-secondary,
.audit-pagination button {
  border: 1px solid var(--admin-border);
  background: #ffffff;
  color: var(--admin-text);
}

.audit-form button:disabled,
.audit-pagination button:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}

.audit-note {
  margin: 12px 0 0;
  color: var(--admin-text-muted);
  line-height: 1.6;
}

.audit-note.is-warning {
  color: #92400e;
}

.audit-toolbar,
.audit-pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
  color: var(--admin-text-muted);
}

.audit-toolbar label {
  display: flex;
  align-items: center;
  gap: 8px;
}

.audit-list {
  display: grid;
  gap: 12px;
}

.audit-card {
  border: 1px solid var(--admin-border);
  border-radius: var(--admin-radius-lg);
  background: #ffffff;
  overflow: hidden;
}

.audit-card__summary {
  width: 100%;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  border: 0;
  padding: 16px;
  text-align: left;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  cursor: pointer;
}

.audit-card__summary strong {
  display: block;
  margin-top: 4px;
  color: var(--admin-text);
}

.audit-card__summary p {
  margin: 4px 0 0;
  color: var(--admin-text-muted);
}

.audit-card__module {
  color: var(--admin-accent);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.audit-card__badge {
  flex: 0 0 auto;
  border-radius: 999px;
  padding: 6px 10px;
  background: #dcfce7;
  color: #166534;
  font-size: 12px;
  font-weight: 700;
}

.audit-card__badge.is-pending {
  background: var(--admin-warn-soft);
  color: #92400e;
}

.audit-card__badge-group {
  display: grid;
  gap: 8px;
  justify-items: end;
}

.audit-card__badge.is-review {
  background: #e0f2fe;
  color: #0369a1;
}

.audit-card__badge.is-review.is-pending {
  background: #fef3c7;
  color: #92400e;
}

.audit-card__badge.is-review.is-approved {
  background: #dcfce7;
  color: #166534;
}

.audit-card__badge.is-review.is-rejected {
  background: #fee2e2;
  color: #b91c1c;
}

.audit-card__content,
.audit-card__detail {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  padding: 14px 16px 16px;
}

.audit-card__detail {
  border-top: 1px solid var(--admin-border);
  background: #f8fafc;
}

.audit-card__context {
  grid-column: 1 / -1;
}

.audit-card__review {
  grid-column: 1 / -1;
  display: grid;
  gap: 10px;
  padding-top: 4px;
}

.audit-card__review-meta {
  display: grid;
  gap: 4px;
  color: var(--admin-text-muted);
}

.audit-card__review-meta p {
  margin: 0;
}

.audit-card__review-actions {
  display: grid;
  grid-template-columns: 220px 1fr auto;
  gap: 12px;
  align-items: end;
}

.audit-card__review-actions label {
  display: grid;
  gap: 6px;
}

.audit-card__review-actions label.is-full {
  grid-column: auto;
}

.audit-card__review-actions select,
.audit-card__review-actions textarea {
  width: 100%;
  border: 1px solid var(--admin-border);
  border-radius: var(--admin-radius-sm);
  padding: 10px;
  color: var(--admin-text);
  background: #ffffff;
  font: inherit;
}

.audit-card__review-actions textarea {
  resize: vertical;
  min-height: 108px;
}

.audit-card__loading {
  grid-column: 1 / -1;
  color: var(--admin-text-muted);
}

.audit-card pre {
  margin: 6px 0 0;
  max-height: 220px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
  border-radius: var(--admin-radius-md);
  background: #0f172a;
  color: #e2e8f0;
  padding: 12px;
  font-size: 12px;
  line-height: 1.55;
}

.audit-card ul,
.audit-card__detail p {
  margin: 6px 0 0;
  color: var(--admin-text);
}

.audit-pagination {
  margin: 16px 0 0;
}

@media (max-width: 1180px) {
  .audit-form {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .audit-form__actions {
    grid-column: 1 / -1;
  }
}

@media (max-width: 820px) {
  .audit-hero {
    display: grid;
  }

  .audit-hero__metrics {
    min-width: 0;
    grid-template-columns: 1fr;
  }

  .audit-card__content,
  .audit-card__detail {
    grid-template-columns: 1fr;
  }

  .audit-card__review-actions {
    grid-template-columns: 1fr;
  }
}
</style>
