<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase.js'
import { testOpenAIConnection } from '../openai.js'
import HomeView from './HomeView.vue'
import JournalEntry from './JournalEntry.vue'
import JournalCalendar from './JournalCalendar.vue'

// リアクティブ状態
const currentUser = ref(null)
const isLoading = ref(false)
const message = ref('')

// OpenAI接続状態
const isOpenAIConnected = ref(false)

// 日記一覧
const journals = ref([])

// アクティブタブ（ボトムナビゲーション）
const activeTab = ref('home') // 'home', 'write', 'calendar'

// 初期化処理
onMounted(async () => {
  await checkUser()
  if (currentUser.value) {
    await loadJournals()
    await checkOpenAIConnection()
  }
})

// ユーザー確認
const checkUser = async () => {
  const { data: { user } } = await supabase.auth.getUser()
  currentUser.value = user
}

// OpenAI接続確認
const checkOpenAIConnection = async () => {
  try {
    const result = await testOpenAIConnection()
    isOpenAIConnected.value = result.success
  } catch (error) {
    isOpenAIConnected.value = false
  }
}

// 日記読み込み
const loadJournals = async () => {
  if (!currentUser.value) return
  
  isLoading.value = true
  try {
    const { data, error } = await supabase
      .from('journals')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    
    journals.value = data || []
    
  } catch (error) {
    message.value = `読み込みエラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 日記保存時のリフレッシュ
const handleJournalSaved = async () => {
  await loadJournals()
  // 日記保存後はホームタブに移動して結果を確認
  activeTab.value = 'home'
}

// タブ切り替え
const switchTab = (tabName) => {
  activeTab.value = tabName
}
</script>

<template>
  <div class="kokoro-meter">
    <div v-if="!currentUser" class="login-required">
      <div class="login-prompt">
        <div class="prompt-icon">🔐</div>
        <h2>ログインが必要です</h2>
        <p>ココロメーターを使用するには、まずログインしてください。</p>
        <p>左側のメニューから「Supabaseテスト」でログインできます。</p>
      </div>
    </div>
    
    <div v-else class="app-content">
      <!-- メインコンテンツエリア -->
      <div class="main-content">
        <!-- ホームタブ -->
        <div v-if="activeTab === 'home'" class="tab-content">
          <HomeView 
            :currentUser="currentUser" 
            :journals="journals"
            :isOpenAIConnected="isOpenAIConnected"
          />
        </div>

        <!-- 日記作成タブ -->
        <div v-if="activeTab === 'write'" class="tab-content">
          <JournalEntry 
            :currentUser="currentUser" 
            :journals="journals"
            :isOpenAIConnected="isOpenAIConnected"
            @journalSaved="handleJournalSaved"
          />
        </div>

        <!-- カレンダータブ -->
        <div v-if="activeTab === 'calendar'" class="tab-content">
          <JournalCalendar 
            :currentUser="currentUser" 
            :journals="journals"
          />
        </div>
      </div>

      <!-- ボトム固定ナビゲーション -->
      <nav class="bottom-nav">
        <button 
          @click="switchTab('home')"
          :class="['nav-item', { active: activeTab === 'home' }]"
        >
          <div class="nav-icon">🏠</div>
          <div class="nav-label">ホーム</div>
        </button>
        
        <button 
          @click="switchTab('write')"
          :class="['nav-item', { active: activeTab === 'write' }]"
        >
          <div class="nav-icon">✏️</div>
          <div class="nav-label">日記</div>
        </button>
        
        <button 
          @click="switchTab('calendar')"
          :class="['nav-item', { active: activeTab === 'calendar' }]"
        >
          <div class="nav-icon">📅</div>
          <div class="nav-label">カレンダー</div>
        </button>
      </nav>

      <!-- ローディング・メッセージ表示 -->
      <div v-if="isLoading" class="loading-overlay">
        <div class="loading-spinner">📊</div>
        <p>読み込み中...</p>
      </div>

      <!-- グローバルメッセージ -->
      <div v-if="message" class="global-message">
        {{ message }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.kokoro-meter {
  min-height: 100vh;
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
}

.login-required {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 2rem;
}

.login-prompt {
  background: white;
  border-radius: 20px;
  padding: 3rem 2rem;
  text-align: center;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  max-width: 400px;
  width: 100%;
}

.prompt-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.login-prompt h2 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.5rem;
}

.login-prompt p {
  color: #4a5568;
  margin-bottom: 1rem;
  line-height: 1.6;
}

.app-content {
  position: relative;
  min-height: 100vh;
}

.main-content {
  padding-bottom: 80px; /* ボトムナビゲーション分のスペース */
  min-height: calc(100vh - 80px);
}

.tab-content {
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
}

.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  border-top: 1px solid #e2e8f0;
  display: flex;
  z-index: 1000;
  box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.1);
}

.nav-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 0.5rem;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.3s ease;
  color: #6b7280;
}

.nav-item:hover {
  background: #f9fafb;
}

.nav-item.active {
  color: #3b82f6;
  background: #eff6ff;
  border-top: 3px solid #3b82f6;
}

.nav-icon {
  font-size: 1.5rem;
  margin-bottom: 0.25rem;
}

.nav-label {
  font-size: 0.75rem;
  font-weight: 500;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.loading-spinner {
  font-size: 3rem;
  animation: pulse 2s infinite;
  margin-bottom: 1rem;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.loading-overlay p {
  color: #4a5568;
  font-size: 1rem;
}

.global-message {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: #3b82f6;
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 25px;
  font-size: 0.875rem;
  z-index: 1500;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
  animation: slideDown 0.3s ease;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}

/* モバイルファースト対応 */
@media (min-width: 768px) {
  .main-content {
    max-width: 1200px;
    margin: 0 auto;
  }
  
  .bottom-nav {
    max-width: 1200px;
    left: 50%;
    transform: translateX(-50%);
    border-radius: 15px 15px 0 0;
  }
}

/* 大きい画面でのボトムナビゲーション調整 */
@media (min-width: 1024px) {
  .nav-item {
    padding: 1rem 1.5rem;
  }
  
  .nav-icon {
    font-size: 1.75rem;
  }
  
  .nav-label {
    font-size: 0.875rem;
  }
}

/* スクロールバー非表示（モバイル向け） */
.main-content {
  -webkit-overflow-scrolling: touch;
}

/* iOS Safari対応 */
@supports (-webkit-appearance: none) {
  .bottom-nav {
    padding-bottom: env(safe-area-inset-bottom);
  }
}
</style> 