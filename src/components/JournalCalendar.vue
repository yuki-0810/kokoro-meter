<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../supabase.js'

// Props
const props = defineProps({
  currentUser: Object,
  journals: Array
})

// リアクティブ状態
const currentDate = ref(new Date())
const selectedDate = ref(null)
const selectedJournal = ref(null)
const isLoading = ref(false)
const message = ref('')

// 日本語の月名と曜日
const monthNames = [
  '1月', '2月', '3月', '4月', '5月', '6月',
  '7月', '8月', '9月', '10月', '11月', '12月'
]

const dayNames = ['日', '月', '火', '水', '木', '金', '土']

// 計算されたプロパティ
const currentYear = computed(() => currentDate.value.getFullYear())
const currentMonth = computed(() => currentDate.value.getMonth())

// 現在表示中の月の日記データをマップ化
const journalMap = computed(() => {
  const map = new Map()
  
  if (props.journals) {
    props.journals.forEach(journal => {
      const entryDate = journal.entry_date || journal.created_at.split('T')[0]
      map.set(entryDate, journal)
    })
  }
  
  return map
})

// カレンダーの日付配列を生成
const calendarDays = computed(() => {
  const year = currentYear.value
  const month = currentMonth.value
  
  // 月の最初の日と最後の日
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  
  // 最初の週の開始日（前月の日曜日）
  const startDate = new Date(firstDay)
  startDate.setDate(startDate.getDate() - firstDay.getDay())
  
  // カレンダーの日付配列
  const days = []
  const current = new Date(startDate)
  
  // 6週分の日付を生成（42日）
  for (let i = 0; i < 42; i++) {
    const dateStr = current.toISOString().split('T')[0]
    const journal = journalMap.value.get(dateStr)
    
    days.push({
      date: new Date(current),
      dateStr: dateStr,
      day: current.getDate(),
      isCurrentMonth: current.getMonth() === month,
      isToday: isToday(current),
      hasJournal: !!journal,
      journal: journal,
      stageLevel: journal?.ai_metadata?.stage_level || null
    })
    
    current.setDate(current.getDate() + 1)
  }
  
  return days
})

// 今日かどうか判定
const isToday = (date) => {
  const today = new Date()
  return date.toDateString() === today.toDateString()
}

// 月を変更
const changeMonth = (delta) => {
  const newDate = new Date(currentDate.value)
  newDate.setMonth(newDate.getMonth() + delta)
  currentDate.value = newDate
}

// 日付をクリック
const selectDate = (dayObj) => {
  if (!dayObj.isCurrentMonth) return
  
  selectedDate.value = dayObj.dateStr
  selectedJournal.value = dayObj.journal
  
  if (dayObj.hasJournal) {
    message.value = `${dayObj.dateStr} の日記を表示しています`
  } else {
    message.value = `${dayObj.dateStr} には日記がありません`
  }
}

// 日付セルのクラス
const getDayClass = (dayObj) => {
  const classes = ['calendar-day']
  
  if (!dayObj.isCurrentMonth) classes.push('other-month')
  if (dayObj.isToday) classes.push('today')
  if (dayObj.hasJournal) classes.push('has-journal')
  if (selectedDate.value === dayObj.dateStr) classes.push('selected')
  
  // ステージレベルに応じたクラス
  if (dayObj.stageLevel !== null) {
    classes.push(`stage-${dayObj.stageLevel}`)
  }
  
  return classes.join(' ')
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

// 月の統計情報
const monthStats = computed(() => {
  const daysInMonth = calendarDays.value.filter(day => day.isCurrentMonth)
  const journalDays = daysInMonth.filter(day => day.hasJournal)
  
  return {
    totalDays: daysInMonth.length,
    journalDays: journalDays.length,
    percentage: Math.round((journalDays.length / daysInMonth.length) * 100)
  }
})

// 日記を削除
const deleteJournal = async (journalId) => {
  if (!props.currentUser || !journalId) return
  
  isLoading.value = true
  try {
    const { error } = await supabase
      .from('journals')
      .delete()
      .eq('id', journalId)
    
    if (error) throw error
    
    selectedJournal.value = null
    selectedDate.value = null
    message.value = '日記を削除しました'
    
    // 親コンポーネントに削除を通知（イベント発行）
    window.location.reload() // 簡易的な更新
  } catch (error) {
    message.value = `削除エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 今日に移動
const goToToday = () => {
  currentDate.value = new Date()
  const today = new Date().toISOString().split('T')[0]
  const todayJournal = journalMap.value.get(today)
  
  selectedDate.value = today
  selectedJournal.value = todayJournal
  
  if (todayJournal) {
    message.value = '今日の日記を表示しています'
  } else {
    message.value = '今日はまだ日記を書いていません'
  }
}
</script>

<template>
  <div class="journal-calendar">
    <div class="calendar-container">
      <!-- カレンダーヘッダー -->
      <div class="calendar-header">
        <div class="month-navigation">
          <button @click="changeMonth(-1)" class="nav-btn">‹</button>
          <h3 class="month-title">{{ currentYear }}年 {{ monthNames[currentMonth] }}</h3>
          <button @click="changeMonth(1)" class="nav-btn">›</button>
        </div>
        
        <div class="calendar-controls">
          <button @click="goToToday" class="btn btn-secondary">今日</button>
        </div>
      </div>

      <!-- 月の統計 -->
      <div class="month-stats">
        <div class="stat-item">
          <span class="stat-label">記録日数:</span>
          <span class="stat-value">{{ monthStats.journalDays }} / {{ monthStats.totalDays }}日</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">達成率:</span>
          <span class="stat-value">{{ monthStats.percentage }}%</span>
        </div>
      </div>

      <!-- 曜日ヘッダー -->
      <div class="weekdays">
        <div v-for="day in dayNames" :key="day" class="weekday">
          {{ day }}
        </div>
      </div>

      <!-- カレンダーグリッド -->
      <div class="calendar-grid">
        <div 
          v-for="dayObj in calendarDays" 
          :key="dayObj.dateStr"
          :class="getDayClass(dayObj)"
          @click="selectDate(dayObj)"
        >
          <div class="day-number">{{ dayObj.day }}</div>
          <div v-if="dayObj.hasJournal" class="journal-indicator">
            <div 
              class="stage-dot" 
              :style="{ backgroundColor: getStageColor(dayObj.stageLevel) }"
            ></div>
          </div>
        </div>
      </div>

      <!-- ステージレベル凡例 -->
      <div class="legend">
        <h4>ステージレベル凡例:</h4>
        <div class="legend-items">
          <div class="legend-item">
            <div class="legend-dot" :style="{ backgroundColor: getStageColor(0) }"></div>
            <span>Stage 0: 正常</span>
          </div>
          <div class="legend-item">
            <div class="legend-dot" :style="{ backgroundColor: getStageColor(1) }"></div>
            <span>Stage 1: 軽度疲労</span>
          </div>
          <div class="legend-item">
            <div class="legend-dot" :style="{ backgroundColor: getStageColor(2) }"></div>
            <span>Stage 2: 中度疲労</span>
          </div>
          <div class="legend-item">
            <div class="legend-dot" :style="{ backgroundColor: getStageColor(3) }"></div>
            <span>Stage 3: 重度疲労</span>
          </div>
          <div class="legend-item">
            <div class="legend-dot" :style="{ backgroundColor: getStageColor(4) }"></div>
            <span>Stage 4: 危険域</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 選択された日記の詳細表示 -->
    <div v-if="selectedDate" class="journal-detail">
      <div class="detail-header">
        <h3>{{ selectedDate }} の日記</h3>
        <button v-if="selectedJournal" @click="deleteJournal(selectedJournal.id)" class="btn-delete">
          削除
        </button>
      </div>

      <div v-if="selectedJournal" class="journal-content">
        <div class="journal-card">
          <h4>{{ selectedJournal.title }}</h4>
          <p class="journal-text">{{ selectedJournal.content }}</p>
          
          <div class="journal-meta">
            <small>{{ new Date(selectedJournal.created_at).toLocaleString('ja-JP') }}</small>
            <div v-if="selectedJournal.ai_metadata" class="ai-badge">
              ✨ AI整理済み
            </div>
          </div>

          <!-- AI分析結果があれば表示 -->
          <div v-if="selectedJournal.ai_metadata" class="ai-analysis">
            <h5>AI分析結果:</h5>
            <div v-if="selectedJournal.ai_metadata.detected_emotions" class="analysis-item">
              <strong>感情:</strong> {{ selectedJournal.ai_metadata.detected_emotions.join(', ') }}
            </div>
            <div v-if="selectedJournal.ai_metadata.key_events" class="analysis-item">
              <strong>出来事:</strong> {{ selectedJournal.ai_metadata.key_events.join(', ') }}
            </div>
            <div v-if="selectedJournal.ai_metadata.stage_level !== undefined" class="analysis-item">
              <strong>ステージレベル:</strong> 
              <span 
                class="stage-badge" 
                :style="{ backgroundColor: getStageColor(selectedJournal.ai_metadata.stage_level) }"
              >
                Stage {{ selectedJournal.ai_metadata.stage_level }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="no-journal">
        <p>この日には日記が記録されていません。</p>
        <small>「今日の日記を書く」セクションから新しい日記を作成できます。</small>
      </div>
    </div>

    <!-- ステータスメッセージ -->
    <div v-if="message" class="status-message">
      {{ message }}
    </div>
  </div>
</template>

<style scoped>
.journal-calendar {
  max-width: 800px;
  margin: 0 auto;
}

.calendar-container {
  background: white;
  border-radius: 10px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.month-navigation {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.nav-btn {
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1.2rem;
  color: #4a5568;
  transition: all 0.2s;
}

.nav-btn:hover {
  background: #edf2f7;
  color: #2d3748;
}

.month-title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #2d3748;
  margin: 0;
  min-width: 140px;
  text-align: center;
}

.month-stats {
  display: flex;
  gap: 2rem;
  margin-bottom: 1rem;
  padding: 1rem;
  background: #f7fafc;
  border-radius: 8px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stat-label {
  color: #4a5568;
  font-weight: 500;
}

.stat-value {
  color: #2d3748;
  font-weight: bold;
}

.weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  margin-bottom: 1px;
}

.weekday {
  background: #4a5568;
  color: white;
  text-align: center;
  padding: 0.75rem 0.5rem;
  font-weight: 600;
  font-size: 0.875rem;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: #e2e8f0;
}

.calendar-day {
  background: white;
  min-height: 80px;
  padding: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.calendar-day:hover {
  background: #f7fafc;
}

.calendar-day.other-month {
  background: #f9fafb;
  color: #9ca3af;
}

.calendar-day.today {
  background: #ebf8ff;
  border: 2px solid #3182ce;
}

.calendar-day.has-journal {
  background: #f0fff4;
}

.calendar-day.selected {
  background: #4299e1;
  color: white;
}

.day-number {
  font-weight: 600;
  font-size: 1rem;
}

.journal-indicator {
  display: flex;
  justify-content: center;
  margin-top: 0.25rem;
}

.stage-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  border: 2px solid white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.legend {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}

.legend h4 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.legend-items {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
  color: #4a5568;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.journal-detail {
  background: white;
  border-radius: 10px;
  padding: 1.5rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  margin-bottom: 1rem;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.detail-header h3 {
  color: #2d3748;
  margin: 0;
}

.journal-card {
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
}

.journal-card h4 {
  color: #2d3748;
  margin-bottom: 1rem;
}

.journal-text {
  color: #4a5568;
  line-height: 1.6;
  margin-bottom: 1rem;
  white-space: pre-wrap;
}

.journal-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}

.ai-badge {
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.75rem;
}

.ai-analysis {
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  padding: 1rem;
  margin-top: 1rem;
}

.ai-analysis h5 {
  color: #2d3748;
  margin-bottom: 0.75rem;
  font-size: 0.9rem;
}

.analysis-item {
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
  color: #4a5568;
}

.stage-badge {
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: bold;
}

.no-journal {
  text-align: center;
  padding: 2rem;
  color: #4a5568;
}

.btn-delete {
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-delete:hover {
  background: #dc2626;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary {
  background: #6b7280;
  color: white;
}

.btn-secondary:hover {
  background: #4b5563;
}

.status-message {
  padding: 0.75rem;
  background: #ebf8ff;
  border: 1px solid #bee3f8;
  border-radius: 6px;
  color: #2c5282;
  text-align: center;
  margin-top: 1rem;
}

@media (max-width: 768px) {
  .calendar-header {
    flex-direction: column;
    gap: 1rem;
  }

  .month-stats {
    flex-direction: column;
    gap: 0.5rem;
  }

  .calendar-day {
    min-height: 60px;
    padding: 0.25rem;
  }

  .day-number {
    font-size: 0.875rem;
  }

  .legend-items {
    flex-direction: column;
    gap: 0.5rem;
  }

  .detail-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
}
</style> 