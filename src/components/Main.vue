<script setup>
import JournalApp from './JournalApp.vue'
</script>

<template>
  <div class="kokoro-meter-app">
    <JournalApp />
  </div>
</template>

<style scoped>
.kokoro-meter-app {
  min-height: 100vh;
  width: 100%;
  margin: 0;
  padding: 0;
}

/* グローバルリセット（このコンポーネント内で適用） */
.kokoro-meter-app * {
  box-sizing: border-box;
}

/* モバイルファースト */
@media (max-width: 768px) {
  .kokoro-meter-app {
    overflow-x: hidden;
  }
}
</style> 