<script setup>
import { ref, computed, onMounted } from 'vue'
import WeeklyStageChart from './WeeklyStageChart.vue'
import { analyzeJournalForStage, generateActiveRestRecommendations } from '../openai.js'
import { supabase } from '../supabase.js'

// Props
const props = defineProps({
  currentUser: Object,
  journals: Array,
  isOpenAIConnected: Boolean
})

// Emits
const emit = defineEmits(['navigateToJournal'])

// リアクティブ状態
const currentStage = ref(null)
const stageAnalysis = ref(null)
const activeRestRecommendations = ref(null)
const isLoading = ref(false)
const message = ref('')
const weeklyAnalysisResults = ref([])
const isGeneratingRecommendations = ref(false) // 休養法生成中フラグ

// 週単位の日付計算ヘルパー関数
const getWeekStartDate = (date = new Date()) => {
  const d = new Date(date)
  const day = d.getDay() // 0 = Sunday, 1 = Monday, ...
  const diff = d.getDate() - day // 日曜日までの差分
  d.setDate(diff)
  d.setHours(0, 0, 0, 0)
  return d
}

const getWeekEndDate = (startDate) => {
  const d = new Date(startDate)
  d.setDate(d.getDate() + 6)
  d.setHours(23, 59, 59, 999)
  return d
}

const formatDateToLocalString = (date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// 計算されたプロパティ
const currentWeekStart = computed(() => getWeekStartDate())
const currentWeekEnd = computed(() => getWeekEndDate(currentWeekStart.value))

const currentWeekJournals = computed(() => {
  if (!props.journals) return []
  
  const startStr = formatDateToLocalString(currentWeekStart.value)
  const endStr = formatDateToLocalString(currentWeekEnd.value)
  
  return props.journals.filter(j => {
    const entryDate = j.entry_date || (j.created_at ? j.created_at.split('T')[0] : null)
    return entryDate && entryDate >= startStr && entryDate <= endStr
  })
})

const currentWeekAnalysis = computed(() => {
  const startStr = formatDateToLocalString(currentWeekStart.value)
  return weeklyAnalysisResults.value.find(w => w.week_start_date === startStr)
})

const canAnalyzeCurrentWeek = computed(() => {
  // 今週の分析がまだない場合のみ分析可能
  if (currentWeekAnalysis.value) return false
  
  // 今週に日記が1件以上ある場合分析可能
  return currentWeekJournals.value.length > 0
})

const isCurrentWeekComplete = computed(() => {
  // 現在の週が終了している（今日が月曜日以降で先週の週末を過ぎている）
  const today = new Date()
  const weekEnd = getWeekEndDate(getWeekStartDate(today))
  return today > weekEnd
})

const weeklyJournals = computed(() => {
  // 互換性のため残す（レガシー）
  return currentWeekJournals.value
})

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

// ステージレベルの色を取得
const getStageColor = (level) => {
  const colors = {
    0: '#38b2ac', // 緑
    1: '#4299e1', // 青
    2: '#ed8936', // オレンジ
    3: '#e53e3e', // 赤
    4: '#9f7aea'  // 紫
  }
  return colors[level] || '#e2e8f0'
}

// ステージ凡例データ
const stageLegend = [
  { level: 0, label: 'Stage 0: 正常', description: 'エネルギッシュで前向きな状態' },
  { level: 1, label: 'Stage 1: 軽度疲労', description: '少し気力が低下している状態' },
  { level: 2, label: 'Stage 2: 中度疲労', description: 'イライラや疲労感が増している状態' },
  { level: 3, label: 'Stage 3: 重度疲労', description: '感情コントロールが困難な状態' },
  { level: 4, label: 'Stage 4: 危険域', description: '専門的な支援が必要な状態' }
]

const todayJournal = computed(() => {
  if (!props.journals) return null
  const today = new Date().toISOString().split('T')[0]
  return props.journals.find(j => j.created_at.startsWith(today))
})

// 週間分析結果をDBから読み込み
const loadWeeklyAnalysis = async () => {
  if (!props.currentUser) return
  
  try {
    const { data, error } = await supabase
      .from('weekly_analysis')
      .select('*')
      .order('week_start_date', { ascending: false })
    
    if (error) throw error
    
    weeklyAnalysisResults.value = data || []
    
    // 最新の分析結果から現在のステージを設定
    if (data && data.length > 0) {
      const latestAnalysis = data[0]
      currentStage.value = latestAnalysis.stage_level
      stageAnalysis.value = {
        stage: latestAnalysis.stage_level,
        confidence: latestAnalysis.confidence,
        ...latestAnalysis.analysis_data
      }
      
      // アクティブレスト提案を生成
      await generateRecommendations()
    }
    
  } catch (error) {
    console.error('週間分析読み込みエラー:', error)
    message.value = `分析結果の読み込みエラー: ${error.message}`
  }
}

// 週間分析結果をDBに保存
const saveWeeklyAnalysis = async (analysisData) => {
  if (!props.currentUser) return false
  
  try {
    const weekStart = formatDateToLocalString(currentWeekStart.value)
    const weekEnd = formatDateToLocalString(currentWeekEnd.value)
    
    const { data, error } = await supabase
      .from('weekly_analysis')
      .upsert([
        {
          user_id: props.currentUser.id,
          week_start_date: weekStart,
          week_end_date: weekEnd,
          stage_level: analysisData.stage,
          confidence: analysisData.confidence,
          analysis_data: analysisData,
          journal_count: currentWeekJournals.value.length
        }
      ])
      .select()
    
    if (error) throw error
    
    // ローカル状態を更新
    await loadWeeklyAnalysis()
    
    return true
  } catch (error) {
    console.error('週間分析保存エラー:', error)
    message.value = `分析結果の保存エラー: ${error.message}`
    return false
  }
}

// 週間メンタルステージ分析
const analyzeWeeklyMentalStage = async () => {
  if (!props.currentUser || currentWeekJournals.value.length === 0) {
    message.value = '分析するジャーナルがありません'
    return
  }
  
  if (!props.isOpenAIConnected) {
    message.value = 'AI機能が利用できません'
    return
  }
  
  if (currentWeekAnalysis.value) {
    message.value = 'この週は既に分析済みです'
    return
  }
  
  isLoading.value = true
  try {
    message.value = 'AIがメンタルステージを分析しています...'
    
    const analysisResult = await analyzeJournalForStage(currentWeekJournals.value)
    
    if (analysisResult.success) {
      // DB保存
      const saved = await saveWeeklyAnalysis(analysisResult.data)
      
      if (saved) {
        message.value = ''
        
        // 緊急時の警告
        if (analysisResult.data.emergency) {
          message.value = '⚠️ 専門的なサポートを推奨します'
        }
        
        // アクティブレスト提案を自動生成
        await generateRecommendations()
      }
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
  if (!props.isOpenAIConnected || currentStage.value === null) return
  
  isGeneratingRecommendations.value = true
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
  } finally {
    isGeneratingRecommendations.value = false
  }
}

// 初期化時にDBから週間分析結果を読み込み
onMounted(async () => {
  if (props.currentUser) {
    await loadWeeklyAnalysis()
  }
})

// 今日の日記作成ページに遷移
const navigateToJournal = () => {
  const today = new Date().toISOString().split('T')[0]
  emit('navigateToJournal', today)
}
</script>

<template>
  <div class="home-view">
    <!-- 今日の記録状況 -->
    <div v-if="!todayJournal" class="today-status">
      <div class="today-pending">
        <div class="status-card pending">
          <div class="status-icon">📝</div>
          <div class="status-text">
            <h3>今日の日記を書きましょう</h3>
            <p>メンタル状態を記録して分析を始めましょう</p>
          </div>
        </div>
        <button @click="navigateToJournal" class="btn btn-primary write-today-btn">
          📝 日記を書く
        </button>
      </div>
    </div>

    <!-- 現在のメンタルステージ -->
    <div v-if="currentStage !== null" class="current-stage">
      <h2>🧠 現在のメンタルステージ</h2>
      <div class="stage-display">
        <div class="stage-circle" :style="{ backgroundColor: stageColor }">
          <span class="stage-number">{{ currentStage }}</span>
        </div>
        <div class="stage-info">
          <h3>Stage {{ currentStage }}</h3>
          <p>{{ stageDescription }}</p>
          <!-- 分析対象と信頼度の表示を削除 -->
        </div>
      </div>
      
      <!-- ステージ凡例 -->
      <div class="stage-legend">
        <h4>ステージ凡例</h4>
        <div class="legend-items">
          <div v-for="stage in stageLegend" :key="stage.level" class="legend-item">
            <div class="legend-dot" :style="{ backgroundColor: getStageColor(stage.level) }"></div>
            <div class="legend-text">
              <span class="legend-label">{{ stage.label }}</span>
              <span class="legend-desc">{{ stage.description }}</span>
            </div>
          </div>
        </div>
      </div>
      
      <div v-if="stageAnalysis && stageAnalysis.emergency" class="emergency-warning">
        ⚠️ 専門機関への相談を強く推奨します
      </div>
    </div>

    <!-- アクティブレスト提案 -->
    <div v-if="currentStage !== null" class="active-rest">
      <h2 v-if="isGeneratingRecommendations">🎯 今のあなたに最適な休養法 <span class="analyzing">分析中...</span></h2>
      <h2 v-else-if="activeRestRecommendations">🎯 今のあなたに最適な休養法</h2>
      
      <div v-if="isGeneratingRecommendations" class="analyzing-message">
        <div class="spinner">⏳</div>
        <p>AIがあなたに最適な休養法を分析しています...</p>
      </div>
      
      <div v-else-if="activeRestRecommendations" class="recommendations-grid">
        <div v-for="rec in activeRestRecommendations.recommendations" :key="rec.title" class="rec-card">
          <h4>{{ rec.title }}</h4>
          <div class="rec-meta">
            <span class="rec-type">{{ rec.type }}</span>
            <span class="rec-duration">{{ rec.duration }}</span>
          </div>
          <p>{{ rec.description }}</p>
        </div>
      </div>
    </div>

    <!-- 週間分析ボタン -->
    <div v-if="canAnalyzeCurrentWeek && !currentWeekAnalysis" class="analysis-prompt">
      <h2>📊 今週の分析</h2>
      <p>今週の日記 {{ currentWeekJournals.length }} 件を分析して、メンタルステージを確認しましょう</p>
      <button 
        @click="analyzeWeeklyMentalStage" 
        :disabled="isLoading || !props.isOpenAIConnected"
        class="btn btn-primary"
      >
        {{ isLoading ? '分析中...' : '🧠 今週の分析を実行' }}
      </button>
      <p class="analysis-note">※分析実行後は過去の日記編集ができなくなります</p>
    </div>

    <!-- 週次推移グラフ -->
    <div class="weekly-trends">
      <WeeklyStageChart 
        :journals="journals"
        :currentUser="currentUser"
        :isOpenAIConnected="isOpenAIConnected"
      />
    </div>

    <!-- ステータスメッセージ -->
    <div v-if="message" class="status-message">
      {{ message }}
    </div>
  </div>
</template>

<style scoped>
.home-view {
  padding: 1rem;
  padding-bottom: 5rem; /* ボトムナビゲーション分のスペース */
  max-width: 100%;
}

.today-status {
  margin-bottom: 2rem;
}

.today-status h2 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

.status-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-radius: 12px;
  border: 1px solid;
}

.status-card.success {
  background: #f0fff4;
  border-color: #9ae6b4;
}

.status-card.pending {
  background: #fef3cd;
  border-color: #fbbf24;
}

.status-icon {
  font-size: 2rem;
}

.status-text h3 {
  margin: 0 0 0.25rem 0;
  color: #2d3748;
  font-size: 1rem;
}

.status-text p {
  margin: 0;
  color: #4a5568;
  font-size: 0.875rem;
}

.write-today-btn {
  margin-top: 1rem;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  width: 100%;
}

.current-stage {
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
  border-radius: 15px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.current-stage h2 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

.stage-display {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.stage-circle {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
  flex-shrink: 0;
}

.stage-number {
  font-size: 1.5rem;
}

.stage-info h3 {
  margin: 0 0 0.25rem 0;
  color: #2d3748;
  font-size: 1.125rem;
}

.stage-info p {
  margin: 0 0 0.5rem 0;
  color: #4a5568;
  font-size: 0.875rem;
}

.stage-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.75rem;
  color: #6b7280;
}

.stage-legend {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.stage-legend h4 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 1rem;
}

.legend-items {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
  color: #4a5568;
}

.legend-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.legend-label {
  font-weight: bold;
}

.legend-desc {
  font-size: 0.75rem;
  color: #6b7280;
}

.emergency-warning {
  background: #fed7d7;
  color: #742a2a;
  padding: 0.75rem;
  border-radius: 8px;
  font-weight: bold;
  text-align: center;
}

.active-rest {
  margin-bottom: 2rem;
}

.active-rest h2 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

.recommendations-grid {
  display: grid;
  gap: 1rem;
}

.rec-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
}

.rec-card h4 {
  color: #2d3748;
  margin: 0 0 0.5rem 0;
  font-size: 1rem;
}

.rec-meta {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
  font-size: 0.75rem;
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

.rec-card p {
  margin: 0;
  color: #4a5568;
  font-size: 0.875rem;
  line-height: 1.4;
}

.analyzing-message {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #4a5568;
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

.analyzing {
  color: #3b82f6;
  font-size: 0.875rem;
  font-weight: normal;
}

.spinner {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.analysis-prompt {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  text-align: center;
}

.analysis-prompt h2 {
  color: #2d3748;
  margin-bottom: 0.5rem;
  font-size: 1.25rem;
}

.analysis-prompt p {
  color: #4a5568;
  margin-bottom: 1rem;
  font-size: 0.875rem;
}

.analysis-note {
  margin-top: 0.5rem;
  font-size: 0.75rem;
  color: #718096;
}

.weekly-trends h2 {
  color: #2d3748;
  margin-bottom: 1rem;
  font-size: 1.25rem;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 500;
}

.btn-primary {
  background-color: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #2563eb;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.status-message {
  margin-top: 1rem;
  padding: 0.75rem;
  background: #ebf8ff;
  border: 1px solid #bee3f8;
  border-radius: 8px;
  color: #2c5282;
  text-align: center;
  font-size: 0.875rem;
}

@media (max-width: 768px) {
  .stage-display {
    flex-direction: column;
    text-align: center;
    gap: 1rem;
  }
  
  .stage-meta {
    flex-direction: column;
    gap: 0.25rem;
  }
  
  .recommendations-grid {
    grid-template-columns: 1fr;
  }
}
</style> 