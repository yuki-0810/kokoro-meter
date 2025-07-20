-- 30日分のテストデータ生成（ココロメーター）
-- ユーザーID: 8c7d6043-beb4-477d-9e48-58d0e7708268

-- テストデータ挿入
INSERT INTO journals (title, content, original_content, ai_metadata, user_id, entry_date, created_at, updated_at) VALUES

-- 30日前
('新しいプロジェクト開始', '今日から新しいプロジェクトが始まった。チームメンバーも良い人たちで、やりがいを感じている。目標が明確で前向きに取り組めそう。', '今日から新しいプロジェクトが始まった。チームメンバーも良い人たちで、やりがいを感じてる。目標が明確で前向きに取り組めそう。', '{"ai_organized": true, "original_length": 67, "organized_length": 70, "detected_emotions": ["期待", "やりがい", "前向き"], "key_events": ["新プロジェクト開始", "チーム結成"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '30 days', CURRENT_TIMESTAMP - INTERVAL '30 days', CURRENT_TIMESTAMP - INTERVAL '30 days'),

-- 29日前
('少し疲れた一日', '会議が多くて頭が回らない。でも同僚と雑談する時間があって少し気分転換できた。', '会議が多くて頭が回らない、、でも同僚と雑談する時間があって少し気分転換できた', '{"ai_organized": true, "original_length": 45, "organized_length": 48, "detected_emotions": ["疲労", "気分転換"], "key_events": ["多数の会議", "同僚との雑談"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '29 days', CURRENT_TIMESTAMP - INTERVAL '29 days', CURRENT_TIMESTAMP - INTERVAL '29 days'),

-- 28日前
('久しぶりの休日', 'ゆっくり寝て、散歩して、本を読んだ。こういう時間が大切だなと改めて思う。心がリセットされた感じ。', 'ゆっくり寝て、散歩して、本を読んだ。こういう時間が大切だなと改めて思う。心がリセットされた感じ', '{"ai_organized": true, "original_length": 56, "organized_length": 59, "detected_emotions": ["リラックス", "充実"], "key_events": ["十分な睡眠", "散歩", "読書"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '28 days', CURRENT_TIMESTAMP - INTERVAL '28 days', CURRENT_TIMESTAMP - INTERVAL '28 days'),

-- 27日前
('プレゼンの準備', '来週のプレゼンの準備で忙しい。でも準備できているので不安はない。むしろ楽しみ。', '来週のプレゼンの準備で忙しい。でも準備できてるので不安はない。むしろ楽しみ', '{"ai_organized": true, "original_length": 48, "organized_length": 51, "detected_emotions": ["集中", "楽しみ"], "key_events": ["プレゼン準備"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '27 days', CURRENT_TIMESTAMP - INTERVAL '27 days', CURRENT_TIMESTAMP - INTERVAL '27 days'),

-- 26日前
('小さなミス', 'ちょっとしたミスをして上司に注意された。悪気はなかったけど、もう少し注意深くやらないと。', 'ちょっとしたミスをして上司に注意された。。悪気はなかったけど、もう少し注意深くやらないと', '{"ai_organized": true, "original_length": 54, "organized_length": 57, "detected_emotions": ["反省", "注意深さ"], "key_events": ["ミス", "上司からの注意"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '26 days', CURRENT_TIMESTAMP - INTERVAL '26 days', CURRENT_TIMESTAMP - INTERVAL '26 days'),

-- 25日前
('友人とのランチ', '久しぶりに大学時代の友人とランチ。昔話に花が咲いて楽しかった。また会おうと約束した。', '久しぶりに大学時代の友人とランチ。昔話に花が咲いて楽しかった！また会おうと約束した', '{"ai_organized": true, "original_length": 53, "organized_length": 56, "detected_emotions": ["楽しい", "懐かしい"], "key_events": ["友人とランチ", "昔話"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '25 days', CURRENT_TIMESTAMP - INTERVAL '25 days', CURRENT_TIMESTAMP - INTERVAL '25 days'),

-- 24日前
('締切に追われる', '締切が迫っているのに進みが悪い。焦りを感じる。周りの人にも迷惑をかけてしまいそう。', '締切が迫ってるのに進みが悪い、、焦りを感じる。周りの人にも迷惑をかけてしまいそう', '{"ai_organized": true, "original_length": 52, "organized_length": 55, "detected_emotions": ["焦り", "不安"], "key_events": ["締切迫る", "進捗遅れ"], "stage_level": 2}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '24 days', CURRENT_TIMESTAMP - INTERVAL '24 days', CURRENT_TIMESTAMP - INTERVAL '24 days'),

-- 23日前
('雨の日の憂鬱', '朝から雨で気分が沈む。なんとなくやる気が出ない一日だった。早く晴れてほしい。', '朝から雨で気分が沈む、、なんとなくやる気が出ない一日だった。早く晴れてほしい', '{"ai_organized": true, "original_length": 48, "organized_length": 51, "detected_emotions": ["憂鬱", "やる気低下"], "key_events": ["雨天", "気分低下"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '23 days', CURRENT_TIMESTAMP - INTERVAL '23 days', CURRENT_TIMESTAMP - INTERVAL '23 days'),

-- 22日前
('プレゼン成功', 'プレゼンがうまくいった！準備していた甲斐があった。チームからも好評で嬉しい。', 'プレゼンがうまくいった！！準備してた甲斐があった。チームからも好評で嬉しい', '{"ai_organized": true, "original_length": 46, "organized_length": 49, "detected_emotions": ["達成感", "嬉しい"], "key_events": ["プレゼン成功", "チームからの好評"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '22 days', CURRENT_TIMESTAMP - INTERVAL '22 days', CURRENT_TIMESTAMP - INTERVAL '22 days'),

-- 21日前
('週末の計画', '明日は友人と映画を見に行く予定。楽しみで仕方ない。久しぶりのリフレッシュタイムになりそう。', '明日は友人と映画を見に行く予定。楽しみで仕方ない！久しぶりのリフレッシュタイムになりそう', '{"ai_organized": true, "original_length": 57, "organized_length": 60, "detected_emotions": ["楽しみ", "期待"], "key_events": ["映画鑑賞予定", "友人との時間"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '21 days', CURRENT_TIMESTAMP - INTERVAL '21 days', CURRENT_TIMESTAMP - INTERVAL '21 days'),

-- 20日前
('映画鑑賞', '友人と映画を見てきた。感動する作品で、見終わった後も感想を語り合った。良い時間だった。', '友人と映画を見てきた。感動する作品で、見終わった後も感想を語り合った。良い時間だった', '{"ai_organized": true, "original_length": 54, "organized_length": 57, "detected_emotions": ["感動", "充実"], "key_events": ["映画鑑賞", "友人との語らい"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '20 days', CURRENT_TIMESTAMP - INTERVAL '20 days', CURRENT_TIMESTAMP - INTERVAL '20 days'),

-- 19日前
('月曜日の憂鬱', '週末が終わって憂鬱。やることが山積みで気が重い。でも一つずつやっていくしかない。', '週末が終わって憂鬱、、やることが山積みで気が重い。でも一つずつやっていくしかない', '{"ai_organized": true, "original_length": 52, "organized_length": 55, "detected_emotions": ["憂鬱", "重圧感"], "key_events": ["週明け", "タスク山積"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '19 days', CURRENT_TIMESTAMP - INTERVAL '19 days', CURRENT_TIMESTAMP - INTERVAL '19 days'),

-- 18日前
('同僚との衝突', '同僚と意見が合わず、少し言い合いになってしまった。後味が悪い。明日は普通に話せるだろうか。', '同僚と意見が合わず、少し言い合いになってしまった、、後味が悪い。明日は普通に話せるだろうか', '{"ai_organized": true, "original_length": 58, "organized_length": 61, "detected_emotions": ["不安", "後悔"], "key_events": ["同僚との衝突", "意見対立"], "stage_level": 2}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '18 days', CURRENT_TIMESTAMP - INTERVAL '18 days', CURRENT_TIMESTAMP - INTERVAL '18 days'),

-- 17日前
('仲直り', '昨日の同僚と話をして、お互い誤解があったことが分かった。仲直りできて良かった。', '昨日の同僚と話をして、お互い誤解があったことが分かった。仲直りできて良かった', '{"ai_organized": true, "original_length": 50, "organized_length": 53, "detected_emotions": ["安堵", "和解"], "key_events": ["誤解の解消", "仲直り"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '17 days', CURRENT_TIMESTAMP - INTERVAL '17 days', CURRENT_TIMESTAMP - INTERVAL '17 days'),

-- 16日前
('風邪気味', '少し体調が悪い。喉が痛くて鼻水も出る。早めに休んで治したい。', '少し体調が悪い、、喉が痛くて鼻水も出る。早めに休んで治したい', '{"ai_organized": true, "original_length": 42, "organized_length": 45, "detected_emotions": ["不調", "心配"], "key_events": ["体調不良", "風邪症状"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '16 days', CURRENT_TIMESTAMP - INTERVAL '16 days', CURRENT_TIMESTAMP - INTERVAL '16 days'),

-- 15日前
('休養日', '体調を考えて今日は休暇を取った。ゆっくり休んで少し回復した。無理は禁物だと実感。', '体調を考えて今日は休暇を取った。ゆっくり休んで少し回復した。無理は禁物だと実感', '{"ai_organized": true, "original_length": 52, "organized_length": 55, "detected_emotions": ["休息", "回復"], "key_events": ["休暇取得", "体調回復"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '15 days', CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP - INTERVAL '15 days'),

-- 14日前
('忙しい一日', '会議が5つもあって疲れ果てた。集中力も途切れがちで効率が悪かった。こんなスケジュールはもう嫌だ。', '会議が5つもあって疲れ果てた、、集中力も途切れがちで効率が悪かった。こんなスケジュールはもう嫌だ', '{"ai_organized": true, "original_length": 66, "organized_length": 69, "detected_emotions": ["疲労", "イライラ"], "key_events": ["会議5つ", "集中力低下"], "stage_level": 2}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '14 days', CURRENT_TIMESTAMP - INTERVAL '14 days', CURRENT_TIMESTAMP - INTERVAL '14 days'),

-- 13日前
('散歩でリフレッシュ', '昼休みに近所の公園を散歩した。緑を見ていると心が落ち着く。気分転換になった。', '昼休みに近所の公園を散歩した。緑を見てると心が落ち着く。気分転換になった', '{"ai_organized": true, "original_length": 48, "organized_length": 51, "detected_emotions": ["リラックス", "落ち着き"], "key_events": ["公園散歩", "自然鑑賞"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '13 days', CURRENT_TIMESTAMP - INTERVAL '13 days', CURRENT_TIMESTAMP - INTERVAL '13 days'),

-- 12日前
('家族との時間', '久しぶりに家族と夕食を一緒に食べた。両親も元気そうで安心した。こういう時間を大切にしたい。', '久しぶりに家族と夕食を一緒に食べた。両親も元気そうで安心した。こういう時間を大切にしたい', '{"ai_organized": true, "original_length": 59, "organized_length": 62, "detected_emotions": ["安心", "温かい"], "key_events": ["家族との夕食", "両親の健康確認"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '12 days', CURRENT_TIMESTAMP - INTERVAL '12 days', CURRENT_TIMESTAMP - INTERVAL '12 days'),

-- 11日前
('重要な会議', '大きなプロジェクトの会議があった。責任重大で緊張したけど、なんとか乗り切れた。', '大きなプロジェクトの会議があった。責任重大で緊張したけど、なんとか乗り切れた', '{"ai_organized": true, "original_length": 50, "organized_length": 53, "detected_emotions": ["緊張", "安堵"], "key_events": ["重要会議", "責任重大"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '11 days', CURRENT_TIMESTAMP - INTERVAL '11 days', CURRENT_TIMESTAMP - INTERVAL '11 days'),

-- 10日前
('ストレス爆発', '今日は本当に最悪だった。すべてがうまくいかず、イライラが止まらない。周りにも八つ当たりしてしまった。', '今日は本当に最悪だった、、すべてがうまくいかず、イライラが止まらない。周りにも八つ当たりしてしまった', '{"ai_organized": true, "original_length": 68, "organized_length": 71, "detected_emotions": ["怒り", "イライラ"], "key_events": ["すべてうまくいかない", "八つ当たり"], "stage_level": 3}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '10 days'),

-- 9日前
('早朝覚醒', '今朝は4時に目が覚めてしまった。その後眠れずに疲れたまま出勤。コントロールできない感情が湧いてくる。', '今朝は4時に目が覚めてしまった、、その後眠れずに疲れたまま出勤。コントロールできない感情が湧いてくる', '{"ai_organized": true, "original_length": 66, "organized_length": 69, "detected_emotions": ["疲労", "感情不安定"], "key_events": ["早朝覚醒", "睡眠不足"], "stage_level": 3}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '9 days', CURRENT_TIMESTAMP - INTERVAL '9 days', CURRENT_TIMESTAMP - INTERVAL '9 days'),

-- 8日前
('カウンセリング', 'メンタルクリニックに相談に行った。話を聞いてもらえて少し楽になった。専門家の助けは大切だと思う。', 'メンタルクリニックに相談に行った。話を聞いてもらえて少し楽になった。専門家の助けは大切だと思う', '{"ai_organized": true, "original_length": 62, "organized_length": 65, "detected_emotions": ["安堵", "希望"], "key_events": ["カウンセリング", "専門家相談"], "stage_level": 2}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '8 days'),

-- 7日前
('新しい趣味', 'ヨガを始めてみた。体を動かすと心も軽くなる気がする。続けてみよう。', 'ヨガを始めてみた。体を動かすと心も軽くなる気がする。続けてみよう', '{"ai_organized": true, "original_length": 44, "organized_length": 47, "detected_emotions": ["前向き", "軽やか"], "key_events": ["ヨガ開始", "運動習慣"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days'),

-- 6日前
('同期との飲み会', '会社の同期と久しぶりに飲みに行った。みんな同じような悩みを抱えていて少し安心した。', '会社の同期と久しぶりに飲みに行った。みんな同じような悩みを抱えてて少し安心した', '{"ai_organized": true, "original_length": 54, "organized_length": 57, "detected_emotions": ["安心", "共感"], "key_events": ["同期との飲み会", "悩み共有"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '6 days'),

-- 5日前
('良い天気', '久しぶりに快晴で気持ちが良い。外を歩いているだけで元気が出てくる。天気の影響って大きいな。', '久しぶりに快晴で気持ちが良い！外を歩いてるだけで元気が出てくる。天気の影響って大きいな', '{"ai_organized": true, "original_length": 57, "organized_length": 60, "detected_emotions": ["爽快", "元気"], "key_events": ["快晴", "外歩き"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days'),

-- 4日前
('小さな成功', 'ずっと悩んでいた問題が解決した。諦めずに続けて良かった。小さいけれど確実な進歩を感じる。', 'ずっと悩んでた問題が解決した！諦めずに続けて良かった。小さいけれど確実な進歩を感じる', '{"ai_organized": true, "original_length": 56, "organized_length": 59, "detected_emotions": ["達成感", "満足"], "key_events": ["問題解決", "継続の成果"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '4 days'),

-- 3日前
('読書の時間', '図書館で静かに本を読んだ。知識を得る喜びを久しぶりに感じた。もっと読書時間を作りたい。', '図書館で静かに本を読んだ。知識を得る喜びを久しぶりに感じた。もっと読書時間を作りたい', '{"ai_organized": true, "original_length": 54, "organized_length": 57, "detected_emotions": ["充実", "知的好奇心"], "key_events": ["図書館", "読書"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days'),

-- 2日前
('疲れが溜まる', 'なんとなく疲れが抜けない。睡眠時間は足りているのに朝がつらい。少し心配になってきた。', 'なんとなく疲れが抜けない、、睡眠時間は足りてるのに朝がつらい。少し心配になってきた', '{"ai_organized": true, "original_length": 55, "organized_length": 58, "detected_emotions": ["疲労", "心配"], "key_events": ["慢性疲労", "朝の不調"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),

-- 1日前
('友人からの励まし', '心配している友人が連絡をくれた。話を聞いてもらって気持ちが楽になった。感謝している。', '心配してる友人が連絡をくれた。話を聞いてもらって気持ちが楽になった。感謝してる', '{"ai_organized": true, "original_length": 50, "organized_length": 53, "detected_emotions": ["感謝", "安心"], "key_events": ["友人からの連絡", "相談"], "stage_level": 1}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day'),

-- 今日
('今日の振り返り', '一ヶ月を振り返ると色々なことがあった。良いことも悪いこともあったけど、成長できた気がする。', '一ヶ月を振り返ると色々なことがあった。良いことも悪いこともあったけど、成長できた気がする', '{"ai_organized": true, "original_length": 58, "organized_length": 61, "detected_emotions": ["振り返り", "成長感"], "key_events": ["月次振り返り", "成長実感"], "stage_level": 0}', '8c7d6043-beb4-477d-9e48-58d0e7708268', CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 実行完了！このSQLファイルをSupabase SQL Editorに貼り付けて実行してください。 