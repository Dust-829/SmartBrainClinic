<template>
  <div class="admin-layout">
    <header class="admin-layout__header">
      <div>
        <div class="admin-layout__eyebrow">智慧云脑诊疗平台</div>
        <h1>管理员端</h1>
      </div>
    </header>
    <main class="admin-layout__main">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.admin-layout {
  min-height: 100vh;
  background: #f1f5f9;
}

.admin-layout__header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 88px 28px 20px;
  border-bottom: 1px solid #dbeafe;
  background: #ffffff;
}

.admin-layout__eyebrow {
  font-size: 12px;
  color: #7c3aed;
}

.admin-layout__header h1 {
  margin: 8px 0 0;
  font-size: 28px;
  color: #0f172a;
}

.admin-layout__main {
  padding: 24px 28px 32px;
}
</style>