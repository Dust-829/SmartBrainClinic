<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import SectionCard from '@/components/common/SectionCard.vue'
import { useAdminSessionStore } from '@/stores/adminSession'

const route = useRoute()
const router = useRouter()
const session = useAdminSessionStore()
const submitting = ref(false)

const form = reactive({
  displayName: '值班管理员',
  staffCode: 'ADMIN-001',
})

const redirectPath = computed(() => {
  const value = route.query.redirect
  return typeof value === 'string' && value.trim() ? value : '/admin/console'
})

function submit() {
  if (!form.displayName.trim() || !form.staffCode.trim()) return

  submitting.value = true
  try {
    session.login({
      displayName: form.displayName,
      staffCode: form.staffCode,
    })
    router.replace(redirectPath.value)
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="admin-login">
    <div class="admin-login__hero">
      <span class="admin-login__eyebrow">智慧云脑诊疗平台</span>
      <h1>管理员登录</h1>
      <p>当前先提供占位登录入口，用于打通独立管理员端访问边界，后续再接真实鉴权。</p>
    </div>

    <SectionCard title="登录控制台" subtitle="输入演示姓名和工号后进入管理后台首页。">
      <div class="admin-login__form">
        <label>
          <span>管理员姓名</span>
          <input v-model="form.displayName" type="text" placeholder="请输入管理员姓名" autocomplete="name" />
        </label>

        <label>
          <span>工号</span>
          <input v-model="form.staffCode" type="text" placeholder="请输入工号" autocomplete="username" />
        </label>

        <button type="button" :disabled="submitting" @click="submit">
          {{ submitting ? '进入中...' : '进入管理后台' }}
        </button>
      </div>
    </SectionCard>
  </div>
</template>

<style scoped>
.admin-login {
  display: grid;
  gap: 20px;
  max-width: 560px;
}

.admin-login__hero {
  display: grid;
  gap: 10px;
}

.admin-login__eyebrow {
  color: #4338ca;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.admin-login__hero h1,
.admin-login__hero p {
  margin: 0;
}

.admin-login__hero h1 {
  color: #0f172a;
  font-size: 34px;
  line-height: 1.1;
}

.admin-login__hero p {
  color: #475569;
  line-height: 1.7;
}

.admin-login__form {
  display: grid;
  gap: 14px;
}

.admin-login__form label {
  display: grid;
  gap: 8px;
}

.admin-login__form span {
  color: #334155;
  font-size: 14px;
  font-weight: 600;
}

.admin-login__form input {
  min-height: 46px;
  padding: 0 14px;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  outline: 0;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
}

.admin-login__form input:focus {
  border-color: #4338ca;
  box-shadow: 0 0 0 3px rgba(67, 56, 202, 0.12);
}

.admin-login__form button {
  min-height: 46px;
  border: 0;
  border-radius: 10px;
  background: linear-gradient(135deg, #4338ca, #6366f1);
  color: #ffffff;
  font: inherit;
  font-weight: 700;
}

.admin-login__form button:disabled {
  opacity: 0.7;
}
</style>
