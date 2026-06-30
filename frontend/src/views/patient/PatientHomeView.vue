<script setup lang="ts">
import { onMounted, ref } from 'vue'
import SectionCard from '@/components/common/SectionCard.vue'
import { patientApi, type DepartmentOption } from '@/api/patient'

const departments = ref<DepartmentOption[]>([])
const loading = ref(false)

onMounted(async () => {
  loading.value = true
  try {
    const response = await patientApi.getDepartments()
    departments.value = response.data.data || []
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="patient-home">
    <SectionCard title="阶段 0 已完成" subtitle="前端工程、路由和公共层已初始化。">
      <ul class="patient-home__checklist">
        <li>统一网关请求层</li>
        <li>患者端移动布局</li>
        <li>医生端工作台布局</li>
        <li>管理员端后台布局</li>
      </ul>
    </SectionCard>

    <SectionCard title="下一步患者主链路" subtitle="后续会把这里逐步替换成真实业务页面。">
      <div class="patient-home__steps">
        <span>1. 注册建档</span>
        <span>2. AI 问诊</span>
        <span>3. 医生推荐</span>
        <span>4. 线上挂号</span>
        <span>5. 支付候诊</span>
      </div>
    </SectionCard>

    <SectionCard title="当前科室接口联通检查" subtitle="这里已经直接调用后端 /api/v1/patient/departments。">
      <el-skeleton :loading="loading" animated>
        <template #template>
          <div style="display: grid; gap: 10px">
            <el-skeleton-item variant="text" style="width: 100%; height: 16px" />
            <el-skeleton-item variant="text" style="width: 80%; height: 16px" />
            <el-skeleton-item variant="text" style="width: 60%; height: 16px" />
          </div>
        </template>
        <template #default>
          <div class="patient-home__departments">
            <div v-for="department in departments" :key="department.code" class="patient-home__department">
              <strong>{{ department.name }}</strong>
              <span>{{ department.code }}</span>
            </div>
            <div v-if="!departments.length" class="patient-home__empty">
              当前未取到科室数据，后续继续联调。
            </div>
          </div>
        </template>
      </el-skeleton>
    </SectionCard>
  </div>
</template>

<style scoped>
.patient-home {
  display: grid;
  gap: 16px;
}

.patient-home__checklist,
.patient-home__steps {
  margin: 0;
  padding: 0;
  list-style: none;
  display: grid;
  gap: 10px;
}

.patient-home__steps span,
.patient-home__checklist li {
  display: block;
  padding: 12px 14px;
  border-radius: 8px;
  background: #eff6ff;
  color: #0f172a;
}

.patient-home__departments {
  display: grid;
  gap: 10px;
}

.patient-home__department {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 14px;
  border: 1px solid #dbeafe;
  border-radius: 8px;
  background: #ffffff;
}

.patient-home__department span,
.patient-home__empty {
  color: #64748b;
  font-size: 13px;
}
</style>
