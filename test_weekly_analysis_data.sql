-- 週次分析テストデータ生成
-- 現在ログイン中のユーザーの直近4週分のテストデータを挿入

-- まず既存のテストデータを削除（重複を避けるため）
DELETE FROM weekly_analysis 
WHERE user_id = auth.uid() 
AND week_start_date >= CURRENT_DATE - INTERVAL '4 weeks';

-- 直近4週分のテストデータを挿入
WITH weekly_test_data AS (
  SELECT 
    generate_series(0, 3) as week_offset,
    ARRAY[0, 1, 2, 1] as stage_levels,
    ARRAY[85, 78, 92, 88] as confidences,
    ARRAY[6, 5, 7, 4] as journal_counts
),
week_dates AS (
  SELECT 
    week_offset,
    -- 今日から週のオフセットを計算して日曜日を算出
    (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::integer - (week_offset * 7))::DATE as week_start,
    stage_levels[week_offset + 1] as stage_level,
    confidences[week_offset + 1] as confidence,
    journal_counts[week_offset + 1] as journal_count
  FROM weekly_test_data
)
INSERT INTO weekly_analysis (
  user_id,
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  analysis_data,
  journal_count,
  analyzed_at
)
SELECT 
  auth.uid(),
  week_start,
  week_start + INTERVAL '6 days',
  stage_level,
  confidence,
  jsonb_build_object(
    'stage', stage_level,
    'confidence', confidence,
    'analysis_summary', CASE 
      WHEN stage_level = 0 THEN 'エネルギッシュで前向きな状態が続いています。'
      WHEN stage_level = 1 THEN '軽度の疲労感が見られますが、概ね安定しています。'
      WHEN stage_level = 2 THEN '中度の疲労感とストレスが増加している傾向です。'
      WHEN stage_level = 3 THEN '重度の疲労感があり、注意が必要な状態です。'
      WHEN stage_level = 4 THEN '専門的な支援が推奨される状態です。'
    END,
    'key_patterns', ARRAY[
      CASE 
        WHEN stage_level <= 1 THEN '安定した生活リズム'
        WHEN stage_level = 2 THEN '睡眠の質低下'
        ELSE '集中力低下'
      END,
      CASE 
        WHEN stage_level <= 1 THEN '適度な運動'
        WHEN stage_level = 2 THEN 'ストレス増加'
        ELSE '気分の落ち込み'
      END
    ],
    'recommendations', ARRAY[
      CASE 
        WHEN stage_level <= 1 THEN '現在の良い状態を維持しましょう'
        WHEN stage_level = 2 THEN '十分な休息を心がけてください'
        ELSE 'リラクゼーション技法を試してみてください'
      END
    ]
  ),
  journal_count,
  week_start + INTERVAL '6 days' + INTERVAL '20:00:00'
FROM week_dates
ORDER BY week_start;

-- 挿入されたデータを確認
SELECT 
  week_start_date,
  week_end_date,
  stage_level,
  confidence,
  journal_count,
  analyzed_at
FROM weekly_analysis 
WHERE user_id = auth.uid()
ORDER BY week_start_date DESC
LIMIT 4;

-- 統計情報
SELECT 
  COUNT(*) as total_weeks,
  AVG(stage_level) as avg_stage,
  MIN(stage_level) as min_stage,
  MAX(stage_level) as max_stage,
  AVG(confidence) as avg_confidence
FROM weekly_analysis 
WHERE user_id = auth.uid()
AND week_start_date >= CURRENT_DATE - INTERVAL '4 weeks'; 