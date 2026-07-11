<script setup lang="ts">
import { computed, reactive, ref } from 'vue'

import { adminApi, type AuditLogPage, type AuditLogRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const DEFAULT_LIMIT = 20

const loading = ref(false)
const logs = ref<AuditLogRecord[]>([])
const pagination = reactive({
  total: 0,
  limit: DEFAULT_LIMIT,
  offset: 0,
})
const summary = reactive({
  total_count: 0,
  validated_count: 0,
  pending_count: 0,
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

const tokenConfigured = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))
const currentPage = computed(() => Math.floor(pagination.offset / pagination.limit) + 1)
const totalPages = computed(() => Math.max(1, Math.ceil(pagination.total / pagination.limit)))
const pageStart = computed(() => (pagination.total ? pagination.offset + 1 : 0))
const pageEnd = computed(() => Math.min(pagination.offset + logs.value.length, pagination.total))
const validatedRatio = computed(() => {
  const total = summary.total_count || pagination.total
  return total ? Math.round((summary.validated_count / total) * 100) : 0
})

async function search(resetPage = true) {
  if (!tokenConfigured.value) {
    clearAuditState()
    configMessage.value = '当前未配置 VITE_ADMIN_API_TOKEN，审计页仅显示配置提示。'
    return
  }

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
}

function clearAuditState() {
  logs.value = []
  pagination.total = 0
  pagination.offset = 0
  summary.total_count = 0
  summary.validated_count = 0
  summary.pending_count = 0
  expandedUuid.value = null
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

function toggleDetail(uuid: string) {
  expandedUuid.value = expandedUuid.value === uuid ? null : uuid
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
            :disabled="!tokenConfigured"
          />
        </label>
        <label>
          <span>来源</span>
          <input v-model="filters.source" type="text" placeholder="llm / rule / fallback" :disabled="!tokenConfigured" />
        </label>
        <label>
          <span>校验状态</span>
          <select v-model="filters.validated" :disabled="!tokenConfigured">
            <option value="all">全部</option>
            <option value="true">已验证</option>
            <option value="false">待复核</option>
          </select>
        </label>
        <label>
          <span>开始日期</span>
          <input v-model="filters.created_from" type="date" :disabled="!tokenConfigured" />
        </label>
        <label>
          <span>结束日期</span>
          <input v-model="filters.created_to" type="date" :disabled="!tokenConfigured" />
        </label>
        <div class="audit-form__actions">
          <button type="submit" :disabled="loading || !tokenConfigured">
            {{ tokenConfigured ? (loading ? '查询中...' : '查询日志') : '等待配置' }}
          </button>
          <button type="button" class="is-secondary" :disabled="loading || !tokenConfigured" @click="resetFilters">
            重置
          </button>
        </div>
      </form>

      <p class="audit-note" :class="{ 'is-warning': !tokenConfigured || Boolean(configMessage) }">
        {{
          configMessage ||
          (tokenConfigured
            ? '已检测到 VITE_ADMIN_API_TOKEN。审计查询只读，不会修改复核状态。'
            : '当前未检测到 VITE_ADMIN_API_TOKEN，审计页不会主动请求接口。')
        }}
      </p>
    </SectionCard>

    <SectionCard title="审计记录" subtitle="点击单条记录查看脱敏后的上下文、warnings 和 validator messages。">
      <div class="audit-toolbar">
        <span>显示 {{ pageStart }}-{{ pageEnd }} / {{ pagination.total }}</span>
        <label>
          每页
          <select :value="pagination.limit" :disabled="loading || !tokenConfigured" @change="updateLimit">
            <option :value="10">10</option>
            <option :value="20">20</option>
            <option :value="50">50</option>
            <option :value="100">100</option>
          </select>
        </label>
      </div>

      <div v-if="logs.length" class="audit-list">
        <article v-for="item in logs" :key="item.uuid" class="audit-card">
          <button type="button" class="audit-card__summary" @click="toggleDetail(item.uuid)">
            <div>
              <span class="audit-card__module">{{ item.module_name }}</span>
              <strong>{{ sourceLabel(item.source) }} · {{ item.model || '未记录模型' }}</strong>
              <p>{{ formatDateTime(item.created_at) }} · {{ item.latency_ms ? `${item.latency_ms} ms` : '未记录耗时' }}</p>
            </div>
            <span :class="['audit-card__badge', { 'is-pending': !item.validated }]">
              {{ item.validated ? '已验证' : '待复核' }}
            </span>
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
            <div>
              <span>Warnings</span>
              <ul v-if="asArray(item.warnings).length">
                <li v-for="warning in asArray(item.warnings)" :key="String(warning)">{{ warning }}</li>
              </ul>
              <p v-else>无</p>
            </div>
            <div>
              <span>Validator Messages</span>
              <ul v-if="asArray(item.validator_messages).length">
                <li v-for="message in asArray(item.validator_messages)" :key="String(message)">{{ message }}</li>
              </ul>
              <p v-else>无</p>
            </div>
            <div class="audit-card__context">
              <span>Context</span>
              <pre>{{ stringifyDetail(item.context) }}</pre>
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
  grid-template-columns: repeat(3, minmax(96px, 1fr));
  gap: 10px;
  min-width: 360px;
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
}

.audit-form button,
.audit-pagination button {
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
}
</style>
