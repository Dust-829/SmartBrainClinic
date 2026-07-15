<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { authApi } from '@/api/auth'
import { useAdminSessionStore } from '@/stores/adminSession'

const route = useRoute()
const router = useRouter()
const session = useAdminSessionStore()
const submitting = ref(false)
const attempted = ref(false)
const submitError = ref('')

const form = reactive({
  staffCode: '',
  password: '',
})

const expiredSessionNotice = computed(() => route.query.reason === 'expired')
const staffCodeError = computed(() => attempted.value && !form.staffCode.trim() ? '请填写工号' : '')
const passwordError = computed(() => attempted.value && !form.password ? '请填写密码' : '')

function clearSubmitError() {
  submitError.value = ''
}

async function submit() {
  attempted.value = true
  clearSubmitError()
  if (staffCodeError.value || passwordError.value) return

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
    submitError.value = '工号或密码不正确，请重新输入。'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <section class="staff-login staff-login--admin" aria-labelledby="admin-login-title">
    <aside class="staff-login__context">
      <div class="staff-login__brand">
        <span>智慧云脑诊疗平台</span>
        <strong>管理端</strong>
      </div>
      <div class="staff-login__context-copy">
        <p class="staff-login__eyebrow">管理员登录</p>
        <h1 id="admin-login-title">让关键运营动作始终可追溯</h1>
        <p>统一处理排班、业务审批与审计追踪。</p>
      </div>
      <ul class="staff-login__capabilities" aria-label="管理端职责">
        <li><strong>01</strong><span>排班管理</span></li>
        <li><strong>02</strong><span>业务审批</span></li>
        <li><strong>03</strong><span>审计追踪</span></li>
      </ul>
    </aside>

    <div class="staff-login__panel">
      <form class="staff-login__form" novalidate @submit.prevent="submit">
        <div class="staff-login__form-heading">
          <p class="staff-login__eyebrow">管理员登录</p>
          <h2>进入管理后台</h2>
          <p>使用已授权的管理员工号和密码登录。</p>
        </div>

        <p v-if="expiredSessionNotice" class="staff-login__feedback is-warning" role="status">登录状态已失效，请重新登录。</p>

        <label class="staff-login__field" :class="{ 'has-error': staffCodeError }">
          <span>工号</span>
          <input v-model="form.staffCode" type="text" autocomplete="username" placeholder="请输入工号" @input="clearSubmitError" />
          <small v-if="staffCodeError">{{ staffCodeError }}</small>
        </label>

        <label class="staff-login__field" :class="{ 'has-error': passwordError }">
          <span>密码</span>
          <input v-model="form.password" type="password" autocomplete="current-password" placeholder="请输入密码" @input="clearSubmitError" />
          <small v-if="passwordError">{{ passwordError }}</small>
        </label>

        <p v-if="submitError" class="staff-login__feedback is-error" role="alert">{{ submitError }}</p>
        <p v-else-if="submitting" class="staff-login__feedback" aria-live="polite">正在登录…</p>

        <button class="staff-login__submit" type="submit" :disabled="submitting">
          {{ submitting ? '正在进入后台…' : '进入管理后台' }}
        </button>
      </form>
    </div>
  </section>
</template>
