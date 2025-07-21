-- シンプルなテストデータ挿入（手動入力版）
-- ユーザーIDを手動で指定する場合はauth.uid()を実際のUUIDに置き換えてください

-- 今週（Stage 1: 軽度疲労）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count
) VALUES (
  auth.uid(),
  DATE_TRUNC('week', CURRENT_DATE)::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days')::DATE,
  1,
  88,
  '{"stage": 1, "confidence": 88, "analysis_summary": "軽度の疲労感が見られますが、概ね安定しています。"}',
  4
);

-- 1週間前（Stage 2: 中度疲労）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count
) VALUES (
  auth.uid(),
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week')::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week' + INTERVAL '6 days')::DATE,
  2,
  92,
  '{"stage": 2, "confidence": 92, "analysis_summary": "中度の疲労感とストレスが増加している傾向です。"}',
  7
);

-- 2週間前（Stage 1: 軽度疲労）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count
) VALUES (
  auth.uid(),
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 weeks')::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 weeks' + INTERVAL '6 days')::DATE,
  1,
  78,
  '{"stage": 1, "confidence": 78, "analysis_summary": "軽度の疲労感が見られますが、概ね安定しています。"}',
  5
);

-- 3週間前（Stage 0: 正常）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count
) VALUES (
  auth.uid(),
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '3 weeks')::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '3 weeks' + INTERVAL '6 days')::DATE,
  0,
  85,
  '{"stage": 0, "confidence": 85, "analysis_summary": "エネルギッシュで前向きな状態が続いています。"}',
  6
);

-- 確認クエリ
SELECT 
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  journal_count,
  created_at
FROM weekly_analysis 
WHERE user_id = auth.uid()
ORDER BY week_start_date DESC; 