<script setup>
import { ref, onMounted } from 'vue'
import { supabase, testConnection } from '../supabase.js'

// リアクティブな状態管理
const connectionStatus = ref('')
const isConnected = ref(false)
const currentUser = ref(null)
const isLoading = ref(false)

// 認証フォーム
const email = ref('')
const password = ref('')
const authMessage = ref('')

// ジャーナル管理
const journals = ref([])
const newJournalTitle = ref('')
const newJournalContent = ref('')
const journalMessage = ref('')

// 1. 接続テスト
const checkConnection = async () => {
  isLoading.value = true
  try {
    const result = await testConnection()
    connectionStatus.value = result.message
    isConnected.value = result.success
    
    if (result.success && result.session) {
      currentUser.value = result.session.user
    }
  } catch (error) {
    connectionStatus.value = `予期しないエラー: ${error.message}`
    isConnected.value = false
  } finally {
    isLoading.value = false
  }
}

// 2. サインアップ
const signUp = async () => {
  if (!email.value || !password.value) {
    authMessage.value = 'メールアドレスとパスワードを入力してください'
    return
  }
  
  isLoading.value = true
  try {
    const { data, error } = await supabase.auth.signUp({
      email: email.value,
      password: password.value,
    })
    
    if (error) throw error
    
    authMessage.value = `サインアップ成功！ ${email.value} に確認メールを送信しました。`
    email.value = ''
    password.value = ''
  } catch (error) {
    authMessage.value = `サインアップエラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 3. ログイン
const signIn = async () => {
  if (!email.value || !password.value) {
    authMessage.value = 'メールアドレスとパスワードを入力してください'
    return
  }
  
  isLoading.value = true
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    })
    
    if (error) throw error
    
    currentUser.value = data.user
    authMessage.value = `ログイン成功！ ようこそ ${data.user.email} さん`
    email.value = ''
    password.value = ''
    await loadJournals() // ログイン後にジャーナルを読み込み
  } catch (error) {
    authMessage.value = `ログインエラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 4. ログアウト
const signOut = async () => {
  isLoading.value = true
  try {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    
    currentUser.value = null
    authMessage.value = 'ログアウトしました'
    journals.value = []
  } catch (error) {
    authMessage.value = `ログアウトエラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 5. ジャーナル読み込み
const loadJournals = async () => {
  if (!currentUser.value) {
    journalMessage.value = 'ログインが必要です'
    return
  }
  
  isLoading.value = true
  try {
    const { data, error } = await supabase
      .from('journals')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    
    journals.value = data || []
    journalMessage.value = `ジャーナル ${data?.length || 0} 件を読み込みました`
  } catch (error) {
    journalMessage.value = `読み込みエラー: ${error.message}`
    if (error.message.includes('relation "journals" does not exist')) {
      journalMessage.value = 'ジャーナルテーブルが存在しません。下記のSQLでテーブルを作成してください。'
    }
  } finally {
    isLoading.value = false
  }
}

// 6. ジャーナル追加
const addJournal = async () => {
  if (!currentUser.value) {
    journalMessage.value = 'ログインが必要です'
    return
  }
  
  if (!newJournalTitle.value || !newJournalContent.value) {
    journalMessage.value = 'タイトルと内容を入力してください'
    return
  }
  
  isLoading.value = true
  try {
    const { data, error } = await supabase
      .from('journals')
      .insert([
        {
          title: newJournalTitle.value,
          content: newJournalContent.value,
          user_id: currentUser.value.id
        }
      ])
      .select()
    
    if (error) throw error
    
    newJournalTitle.value = ''
    newJournalContent.value = ''
    journalMessage.value = 'ジャーナルを追加しました'
    await loadJournals() // 追加後に再読み込み
  } catch (error) {
    journalMessage.value = `追加エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 7. ジャーナル削除
const deleteJournal = async (id) => {
  if (!currentUser.value) {
    journalMessage.value = 'ログインが必要です'
    return
  }
  
  isLoading.value = true
  try {
    const { error } = await supabase
      .from('journals')
      .delete()
      .eq('id', id)
    
    if (error) throw error
    
    journalMessage.value = 'ジャーナルを削除しました'
    await loadJournals() // 削除後に再読み込み
  } catch (error) {
    journalMessage.value = `削除エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// コンポーネントマウント時に接続確認
onMounted(() => {
  checkConnection()
})
</script>

<template>
  <div class="supabase-test">
    <h2 class="test-title">🔧 Supabase 接続・認証・DB操作テスト</h2>
    
    <!-- 手順説明 -->
    <div class="instructions">
      <h3>📋 テスト手順</h3>
      <ol>
        <li><strong>接続確認</strong>: まず「接続テスト」ボタンで Supabase への接続を確認</li>
        <li><strong>認証テスト</strong>: サインアップ→メール確認→ログインの流れをテスト</li>
        <li><strong>テーブル操作</strong>: ジャーナル（日記）の作成・読み込み・削除をテスト</li>
      </ol>
    </div>

    <!-- 1. 接続テスト -->
    <div class="test-section">
      <h3>🌐 1. 接続テスト</h3>
      <button @click="checkConnection" :disabled="isLoading" class="btn btn-primary">
        {{ isLoading ? '確認中...' : '接続テスト' }}
      </button>
      <div v-if="connectionStatus" :class="['status-message', isConnected ? 'success' : 'error']">
        {{ connectionStatus }}
      </div>
    </div>

    <!-- 2. 認証テスト -->
    <div class="test-section">
      <h3>🔐 2. 認証テスト</h3>
      
      <div v-if="!currentUser" class="auth-form">
        <div class="form-group">
          <input 
            v-model="email" 
            type="email" 
            placeholder="メールアドレス"
            class="form-input"
          />
          <input 
            v-model="password" 
            type="password" 
            placeholder="パスワード (6文字以上)"
            class="form-input"
          />
        </div>
        
        <div class="button-group">
          <button @click="signUp" :disabled="isLoading" class="btn btn-secondary">
            {{ isLoading ? '処理中...' : 'サインアップ' }}
          </button>
          <button @click="signIn" :disabled="isLoading" class="btn btn-primary">
            {{ isLoading ? '処理中...' : 'ログイン' }}
          </button>
        </div>
      </div>
      
      <div v-else class="user-info">
        <p><strong>ログイン中:</strong> {{ currentUser.email }}</p>
        <button @click="signOut" :disabled="isLoading" class="btn btn-secondary">
          {{ isLoading ? '処理中...' : 'ログアウト' }}
        </button>
      </div>
      
      <div v-if="authMessage" :class="['status-message', authMessage.includes('エラー') ? 'error' : 'success']">
        {{ authMessage }}
      </div>
    </div>

    <!-- 3. テーブル操作テスト -->
    <div class="test-section">
      <h3>🗄️ 3. テーブル操作テスト (ジャーナル)</h3>
      
      <div v-if="currentUser">
        <!-- ジャーナル追加フォーム -->
        <div class="journal-form">
          <input 
            v-model="newJournalTitle" 
            type="text" 
            placeholder="ジャーナルタイトル"
            class="form-input"
          />
          <textarea 
            v-model="newJournalContent" 
            placeholder="今日の気分や出来事を書いてみてください..."
            class="form-textarea"
            rows="3"
          ></textarea>
          <button @click="addJournal" :disabled="isLoading" class="btn btn-primary">
            {{ isLoading ? '追加中...' : 'ジャーナル追加' }}
          </button>
        </div>
        
        <!-- ジャーナル一覧 -->
        <div class="journal-actions">
          <button @click="loadJournals" :disabled="isLoading" class="btn btn-secondary">
            {{ isLoading ? '読み込み中...' : 'ジャーナル読み込み' }}
          </button>
        </div>
        
        <div v-if="journals.length > 0" class="journals-list">
          <h4>📝 ジャーナル一覧 ({{ journals.length }} 件)</h4>
          <div v-for="journal in journals" :key="journal.id" class="journal-item">
            <h5>{{ journal.title }}</h5>
            <p>{{ journal.content }}</p>
            <small>{{ new Date(journal.created_at).toLocaleString('ja-JP') }}</small>
            <button @click="deleteJournal(journal.id)" class="btn-delete">削除</button>
          </div>
        </div>
      </div>
      
      <div v-else class="login-required">
        <p>⚠️ ジャーナル機能を使用するには、まず上記でログインしてください</p>
      </div>
      
      <div v-if="journalMessage" :class="['status-message', journalMessage.includes('エラー') ? 'error' : 'success']">
        {{ journalMessage }}
      </div>
    </div>

    <!-- テーブル作成SQL -->
    <div class="sql-section">
      <h3>📊 テーブル作成SQL</h3>
      <p>以下のSQLをSupabase SQLエディタで実行してください:</p>
      <pre class="sql-code">-- ジャーナルテーブル作成
CREATE TABLE journals (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) 有効化
ALTER TABLE journals ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーのみアクセス可能なポリシー作成
CREATE POLICY "Users can view own journals" ON journals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journals" ON journals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journals" ON journals
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journals" ON journals
  FOR DELETE USING (auth.uid() = user_id);</pre>
    </div>
  </div>
</template>

<style scoped>
.supabase-test {
  max-width: 800px;
  margin: 0 auto;
  padding: 1rem;
}

.test-title {
  color: #2d3748;
  margin-bottom: 2rem;
  text-align: center;
}

.instructions {
  background: #f7fafc;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 2rem;
  border-left: 4px solid #4299e1;
}

.instructions h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.instructions ol {
  color: #4a5568;
  line-height: 1.6;
  padding-left: 1.5rem;
}

.test-section {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.test-section h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.status-message {
  margin-top: 1rem;
  padding: 0.75rem;
  border-radius: 6px;
  font-weight: 500;
}

.status-message.success {
  background: #f0fff4;
  color: #22543d;
  border: 1px solid #9ae6b4;
}

.status-message.error {
  background: #fed7d7;
  color: #742a2a;
  border: 1px solid #feb2b2;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-group {
  display: flex;
  gap: 0.5rem;
}

.form-input {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 1rem;
}

.form-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 1rem;
  resize: vertical;
  font-family: inherit;
}

.button-group {
  display: flex;
  gap: 0.5rem;
}

.user-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  border-radius: 6px;
}

.journal-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1rem;
}

.journal-actions {
  margin-bottom: 1rem;
}

.journals-list h4 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.journal-item {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  padding: 1rem;
  margin-bottom: 0.5rem;
  position: relative;
}

.journal-item h5 {
  color: #1f2937;
  margin-bottom: 0.5rem;
  font-size: 1.1rem;
}

.journal-item p {
  color: #4b5563;
  line-height: 1.5;
  margin-bottom: 0.5rem;
}

.journal-item small {
  color: #6b7280;
  font-size: 0.875rem;
}

.btn-delete {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-delete:hover {
  background: #dc2626;
}

.login-required {
  background: #fef3cd;
  border: 1px solid #fbbf24;
  border-radius: 6px;
  padding: 1rem;
  color: #92400e;
}

.sql-section {
  background: #1a202c;
  color: #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
  margin-top: 2rem;
}

.sql-section h3 {
  color: #e2e8f0;
  margin-bottom: 1rem;
}

.sql-section p {
  color: #a0aec0;
  margin-bottom: 1rem;
}

.sql-code {
  background: #2d3748;
  color: #e2e8f0;
  padding: 1rem;
  border-radius: 6px;
  overflow-x: auto;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 0.875rem;
  line-height: 1.5;
  white-space: pre;
}

@media (max-width: 768px) {
  .form-group {
    flex-direction: column;
  }
  
  .button-group {
    flex-direction: column;
  }
  
  .user-info {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
}
</style> 