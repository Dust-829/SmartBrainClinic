<script setup lang="ts">
import SectionCard from '@/components/common/SectionCard.vue'

const queueItems = [
  { name: '张三', status: '待叫号', slot: '09:00-09:30' },
  { name: '李四', status: '候诊中', slot: '09:30-10:00' },
  { name: '王五', status: '已报到', slot: '10:00-10:30' },
]

const aiBlocks = [
  'AI 病历草稿',
  '相似病历召回',
  '检查检验建议',
  '影像辅助判断',
  '处方推荐',
]
</script>

<template>
  <div class="doctor-workbench">
    <div class="doctor-workbench__human">
      <SectionCard title="人工业务区" subtitle="后续接入候诊队列、接诊、病历确认、检查检验开立。">
        <div class="doctor-workbench__queue">
          <div v-for="item in queueItems" :key="`${item.name}-${item.slot}`" class="doctor-workbench__queue-item">
            <div>
              <strong>{{ item.name }}</strong>
              <p>{{ item.slot }}</p>
            </div>
            <el-tag effect="plain">{{ item.status }}</el-tag>
          </div>
        </div>
      </SectionCard>
    </div>

    <div class="doctor-workbench__ai">
      <SectionCard title="AI 辅助区" subtitle="后续接入 AI 问答、相似病历、影像建议、处方建议。">
        <div class="doctor-workbench__ai-grid">
          <div v-for="block in aiBlocks" :key="block" class="doctor-workbench__ai-block">
            {{ block }}
          </div>
        </div>
      </SectionCard>
    </div>
  </div>
</template>

<style scoped>
.doctor-workbench {
  min-height: calc(100vh - 48px);
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(320px, 0.9fr);
  gap: 20px;
}

.doctor-workbench__queue,
.doctor-workbench__ai-grid {
  display: grid;
  gap: 12px;
}

.doctor-workbench__queue-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #f8fafc;
}

.doctor-workbench__queue-item p {
  margin: 6px 0 0;
  font-size: 13px;
  color: #64748b;
}

.doctor-workbench__ai-block {
  min-height: 84px;
  display: flex;
  align-items: center;
  padding: 14px;
  border-radius: 8px;
  background: #ecfeff;
  color: #134e4a;
  border: 1px solid #99f6e4;
}

@media (max-width: 1100px) {
  .doctor-workbench {
    grid-template-columns: 1fr;
  }
}
</style>
