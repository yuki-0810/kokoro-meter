-- 週間分析テーブルのデータを日曜日開始から月曜日開始に修正（PostgreSQL版）
-- 開始日: 元の開始日（日曜日）+ 1日 = 月曜日  
-- 終了日: 元の開始日（日曜日）+ 7日 = 日曜日

-- 2段階で更新：先にweek_end_dateを更新してからweek_start_dateを更新
UPDATE weekly_analysis 
SET 
  week_end_date = week_start_date + INTERVAL '7 days'
WHERE 
  -- 日曜日開始のデータのみを対象とする (0 = Sunday)
  EXTRACT(DOW FROM week_start_date) = 0;

UPDATE weekly_analysis 
SET 
  week_start_date = week_start_date + INTERVAL '1 day'
WHERE 
  -- 日曜日開始のデータのみを対象とする（まだ更新されていないもの）
  EXTRACT(DOW FROM week_start_date) = 0;

-- 実行前に確認用クエリ（実行前にこのクエリで確認してください）
/*
SELECT 
  id,
  week_start_date,
  week_end_date,
  EXTRACT(DOW FROM week_start_date) as start_day_of_week,
  EXTRACT(DOW FROM week_end_date) as end_day_of_week,
  TO_CHAR(week_start_date, 'Day') as start_day_name,
  TO_CHAR(week_end_date, 'Day') as end_day_name
FROM weekly_analysis 
ORDER BY week_start_date;
*/

-- 実行後の確認用クエリ
/*
SELECT 
  id,
  week_start_date,
  week_end_date,
  EXTRACT(DOW FROM week_start_date) as start_day_of_week,
  EXTRACT(DOW FROM week_end_date) as end_day_of_week,
  TO_CHAR(week_start_date, 'Day') as start_day_name,
  TO_CHAR(week_end_date, 'Day') as end_day_name
FROM weekly_analysis 
ORDER BY week_start_date;
*/ 