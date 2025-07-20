<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { 
  analyzeJournalForStage,
  generateActiveRestRecommendations 
} from '../openai.js'

// Props
const props = defineProps({
  currentUser: Object,
  journals: Array,
  isOpenAIConnected: Boolean
})

// リアクティブ状態
const weeklyAnalysis = ref([])
const isLoading = ref(false)
const message = ref('')
const selectedWeek = ref(null)
const selectedWeekRecommendations = ref(null)
const chartContainer = ref(null)
const chartInstance = ref(null)

// 週次データの計算
const weeklyData = computed(() => {
  if (!props.journals || props.journals.length === 0) return []
  
  // 過去12週間のデータを準備
  const weeks = []
  const today = new Date()
  
  for (let i = 11; i >= 0; i--) {
    const weekStart = new Date(today)
    weekStart.setDate(today.getDate() - (today.getDay() + 7 * i))
    weekStart.setHours(0, 0, 0, 0)
    
    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekStart.getDate() + 6)
    weekEnd.setHours(23, 59, 59, 999)
    
    // この週の日記を抽出
    const weekJournals = props.journals.filter(journal => {
      const journalDate = new Date(journal.created_at)
      return journalDate >= weekStart && journalDate <= weekEnd
    })
    
    // 週次ステージレベルを計算（日記のステージレベル平均）
    let weekStageLevel = null
    let confidence = 0
    
    if (weekJournals.length > 0) {
      const stages = weekJournals
        .map(j => j.ai_metadata?.stage_level)
        .filter(s => s !== null && s !== undefined)
      
      if (stages.length > 0) {
        weekStageLevel = Math.round(stages.reduce((sum, stage) => sum + stage, 0) / stages.length)
        confidence = Math.round((stages.length / 7) * 100) // 7日中何日記録したかで信頼度
      }
    }
    
    weeks.push({
      weekNumber: i === 0 ? '今週' : `${i}週前`,
      weekIndex: 11 - i,
      startDate: weekStart,
      endDate: weekEnd,
      dateRange: `${formatDate(weekStart)} - ${formatDate(weekEnd)}`,
      journals: weekJournals,
      journalCount: weekJournals.length,
      stageLevel: weekStageLevel,
      confidence: confidence
    })
  }
  
  return weeks
})

// 日付フォーマット関数
const formatDate = (date) => {
  return `${date.getMonth() + 1}/${date.getDate()}`
}

// ステージレベルの色
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

// ステージレベルの説明
const getStageDescription = (level) => {
  const descriptions = {
    0: '正常 - エネルギッシュで前向きな状態',
    1: '軽度疲労 - 少し気力が低下している状態',
    2: '中度疲労 - イライラや疲労感が増している状態',
    3: '重度疲労 - 感情コントロールが困難な状態',
    4: '危険域 - 専門的な支援が必要な状態'
  }
  return descriptions[level] || '分析不可'
}

// Chart.jsでグラフを描画
const drawChart = () => {
  if (!chartContainer.value || weeklyData.value.length === 0) return
  
  // 既存のチャートを破棄
  if (chartInstance.value) {
    chartInstance.value.destroy()
  }
  
  const ctx = chartContainer.value.getContext('2d')
  
  const labels = weeklyData.value.map(week => week.weekNumber)
  const data = weeklyData.value.map(week => week.stageLevel)
  const colors = weeklyData.value.map(week => 
    week.stageLevel !== null ? getStageColor(week.stageLevel) : '#e2e8f0'
  )
  
  chartInstance.value = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: 'ステージレベル',
        data: data,
        borderColor: '#4299e1',
        backgroundColor: 'rgba(66, 153, 225, 0.1)',
        borderWidth: 3,
        pointBackgroundColor: colors,
        pointBorderColor: '#ffffff',
        pointBorderWidth: 2,
        pointRadius: 8,
        tension: 0.4,
        fill: true
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: {
          display: true,
          text: '週次ステージレベル推移（過去12週間）',
          font: {
            size: 16,
            weight: 'bold'
          }
        },
        legend: {
          display: false
        },
        tooltip: {
          callbacks: {
            title: function(context) {
              const weekIndex = context[0].dataIndex
              const week = weeklyData.value[weekIndex]
              return `${week.weekNumber} (${week.dateRange})`
            },
            label: function(context) {
              const weekIndex = context.dataIndex
              const week = weeklyData.value[weekIndex]
              if (week.stageLevel === null) {
                return '記録なし'
              }
              return [
                `ステージレベル: ${week.stageLevel}`,
                `説明: ${getStageDescription(week.stageLevel)}`,
                `記録日数: ${week.journalCount}/7日`,
                `信頼度: ${week.confidence}%`
              ]
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          max: 4,
          ticks: {
            stepSize: 1,
            callback: function(value) {
              return `Stage ${value}`
            }
          },
          title: {
            display: true,
            text: 'ステージレベル'
          }
        },
        x: {
          title: {
            display: true,
            text: '期間'
          }
        }
      },
      onClick: (event, elements) => {
        if (elements.length > 0) {
          const weekIndex = elements[0].index
          selectWeek(weeklyData.value[weekIndex])
        }
      }
    }
  })
}

// 週を選択
const selectWeek = async (week) => {
  selectedWeek.value = week
  selectedWeekRecommendations.value = null
  
  if (week.stageLevel !== null && props.isOpenAIConnected) {
    // 選択された週のアクティブレスト提案を生成
    try {
      const result = await generateActiveRestRecommendations(week.stageLevel, 'morning')
      if (result.success) {
        selectedWeekRecommendations.value = result.data
      }
    } catch (error) {
      console.error('アクティブレスト提案エラー:', error)
    }
  }
}

// 週次AI分析を実行
const performWeeklyAnalysis = async (week) => {
  if (!props.isOpenAIConnected || week.journals.length === 0) return
  
  isLoading.value = true
  message.value = `${week.weekNumber}の分析中...`
  
  try {
    const result = await analyzeJournalForStage(week.journals)
    if (result.success) {
      // 分析結果を保存（実際の実装では週次分析テーブルに保存）
      const analysis = {
        ...result.data,
        week_start: week.startDate,
        week_end: week.endDate,
        journal_count: week.journals.length
      }
      
      // weeklyAnalysisに追加
      const existingIndex = weeklyAnalysis.value.findIndex(a => 
        a.week_start.getTime() === week.startDate.getTime()
      )
      
      if (existingIndex >= 0) {
        weeklyAnalysis.value[existingIndex] = analysis
      } else {
        weeklyAnalysis.value.push(analysis)
      }
      
      message.value = `${week.weekNumber}の分析完了: Stage ${result.data.stage}`
    }
  } catch (error) {
    message.value = `分析エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 統計情報の計算
const statistics = computed(() => {
  const validWeeks = weeklyData.value.filter(w => w.stageLevel !== null)
  if (validWeeks.length === 0) return null
  
  const levels = validWeeks.map(w => w.stageLevel)
  const average = levels.reduce((sum, level) => sum + level, 0) / levels.length
  const trend = validWeeks.length >= 2 ? 
    validWeeks[validWeeks.length - 1].stageLevel - validWeeks[0].stageLevel : 0
  
  return {
    averageStage: Math.round(average * 10) / 10,
    trend: trend,
    trendDirection: trend > 0 ? 'worsening' : trend < 0 ? 'improving' : 'stable',
    analysisWeeks: validWeeks.length,
    totalWeeks: weeklyData.value.length
  }
})

// Chart.jsを動的読み込み
const loadChart = async () => {
  if (window.Chart) {
    drawChart()
    return
  }
  
  // Chart.jsを動的に読み込み
  const script = document.createElement('script')
  script.src = 'https://cdn.jsdelivr.net/npm/chart.js'
  script.onload = () => {
    drawChart()
  }
  document.head.appendChild(script)
}

// データ変更を監視
watch(() => props.journals, () => {
  if (chartInstance.value) {
    drawChart()
  }
}, { deep: true })

// マウント時の処理
onMounted(() => {
  loadChart()
})
</script>

<template>
  <div class="weekly-stage-chart">
    <div class="chart-header">
      <h3>📈 週次ステージ推移分析</h3>
      <p>過去12週間のメンタルヘルストレンドを可視化します</p>
    </div>

    <!-- 統計サマリー -->
    <div v-if="statistics" class="statistics-summary">
      <div class="stat-card">
        <div class="stat-label">平均ステージ</div>
        <div class="stat-value">{{ statistics.averageStage }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">トレンド</div>
        <div class="stat-value" :class="statistics.trendDirection">
          <span v-if="statistics.trendDirection === 'improving'">📈 改善傾向</span>
          <span v-else-if="statistics.trendDirection === 'worsening'">📉 悪化傾向</span>
          <span v-else>➡️ 安定</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-label">分析週数</div>
        <div class="stat-value">{{ statistics.analysisWeeks }}/{{ statistics.totalWeeks }}週</div>
      </div>
    </div>

    <!-- チャート表示 -->
    <div class="chart-container">
      <canvas ref="chartContainer" width="800" height="400"></canvas>
    </div>

    <!-- 週次データテーブル -->
    <div class="weekly-data-table">
      <h4>週次詳細データ</h4>
      <div class="table-container">
        <table>
          <thead>
            <tr>
              <th>期間</th>
              <th>ステージレベル</th>
              <th>記録日数</th>
              <th>信頼度</th>
              <th>アクション</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="week in weeklyData" 
              :key="week.weekIndex"
              :class="{ 'selected-week': selectedWeek?.weekIndex === week.weekIndex }"
              @click="selectWeek(week)"
            >
              <td>
                <div class="week-info">
                  <div class="week-label">{{ week.weekNumber }}</div>
                  <div class="week-dates">{{ week.dateRange }}</div>
                </div>
              </td>
              <td>
                <div v-if="week.stageLevel !== null" class="stage-display">
                  <div 
                    class="stage-dot" 
                    :style="{ backgroundColor: getStageColor(week.stageLevel) }"
                  ></div>
                  <span>Stage {{ week.stageLevel }}</span>
                </div>
                <span v-else class="no-data">記録なし</span>
              </td>
              <td>{{ week.journalCount }}/7日</td>
              <td>
                <span v-if="week.stageLevel !== null">{{ week.confidence }}%</span>
                <span v-else>-</span>
              </td>
              <td>
                <button 
                  v-if="week.journals.length > 0 && isOpenAIConnected"
                  @click.stop="performWeeklyAnalysis(week)"
                  :disabled="isLoading"
                  class="btn btn-small"
                >
                  {{ isLoading ? '分析中...' : 'AI分析' }}
                </button>
                <span v-else-if="week.journals.length === 0" class="no-action">-</span>
                <span v-else class="ai-disabled">AI接続なし</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 選択された週の詳細 -->
    <div v-if="selectedWeek" class="selected-week-detail">
      <h4>{{ selectedWeek.weekNumber }} 詳細分析</h4>
      
      <div class="week-overview">
        <div class="overview-item">
          <strong>期間:</strong> {{ selectedWeek.dateRange }}
        </div>
        <div class="overview-item">
          <strong>記録日数:</strong> {{ selectedWeek.journalCount }}/7日
        </div>
        <div v-if="selectedWeek.stageLevel !== null" class="overview-item">
          <strong>ステージレベル:</strong> 
          <span 
            class="stage-badge" 
            :style="{ backgroundColor: getStageColor(selectedWeek.stageLevel) }"
          >
            Stage {{ selectedWeek.stageLevel }}
          </span>
        </div>
        <div v-if="selectedWeek.stageLevel !== null" class="overview-item">
          <strong>状態:</strong> {{ getStageDescription(selectedWeek.stageLevel) }}
        </div>
      </div>

      <!-- この週の日記リスト -->
      <div v-if="selectedWeek.journals.length > 0" class="week-journals">
        <h5>この週の日記 ({{ selectedWeek.journals.length }}件)</h5>
        <div class="journals-grid">
          <div 
            v-for="journal in selectedWeek.journals" 
            :key="journal.id" 
            class="journal-mini-card"
          >
            <div class="journal-date">
              {{ new Date(journal.created_at).toLocaleDateString('ja-JP') }}
            </div>
            <div class="journal-title">{{ journal.title }}</div>
            <div v-if="journal.ai_metadata?.stage_level !== undefined" class="journal-stage">
              <div 
                class="mini-stage-dot" 
                :style="{ backgroundColor: getStageColor(journal.ai_metadata.stage_level) }"
              ></div>
              Stage {{ journal.ai_metadata.stage_level }}
            </div>
          </div>
        </div>
      </div>

      <!-- アクティブレスト提案 -->
      <div v-if="selectedWeekRecommendations" class="week-recommendations">
        <h5>🎯 この週のアクティブレスト提案</h5>
        <div class="recommendations-grid">
          <div 
            v-for="rec in selectedWeekRecommendations.recommendations" 
            :key="rec.title" 
            class="rec-card-mini"
          >
            <h6>{{ rec.title }}</h6>
            <div class="rec-meta-mini">
              <span class="rec-type-mini">{{ rec.type }}</span>
              <span class="rec-duration-mini">{{ rec.duration }}</span>
            </div>
            <p class="rec-description-mini">{{ rec.description }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ステータスメッセージ -->
    <div v-if="message" class="status-message">
      {{ message }}
    </div>
  </div>
</template>

<style scoped>
.weekly-stage-chart {
  max-width: 1000px;
  margin: 0 auto;
  padding: 1rem;
  padding-bottom: 2rem; /* ボトムナビゲーション用の追加スペース */
}

.chart-header {
  text-align: center;
  margin-bottom: 1.5rem;
}

.chart-header h3 {
  color: #2d3748;
  margin-bottom: 0.5rem;
  font-size: 1.125rem;
}

.chart-header p {
  color: #4a5568;
  font-size: 0.8rem;
}

.statistics-summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.stat-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 0.75rem;
  text-align: center;
}

.stat-label {
  font-size: 0.75rem;
  color: #4a5568;
  margin-bottom: 0.25rem;
}

.stat-value {
  font-size: 1.25rem;
  font-weight: bold;
  color: #2d3748;
}

.stat-value.improving {
  color: #38a169;
}

.stat-value.worsening {
  color: #e53e3e;
}

.stat-value.stable {
  color: #4299e1;
}

.chart-container {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  margin-bottom: 1.5rem;
  height: 250px; /* モバイル向けに高さを調整 */
}

.weekly-data-table {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  margin-bottom: 1.5rem;
}

.weekly-data-table h4 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 1rem;
}

.table-container {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8rem;
}

th, td {
  padding: 0.5rem;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

th {
  background: #f7fafc;
  font-weight: 600;
  color: #2d3748;
  font-size: 0.75rem;
}

tbody tr {
  cursor: pointer;
  transition: background 0.2s;
}

tbody tr:hover {
  background: #f7fafc;
}

tbody tr.selected-week {
  background: #ebf8ff;
  border-left: 4px solid #4299e1;
}

.week-info {
  display: flex;
  flex-direction: column;
}

.week-label {
  font-weight: 600;
  color: #2d3748;
  font-size: 0.8rem;
}

.week-dates {
  font-size: 0.7rem;
  color: #4a5568;
}

.stage-display {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stage-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  border: 2px solid white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.no-data, .no-action, .ai-disabled {
  color: #9ca3af;
  font-style: italic;
  font-size: 0.75rem;
}

.btn {
  padding: 0.25rem 0.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.7rem;
  transition: all 0.2s;
}

.btn-small {
  background: #4299e1;
  color: white;
}

.btn-small:hover:not(:disabled) {
  background: #3182ce;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.selected-week-detail {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  margin-bottom: 1.5rem;
}

.selected-week-detail h4 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 1rem;
}

.week-overview {
  display: grid;
  grid-template-columns: 1fr;
  gap: 0.5rem;
  margin-bottom: 1rem;
  padding: 0.75rem;
  background: #f7fafc;
  border-radius: 6px;
}

.overview-item {
  font-size: 0.8rem;
  color: #4a5568;
}

.stage-badge {
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: bold;
  margin-left: 0.25rem;
}

.week-journals h5 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.journals-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.journal-mini-card {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  padding: 0.5rem;
}

.journal-date {
  font-size: 0.7rem;
  color: #6b7280;
  margin-bottom: 0.25rem;
}

.journal-title {
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.25rem;
  font-size: 0.8rem;
}

.journal-stage {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.7rem;
  color: #4b5563;
}

.mini-stage-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.week-recommendations h5 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.recommendations-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 0.75rem;
}

.rec-card-mini {
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  border-radius: 6px;
  padding: 0.75rem;
}

.rec-card-mini h6 {
  color: #2d3748;
  margin-bottom: 0.25rem;
  font-size: 0.8rem;
}

.rec-meta-mini {
  display: flex;
  gap: 0.25rem;
  margin-bottom: 0.5rem;
  font-size: 0.7rem;
}

.rec-type-mini {
  background: #e2e8f0;
  padding: 0.125rem 0.25rem;
  border-radius: 3px;
  color: #4a5568;
}

.rec-duration-mini {
  background: #bee3f8;
  padding: 0.125rem 0.25rem;
  border-radius: 3px;
  color: #2c5282;
}

.rec-description-mini {
  font-size: 0.7rem;
  color: #4a5568;
  line-height: 1.4;
  margin: 0;
}

.status-message {
  padding: 0.75rem;
  background: #ebf8ff;
  border: 1px solid #bee3f8;
  border-radius: 6px;
  color: #2c5282;
  text-align: center;
  font-size: 0.8rem;
}

@media (max-width: 768px) {
  .weekly-stage-chart {
    padding: 0.75rem;
  }
  
  .statistics-summary {
    grid-template-columns: 1fr;
    gap: 0.5rem;
  }
  
  .chart-container {
    height: 200px;
    padding: 0.75rem;
  }
  
  .table-container {
    font-size: 0.75rem;
  }
  
  .journals-grid {
    grid-template-columns: 1fr;
  }
  
  .recommendations-grid {
    grid-template-columns: 1fr;
  }
  
  .week-overview {
    grid-template-columns: 1fr;
  }
}
</style> 