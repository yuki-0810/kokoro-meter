-- 週間分析テーブルのデータを日曜日開始から月曜日開始に修正
-- 開始日: 元の開始日（日曜日）+ 1日 = 月曜日  
-- 終了日: 元の開始日（日曜日）+ 7日 = 日曜日

-- 2段階で更新：先にweek_end_dateを更新してからweek_start_dateを更新
UPDATE weekly_analysis 
SET 
  week_end_date = DATE(week_start_date, '+7 days')
WHERE 
  -- 日曜日開始のデータのみを対象とする
  strftime('%w', week_start_date) = '0';

UPDATE weekly_analysis 
SET 
  week_start_date = DATE(week_start_date, '+1 day')
WHERE 
  -- 日曜日開始のデータのみを対象とする（まだ更新されていないもの）
  strftime('%w', week_start_date) = '0';

-- 実行前に確認用クエリ（実行前にこのクエリで確認してください）
/*
SELECT 
  id,
  week_start_date,
  week_end_date,
  strftime('%w', week_start_date) as start_day_of_week,
  strftime('%w', week_end_date) as end_day_of_week
FROM weekly_analysis 
ORDER BY week_start_date;
*/

-- 実行後の確認用クエリ
/*
SELECT 
  id,
  week_start_date,
  week_end_date,
  strftime('%w', week_start_date) as start_day_of_week,
  strftime('%w', week_end_date) as end_day_of_week
FROM weekly_analysis 
ORDER BY week_start_date;
*/ 