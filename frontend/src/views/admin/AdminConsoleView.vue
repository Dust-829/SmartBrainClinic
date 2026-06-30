<script setup lang="ts">
import SectionCard from '@/components/common/SectionCard.vue'

const adminTasks = [
  '排班批量生成',
  'AI 排班微调',
  '排班审批',
  '规则干预',
  'AI 审计日志',
]
</script>

<template>
  <div class="admin-console">
    <SectionCard title="管理后台骨架" subtitle="后续会按排班、审批、审计三个域展开。">
      <div class="admin-console__grid">
        <div v-for="task in adminTasks" :key="task" class="admin-console__tile">
          {{ task }}
        </div>
      </div>
    </SectionCard>
  </div>
</template>

<style scoped>
.admin-console__grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.admin-console__tile {
  min-height: 120px;
  display: flex;
  align-items: flex-end;
  padding: 18px;
  border-radius: 8px;
  color: #312e81;
  background: linear-gradient(180deg, #eef2ff 0%, #e0e7ff 100%);
  border: 1px solid #c7d2fe;
}

@media (max-width: 1100px) {
  .admin-console__grid {
    grid-template-columns: 1fr;
  }
}
</style>
