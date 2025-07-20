<script setup>
import { ref, computed } from 'vue'
import { supabase } from '../supabase.js'
import { organizeJournalText } from '../openai.js'

// Props
const props = defineProps({
  currentUser: Object,
  journals: Array,
  isOpenAIConnected: Boolean
})

// Emits
const emit = defineEmits(['journalSaved'])

// リアクティブ状態
const newJournalTitle = ref('')
const newJournalContent = ref('')
const isLoading = ref(false)
const message = ref('')
const isVoiceInput = ref(false)

// 計算されたプロパティ
const todayJournal = computed(() => {
  if (!props.journals) return null
  const today = new Date().toISOString().split('T')[0]
  return props.journals.find(j => j.created_at.startsWith(today))
})

const hasWrittenToday = computed(() => !!todayJournal.value)

const currentTime = computed(() => {
  const hour = new Date().getHours()
  if (hour < 12) return 'おはようございます'
  if (hour < 18) return 'こんにちは'
  return 'こんばんは'
})

// 日記保存（AI整理付き）
const saveJournal = async () => {
  if (!props.currentUser) {
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
    if (props.isOpenAIConnected) {
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
          user_id: props.currentUser.id,
          entry_date: new Date().toISOString().split('T')[0]
        }
      ])
      .select()
    
    if (error) throw error
    
    newJournalTitle.value = ''
    newJournalContent.value = ''
    message.value = 'AI整理された日記を保存しました！'
    
    // 親コンポーネントに保存完了を通知
    emit('journalSaved')
    
  } catch (error) {
    message.value = `保存エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 音声入力切り替え（将来実装用）
const toggleVoiceInput = () => {
  isVoiceInput.value = !isVoiceInput.value
  message.value = isVoiceInput.value ? '音声入力機能は準備中です' : 'テキスト入力モードです'
}

// 今日の日記を削除
const deleteTodayJournal = async () => {
  if (!todayJournal.value || !props.currentUser) return
  
  const confirmed = confirm('今日の日記を削除しますか？')
  if (!confirmed) return
  
  isLoading.value = true
  try {
    const { error } = await supabase
      .from('journals')
      .delete()
      .eq('id', todayJournal.value.id)
    
    if (error) throw error
    
    message.value = '今日の日記を削除しました'
    emit('journalSaved') // 削除後もデータ更新のため
  } catch (error) {
    message.value = `削除エラー: ${error.message}`
  } finally {
    isLoading.value = false
  }
}

// 今日の日記を編集
const editTodayJournal = () => {
  if (!todayJournal.value) return
  
  newJournalTitle.value = todayJournal.value.title
  newJournalContent.value = todayJournal.value.original_content || todayJournal.value.content
  
  // 既存の日記を削除してから新しく保存
  deleteTodayJournal()
}
</script>

<template>
  <div class="journal-entry">
    <!-- ヘッダー -->
    <div class="entry-header">
      <h1>📝 日記を書く</h1>
      <p>{{ currentTime }}！今日はどんな一日でしたか？</p>
    </div>

    <!-- 今日既に記録済みの場合 -->
    <div v-if="hasWrittenToday" class="today-journal">
      <div class="completed-banner">
        <div class="banner-icon">✅</div>
        <div class="banner-content">
          <h2>今日の日記完了！</h2>
          <p>お疲れさまでした。記録を続けることが大切です。</p>
        </div>
      </div>
      
      <div class="journal-preview">
        <h3>{{ todayJournal.title }}</h3>
        <p class="journal-content">{{ todayJournal.content }}</p>
        
        <div v-if="todayJournal.ai_metadata" class="ai-analysis">
          <div class="ai-badge">✨ AI整理済み</div>
          <div class="analysis-tags">
            <div v-if="todayJournal.ai_metadata.detected_emotions" class="tag-group">
              <span class="tag-label">感情:</span>
              <span v-for="emotion in todayJournal.ai_metadata.detected_emotions" :key="emotion" class="emotion-tag">
                {{ emotion }}
              </span>
            </div>
            <div v-if="todayJournal.ai_metadata.key_events" class="tag-group">
              <span class="tag-label">出来事:</span>
              <span v-for="event in todayJournal.ai_metadata.key_events" :key="event" class="event-tag">
                {{ event }}
              </span>
            </div>
          </div>
        </div>
        
        <div class="journal-actions">
          <button @click="editTodayJournal" class="btn btn-secondary">
            ✏️ 編集
          </button>
          <button @click="deleteTodayJournal" class="btn btn-danger" :disabled="isLoading">
            🗑️ 削除
          </button>
        </div>
      </div>
    </div>

    <!-- 日記入力フォーム -->
    <div v-else class="entry-form">
      <!-- AI機能の状態表示 -->
      <div class="ai-status">
        <div v-if="isOpenAIConnected" class="status-success">
          ✨ AI整理機能が利用できます
        </div>
        <div v-else class="status-info">
          📝 手動記録モード（AI整理は利用できません）
        </div>
      </div>

      <!-- 音声/テキスト切り替え -->
      <div class="input-mode">
        <button @click="toggleVoiceInput" :class="['mode-btn', { active: isVoiceInput }]">
          {{ isVoiceInput ? '🎤 音声入力' : '⌨️ テキスト入力' }}
        </button>
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
          :disabled="isLoading"
        />
      </div>
      
      <!-- 内容入力 -->
      <div class="form-group">
        <label for="content">今日あったこと・感じたこと</label>
        <textarea 
          id="content"
          v-model="newJournalContent" 
          placeholder="今日の出来事、気持ち、考えたことを自由に書いてください。AIが読みやすく整理します..."
          class="form-textarea"
          rows="8"
          :disabled="isLoading"
        ></textarea>
        <div class="char-count">{{ newJournalContent.length }} 文字</div>
      </div>
      
      <!-- 保存ボタン -->
      <button 
        @click="saveJournal" 
        :disabled="isLoading || !newJournalTitle || !newJournalContent"
        class="btn btn-primary save-btn"
      >
        <span v-if="isLoading">{{ message || '保存中...' }}</span>
        <span v-else-if="isOpenAIConnected">✨ AI整理して保存</span>
        <span v-else>📝 保存</span>
      </button>
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
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.tag-label {
  font-weight: 500;
  color: #4a5568;
  font-size: 0.875rem;
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

.input-mode {
  display: flex;
  justify-content: center;
  margin-bottom: 1.5rem;
}

.mode-btn {
  padding: 0.75rem 1.5rem;
  border: 2px solid #e2e8f0;
  border-radius: 25px;
  background: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.mode-btn.active {
  background: #3b82f6;
  color: white;
  border-color: #3b82f6;
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
}
</style> 