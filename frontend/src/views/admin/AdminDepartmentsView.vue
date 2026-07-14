<script setup lang="ts">
import { reactive, ref } from 'vue'

import { authApi, type DepartmentRecord, type EmployeeRecord } from '@/api/auth'
import SectionCard from '@/components/common/SectionCard.vue'

const department = ref<DepartmentRecord | null>(null)
const employees = ref<EmployeeRecord[]>([])
const loadingDepartment = ref(false)
const loadingEmployees = ref(false)

const deptForm = reactive({
  dept_code: 'SJWK',
})

const deptTypeForm = reactive({
  dept_type: 'outpatient',
})

async function loadDepartment() {
  loadingDepartment.value = true
  try {
    const response = await authApi.getDepartmentByCode(deptForm.dept_code.trim())
    department.value = response.data.data ?? null
  } catch {
    department.value = null
  } finally {
    loadingDepartment.value = false
  }
}

async function loadEmployeesByType() {
  loadingEmployees.value = true
  try {
    const response = await authApi.getEmployeesByDeptType(deptTypeForm.dept_type.trim())
    employees.value = response.data.data ?? []
  } catch {
    employees.value = []
  } finally {
    loadingEmployees.value = false
  }
}

loadDepartment()
loadEmployeesByType()
</script>

<template>
  <div class="admin-page">
    <section class="admin-page__hero">
      <div>
        <span>基础资料中心</span>
        <h2>科室与人员视图</h2>
        <p>当前先用现有接口支持科室查询和按科室类型浏览员工，保证管理员端有基础资料入口可演示。</p>
      </div>
    </section>

    <div class="admin-page__grid is-two-column">
      <SectionCard title="科室查询" subtitle="通过科室编码读取科室基础资料。">
        <form class="admin-form" @submit.prevent="loadDepartment">
          <label>
            <span>科室编码</span>
            <input v-model="deptForm.dept_code" type="text" placeholder="如 SJWK" />
          </label>
          <button type="submit" :disabled="loadingDepartment">
            {{ loadingDepartment ? '查询中...' : '查询科室' }}
          </button>
        </form>

        <div v-if="department" class="department-card">
          <strong>{{ department.dept_name }}</strong>
          <p>编码：{{ department.dept_code }}</p>
          <p>类型：{{ department.dept_type || '未记录' }}</p>
          <p>地址：{{ department.dept_address || '未记录' }}</p>
          <span>{{ department.uuid }}</span>
        </div>
        <div v-else class="admin-empty">当前没有查到对应科室。</div>
      </SectionCard>

      <SectionCard title="按科室类型查看员工" subtitle="用于快速展示某类科室下的人员资源。">
        <form class="admin-form" @submit.prevent="loadEmployeesByType">
          <label>
            <span>科室类型</span>
            <input v-model="deptTypeForm.dept_type" type="text" placeholder="如 outpatient、medical-tech" />
          </label>
          <button type="submit" :disabled="loadingEmployees">
            {{ loadingEmployees ? '加载中...' : '加载员工' }}
          </button>
        </form>
      </SectionCard>
    </div>

    <SectionCard title="员工资源列表" subtitle="展示管理员端对人员资源的浏览能力。">
      <div v-if="employees.length" class="employee-list">
        <article v-for="employee in employees" :key="employee.uuid" class="employee-card">
          <strong>{{ employee.realname }}</strong>
          <p>{{ employee.gender || '未知性别' }} | AI 评分 {{ employee.ai_eval_score ?? '未记录' }}</p>
          <p>{{ employee.expertise || '暂无专长描述' }}</p>
          <span>{{ employee.uuid }}</span>
        </article>
      </div>
      <div v-else class="admin-empty">当前没有查到该类型下的员工数据。</div>
    </SectionCard>
  </div>
</template>
