<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase.js'
import { 
  testOpenAIConnection, 
  organizeJournalText, 
  analyzeJournalForStage, 
  generateActiveRestRecommendations 
} from '../openai.js'
import JournalCalendar from './JournalCalendar.vue'

// リアクティブ状態
const currentUser = ref(null)
const isLoading = ref(false)
const message = ref('')

// OpenAI接続状態
const openAIStatus = ref('')
const isOpenAIConnected = ref(false)

// 日記入力
const newJournalTitle = ref('')
const newJournalContent = ref('')
const isVoiceInput = ref(false)

// 日記一覧とカレンダー
const journals = ref([])
const selectedDate = ref(new Date().toISOString().split('T')[0])

// メンタルステージ分析
const currentStage = ref(null)
const stageAnalysis = ref(null)
const weeklyJournals = ref([])

// アクティブレスト提案
const activeRestRecommendations = ref(null)

// ビュー切り替え
const activeView = ref('record') // 'record' または 'calendar'

// 計算されたプロパティ
const todayJournal = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return journals.value.find(j => j.created_at.startsWith(today))
})

const hasWrittenToday = computed(() => !!todayJournal.value)

const stageColor = computed(() => {
  if (!currentStage.value) return '#38b2ac'
  const colors = {
    0: '#38b2ac', // 緑
    1: '#4299e1', // 青
    2: '#ed8936', // オレンジ
    3: '#e53e3e', // 赤
    4: '#9f7aea'  // 紫
  }
  return colors[currentStage.value] || '#38b2ac'
})

const stageDescription = computed(() => {
  if (!currentStage.value) return '正常 - エネルギッシュで前向きな状態'
  const descriptions = {
    0: '正常 - エネルギッシュで前向きな状態',
    1: '軽度疲労 - 少し気力が低下している状態',
    2: '中度疲労 - イライラや疲労感が増している状態',
    3: '重度疲労 - 感情コントロールが困難な状態',
    4: '危険域 - 専門的な支援が必要な状態'
  }
  return descriptions[currentStage.value] || '分析中...'
})

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
  isLoading.value = true
  try {
    const result = await testOpenAIConnection()
    openAIStatus.value = result.message
    isOpenAIConnected.value = result.success
    
    if (result.success) {
      message.value = `OpenAI接続成功: ${result.model}`
    }
  } catch (error) {
    openAIStatus.value = `接続エラー: ${error.message}`
    isOpenAIConnected.value = false
  } finally {
    isLoading.value = false
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
    
    // 週間分析用データを準備
    const oneWeekAgo = new Date()
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)
    
    weeklyJournals.value = journals.value.filter(j => 
      new Date(j.created_at) >= oneWeekAgo
    )
    
    message.value = `日記 ${data?.length || 0} 件を読み込みました`
  } catch (error) {
    message.value = `読み込みエラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 日記保存（AI整理付き）
const saveJournal = async () => {
  if (!currentUser.value) {
    message.value = 'ログインが必要です'
    return
  }
  
  if (!newJournalTitle.value || !newJournalContent.value) {
    message.value = 'タイトルと内容を入力してください'
    return
  }
  
  if (hasWrittenToday.value) {
    message.value = '今日はすでに日記を書いています'
    return
  }
  
  isLoading.value = true
  try {
    let organizedContent = newJournalContent.value
    let aiMetadata = null
    
    // OpenAI接続時はAI整理を実行
    if (isOpenAIConnected.value) {
      message.value = 'AIが日記を整理しています...'
      const organizeResult = await organizeJournalText(newJournalContent.value)
      
      if (organizeResult.success) {
        organizedContent = organizeResult.data.organized_text
        aiMetadata = {
          original_length: newJournalContent.value.length,
          organized_length: organizeResult.data.word_count,
          detected_emotions: organizeResult.data.detected_emotions,
          key_events: organizeResult.data.key_events,
          ai_organized: true
        }
        message.value = 'AI整理完了！日記を保存しています...'
      }
    }
    
    const { data, error } = await supabase
      .from('journals')
      .insert([
        {
          title: newJournalTitle.value,
          content: organizedContent,
          original_content: newJournalContent.value,
          ai_metadata: aiMetadata,
          user_id: currentUser.value.id,
          entry_date: new Date().toISOString().split('T')[0]
        }
      ])
      .select()
    
    if (error) throw error
    
    newJournalTitle.value = ''
    newJournalContent.value = ''
    message.value = 'AI整理された日記を保存しました'
    await loadJournals()
    
  } catch (error) {
    message.value = `保存エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 週間メンタルステージ分析
const analyzeWeeklyMentalStage = async () => {
  if (!currentUser.value || weeklyJournals.value.length === 0) {
    message.value = '分析するジャーナルがありません'
    return
  }
  
  if (!isOpenAIConnected.value) {
    message.value = 'OpenAI接続が必要です'
    return
  }
  
  isLoading.value = true
  try {
    message.value = 'AIがメンタルステージを分析しています...'
    
    const analysisResult = await analyzeJournalForStage(weeklyJournals.value)
    
    if (analysisResult.success) {
      stageAnalysis.value = analysisResult.data
      currentStage.value = analysisResult.data.stage
      
      message.value = `分析完了！現在のステージ: Stage ${analysisResult.data.stage}`
      
      // 緊急時の警告
      if (analysisResult.data.emergency) {
        message.value += ' ⚠️ 専門的なサポートを推奨します'
      }
      
      // アクティブレスト提案を自動生成
      await generateRecommendations()
      
    } else {
      message.value = analysisResult.message
    }
  } catch (error) {
    message.value = `分析エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// アクティブレスト提案生成
const generateRecommendations = async () => {
  if (!isOpenAIConnected.value || currentStage.value === null) return
  
  try {
    const hour = new Date().getHours()
    let timeOfDay = 'morning'
    if (hour >= 12 && hour < 18) timeOfDay = 'afternoon'
    else if (hour >= 18) timeOfDay = 'evening'
    
    const result = await generateActiveRestRecommendations(currentStage.value, timeOfDay)
    
    if (result.success) {
      activeRestRecommendations.value = result.data
    }
  } catch (error) {
    console.error('アクティブレスト提案エラー:', error)
  }
}

// 音声入力切り替え（将来実装用）
const toggleVoiceInput = () => {
  isVoiceInput.value = !isVoiceInput.value
  message.value = isVoiceInput.value ? '音声入力機能は準備中です' : 'テキスト入力モードです'
}

// 日記削除
const deleteJournal = async (id) => {
  if (!currentUser.value) return
  
  isLoading.value = true
  try {
    const { error } = await supabase
      .from('journals')
      .delete()
      .eq('id', id)
    
    if (error) throw error
    
    message.value = '日記を削除しました'
    await loadJournals()
  } catch (error) {
    message.value = `削除エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="journal-app">
    <div v-if="!currentUser" class="login-required">
      <p>📝 ジャーナル機能を使用するには、まず「Supabaseテスト」タブでログインしてください</p>
    </div>
    
    <div v-else class="journal-content">
      <!-- OpenAI接続状態 -->
      <div class="connection-status">
        <div v-if="isOpenAIConnected" class="status-success">
          ✅ AI機能: 利用可能 (日記整理・メンタル分析・アクティブレスト提案)
        </div>
        <div v-else class="status-warning">
          ⚠️ AI機能: 利用不可 (環境変数VITE_OPENAI_API_KEYを設定してください)
        </div>
      </div>

      <!-- ビュー切り替えタブ -->
      <div class="view-tabs">
        <button 
          @click="activeView = 'record'" 
          :class="['tab-btn', { active: activeView === 'record' }]"
        >
          📝 日記記録・分析
        </button>
        <button 
          @click="activeView = 'calendar'" 
          :class="['tab-btn', { active: activeView === 'calendar' }]"
        >
          📅 カレンダー表示
        </button>
      </div>

      <!-- 日記記録・分析ビュー -->
      <div v-if="activeView === 'record'" class="record-view">
        <!-- 現在のメンタルステージ表示 -->
        <div v-if="currentStage !== null" class="current-stage">
          <h3>📊 現在のメンタルステージ</h3>
          <div class="stage-display">
            <div class="stage-circle" :style="{ backgroundColor: stageColor }">
              <span class="stage-number">{{ currentStage }}</span>
            </div>
            <div class="stage-info">
              <h4>Stage {{ currentStage }}: {{ stageDescription }}</h4>
              <p v-if="stageAnalysis">信頼度: {{ stageAnalysis.confidence }}%</p>
              <div v-if="stageAnalysis && stageAnalysis.emergency" class="emergency-warning">
                ⚠️ 専門機関への相談を強く推奨します
              </div>
            </div>
          </div>
          
          <!-- 分析詳細 -->
          <div v-if="stageAnalysis" class="analysis-details">
            <h5>分析理由:</h5>
            <ul>
              <li v-for="reason in stageAnalysis.reasons" :key="reason">{{ reason }}</li>
            </ul>
            <p><strong>検出キーワード:</strong> {{ stageAnalysis.keywords.join(', ') }}</p>
            <small>分析モデル: {{ stageAnalysis.model_used }} | {{ new Date(stageAnalysis.analysis_date).toLocaleString('ja-JP') }}</small>
          </div>
        </div>

        <!-- アクティブレスト提案 -->
        <div v-if="activeRestRecommendations" class="active-rest">
          <h3>🎯 あなたへのアクティブレスト提案</h3>
          <div class="recommendations-grid">
            <div v-for="rec in activeRestRecommendations.recommendations" :key="rec.title" class="rec-card">
              <h4>{{ rec.title }}</h4>
              <div class="rec-meta">
                <span class="rec-type">{{ rec.type }}</span>
                <span class="rec-duration">{{ rec.duration }}</span>
              </div>
              <p>{{ rec.description }}</p>
              <p v-if="rec.materials"><strong>必要なもの:</strong> {{ rec.materials }}</p>
            </div>
          </div>
          
          <div v-if="activeRestRecommendations.emergency_message" class="emergency-message">
            ⚠️ {{ activeRestRecommendations.emergency_message }}
          </div>
        </div>

        <!-- 今日の日記入力 -->
        <div class="journal-entry">
          <h3>📝 {{ hasWrittenToday ? '今日の日記（記録済み）' : '今日の日記を書く' }}</h3>
          
          <div v-if="hasWrittenToday" class="today-journal">
            <div class="journal-card">
              <h4>{{ todayJournal.title }}</h4>
              <p>{{ todayJournal.content }}</p>
              <small>{{ new Date(todayJournal.created_at).toLocaleString('ja-JP') }}</small>
              <div v-if="todayJournal.ai_metadata" class="ai-badge">
                ✨ AI整理済み
              </div>
            </div>
          </div>
          
          <div v-else class="entry-form">
            <div class="form-header">
              <button @click="toggleVoiceInput" :class="['voice-btn', { active: isVoiceInput }]">
                {{ isVoiceInput ? '🎤 音声入力' : '⌨️ テキスト入力' }}
              </button>
            </div>
            
            <input 
              v-model="newJournalTitle" 
              type="text" 
              placeholder="今日のタイトル (例: 忙しい一日、リラックスした午後)"
              class="form-input"
            />
            
            <textarea 
              v-model="newJournalContent" 
              placeholder="今日あったこと、感じたことを自由に書いてください。AIが読みやすく整理します..."
              class="form-textarea"
              rows="6"
            ></textarea>
            
            <button @click="saveJournal" :disabled="isLoading" class="btn btn-primary">
              {{ isLoading ? '保存中...' : 'AI整理して保存' }}
            </button>
          </div>
        </div>

        <!-- 週間分析ボタン -->
        <div class="analysis-section">
          <h3>🧠 週間メンタル分析</h3>
          <p>過去7日間の日記 {{ weeklyJournals.length }} 件を分析します</p>
          <button 
            @click="analyzeWeeklyMentalStage" 
            :disabled="isLoading || weeklyJournals.length === 0 || !isOpenAIConnected"
            class="btn btn-secondary"
          >
            {{ isLoading ? '分析中...' : 'メンタルステージを分析' }}
          </button>
        </div>

        <!-- 過去の日記一覧 -->
        <div class="journal-history">
          <h3>📚 過去の日記 ({{ journals.length }} 件)</h3>
          
          <div v-if="journals.length === 0" class="no-journals">
            <p>まだ日記がありません。今日から始めてみましょう！</p>
          </div>
          
          <div v-else class="journals-list">
            <div v-for="journal in journals.slice(0, 5)" :key="journal.id" class="journal-item">
              <div class="journal-header">
                <h4>{{ journal.title }}</h4>
                <small>{{ new Date(journal.created_at).toLocaleString('ja-JP') }}</small>
                <button @click="deleteJournal(journal.id)" class="btn-delete">削除</button>
              </div>
              <p>{{ journal.content }}</p>
              
              <div v-if="journal.ai_metadata" class="ai-metadata">
                <div class="ai-badge">✨ AI整理済み</div>
                <div class="metadata-details">
                  <span>感情: {{ journal.ai_metadata.detected_emotions?.join(', ') || 'なし' }}</span>
                  <span>出来事: {{ journal.ai_metadata.key_events?.join(', ') || 'なし' }}</span>
                </div>
              </div>
            </div>
            
            <div v-if="journals.length > 5" class="view-more">
              <p>さらに {{ journals.length - 5 }} 件の日記があります</p>
              <button @click="activeView = 'calendar'" class="btn btn-secondary">
                📅 カレンダーで全ての日記を確認
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- カレンダー表示ビュー -->
      <div v-if="activeView === 'calendar'" class="calendar-view">
        <JournalCalendar 
          :currentUser="currentUser" 
          :journals="journals"
        />
      </div>

      <!-- ステータスメッセージ -->
      <div v-if="message" class="status-message">
        {{ message }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.journal-app {
  max-width: 900px;
  margin: 0 auto;
  padding: 1rem;
}

.login-required {
  text-align: center;
  padding: 2rem;
  background: #fef3cd;
  border: 1px solid #fbbf24;
  border-radius: 8px;
  color: #92400e;
}

.connection-status {
  margin-bottom: 2rem;
  padding: 1rem;
  border-radius: 8px;
}

.status-success {
  background: #f0fff4;
  color: #22543d;
  border: 1px solid #9ae6b4;
}

.status-warning {
  background: #fef3cd;
  color: #92400e;
  border: 1px solid #fbbf24;
}

.view-tabs {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  border-bottom: 1px solid #e2e8f0;
}

.tab-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  background: transparent;
  color: #4a5568;
  font-weight: 500;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  transition: all 0.3s ease;
}

.tab-btn:hover {
  color: #2d3748;
  background: #f7fafc;
}

.tab-btn.active {
  color: #3182ce;
  border-bottom-color: #3182ce;
  background: #ebf8ff;
}

.current-stage {
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
  border-radius: 15px;
  padding: 2rem;
  margin-bottom: 2rem;
}

.stage-display {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 1rem;
}

.stage-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}

.stage-number {
  font-size: 2rem;
}

.stage-info h4 {
  margin: 0 0 0.5rem 0;
  color: #2d3748;
}

.emergency-warning {
  background: #fed7d7;
  color: #742a2a;
  padding: 0.5rem;
  border-radius: 6px;
  margin-top: 0.5rem;
  font-weight: bold;
}

.analysis-details {
  background: white;
  padding: 1rem;
  border-radius: 8px;
  margin-top: 1rem;
}

.analysis-details ul {
  margin: 0.5rem 0;
  padding-left: 1.5rem;
}

.active-rest {
  margin-bottom: 2rem;
}

.active-rest h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.recommendations-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.rec-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
}

.rec-card h4 {
  color: #2d3748;
  margin-bottom: 0.5rem;
}

.rec-meta {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  font-size: 0.875rem;
}

.rec-type {
  background: #e2e8f0;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  color: #4a5568;
}

.rec-duration {
  background: #bee3f8;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  color: #2c5282;
}

.emergency-message {
  background: #fed7d7;
  color: #742a2a;
  padding: 1rem;
  border-radius: 8px;
  font-weight: bold;
  text-align: center;
}

.journal-entry {
  background: white;
  border-radius: 10px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.journal-entry h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.today-journal .journal-card {
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  border-radius: 8px;
  padding: 1rem;
}

.form-header {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 1rem;
}

.voice-btn {
  padding: 0.5rem 1rem;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
}

.voice-btn.active {
  background: #3b82f6;
  color: white;
  border-color: #3b82f6;
}

.entry-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-input, .form-textarea {
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 1rem;
  font-family: inherit;
}

.form-textarea {
  resize: vertical;
  min-height: 120px;
}

.analysis-section {
  background: white;
  border-radius: 10px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  text-align: center;
}

.journal-history h3 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.no-journals {
  text-align: center;
  padding: 2rem;
  color: #4a5568;
}

.journals-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.journal-item {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1rem;
}

.journal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.journal-header h4 {
  margin: 0;
  color: #2d3748;
}

.btn-delete {
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  cursor: pointer;
}

.ai-badge {
  display: inline-block;
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.75rem;
  margin-top: 0.5rem;
}

.ai-metadata {
  margin-top: 0.5rem;
  padding-top: 0.5rem;
  border-top: 1px solid #e2e8f0;
}

.metadata-details {
  display: flex;
  gap: 1rem;
  margin-top: 0.5rem;
  font-size: 0.875rem;
  color: #4a5568;
}

.view-more {
  text-align: center;
  padding: 1.5rem;
  border: 2px dashed #e2e8f0;
  border-radius: 8px;
  background: #f9fafb;
}

.view-more p {
  color: #4a5568;
  margin-bottom: 1rem;
}

.status-message {
  margin-top: 1rem;
  padding: 0.75rem;
  background: #ebf8ff;
  border: 1px solid #bee3f8;
  border-radius: 6px;
  color: #2c5282;
  text-align: center;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-primary {
  background-color: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #2563eb;
}

.btn-secondary {
  background-color: #6b7280;
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background-color: #4b5563;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .view-tabs {
    flex-direction: column;
    gap: 0;
  }
  
  .tab-btn {
    border-bottom: 1px solid #e2e8f0;
    border-radius: 0;
  }
  
  .tab-btn.active {
    border-left: 4px solid #3182ce;
    border-bottom: 1px solid #e2e8f0;
  }
  
  .stage-display {
    flex-direction: column;
    text-align: center;
  }
  
  .recommendations-grid {
    grid-template-columns: 1fr;
  }
  
  .metadata-details {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .journal-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
</style> 