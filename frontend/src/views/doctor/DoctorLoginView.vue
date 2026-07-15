<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'

import { authApi } from '@/api/auth'
import { useDoctorSessionStore } from '@/stores/doctorSession'

const router = useRouter()
const session = useDoctorSessionStore()
const submitting = ref(false)
const attempted = ref(false)
const submitError = ref('')

const form = reactive({
  staffCode: '',
  password: '',
})

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
    const response = await authApi.doctorLogin({
      staff_code: form.staffCode.trim(),
      password: form.password,
    })
    const staff = response.data.data.staff
    session.login({
      displayName: staff.display_name,
      employeeUuid: staff.uuid,
      staffCode: staff.staff_code,
      deptCode: staff.dept_code || undefined,
      deptName: staff.dept_name || undefined,
    })
    router.replace({ name: 'doctor-home' })
  } catch {
    submitError.value = '工号或密码不正确，请重新输入。'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <section class="staff-login staff-login--doctor" aria-labelledby="doctor-login-title">
    <aside class="staff-login__context">
      <div class="staff-login__brand">
        <span>智慧云脑诊疗平台</span>
        <strong>医生端</strong>
      </div>
      <div class="staff-login__context-copy">
        <p class="staff-login__eyebrow">医生登录</p>
        <h1 id="doctor-login-title">回到清晰、专注的接诊节奏</h1>
        <p>登录后查看今日候诊队列，并进入接诊工作台。</p>
      </div>
    </aside>

    <div class="staff-login__panel">
      <form class="staff-login__form" novalidate @submit.prevent="submit">
        <div class="staff-login__form-heading">
          <p class="staff-login__eyebrow">医生登录</p>
          <h2>进入医生工作台</h2>
          <p>使用已分配的工号和密码登录。</p>
        </div>

        <label class="staff-login__field" :class="{ 'has-error': staffCodeError }">
          <span>工号</span>
          <input
            v-model="form.staffCode"
            type="text"
            autocomplete="username"
            placeholder="请输入工号"
            @input="clearSubmitError"
          />
          <small v-if="staffCodeError">{{ staffCodeError }}</small>
        </label>

        <label class="staff-login__field" :class="{ 'has-error': passwordError }">
          <span>密码</span>
          <input
            v-model="form.password"
            type="password"
            autocomplete="current-password"
            placeholder="请输入密码"
            @input="clearSubmitError"
          />
          <small v-if="passwordError">{{ passwordError }}</small>
        </label>

        <p v-if="submitError" class="staff-login__feedback is-error" role="alert">{{ submitError }}</p>
        <p v-else-if="submitting" class="staff-login__feedback" aria-live="polite">正在登录…</p>

        <button class="staff-login__submit" type="submit" :disabled="submitting">
          {{ submitting ? '正在进入工作台…' : '登录并进入工作台' }}
        </button>
      </form>
    </div>
  </section>
</template>
