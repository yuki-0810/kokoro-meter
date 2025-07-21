-- シンプルなテストデータ挿入（指定user_id版）
-- user_id: 8c7d6043-beb4-477d-9e48-58d0e7708268

-- 既存データを削除
DELETE FROM weekly_analysis 
WHERE user_id = '8c7d6043-beb4-477d-9e48-58d0e7708268';

-- 今週（Stage 1: 軽度疲労）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count,
  analyzed_at
) VALUES (
  '8c7d6043-beb4-477d-9e48-58d0e7708268',
  DATE_TRUNC('week', CURRENT_DATE)::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days')::DATE,
  1,
  88,
  '{"stage": 1, "confidence": 88, "analysis_summary": "軽度の疲労感が見られますが、概ね安定しています。"}',
  4,
  NOW()
);

-- 1週間前（Stage 2: 中度疲労）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count,
  analyzed_at
) VALUES (
  '8c7d6043-beb4-477d-9e48-58d0e7708268',
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week')::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week' + INTERVAL '6 days')::DATE,
  2,
  92,
  '{"stage": 2, "confidence": 92, "analysis_summary": "中度の疲労感とストレスが増加している傾向です。"}',
  7,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week' + INTERVAL '6 days' + INTERVAL '20:00:00')::TIMESTAMP
);

-- 2週間前（Stage 1: 軽度疲労）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count,
  analyzed_at
) VALUES (
  '8c7d6043-beb4-477d-9e48-58d0e7708268',
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 weeks')::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 weeks' + INTERVAL '6 days')::DATE,
  1,
  78,
  '{"stage": 1, "confidence": 78, "analysis_summary": "軽度の疲労感が見られますが、概ね安定しています。"}',
  5,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 weeks' + INTERVAL '6 days' + INTERVAL '20:00:00')::TIMESTAMP
);

-- 3週間前（Stage 0: 正常）
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count,
  analyzed_at
) VALUES (
  '8c7d6043-beb4-477d-9e48-58d0e7708268',
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '3 weeks')::DATE,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '3 weeks' + INTERVAL '6 days')::DATE,
  0,
  85,
  '{"stage": 0, "confidence": 85, "analysis_summary": "エネルギッシュで前向きな状態が続いています。"}',
  6,
  (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '3 weeks' + INTERVAL '6 days' + INTERVAL '20:00:00')::TIMESTAMP
);

-- 挿入結果を確認
SELECT 
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  journal_count,
  analyzed_at,
  created_at
FROM weekly_analysis 
WHERE user_id = '8c7d6043-beb4-477d-9e48-58d0e7708268'
ORDER BY week_start_date DESC;

-- データ件数確認
SELECT COUNT(*) as inserted_count
FROM weekly_analysis 
WHERE user_id = '8c7d6043-beb4-477d-9e48-58d0e7708268'; 