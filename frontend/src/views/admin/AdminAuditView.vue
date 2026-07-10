<script setup lang="ts">
import { computed, reactive, ref } from 'vue'

import { adminApi, type AuditLogRecord } from '@/api/admin'
import SectionCard from '@/components/common/SectionCard.vue'

const loading = ref(false)
const logs = ref<AuditLogRecord[]>([])
const configMessage = ref('')
const filters = reactive({
  module_name: '',
  source: '',
  validated: 'all',
  limit: 20,
})

const tokenConfigured = computed(() => Boolean(import.meta.env.VITE_ADMIN_API_TOKEN?.trim()))

async function search() {
  if (!tokenConfigured.value) {
    logs.value = []
    configMessage.value = '当前后端未配置 AI 审计管理员 token，审计页已进入只读提示状态。'
    return
  }

  loading.value = true
  try {
    const response = await adminApi.listAiAudits({
      module_name: filters.module_name.trim() || undefined,
      source: filters.source.trim() || undefined,
      validated:
        filters.validated === 'all'
          ? undefined
          : filters.validated === 'true',
      limit: filters.limit,
    })
    logs.value = response.data.data ?? []
    configMessage.value = ''
  } catch {
    logs.value = []
    configMessage.value = '审计日志查询失败，请检查 token 配置或接口状态。'
  } finally {
    loading.value = false
  }
}

function asArray(value: unknown) {
  return Array.isArray(value) ? value : []
}

search()
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>证据链与可追溯性</span>
        <h2>AI 审计与运行监控</h2>
        <p>突出 AI 输出、校验结果、人工复核痕迹和模型来源，服务答辩要求。</p>
      </div>
    </section>

    <SectionCard title="审计查询" subtitle="需要后端配置审计管理员 token 才能正常访问。">
      <form class="audit-form" @submit.prevent="search">
        <label>
          <span>模块名</span>
          <input
            v-model="filters.module_name"
            type="text"
            placeholder="如 triage / scheduling / prescription"
            :disabled="!tokenConfigured"
          />
        </label>
        <label>
          <span>来源</span>
          <input v-model="filters.source" type="text" placeholder="如 llm / fallback" :disabled="!tokenConfigured" />
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
          <span>查询条数</span>
          <input v-model.number="filters.limit" type="number" min="1" max="50" :disabled="!tokenConfigured" />
        </label>
        <button type="submit" :disabled="loading || !tokenConfigured">
          {{ tokenConfigured ? (loading ? '查询中...' : '查询日志') : '等待配置' }}
        </button>
      </form>

      <p class="audit-note" :class="{ 'is-warning': !tokenConfigured || Boolean(configMessage) }">
        {{
          configMessage ||
          (tokenConfigured
            ? '当前已检测到 VITE_ADMIN_API_TOKEN，可直接联调审计接口。'
            : '当前未检测到 VITE_ADMIN_API_TOKEN，审计页将不主动请求接口。')
        }}
      </p>
    </SectionCard>

    <SectionCard title="审计记录" subtitle="真实接口优先，空态时不伪造 AI 日志。">
      <div v-if="logs.length" class="audit-list">
        <article v-for="item in logs" :key="item.uuid" class="audit-card">
          <div class="audit-card__head">
            <div>
              <strong>{{ item.module_name }}</strong>
              <p>{{ item.source || '未知来源' }} · {{ item.model || '未记录模型' }}</p>
            </div>
            <span :class="['audit-card__badge', { 'is-pending': !item.validated }]">
              {{ item.validated ? '已验证' : '待复核' }}
            </span>
          </div>

          <dl class="audit-card__meta">
            <div>
              <dt>时间</dt>
              <dd>{{ item.created_at?.replace('T', ' ').slice(0, 19) || '暂无' }}</dd>
            </div>
            <div>
              <dt>耗时</dt>
              <dd>{{ item.latency_ms ? `${item.latency_ms} ms` : '未记录' }}</dd>
            </div>
          </dl>

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

          <div class="audit-card__foot">
            <div v-if="asArray(item.warnings).length">
              <span>Warnings</span>
              <ul>
                <li v-for="warning in asArray(item.warnings)" :key="String(warning)">{{ warning }}</li>
              </ul>
            </div>
            <div v-if="asArray(item.validator_messages).length">
              <span>Validator Messages</span>
              <ul>
                <li v-for="message in asArray(item.validator_messages)" :key="String(message)">{{ message }}</li>
              </ul>
            </div>
          </div>
        </article>
      </div>
      <div v-else class="admin-empty">当前没有命中的审计日志记录。</div>
    </SectionCard>
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
  border: 1px solid rgba(16, 185, 129, 0.2);
  background: linear-gradient(135deg, #ecfeff, #ffffff 68%);
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
  color: #0f766e;
  font-size: 13px;
  font-weight: 700;
}

.admin-page__hero p {
  margin-top: 8px;
  color: #475569;
}

.audit-form {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 12px;
}

.audit-form label {
  display: grid;
  gap: 8px;
}

.audit-form span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.audit-form input,
.audit-form select,
.audit-form button {
  min-height: 42px;
  padding: 0 14px;
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
}

.audit-form button {
  align-self: end;
  border: 0;
  background: linear-gradient(135deg, #0f766e, #0891b2);
  color: #ffffff;
  font-weight: 700;
}

.audit-note {
  margin: 14px 0 0;
  color: #0f766e;
  line-height: 1.6;
}

.audit-note.is-warning {
  color: #b45309;
}

.audit-list {
  display: grid;
  gap: 14px;
}

.audit-card {
  display: grid;
  gap: 14px;
  padding: 18px;
  border-radius: 16px;
  border: 1px solid #dbeafe;
  background: #f8fbff;
}

.audit-card__head,
.audit-card__meta {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.audit-card__head strong,
.audit-card__head p {
  margin: 0;
}

.audit-card__head p {
  margin-top: 4px;
  color: #475569;
}

.audit-card__badge {
  padding: 6px 10px;
  border-radius: 999px;
  background: #dcfce7;
  color: #166534;
  font-size: 12px;
  font-weight: 700;
}

.audit-card__badge.is-pending {
  background: #fff7ed;
  color: #c2410c;
}

.audit-card__meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.audit-card__meta div {
  display: grid;
  gap: 4px;
  padding: 12px;
  border-radius: 12px;
  background: #ffffff;
}

.audit-card__meta dt {
  color: #64748b;
  font-size: 12px;
}

.audit-card__meta dd {
  margin: 0;
  color: #0f172a;
  font-weight: 700;
}

.audit-card__content {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.audit-card__content div,
.audit-card__foot div {
  display: grid;
  gap: 8px;
}

.audit-card__content span,
.audit-card__foot span {
  color: #334155;
  font-size: 13px;
  font-weight: 700;
}

.audit-card__content pre {
  margin: 0;
  min-height: 120px;
  padding: 14px;
  border-radius: 12px;
  background: #ffffff;
  color: #0f172a;
  white-space: pre-wrap;
  word-break: break-word;
}

.audit-card__foot {
  display: grid;
  gap: 12px;
}

.audit-card__foot ul {
  margin: 0;
  padding-left: 18px;
  color: #475569;
}

.admin-empty {
  padding: 18px;
  border-radius: 14px;
  background: #f8fafc;
  color: #64748b;
}

@media (max-width: 980px) {
  .audit-form,
  .audit-card__content {
    grid-template-columns: 1fr;
  }
}
</style>
