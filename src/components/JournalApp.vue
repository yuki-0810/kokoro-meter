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

// 日記作成時の選択日付
const selectedJournalDate = ref(null)

// 認証関連
const newEmail = ref('')
const newPassword = ref('')
const loginEmail = ref('')
const loginPassword = ref('')
const authLoading = ref(false)
const authMessage = ref('')

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

// カレンダーから日記作成への遷移
const handleNavigateToJournal = (dateStr) => {
  selectedJournalDate.value = dateStr
  activeTab.value = 'write'
}

// タブ切り替え
const switchTab = (tabName) => {
  activeTab.value = tabName
}

// 認証関連関数
const signUp = async () => {
  authLoading.value = true
  authMessage.value = ''
  try {
    const { user, error } = await supabase.auth.signUp({
      email: newEmail.value,
      password: newPassword.value,
    })
    if (error) throw error
    authMessage.value = 'アカウントが作成されました！ログインしてください。'
    newEmail.value = ''
    newPassword.value = ''
  } catch (error) {
    authMessage.value = `アカウント作成エラー: ${error.message}`
  } finally {
    authLoading.value = false
  }
}

const signIn = async () => {
  authLoading.value = true
  authMessage.value = ''
  try {
    const { user, error } = await supabase.auth.signInWithPassword({
      email: loginEmail.value,
      password: loginPassword.value,
    })
    if (error) throw error
    authMessage.value = 'ログインしました！'
    loginEmail.value = ''
    loginPassword.value = ''
    await checkUser() // ログイン後にユーザー情報を更新
    await loadJournals() // ログイン後に日記を読み込み
    await checkOpenAIConnection() // ログイン後にOpenAI接続を確認
  } catch (error) {
    authMessage.value = `ログインエラー: ${error.message}`
  } finally {
    authLoading.value = false
  }
}

const signOut = async () => {
  const { error } = await supabase.auth.signOut()
  if (error) {
    message.value = `ログアウトエラー: ${error.message}`
  } else {
    message.value = 'ログアウトしました。'
    currentUser.value = null
    journals.value = []
    isOpenAIConnected.value = false
    activeTab.value = 'home'
  }
}
</script>

<template>
  <div class="kokoro-meter">
    <div v-if="!currentUser" class="login-required">
      <div class="login-prompt">
        <div class="prompt-icon">��</div>
        <h2>ココロメーターへようこそ</h2>
        <p>メンタルステージを可視化し、AIがあなたに最適なアクティブレストを提案します。</p>
        
        <div class="auth-options">
          <div class="auth-option">
            <h3>🆕 新規アカウント作成</h3>
            <p>初回の方はこちらからアカウントを作成してください</p>
            <div class="auth-form">
              <input v-model="newEmail" type="email" placeholder="メールアドレス" class="auth-input" />
              <input v-model="newPassword" type="password" placeholder="パスワード（6文字以上）" class="auth-input" />
              <button @click="signUp" :disabled="authLoading" class="btn btn-primary auth-btn">
                {{ authLoading ? '作成中...' : '🚀 アカウント作成' }}
              </button>
            </div>
          </div>
          
          <div class="auth-divider">または</div>
          
          <div class="auth-option">
            <h3>🔑 既存アカウントでログイン</h3>
            <p>すでにアカウントをお持ちの方はこちら</p>
            <div class="auth-form">
              <input v-model="loginEmail" type="email" placeholder="メールアドレス" class="auth-input" />
              <input v-model="loginPassword" type="password" placeholder="パスワード" class="auth-input" />
              <button @click="signIn" :disabled="authLoading" class="btn btn-secondary auth-btn">
                {{ authLoading ? 'ログイン中...' : '✅ ログイン' }}
              </button>
            </div>
          </div>
        </div>
        
        <div v-if="authMessage" class="auth-message">
          {{ authMessage }}
        </div>
      </div>
    </div>
    
    <div v-else class="app-content">
      <!-- ヘッダー -->
      <header class="app-header">
        <div class="header-content">
          <h1 class="app-title">ココロメーター</h1>
          <button @click="signOut" class="logout-btn">ログアウト</button>
        </div>
      </header>

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
            :selectedJournalDate="selectedJournalDate"
          />
        </div>

        <!-- カレンダータブ -->
        <div v-if="activeTab === 'calendar'" class="tab-content">
          <JournalCalendar 
            :currentUser="currentUser" 
            :journals="journals"
            @navigateToJournal="handleNavigateToJournal"
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

.auth-options {
  margin-top: 2rem;
  text-align: left;
}

.auth-option {
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.auth-option h3 {
  color: #3b82f6;
  margin-bottom: 0.5rem;
  font-size: 1.25rem;
}

.auth-option p {
  color: #4a5568;
  margin-bottom: 1.5rem;
  font-size: 0.9rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.auth-input {
  padding: 0.75rem 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
}

.auth-input:focus {
  border-color: #3b82f6;
  outline: none;
}

.auth-btn {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.3s ease, opacity 0.3s ease;
  border: none;
  width: 100%;
}

.btn-primary {
  background-color: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #2b6cb0;
}

.btn-primary:disabled {
  background-color: #90cdf4;
  cursor: not-allowed;
  opacity: 0.7;
}

.btn-secondary {
  background-color: #edf2f7;
  color: #3b82f6;
  border: 1px solid #3b82f6;
}

.btn-secondary:hover:not(:disabled) {
  background-color: #e2e8f0;
}

.btn-secondary:disabled {
  background-color: #f9fafb;
  cursor: not-allowed;
  opacity: 0.7;
}

.auth-divider {
  margin: 1.5rem 0;
  text-align: center;
  color: #a0aec0;
  font-size: 0.9rem;
}

.auth-message {
  margin-top: 1.5rem;
  padding: 0.75rem 1.5rem;
  background: #f9fafb;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #4a5568;
  font-size: 0.9rem;
}

.app-content {
  position: relative;
  min-height: 100vh;
}

.app-header {
  background: white;
  padding: 1rem 2rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 999;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
}

.app-title {
  color: #2d3748;
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0;
}

.logout-btn {
  background-color: #f56565;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.3s ease;
  border: none;
}

.logout-btn:hover {
  background-color: #e53e3e;
}

.main-content {
  padding-top: 80px; /* ヘッダー分のスペース */
  padding-bottom: 80px; /* ボトムナビゲーション分のスペース */
  min-height: calc(100vh - 80px - 80px); /* ヘッダーとボトムナビゲーション分の高さ */
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