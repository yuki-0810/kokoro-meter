<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../supabase.js'

// Props
const props = defineProps({
  currentUser: Object,
  journals: Array
})

// Emits
const emit = defineEmits(['navigateToJournal'])

// 地域時間で日付文字列を生成する関数
const formatDateToLocalString = (date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// 現在の日付状態
const currentDate = ref(new Date())
const selectedDate = ref(formatDateToLocalString(new Date())) // 文字列として初期化
const selectedJournal = ref(null)
const isLoading = ref(false)
const weeklyAnalysisResults = ref([])

// 週単位の日付計算ヘルパー関数（月曜日起点）
const getWeekStartDate = (date = new Date()) => {
  const d = new Date(date)
  const day = d.getDay() // 0 = Sunday, 1 = Monday, ...
  const diff = day === 0 ? -6 : 1 - day // 月曜日までの差分
  d.setDate(d.getDate() + diff)
  d.setHours(0, 0, 0, 0)
  return d
}

const getWeekEndDate = (startDate) => {
  const d = new Date(startDate)
  d.setDate(d.getDate() + 6)
  d.setHours(23, 59, 59, 999)
  return d
}

// 日本語の月名と曜日
const monthNames = [
  '1月', '2月', '3月', '4月', '5月', '6月',
  '7月', '8月', '9月', '10月', '11月', '12月'
]

const dayNames = ['日', '月', '火', '水', '木', '金', '土']

// 計算されたプロパティ
const currentYear = computed(() => currentDate.value.getFullYear())
const currentMonth = computed(() => currentDate.value.getMonth())

// 今日の日付（比較用）
const todayDateString = computed(() => {
  return formatDateToLocalString(new Date())
})

// 現在表示中の月の日記データをマップ化
const journalMap = computed(() => {
  const map = new Map()
  
  if (props.journals) {
    props.journals.forEach(journal => {
      // entry_dateが存在する場合はそれを使用、そうでなければcreated_atから日付部分を抽出
      let entryDate = journal.entry_date
      if (!entryDate && journal.created_at) {
        // created_atが文字列の場合（ISO形式）は日付部分のみ抽出
        if (typeof journal.created_at === 'string') {
          entryDate = journal.created_at.split('T')[0]
        } else {
          // Dateオブジェクトの場合は地域時間で変換
          entryDate = formatDateToLocalString(new Date(journal.created_at))
        }
      }
      if (entryDate) {
        map.set(entryDate, journal)
      }
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
    const dateStr = formatDateToLocalString(current)
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
  
  // 未来日は選択不可
  if (dayObj.dateStr > todayDateString.value) return
  
  selectedDate.value = dayObj.dateStr
  selectedJournal.value = dayObj.journal
}

// 日記作成ページに遷移
const navigateToJournal = (dateStr) => {
  emit('navigateToJournal', dateStr)
}

// 日付セルのクラス
const getDayClass = (dayObj) => {
  const classes = ['calendar-day']
  
  if (!dayObj.isCurrentMonth) classes.push('other-month')
  if (dayObj.isToday) classes.push('today')
  if (dayObj.hasJournal) classes.push('has-journal')
  if (selectedDate.value === dayObj.dateStr) classes.push('selected')
  
  // 未来日は無効化
  if (dayObj.dateStr > todayDateString.value) {
    classes.push('future-date')
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

// DBから週次分析結果を読み込み
const loadWeeklyAnalysis = async () => {
  if (!props.currentUser) return
  
  try {
    const { data, error } = await supabase
      .from('weekly_analysis')
      .select('*')
      .order('week_start_date', { ascending: false })
    
    if (error) throw error
    
    weeklyAnalysisResults.value = data || []
    
  } catch (error) {
    console.error('週間分析読み込みエラー:', error)
  }
}

// 選択された日付の週が分析済みかどうかを判定
const isSelectedDateWeekAnalyzed = computed(() => {
  if (!selectedDate.value) return false
  
  const dateObj = new Date(selectedDate.value)
  const weekStartDate = getWeekStartDate(dateObj)
  const weekStartStr = formatDateToLocalString(weekStartDate)
  
  return weeklyAnalysisResults.value.some(w => w.week_start_date === weekStartStr)
})

// 新規日記作成が可能かどうかを判定
const canCreateNewJournal = computed(() => {
  // 分析済みの週は新規作成不可
  if (isSelectedDateWeekAnalyzed.value) return false
  
  // 未来日は作成不可
  if (selectedDate.value > todayDateString.value) return false
  
  // 既に日記がある場合は作成不可
  if (selectedJournal.value) return false
  
  return true
})

// 週次ステージデータを計算
const weeklyStageData = computed(() => {
  const weeks = []
  const daysInGrid = calendarDays.value
  
  // カレンダーグリッドを週単位に分割（6週間）
  for (let weekIndex = 0; weekIndex < 6; weekIndex++) {
    const weekDays = daysInGrid.slice(weekIndex * 7, (weekIndex + 1) * 7)
    
    if (weekDays.length === 0) continue
    
    const weekStart = weekDays[0]
    const weekEnd = weekDays[6]
    
    // この週の分析結果を検索
    const weekStartStr = formatDateToLocalString(getWeekStartDate(new Date(weekStart.dateStr)))
    const weekAnalysis = weeklyAnalysisResults.value.find(w => w.week_start_date === weekStartStr)
    
    weeks.push({
      weekIndex,
      startDate: weekStart.dateStr,
      endDate: weekEnd.dateStr,
      hasAnalysis: !!weekAnalysis,
      stageLevel: weekAnalysis?.stage_level || null,
      days: weekDays
    })
  }
  
  return weeks
})

// 今日に移動
const goToToday = () => {
  currentDate.value = new Date()
  const today = formatDateToLocalString(new Date())
  const todayJournal = journalMap.value.get(today)
  
  selectedDate.value = today
  selectedJournal.value = todayJournal
}

// 初期化処理
onMounted(() => {
  // 今日の日記を初期選択
  const today = formatDateToLocalString(new Date())
  selectedDate.value = today
  
  // journalsが既に読み込まれている場合は今日の日記を設定
  if (props.journals) {
    const todayJournal = props.journals.find(j => {
      const entryDate = j.entry_date || (j.created_at ? j.created_at.split('T')[0] : null)
      return entryDate === today
    })
    selectedJournal.value = todayJournal || null
  }
})

// journalsが変更されたときに選択中の日記を更新
watch(() => props.journals, () => {
  if (selectedDate.value && journalMap.value.has(selectedDate.value)) {
    selectedJournal.value = journalMap.value.get(selectedDate.value)
  } else {
    selectedJournal.value = null
  }
}, { deep: true })

// ユーザーが変更されたときに週間分析を再読み込み
watch(() => props.currentUser, async () => {
  if (props.currentUser) {
    await loadWeeklyAnalysis()
  }
}, { immediate: true })
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
        <div class="calendar-controls">
          <button @click="goToToday" class="btn btn-secondary">今日</button>
        </div>
      </div>

      <!-- 曜日ヘッダー -->
      <div class="weekdays">
        <div v-for="day in dayNames" :key="day" class="weekday">
          {{ day }}
        </div>
      </div>

      <!-- カレンダーグリッド -->
      <div class="calendar-grid-container">
        <!-- 週次ステージバー -->
        <div class="weekly-stage-bars">
          <div 
            v-for="week in weeklyStageData" 
            :key="week.weekIndex" 
            class="week-stage-bar"
            :class="{ 'has-analysis': week.hasAnalysis }"
            :style="{ 
              backgroundColor: week.hasAnalysis ? getStageColor(week.stageLevel) : 'rgba(200, 200, 200, 0.3)',
              top: `${week.weekIndex * (100 / 6)}%`,
              height: `${100 / 6}%`
            }"
          >
            <span v-if="week.hasAnalysis" class="stage-label">
              Stage {{ week.stageLevel }}
            </span>
            <span v-else class="stage-label-test" style="color: #666; font-size: 0.7rem;">
              Week {{ week.weekIndex + 1 }}
            </span>
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
              <div class="journal-dot"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- ステージレベル凡例 -->
      <div class="legend">
        <h4>週次ステージレベル凡例:</h4>
        <div class="legend-items-horizontal">
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
        <p class="legend-note">横のバーは各週の分析結果を表示します</p>
      </div>
    </div>

    <!-- 選択された日記の詳細表示 -->
    <div v-if="selectedDate" class="journal-detail">
      <div class="detail-header">
        <h3>{{ selectedDate }} の日記</h3>
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
            <div class="analysis-tags">
              <div v-if="selectedJournal.ai_metadata.detected_emotions" class="tag-group">
                <span class="tag-label">感情:</span>
                <div class="tag-items">
                  <span v-for="emotion in selectedJournal.ai_metadata.detected_emotions" :key="emotion" class="emotion-tag">
                    {{ emotion }}
                  </span>
                </div>
              </div>
              <div v-if="selectedJournal.ai_metadata.key_events" class="tag-group">
                <span class="tag-label">出来事:</span>
                <div class="tag-items">
                  <span v-for="event in selectedJournal.ai_metadata.key_events" :key="event" class="event-tag">
                    {{ event }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="no-journal">
        <div v-if="canCreateNewJournal">
          <p>この日には日記が記録されていません。</p>
          <button @click="navigateToJournal(selectedDate)" class="btn btn-primary write-journal-btn">
            📝 日記を書く
          </button>
        </div>
        <div v-else-if="isSelectedDateWeekAnalyzed">
          <p>この週は分析が完了しているため、新しい日記は作成できません。</p>
        </div>
        <div v-else-if="selectedDate > todayDateString.value">
          <p>未来日は選択できません。</p>
        </div>
        <div v-else>
          <p>この日には日記が記録されていません。</p>
        </div>
      </div>
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

.calendar-grid-container {
  position: relative;
  margin-top: 1rem;
  margin-bottom: 1rem;
  background: #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  min-height: 510px; /* 6週間 × 85px */
}

.weekly-stage-bars {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 10;
}

.week-stage-bar {
  height: calc(100% / 6); /* 6週間分で均等分割 */
  display: flex;
  align-items: center;
  justify-content: flex-start;
  padding-left: 0.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  color: white;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
  position: absolute;
  width: 100%;
  box-sizing: border-box;
  border-radius: 0;
  margin: 0;
  opacity: 1;
  border-left: 4px solid rgba(255, 255, 255, 0.4);
  border-right: 4px solid rgba(255, 255, 255, 0.2);
  box-shadow: inset 0 0 10px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(2px);
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: #e2e8f0;
  position: relative;
  z-index: 1;
}

.calendar-day {
  background: white;
  min-height: 85px;
  padding: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  z-index: 1;
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

.calendar-day.future-date {
  opacity: 0.5;
  cursor: not-allowed;
  background: #f9fafb;
  color: #9ca3af;
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

.journal-dot {
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

.legend-items-horizontal {
  display: flex;
  flex-wrap: nowrap;
  gap: 0.75rem;
  justify-content: center;
  overflow-x: auto;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.7rem;
  color: #4a5568;
  white-space: nowrap;
  flex-shrink: 0;
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.legend-note {
  margin-top: 0.5rem;
  font-size: 0.75rem;
  color: #6b7280;
  text-align: center;
  font-style: italic;
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

.analysis-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.tag-group {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.tag-label {
  font-weight: 500;
  color: #4a5568;
  font-size: 0.875rem;
}

.tag-items {
  display: flex;
  flex-wrap: wrap;
  gap: 0.375rem;
}

.emotion-tag,
.event-tag {
  padding: 0.25rem 0.5rem;
  border-radius: 8px;
  font-size: 0.75rem;
  font-weight: 500;
}

.emotion-tag {
  background: #fef3cd;
  color: #92400e;
}

.event-tag {
  background: #e0f2fe;
  color: #0369a1;
}

.no-journal {
  text-align: center;
  padding: 2rem;
  color: #4a5568;
}

.write-journal-btn {
  margin-top: 1rem;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 500;
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

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
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

  .legend-items-horizontal {
    gap: 0.5rem;
    justify-content: flex-start;
    padding: 0 0.5rem;
  }

  .legend-item {
    font-size: 0.65rem;
  }

  .legend-dot {
    width: 6px;
    height: 6px;
  }

  .detail-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
}
</style> 