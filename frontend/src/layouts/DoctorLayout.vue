<template>
  <div class="doctor-layout">
    <aside class="doctor-layout__sidebar">
      <div>
        <div class="doctor-layout__eyebrow">智慧云脑诊疗平台</div>
        <h1>医生端</h1>
        <p>左侧为人工业务区，右侧为 AI 辅助区。</p>
      </div>
    </aside>
    <main class="doctor-layout__main">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.doctor-layout {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  background: #f8fafc;
}

.doctor-layout__sidebar {
  border-right: 1px solid #e2e8f0;
  padding: 88px 24px 24px;
  background: #ffffff;
  display: flex;
  flex-direction: column;
}

.doctor-layout__eyebrow {
  font-size: 12px;
  color: #0f766e;
}

.doctor-layout__sidebar h1 {
  margin: 10px 0 0;
  font-size: 30px;
  color: #0f172a;
}

.doctor-layout__sidebar p {
  margin: 12px 0 0;
  color: #475569;
  line-height: 1.6;
}

.doctor-layout__main {
  padding: 24px;
}

@media (max-width: 1100px) {
  .doctor-layout {
    grid-template-columns: 1fr;
  }

  .doctor-layout__sidebar {
    gap: 16px;
  }
}
</style>