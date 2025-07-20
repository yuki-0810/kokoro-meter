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

## 🗄️ Supabase設定

### 1. 環境変数設定（Vercel）

```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 2. テーブル作成

以下のSQLをSupabase SQLエディタで実行してください：

```sql
-- ジャーナルテーブル作成
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
  FOR DELETE USING (auth.uid() = user_id);
```

## 🚀 機能

### 開発済み機能
- ✅ Supabase接続テスト
- ✅ 認証機能（サインアップ・ログイン・ログアウト）
- ✅ ジャーナル機能（CRUD操作）
- ✅ 5段階ステージ表示UI
- ✅ レスポンシブデザイン

### 開発予定機能
- 🚧 自然言語処理によるメンタルステージ自動判定
- 🚧 ステージ別アクティブレスト提案システム
- 🚧 ストレス要因分析（作業負荷、コミュニケーション、役割衝突、仕事制限）
- 🚧 時間管理アラート（会議3h/集中3h上限）
- 🚧 緊急時エスカレーション機能（Stage 4以上）
- 🚧 30日間ステージ推移グラフ

## 📊 技術仕様

### フロントエンド
- **Vue.js 3** (Composition API)
- **Vite** (ビルドツール)
- **レスポンシブデザイン** (CSS Grid/Flexbox)

### バックエンド
- **Supabase** (PostgreSQL + 認証)
- **Row Level Security** (RLS) によるデータ保護

### インフラ
- **Vercel** (自動デプロイ・ホスティング)
- **GitHub** (ソースコード管理)

## 🔐 セキュリティ設計

### プライバシー重視設計
- 感情分析は端末内処理を基本
- Stage 4以上のみクラウド連携（緊急時対応）
- ユーザー同意に基づく段階的データ共有
- RLSによるユーザーデータ分離

## 📱 UI/UX

### ホーム画面
- 5段階円形ゲージ + 現在のステージ表示
- ステージ別推奨アクション（散歩、呼吸法、専門機関相談等）
- 過去30日のステージ推移カレンダー

### ジャーナル機能
- テキスト入力 → リアルタイム解析
- 音声入力対応（将来予定）
- 写真キャプション解析（将来予定）

## 🎭 開発者向けメモ

- このREADMEは AI が読み取り、ローカル環境を使わないことを理解するためのものです
- 全ての動作確認は Vercel デプロイ後のライブ環境で実行してください
- npm コマンドの提案や実行は不要です
- Supabase環境変数が未設定の場合、コンソールにエラーメッセージが表示されます
- アプリの「Supabaseテスト」タブで接続・認証・DB操作の動作確認が可能です

## 🌟 将来の拡張計画

### AI機能強化
- GPT-4を使った高精度感情分析
- パーソナライズされたアクティブレスト提案
- 音声・画像からの感情読み取り

### 医療連携
- 専門医療機関との連携システム
- 産業医・カウンセラーとの情報共有
- 診断書・報告書自動生成

### 企業向け機能
- チーム全体のメンタルヘルス可視化
- 組織のストレス要因分析
- 人事・労務管理システム連携

---

このアプリケーションは、現代社会のメンタルヘルス課題解決を目指す革新的なソリューションです。 