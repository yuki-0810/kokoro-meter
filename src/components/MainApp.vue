<script setup>
import { ref } from 'vue'
import SupabaseTest from './SupabaseTest.vue'

const appTitle = ref('ココロメーター')
const subtitle = ref('メンタルステージ可視化 × アクティブレスト')
const activeTab = ref('home') // 'home' または 'test'

const switchTab = (tab) => {
  activeTab.value = tab
}
</script>

<template>
  <div class="main-app">
    <header class="header">
      <div class="container">
        <h1 class="title">{{ appTitle }}</h1>
        <p class="subtitle">{{ subtitle }}</p>
        
        <!-- タブナビゲーション -->
        <nav class="tab-nav">
          <button 
            @click="switchTab('home')" 
            :class="['tab-btn', { active: activeTab === 'home' }]"
          >
            🏠 ホーム
          </button>
          <button 
            @click="switchTab('test')" 
            :class="['tab-btn', { active: activeTab === 'test' }]"
          >
            🔧 Supabaseテスト
          </button>
        </nav>
      </div>
    </header>
    
    <main class="main-content">
      <div class="container">
        <!-- ホームタブ -->
        <div v-if="activeTab === 'home'" class="tab-content">
          <div class="welcome-section">
            <div class="hero-section">
              <div class="stage-display">
                <h2 class="stage-title">現在のメンタルステージ</h2>
                <div class="stage-gauge">
                  <div class="gauge-circle stage-0">
                    <span class="stage-number">0</span>
                  </div>
                </div>
                <p class="stage-description">正常 - エネルギッシュで前向きな状態です</p>
              </div>
            </div>
            
            <div class="features-grid">
              <div class="feature-card">
                <h3>📝 今日の気持ちを記録</h3>
                <p>日記やつぶやきを入力すると、自動でメンタルステージを分析します</p>
                <button class="btn btn-primary">記録を開始</button>
              </div>
              
              <div class="feature-card">
                <h3>🎯 アクティブレスト提案</h3>
                <p>あなたのステージに合わせた回復方法を具体的に提案します</p>
                <button class="btn btn-secondary">提案を見る</button>
              </div>
              
              <div class="feature-card">
                <h3>📊 ステージ推移分析</h3>
                <p>過去30日間のメンタルステージの変化を可視化します</p>
                <button class="btn btn-secondary">分析を見る</button>
              </div>
            </div>
            
            <div class="stage-info">
              <h3>5段階ステージシステム</h3>
              <div class="stages-list">
                <div class="stage-item stage-0">Stage 0: 正常 - 予防メンテナンス</div>
                <div class="stage-item stage-1">Stage 1: 軽度疲労 - 早期ケア</div>
                <div class="stage-item stage-2">Stage 2: 中度疲労 - 積極的休養</div>
                <div class="stage-item stage-3">Stage 3: 重度疲労 - 専門的サポート</div>
                <div class="stage-item stage-4">Stage 4: 危険域 - 緊急対応</div>
              </div>
            </div>
            
            <div class="test-note">
              <p>💡 <strong>開発中:</strong> 上部の「Supabaseテスト」タブから接続・認証・DB操作をテストできます</p>
            </div>
          </div>
        </div>
        
        <!-- Supabaseテストタブ -->
        <div v-if="activeTab === 'test'" class="tab-content">
          <SupabaseTest />
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped>
.main-app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  padding: 1.5rem 0;
}

.title {
  font-size: 2.5rem;
  font-weight: bold;
  color: #2d3748;
  text-align: center;
  margin-bottom: 0.5rem;
}

.subtitle {
  text-align: center;
  color: #4a5568;
  font-size: 1.1rem;
  margin-bottom: 2rem;
}

.tab-nav {
  display: flex;
  justify-content: center;
  gap: 1rem;
}

.tab-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 25px;
  background: #e2e8f0;
  color: #4a5568;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tab-btn:hover {
  background: #cbd5e0;
}

.tab-btn.active {
  background: #4299e1;
  color: white;
}

.main-content {
  padding: 2rem 0;
  flex: 1;
}

.tab-content {
  background: white;
  border-radius: 15px;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  margin: 0 auto;
  max-width: 900px;
}

.hero-section {
  text-align: center;
  margin-bottom: 3rem;
}

.stage-display {
  padding: 2rem;
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
  border-radius: 15px;
  margin-bottom: 2rem;
}

.stage-title {
  font-size: 1.5rem;
  color: #2d3748;
  margin-bottom: 1.5rem;
}

.gauge-circle {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1rem;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.stage-0 {
  background: linear-gradient(135deg, #68d391 0%, #38b2ac 100%);
}

.stage-number {
  font-size: 2.5rem;
  font-weight: bold;
  color: white;
}

.stage-description {
  font-size: 1.1rem;
  color: #4a5568;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.feature-card {
  padding: 1.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  text-align: center;
  transition: transform 0.3s ease;
}

.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.feature-card h3 {
  font-size: 1.2rem;
  margin-bottom: 1rem;
  color: #2d3748;
}

.feature-card p {
  color: #4a5568;
  margin-bottom: 1.5rem;
  line-height: 1.6;
}

.stage-info {
  margin-top: 2rem;
  padding: 1.5rem;
  background: #f7fafc;
  border-radius: 10px;
}

.stage-info h3 {
  text-align: center;
  margin-bottom: 1rem;
  color: #2d3748;
}

.stages-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.stage-item {
  padding: 0.75rem;
  border-radius: 8px;
  font-weight: 500;
  color: white;
}

.stage-item.stage-0 { background: #38b2ac; }
.stage-item.stage-1 { background: #4299e1; }
.stage-item.stage-2 { background: #ed8936; }
.stage-item.stage-3 { background: #e53e3e; }
.stage-item.stage-4 { background: #9f7aea; }

.test-note {
  margin-top: 2rem;
  padding: 1rem;
  background: #ebf8ff;
  border: 1px solid #bee3f8;
  border-radius: 8px;
  text-align: center;
}

@media (max-width: 768px) {
  .title {
    font-size: 2rem;
  }
  
  .tab-nav {
    flex-direction: column;
    align-items: center;
  }
  
  .features-grid {
    grid-template-columns: 1fr;
  }
  
  .gauge-circle {
    width: 100px;
    height: 100px;
  }
  
  .stage-number {
    font-size: 2rem;
  }
}
</style> 