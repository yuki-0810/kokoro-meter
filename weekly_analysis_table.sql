-- 週次分析結果テーブル
CREATE TABLE IF NOT EXISTS weekly_analysis (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  stage_level INTEGER NOT NULL CHECK (stage_level >= 0 AND stage_level <= 4),
  confidence INTEGER NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  analysis_data JSONB,
  journal_count INTEGER NOT NULL DEFAULT 0,
  analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 1ユーザーにつき1週間に1つの分析結果のみ
  UNIQUE(user_id, week_start_date)
);

-- RLS (Row Level Security) を有効化
ALTER TABLE weekly_analysis ENABLE ROW LEVEL SECURITY;

-- ユーザーは自分の分析結果のみアクセス可能
CREATE POLICY "Users can only access their own weekly analysis" ON weekly_analysis
FOR ALL USING (auth.uid() = user_id);

-- インデックス作成
CREATE INDEX idx_weekly_analysis_user_date ON weekly_analysis (user_id, week_start_date DESC);
CREATE INDEX idx_weekly_analysis_week_start ON weekly_analysis (week_start_date);

-- コメント追加
COMMENT ON TABLE weekly_analysis IS '週次メンタルステージ分析結果';
COMMENT ON COLUMN weekly_analysis.week_start_date IS '週の開始日（日曜日）';
COMMENT ON COLUMN weekly_analysis.week_end_date IS '週の終了日（土曜日）';
COMMENT ON COLUMN weekly_analysis.stage_level IS 'メンタルステージレベル（0-4）';
COMMENT ON COLUMN weekly_analysis.confidence IS '分析信頼度（0-100%）';
COMMENT ON COLUMN weekly_analysis.analysis_data IS 'AI分析結果の詳細データ';
COMMENT ON COLUMN weekly_analysis.journal_count IS 'この週の日記記録数'; 