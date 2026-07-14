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
  return typeof value === 'string' && value.trim() ? value : '/admin/dashboard'
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
      <p>当前先提供演示登录入口，用于进入统一风格后的管理员工作台，后续再接真实鉴权。</p>
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
