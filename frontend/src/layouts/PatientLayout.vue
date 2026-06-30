<template>
  <div class="patient-layout">
    <header class="patient-layout__header">
      <div>
        <div class="patient-layout__eyebrow">智慧云脑诊疗平台</div>
        <h1>患者端</h1>
      </div>
    </header>
    <main class="patient-layout__main">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.patient-layout {
  min-height: 100vh;
  background:
    linear-gradient(180deg, rgba(59, 130, 246, 0.08), rgba(255, 255, 255, 0) 24%),
    #f8fafc;
}

.patient-layout__header {
  max-width: 420px;
  margin: 0 auto;
  padding: 88px 20px 18px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.patient-layout__eyebrow {
  font-size: 12px;
  color: #0369a1;
}

.patient-layout__header h1 {
  margin: 8px 0 0;
  font-size: 28px;
  color: #0f172a;
}

.patient-layout__main {
  max-width: 420px;
  margin: 0 auto;
  padding: 0 20px 28px;
}
</style>