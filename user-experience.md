以下ユーザーの体験フロー

#初期セットアップ
アカウント登録ログインログアウト
アカウント登録はまずはEメールとパスワードのみ

#日記の記録・確認
ユーザは1日1回日記を記録する。日記については音声・テキスト入力で今日あったことを1分間程度喋って、その内容をAIが整理して保存する
✅ **実装済み**: ユーザはカレンダーから登録した日記の内容を確認する
- 月単位でのカレンダー表示
- 日付別の日記記録状況の可視化（ステージレベル別色分け）
- 特定の日付をクリックして日記詳細表示
- 月の記録統計（記録日数・達成率）表示
- AI分析結果（感情・出来事・ステージレベル）の表示

#１週間ごとに判定
✅ **実装済み**: 1週間ごとにユーザが登録した日記をAIが読み込んでユーザアドメンタル状態を分析し、今どのステージなのか、そのステージですべきことを表示する
- OpenAI o4-mini による5段階ステージ自動判定
- Stage 3以上の緊急時は o3 による二重チェック
- 信頼度スコア・判定理由・検出キーワード表示
✅ **実装済み**: そのステージですべきことの中にアクティブレスの提案を入れる
- 7つの休養モデル（生理的・心理的・社会的）に基づく具体的提案
- ステージ別最適化された3つの提案を自動生成
- 時間帯（朝・昼・夜）に応じたパーソナライズ

#ステージ推移分析
✅ **実装済み**: ユーザのメンタルステージの変化を可視化するために、1週間単位での推移のグラフを表示する。
- カレンダー形式でのステージレベル色分け表示
- 月単位での記録統計・達成率表示
- 日付別詳細分析結果の確認機能
✅ **実装済み**: 週次ステージ推移分析機能
- 過去12週間のステージレベルトレンドグラフ（Chart.js使用）
- 週次統計サマリー（平均ステージ・トレンド方向・分析週数）
- インタラクティブな週選択・詳細分析機能
- 週次AI分析実行・アクティブレスト提案生成
- 週ごとの記録詳細・信頼度スコア表示

## 🚧 **将来実装予定**
- 音声入力機能（Whisper API統合済み、UI実装中）
- ストレス要因分析（作業負荷、コミュニケーション等）
- 緊急時エスカレーション機能
