<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { useRoute, useRouter } from 'vue-router'

import { authApi } from '@/api/auth'
import SectionCard from '@/components/common/SectionCard.vue'
import { useAdminSessionStore } from '@/stores/adminSession'

const route = useRoute()
const router = useRouter()
const session = useAdminSessionStore()
const submitting = ref(false)

const form = reactive({
  staffCode: '',
  password: '',
})

const expiredSessionNotice = computed(() => route.query.reason === 'expired')

async function submit() {
  if (!form.staffCode.trim() || !form.password) {
    ElMessage.warning('请输入管理员工号和密码')
    return
  }

  submitting.value = true
  try {
    const response = await authApi.adminLogin({
      staff_code: form.staffCode.trim(),
      password: form.password,
    })
    const result = response.data.data
    session.login({
      uuid: result.staff.uuid,
      displayName: result.staff.display_name,
      staffCode: result.staff.staff_code,
    }, result.access_token)
    router.replace({ name: 'admin-home' })
  } catch {
    ElMessage.error('登录失败，请检查工号、密码或管理员认证配置。')
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
      <p>使用已授权的管理员工号和密码登录，进入医院运营后台。</p>
    </div>

    <SectionCard title="登录控制台" subtitle="登录凭据由部署管理员初始化，不在前端保存默认账号。">
      <div class="admin-login__form">
        <p v-if="expiredSessionNotice" class="admin-login__notice">登录状态已失效，请重新登录。</p>
        <label>
          <span>工号</span>
          <input v-model="form.staffCode" type="text" placeholder="请输入工号" autocomplete="username" />
        </label>

        <label>
          <span>密码</span>
          <input v-model="form.password" type="password" placeholder="请输入密码" autocomplete="current-password" @keyup.enter="submit" />
        </label>

        <button type="button" :disabled="submitting" @click="submit">
          {{ submitting ? '进入中...' : '进入管理后台' }}
        </button>
      </div>
    </SectionCard>
  </div>
</template>

<style scoped>
.admin-login__notice {
  margin: 0;
  color: #92400e;
  line-height: 1.6;
}
</style>
