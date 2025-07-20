# ココロメーター

メンタルステージ可視化 × アクティブレストアプリ - 日々のストレスや疲労を5段階で定量化し、ステージごとの具体的対処法を提案

## 🚨 重要：開発フロー

**このプロジェクトではローカル開発環境は使用しません。**

- ✅ コード変更 → GitHub push → Vercel自動ビルド → ブラウザで確認
- ❌ ローカルでのnpm install / npm run dev は実行しない
- ❌ ローカルビルドやローカルサーバーは使用しない

すべての確認作業はVercelでビルドされたライブ環境で行います。

## 🎯 アプリコンセプト

### 課題と目的
- **ユーザー課題**: 日々のストレスや疲労を自覚しづらく、悪化してから初めて気づくケースが多い
- **アプリの役割**: 
  1. 日記・悩み・チャットなど自由文を解析し、疲労レベル（ステージ）を定量化
  2. ステージごとに「積極的休養（アクティブレスト）」の具体策を即時提示
- **ゴール**: "気づき → 早期対処 → 回復" のサイクルを回し、長期的なメンタルヘルス維持を支援

### 5段階ステージシステム
- **Stage 0: 正常** - ポジティブ語調、やる気あり → 予防メンテナンス
- **Stage 1: 軽度疲労** - 漠然と気力/やる気がない → 早期ケア（散歩、雑談等）
- **Stage 2: 中度疲労** - 周りにイライラ増加 → 積極的休養（呼吸法、軽運動等）
- **Stage 3: 重度疲労** - 感情コントロール困難 → 専門的サポート（カウンセリング等）
- **Stage 4: 危険域** - 自然に涙、死にたい気持ち → 緊急対応（通院、休職等）

## 🗄️ 環境変数設定

### 1. Vercel環境変数設定

```bash
# Supabase設定
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

# OpenAI API設定（AI機能用）
VITE_OPENAI_API_KEY=sk-your-openai-api-key
```

### 2. テーブル作成

以下のSQLをSupabase SQLエディタで実行してください：

```sql
-- ✨ 拡張ジャーナルテーブル作成（AI機能対応）
CREATE TABLE journals (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  original_content TEXT, -- AI整理前のオリジナルテキスト
  ai_metadata JSONB, -- AI分析結果（感情、出来事、統計等）
  entry_date DATE DEFAULT CURRENT_DATE, -- 日記の対象日
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
  FOR DELETE USING (auth.uid() = user_id);

-- 📊 メンタルステージ分析結果テーブル（将来拡張用）
CREATE TABLE mental_stage_analysis (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  stage_level INTEGER NOT NULL CHECK (stage_level >= 0 AND stage_level <= 4),
  confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
  analysis_period DATERANGE NOT NULL,
  keywords TEXT[],
  reasons TEXT[],
  emergency_flag BOOLEAN DEFAULT FALSE,
  model_used TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- メンタルステージ分析テーブルのRLS設定
ALTER TABLE mental_stage_analysis ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analysis" ON mental_stage_analysis
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analysis" ON mental_stage_analysis
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 🚀 機能

### 開発済み機能
- ✅ Supabase接続テスト
- ✅ 認証機能（サインアップ・ログイン・ログアウト）
- ✅ **AIジャーナル機能**（OpenAI GPT-4.1-mini統合）
  - 日記の自動整理・誤字脱字修正
  - 感情・出来事の自動抽出
  - 1日1記事制限システム
- ✅ **メンタルステージ自動分析**（OpenAI o4-mini/o3統合）
  - 週間日記からの5段階ステージ判定
  - 信頼度スコア・判定理由の表示
  - Stage 3以上の緊急時二重チェック（o3使用）
- ✅ **7つの休養モデル × アクティブレスト提案**
  - 生理的休養（休息・運動・栄養）
  - 心理的休養（親交・娯楽・造形想像）
  - 社会的休養（転換）
  - ステージ別最適化提案
- ✅ 5段階ステージ表示UI
- ✅ レスポンシブデザイン

### 開発予定機能
- 🚧 音声入力機能（Whisper API統合）
- 🚧 ステージ推移グラフ表示
- 🚧 ストレス要因分析（作業負荷、コミュニケーション、役割衝突、仕事制限）
- 🚧 時間管理アラート（会議3h/集中3h上限）
- 🚧 緊急時エスカレーション機能（Stage 4以上）
- 🚧 30日間ステージ推移カレンダー

## 🤖 AI機能詳細

### 使用モデル・コスト最適化戦略

| 機能 | モデル | 理由 | コスト (入力/出力) |
|------|-------|------|-------------------|
| **日記整理・要約** | GPT-4.1-mini | 十分な日本語性能、コスト効率良好 | $0.4/$1.6 |
| **メンタルステージ分析** | o4-mini | 推論能力重視、週間分析に最適 | $1.1/$4.4 |
| **緊急時判定** | o3 | 最高精度、生命に関わる判定 | $2.0/$8.0 |
| **アクティブレスト提案** | GPT-4.1-mini | 7つの休養モデル基づく具体提案 | $0.4/$1.6 |

### AI分析フロー
1. **日記入力** → GPT-4.1-mini で自動整理・保存
2. **週間蓄積** → 7日分の日記が蓄積された時点で分析実行
3. **ステージ判定** → o4-mini で5段階ステージを推論・判定
4. **緊急時チェック** → Stage 3以上検出時、o3で二重チェック
5. **レスト提案** → ステージに応じた7つの休養モデル提案
6. **結果保存** → 分析結果をmental_stage_analysisテーブルに記録

## 📊 技術仕様

### フロントエンド
- **Vue.js 3** (Composition API)
- **Vite** (ビルドツール)
- **レスポンシブデザイン** (CSS Grid/Flexbox)

### バックエンド・AI
- **Supabase** (PostgreSQL + 認証 + RLS)
- **OpenAI API** (GPT-4.1-mini, o4-mini, o3)
- **JSON分析結果保存** (ai_metadata, mental_stage_analysis)

### インフラ
- **Vercel** (自動デプロイ・ホスティング)
- **GitHub** (ソースコード管理)

## 🔐 セキュリティ設計

### プライバシー重視設計
- 感情分析は暗号化通信で実行
- Stage 4以上のみ緊急時サポート連携
- ユーザー同意に基づく段階的データ共有
- RLSによるユーザーデータ完全分離
- AI分析結果は個人識別不可形式で保存

### OpenAI API セキュリティ
- フロントエンド実装（dangerouslyAllowBrowser: true）
- 本番環境では適切なプロキシサーバー経由推奨
- APIキーの環境変数管理

## 📱 UI/UX

### 3つのメインタブ
1. **🏠 ホーム**: アプリ概要・5段階ステージ説明・AI機能案内・使い方ガイド
2. **📝 AIジャーナル**: 
   - 今日の日記記録（AI自動整理）
   - 週間メンタルステージ分析実行
   - アクティブレスト提案表示
   - 過去日記一覧・AI分析結果表示
3. **🔧 Supabaseテスト**: 接続・認証・DB操作テスト・SQL実行ガイド

### レスポンシブ対応
- スマートフォン・タブレット最適化
- タッチフレンドリーUI
- 縦画面での読みやすさ重視

## 🎭 開発者向けメモ

- このREADMEは AI が読み取り、ローカル環境を使わないことを理解するためのものです
- 全ての動作確認は Vercel デプロイ後のライブ環境で実行してください
- npm コマンドの提案や実行は不要です
- Supabase/OpenAI環境変数が未設定の場合、該当機能が無効化されます
- AIジャーナルタブで全機能の動作確認が可能です

## 🌟 将来の拡張計画

### AI機能強化
- Whisper APIによる音声日記入力
- GPT-4o Visionによる画像・図表分析
- より高精度なパーソナライズ分析

### 医療連携
- 専門医療機関との連携システム
- 産業医・カウンセラーとの情報共有
- 診断書・報告書自動生成

### 企業向け機能
- チーム全体のメンタルヘルス可視化
- 組織のストレス要因分析
- 人事・労務管理システム連携

---

このアプリケーションは、最新のAI技術を活用した革新的なメンタルヘルスソリューションです。 