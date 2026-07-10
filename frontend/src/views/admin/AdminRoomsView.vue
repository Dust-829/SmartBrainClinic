<script setup lang="ts">
import { reactive, ref } from 'vue'

import { authApi, type ClinicRoomRecord } from '@/api/auth'
import SectionCard from '@/components/common/SectionCard.vue'

const loadingByName = ref(false)
const loadingByUuid = ref(false)
const roomByName = ref<ClinicRoomRecord | null>(null)
const roomByUuid = ref<ClinicRoomRecord | null>(null)

const roomNameForm = reactive({
  room_name: '',
})

const roomUuidForm = reactive({
  room_uuid: '',
})

async function loadRoomByName() {
  loadingByName.value = true
  try {
    const response = await authApi.getClinicRoomByName(roomNameForm.room_name.trim())
    roomByName.value = response.data.data ?? null
  } catch {
    roomByName.value = null
  } finally {
    loadingByName.value = false
  }
}

async function loadRoomByUuid() {
  loadingByUuid.value = true
  try {
    const response = await authApi.getClinicRoom(roomUuidForm.room_uuid.trim())
    roomByUuid.value = response.data.data ?? null
  } catch {
    roomByUuid.value = null
  } finally {
    loadingByUuid.value = false
  }
}

</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>基础资料中心</span>
        <h2>诊室与检查室资源</h2>
        <p>按规划文档补齐资源配置入口，先用现有诊室查询接口支撑管理员端资源视图。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="按名称查询诊室" subtitle="适合演示 CT 室、门诊诊室、检查室等资源对象。">
        <form class="admin-form" @submit.prevent="loadRoomByName">
          <label>
            <span>诊室名称</span>
            <input v-model="roomNameForm.room_name" type="text" placeholder="如 CT一室" />
          </label>
          <button type="submit" :disabled="loadingByName">
            {{ loadingByName ? '查询中...' : '按名称查询' }}
          </button>
        </form>

        <div v-if="roomByName" class="room-card">
          <strong>{{ roomByName.room_name }}</strong>
          <p>诊室 UUID：{{ roomByName.uuid }}</p>
          <p>诊室编码：{{ roomByName.room_code || '未记录' }}</p>
          <p>科室 ID：{{ roomByName.dept_id ?? '未记录' }}</p>
        </div>
        <div v-else class="admin-empty">请输入诊室名称后再查询，避免默认请求命中 404。</div>
      </SectionCard>

      <SectionCard title="按 UUID 查询诊室" subtitle="便于与排班、医生、检查资源做精确关联。">
        <form class="admin-form" @submit.prevent="loadRoomByUuid">
          <label>
            <span>诊室 UUID</span>
            <input v-model="roomUuidForm.room_uuid" type="text" placeholder="请输入 room uuid" />
          </label>
          <button type="submit" :disabled="loadingByUuid">
            {{ loadingByUuid ? '查询中...' : '按 UUID 查询' }}
          </button>
        </form>

        <div v-if="roomByUuid" class="room-card">
          <strong>{{ roomByUuid.room_name }}</strong>
          <p>诊室 UUID：{{ roomByUuid.uuid }}</p>
          <p>诊室编码：{{ roomByUuid.room_code || '未记录' }}</p>
          <p>科室 ID：{{ roomByUuid.dept_id ?? '未记录' }}</p>
        </div>
        <div v-else class="admin-empty">输入 UUID 后可查看精确诊室资料。</div>
      </SectionCard>
    </div>

    <SectionCard title="资源配置说明" subtitle="这一页当前先以查询与展示为主，不额外创造不存在的房间维护接口。">
      <div class="resource-guide">
        <article>
          <strong>门诊诊室</strong>
          <p>用于医生日常出诊，与排班中心中的 `clinic_room_uuid` 形成绑定。</p>
        </article>
        <article>
          <strong>CT / 检查室</strong>
          <p>用于答辩展示“多个 CT 室如何选择”的资源承载对象，当前先做资料视图。</p>
        </article>
        <article>
          <strong>后续扩展</strong>
          <p>如果后端后续补充房间列表或维护接口，再把这一页升级成完整 CRUD 工作台。</p>
        </article>
      </div>
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
  border: 1px solid rgba(15, 118, 110, 0.18);
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

.admin-page__grid {
  display: grid;
  gap: 16px;
}

.admin-page__grid.is-two-column {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.admin-form,
.resource-guide {
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
.admin-form button {
  min-height: 42px;
  padding: 0 14px;
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
}

.admin-form button {
  border: 0;
  background: linear-gradient(135deg, #0f766e, #2563eb);
  color: #ffffff;
  font-weight: 700;
}

.room-card,
.resource-guide article {
  display: grid;
  gap: 6px;
  padding: 16px;
  border-radius: 14px;
  border: 1px solid #dbeafe;
  background: #f8fbff;
}

.room-card strong,
.room-card p,
.resource-guide strong,
.resource-guide p {
  margin: 0;
}

.room-card p,
.resource-guide p {
  color: #475569;
}

.admin-empty {
  padding: 18px;
  border-radius: 14px;
  background: #f8fafc;
  color: #64748b;
}

@media (max-width: 960px) {
  .admin-page__grid.is-two-column {
    grid-template-columns: 1fr;
  }
}
</style>
