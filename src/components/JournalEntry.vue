<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '../supabase.js'
import { organizeJournalText } from '../openai.js'

// 地域時間で日付文字列を生成する関数
const formatDateToLocalString = (date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// Props
const props = defineProps({
  currentUser: Object,
  journals: Array,
  isOpenAIConnected: Boolean,
  selectedJournalDate: String
})

// Emits
const emit = defineEmits(['journalSaved'])

// リアクティブ状態
const newJournalTitle = ref('')
const newJournalContent = ref('')
const isLoading = ref(false)
const message = ref('')
const selectedDate = ref(formatDateToLocalString(new Date())) // 今日の日付
const errorPopup = ref(false)
const errorMessage = ref('')
const weeklyAnalysisResults = ref([])
const toastMessage = ref('')
const showToast = ref(false)

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

// selectedJournalDateの変更を監視
watch(() => props.selectedJournalDate, (newDate) => {
  if (newDate) {
    selectedDate.value = newDate
    loadJournalForDate()
  }
}, { immediate: true })

// 初期化
onMounted(async () => {
  if (props.selectedJournalDate) {
    selectedDate.value = props.selectedJournalDate
  }
  if (props.currentUser) {
    await loadWeeklyAnalysis()
  }
  loadJournalForDate()
})

// 計算されたプロパティ
const selectedDateJournal = computed(() => {
  if (!props.journals) return null
  // entry_dateフィールドがあればそれを使用、なければcreated_atから日付部分を使用
  return props.journals.find(j => {
    const entryDate = j.entry_date || (j.created_at ? j.created_at.split('T')[0] : null)
    return entryDate === selectedDate.value
  })
})

const hasWrittenToday = computed(() => !!selectedDateJournal.value)

const currentTime = computed(() => {
  const hour = new Date().getHours()
  if (hour < 12) return 'おはようございます'
  if (hour < 18) return 'こんにちは'
  return 'こんばんは'
})

const isSelectedDateToday = computed(() => {
  const today = formatDateToLocalString(new Date())
  return selectedDate.value === today
})

const isSelectedDateInCurrentWeek = computed(() => {
  const currentWeekStart = getWeekStartDate()
  const currentWeekEnd = getWeekEndDate(currentWeekStart)
  const selectedDateObj = new Date(selectedDate.value)
  
  return selectedDateObj >= currentWeekStart && selectedDateObj <= currentWeekEnd
})

const selectedDateWeekStart = computed(() => {
  const dateObj = new Date(selectedDate.value)
  return formatDateToLocalString(getWeekStartDate(dateObj))
})

const isSelectedDateWeekAnalyzed = computed(() => {
  return weeklyAnalysisResults.value.some(w => w.week_start_date === selectedDateWeekStart.value)
})

const canEditSelectedDate = computed(() => {
  // 過去の週で分析が実行されている場合は編集不可
  if (isSelectedDateWeekAnalyzed.value) return false
  
  // 今週の日記は編集可能（ただし分析未実行の場合のみ）
  if (isSelectedDateInCurrentWeek.value) return true
  
  // 過去の週で分析が実行されていない場合は編集可能
  return true
})

const editRestrictionMessage = computed(() => {
  if (canEditSelectedDate.value) return ''
  
  if (isSelectedDateWeekAnalyzed.value) {
    return 'この週は分析が完了しているため、日記の編集はできません。'
  }
  
  return ''
})

// 日付操作関数
const changeDate = (delta) => {
  const currentSelectedDate = new Date(selectedDate.value)
  currentSelectedDate.setDate(currentSelectedDate.getDate() + delta)
  
  const newDateStr = formatDateToLocalString(currentSelectedDate)
  const today = formatDateToLocalString(new Date())
  
  // 未来日は選択不可
  if (newDateStr <= today) {
    selectedDate.value = newDateStr
    loadJournalForDate()
  }
}

// 選択された日付の日記を読み込み
const loadJournalForDate = () => {
  const journal = selectedDateJournal.value
  if (journal) {
    newJournalTitle.value = journal.title
    newJournalContent.value = journal.original_content || journal.content
  } else {
    newJournalTitle.value = ''
    newJournalContent.value = ''
  }
}

// 日記保存（AI整理付き）
const saveJournal = async () => {
  if (!props.currentUser) {
    showError('ログインが必要です')
    return
  }
  
  if (!canEditSelectedDate.value) {
    showError(editRestrictionMessage.value)
    return
  }
  
  if (!newJournalTitle.value || !newJournalContent.value) {
    showError('タイトルと内容を入力してください')
    return
  }
  
  if (hasWrittenToday.value) {
    showError(`${selectedDate.value}はすでに日記を書いています`)
    return
  }
  
  isLoading.value = true
  try {
    let organizedContent = newJournalContent.value
    let aiMetadata = null
    
    // OpenAI接続時はAI整理を実行
    if (props.isOpenAIConnected) {
      message.value = 'AIが日記を整理しています...'
      try {
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
      } catch (aiError) {
        console.error('AI整理エラー:', aiError)
        showError('AI整理に失敗しました。手動記録として保存します。')
        // AI整理に失敗しても保存は続行
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
          user_id: props.currentUser.id,
          entry_date: selectedDate.value
        }
      ])
      .select()
    
    if (error) throw error
    
    newJournalTitle.value = ''
    newJournalContent.value = ''
    message.value = aiMetadata ? 'AI整理された日記を保存しました！' : '日記を保存しました！'
    
    // Toast表示でユーザーに通知し、ホーム遷移は行わない
    showToastMessage(aiMetadata ? 'AI整理された日記を保存しました！' : '日記を保存しました！')
    
    // 親コンポーネントに保存完了を通知（ホーム遷移なし）
    emit('journalSaved')
    
  } catch (error) {
    showError(`保存エラー: ${error.message}`)
  } finally {
    isLoading.value = false
  }
}

// エラーポップアップ表示
const showError = (msg) => {
  errorMessage.value = msg
  errorPopup.value = true
  setTimeout(() => {
    errorPopup.value = false
  }, 3000)
}

// Toast表示関数
const showToastMessage = (msg) => {
  toastMessage.value = msg
  showToast.value = true
  setTimeout(() => {
    showToast.value = false
  }, 3000)
}

// 今日の日記を削除
const deleteTodayJournal = async () => {
  if (!selectedDateJournal.value || !props.currentUser) return
  
  if (!canEditSelectedDate.value) {
    showError(editRestrictionMessage.value)
    return
  }
  
  const confirmed = confirm(`${selectedDate.value}の日記を削除しますか？`)
  if (!confirmed) return
  
  isLoading.value = true
  try {
    const { error } = await supabase
      .from('journals')
      .delete()
      .eq('id', selectedDateJournal.value.id)
    
    if (error) throw error
    
    message.value = `${selectedDate.value}の日記を削除しました`
    showToastMessage(`${selectedDate.value}の日記を削除しました`)
    loadJournalForDate() // 日記を再読み込み
    emit('journalSaved') // 削除後もデータ更新のため
  } catch (error) {
    showError(`削除エラー: ${error.message}`)
  } finally {
    isLoading.value = false
  }
}

// 今日の日記を編集
const editTodayJournal = () => {
  if (!selectedDateJournal.value) return
  
  if (!canEditSelectedDate.value) {
    showError(editRestrictionMessage.value)
    return
  }
  
  newJournalTitle.value = selectedDateJournal.value.title
  newJournalContent.value = selectedDateJournal.value.original_content || selectedDateJournal.value.content
  
  // 既存の日記を削除してから新しく保存
  deleteTodayJournal()
}
</script>

<template>
  <div class="journal-entry">
    <!-- エラーポップアップ -->
    <div v-if="errorPopup" class="error-popup">
      {{ errorMessage }}
    </div>

    <!-- Toast表示 -->
    <div v-if="showToast" class="toast-notification">
      {{ toastMessage }}
    </div>

    <!-- 今日既に記録済みの場合 -->
    <div v-if="hasWrittenToday" class="today-journal">
      <!-- 日付選択 -->
      <div class="date-selector">
        <button @click="changeDate(-1)" class="date-btn" :disabled="isLoading">‹</button>
        <div class="selected-date">
          <h2>{{ selectedDate }}</h2>
          <span class="date-label">{{ isSelectedDateToday ? '今日' : '過去の日記' }}</span>
        </div>
        <button @click="changeDate(1)" class="date-btn" :disabled="isLoading || selectedDate >= formatDateToLocalString(new Date())">›</button>
      </div>
      
      <div class="journal-preview">
        <h3>{{ selectedDateJournal.title }}</h3>
        <p class="journal-content">{{ selectedDateJournal.content }}</p>
        
        <div v-if="selectedDateJournal.ai_metadata" class="ai-analysis">
          <div class="ai-badge">✨ AI整理済み</div>
          <div class="analysis-tags">
            <div v-if="selectedDateJournal.ai_metadata.detected_emotions" class="tag-group">
              <span class="tag-label">感情:</span>
              <div class="tag-items">
                <span v-for="emotion in selectedDateJournal.ai_metadata.detected_emotions" :key="emotion" class="emotion-tag">
                  {{ emotion }}
                </span>
              </div>
            </div>
            <div v-if="selectedDateJournal.ai_metadata.key_events" class="tag-group">
              <span class="tag-label">出来事:</span>
              <div class="tag-items">
                <span v-for="event in selectedDateJournal.ai_metadata.key_events" :key="event" class="event-tag">
                  {{ event }}
                </span>
              </div>
            </div>
          </div>
        </div>
        
        <div class="journal-actions">
          <button v-if="canEditSelectedDate" @click="editTodayJournal" class="btn btn-secondary">
            ✏️ 編集
          </button>
          <button v-if="canEditSelectedDate" @click="deleteTodayJournal" class="btn btn-danger" :disabled="isLoading">
            🗑️ 削除
          </button>
          
          <!-- 編集制限メッセージ -->
          <div v-if="!canEditSelectedDate" class="edit-restriction-message-action">
            {{ editRestrictionMessage }}
          </div>
        </div>
      </div>
    </div>

    <!-- 日記入力フォーム -->
    <div v-else class="entry-form">
      <!-- 日付選択 -->
      <div class="date-selector">
        <button @click="changeDate(-1)" class="date-btn" :disabled="isLoading">‹</button>
        <div class="selected-date">
          <h2>{{ selectedDate }}</h2>
          <span class="date-label">{{ isSelectedDateToday ? '今日' : '過去の日記' }}</span>
        </div>
        <button @click="changeDate(1)" class="date-btn" :disabled="isLoading || selectedDate >= formatDateToLocalString(new Date())">›</button>
      </div>

      <!-- タイトル入力 -->
      <div class="form-group">
        <label for="title">今日のタイトル</label>
        <input 
          id="title"
          v-model="newJournalTitle" 
          type="text" 
          placeholder="例: 充実した一日、疲れた日、新しい発見"
          class="form-input"
          :disabled="isLoading || !canEditSelectedDate"
        />
      </div>
      
      <!-- 内容入力 -->
      <div class="form-group">
        <label for="content">今日あったこと・感じたこと</label>
        <textarea 
          id="content"
          v-model="newJournalContent" 
          placeholder="今日の出来事、気持ち、考えたことを自由に書いてください..."
          class="form-textarea"
          rows="8"
          :disabled="isLoading || !canEditSelectedDate"
        ></textarea>
        <div class="char-count">{{ newJournalContent.length }} 文字</div>
      </div>
      
      <!-- 保存ボタンまたは編集制限メッセージ -->
      <div v-if="canEditSelectedDate" class="action-section">
        <button 
          @click="saveJournal" 
          :disabled="isLoading || !newJournalTitle || !newJournalContent"
          class="btn btn-primary save-btn"
        >
          <span v-if="isLoading">{{ message || '保存中...' }}</span>
          <span v-else>📝 保存</span>
        </button>
      </div>
      <div v-else class="action-section">
        <div class="edit-restriction-message-action">
          {{ editRestrictionMessage }}
        </div>
      </div>
    </div>

    <!-- ヘルプメッセージ -->
    <div class="help-section">
      <h3>💡 日記を書くコツ</h3>
      <ul class="help-list">
        <li>感情や気持ちを素直に表現してみましょう</li>
        <li>今日起こった出来事を時系列で振り返ってみましょう</li>
        <li>良かったこと・改善したいことを書いてみましょう</li>
        <li>明日への気持ちや目標も記録してみましょう</li>
      </ul>
    </div>

    <!-- ステータスメッセージ -->
    <div v-if="message" class="status-message">
      {{ message }}
    </div>
  </div>
</template>

<style scoped>
.journal-entry {
  padding: 1rem;
  padding-bottom: 5rem; /* ボトムナビゲーション分のスペース */
  max-width: 100%;
}

.entry-header {
  text-align: center;
  margin-bottom: 2rem;
}

.entry-header h1 {
  color: #2d3748;
  margin-bottom: 0.5rem;
  font-size: 1.5rem;
}

.entry-header p {
  color: #4a5568;
  margin: 0;
  font-size: 1rem;
}

.today-journal {
  margin-bottom: 2rem;
}

.completed-banner {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  background: linear-gradient(135deg, #f0fff4 0%, #e6fffa 100%);
  border: 1px solid #9ae6b4;
  border-radius: 15px;
  margin-bottom: 1.5rem;
}

.banner-icon {
  font-size: 3rem;
  flex-shrink: 0;
}

.banner-content h2 {
  margin: 0 0 0.25rem 0;
  color: #22543d;
  font-size: 1.25rem;
}

.banner-content p {
  margin: 0;
  color: #2f855a;
  font-size: 0.875rem;
}

.journal-preview {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.5rem;
}

.journal-preview h3 {
  color: #2d3748;
  margin: 0 0 1rem 0;
  font-size: 1.125rem;
}

.journal-content {
  color: #4a5568;
  line-height: 1.6;
  margin-bottom: 1rem;
}

.ai-analysis {
  margin-bottom: 1.5rem;
}

.ai-badge {
  display: inline-block;
  background: linear-gradient(45deg, #667eea, #764ba2);
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  margin-bottom: 1rem;
}

.analysis-tags {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.tag-group {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.tag-items {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.tag-label {
  font-weight: 500;
  color: #4a5568;
  font-size: 0.875rem;
  flex-shrink: 0;
}

.emotion-tag, .event-tag {
  padding: 0.25rem 0.5rem;
  border-radius: 6px;
  font-size: 0.75rem;
}

.emotion-tag {
  background: #fef3cd;
  color: #92400e;
}

.event-tag {
  background: #e0f2fe;
  color: #0369a1;
}

.journal-actions {
  display: flex;
  gap: 1rem;
}

.entry-form {
  background: white;
  border-radius: 15px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.ai-status {
  margin-bottom: 1.5rem;
  padding: 1rem;
  border-radius: 8px;
}

.status-success {
  background: #f0fff4;
  color: #22543d;
  border: 1px solid #9ae6b4;
}

.status-info {
  background: #ebf8ff;
  color: #2c5282;
  border: 1px solid #bee3f8;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #2d3748;
  font-weight: 500;
  font-size: 0.875rem;
}

.form-input, .form-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.form-input:focus, .form-textarea:focus {
  outline: none;
  border-color: #3b82f6;
}

.form-textarea {
  resize: vertical;
  min-height: 150px;
  line-height: 1.6;
}

.char-count {
  text-align: right;
  font-size: 0.75rem;
  color: #6b7280;
  margin-top: 0.25rem;
}

.save-btn {
  width: 100%;
  padding: 1rem;
  font-size: 1.125rem;
  font-weight: 600;
}

.help-section {
  background: #f7fafc;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.help-section h3 {
  color: #2d3748;
  margin: 0 0 1rem 0;
  font-size: 1rem;
}

.help-list {
  margin: 0;
  padding-left: 1.5rem;
  color: #4a5568;
}

.help-list li {
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
  line-height: 1.4;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 500;
  font-size: 0.875rem;
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

.btn-danger {
  background-color: #ef4444;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background-color: #dc2626;
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

.date-selector {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding: 0.75rem 1rem;
  background: #f7fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}

.date-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #4a5568;
  cursor: pointer;
  padding: 0.25rem;
  transition: color 0.2s;
}

.date-btn:hover:not(:disabled) {
  color: #3b82f6;
}

.date-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.selected-date {
  text-align: center;
  flex-grow: 1;
}

.selected-date h2 {
  margin: 0 0 0.25rem 0;
  color: #2d3748;
  font-size: 1.25rem;
}

.date-label {
  font-size: 0.75rem;
  color: #6b7280;
}

.error-popup {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background-color: #f8d7da;
  color: #721c24;
  padding: 10px 20px;
  border: 1px solid #f5c6cb;
  border-radius: 8px;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  max-width: 90%;
  text-align: center;
  font-size: 0.875rem;
  font-weight: 500;
}

.toast-notification {
  position: fixed;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background-color: #4CAF50;
  color: white;
  padding: 10px 20px;
  border-radius: 8px;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  max-width: 90%;
  text-align: center;
  font-size: 0.875rem;
  font-weight: 500;
}

.edit-restriction-message {
  background-color: #fffbeb;
  color: #92400e;
  border: 1px solid #fde68a;
  border-radius: 8px;
  padding: 0.75rem 1rem;
  margin-top: 1rem;
  font-size: 0.875rem;
  text-align: center;
}

.edit-restriction-message-action {
  background-color: #fffbeb;
  color: #92400e;
  border: 1px solid #fde68a;
  border-radius: 8px;
  padding: 0.75rem 1rem;
  margin-top: 1rem;
  font-size: 0.875rem;
  text-align: center;
}

@media (max-width: 768px) {
  .completed-banner {
    flex-direction: column;
    text-align: center;
    gap: 1rem;
  }
  
  .banner-icon {
    font-size: 2.5rem;
  }
  
  .journal-actions {
    flex-direction: column;
  }
  
  .analysis-tags {
    gap: 0.75rem;
  }
  
  .tag-group {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }
  
  .tag-items {
    gap: 0.25rem;
  }
}
</style> 