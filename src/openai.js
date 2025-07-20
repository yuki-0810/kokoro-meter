import OpenAI from 'openai'

// Vercel環境変数から取得
const apiKey = import.meta.env.VITE_OPENAI_API_KEY

if (!apiKey) {
  console.error('OpenAI API環境変数が設定されていません')
  console.error('必要な環境変数: VITE_OPENAI_API_KEY')
}

export const openai = new OpenAI({
  apiKey: apiKey,
  dangerouslyAllowBrowser: true // フロントエンド使用のため（本番では要注意）
})

// メンタルステージ分析用プロンプト
const STAGE_ANALYSIS_PROMPT = `
あなたは心理カウンセラーです。ユーザーの日記内容を分析し、メンタルステージを5段階で判定してください。

## 5段階ステージ基準：
- Stage 0（正常）: ポジティブ語調、やる気あり
- Stage 1（軽度疲労）: 漠然と気力/やる気がない、頭が回らない
- Stage 2（中度疲労）: 周りにイライラすることが増加
- Stage 3（重度疲労）: 感情コントロール困難、表情・態度に出る、早朝覚醒
- Stage 4（危険域）: 涙が自然に出る、死にたい気持ち（適応障害レベル）

## 分析観点：
1. 感情語の頻度・種類
2. 疲労・ストレス関連表現
3. 対人関係の記述
4. 睡眠・身体症状の言及
5. 未来への展望

## 出力形式：
必ずJSON形式で以下の構造で回答してください：
{
  "stage": 数値(0-4),
  "confidence": 数値(0-100),
  "reasons": ["理由1", "理由2", "理由3"],
  "keywords": ["検出されたキーワード1", "キーワード2"],
  "emergency": boolean（Stage 3以上でtrue）
}

分析対象の日記内容：
`

// アクティブレスト提案用プロンプト
const ACTIVE_REST_PROMPT = `
あなたは「7つの休養モデル」に基づいてアクティブレストを提案する専門家です。

## 7つの休養モデル：
### 生理的休養
1. 休息タイプ: 睡眠・仮眠、仕事停止、ソファでゴロゴロ
2. 運動タイプ: ウォーキング、ヨガ、ストレッチ、軽い筋トレ
3. 栄養タイプ: 胃腸にやさしい食事、白湯で温める

### 心理的休養  
4. 親交タイプ: 家族とハグ、ペット触れ合い、雑談、自然浴
5. 娯楽タイプ: 音楽・映画鑑賞、推し活、読書
6. 造形・想像タイプ: 絵・工作、DIY、瞑想、空想

### 社会的休養
7. 転換タイプ: 服を着替える、模様替え、外食、旅行

## ステージ別推奨：
- Stage 0: バランス型（全7タイプローテーション）
- Stage 1: 運動+親交（散歩しながら電話、カフェで雑談）
- Stage 2: 休息+娯楽+転換（仮眠+音楽+模様替え）
- Stage 3: 栄養+造形想像+専門サポート（白湯+瞑想+カウンセリング）
- Stage 4: 緊急対応（即座に専門機関受診）

現在のステージ：Stage {stage}
時間帯：{timeOfDay}

以下の形式で3つの具体的提案をしてください：
{
  "recommendations": [
    {
      "title": "提案タイトル",
      "type": "休養タイプ（例：運動タイプ）",
      "duration": "所要時間（例：5-10分）",
      "description": "具体的な実行方法",
      "materials": "必要なもの（例：なし、ヨガマット等）"
    }
  ],
  "emergency_message": "緊急時メッセージ（Stage 3以上の場合）"
}
`

// 日記テキスト整理用プロンプト
const JOURNAL_ORGANIZE_PROMPT = `
ユーザーが入力した日記の内容を読みやすく整理してください。

## 整理方針：
1. 誤字脱字を自然に修正
2. 読みやすい段落分けを追加
3. 感情や出来事を明確に分離
4. 元の意味や感情は一切変更しない
5. 追加の解釈や推測は行わない

## 出力形式：
{
  "organized_text": "整理された日記テキスト",
  "word_count": 文字数,
  "detected_emotions": ["検出された感情1", "感情2"],
  "key_events": ["主要な出来事1", "出来事2"]
}

入力された日記内容：
`

// 接続テスト関数
export const testOpenAIConnection = async () => {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4.1-mini-2025-04-14",
      messages: [
        {
          role: "user", 
          content: "Hello! This is a connection test. Please respond with 'OpenAI connection successful' in Japanese."
        }
      ],
      max_tokens: 50
    })
    
    return {
      success: true,
      message: response.choices[0].message.content,
      model: "gpt-4.1-mini-2025-04-14"
    }
  } catch (error) {
    return {
      success: false,
      message: `OpenAI接続エラー: ${error.message}`
    }
  }
}

// 日記テキスト整理機能
export const organizeJournalText = async (rawText) => {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4.1-mini-2025-04-14",
      messages: [
        {
          role: "user",
          content: JOURNAL_ORGANIZE_PROMPT + rawText
        }
      ],
      max_tokens: 1000,
      temperature: 0.3
    })

    const result = JSON.parse(response.choices[0].message.content)
    return {
      success: true,
      data: result
    }
  } catch (error) {
    return {
      success: false,
      message: `日記整理エラー: ${error.message}`
    }
  }
}

// メンタルステージ分析機能
export const analyzeJournalForStage = async (journalTexts, useHighAccuracy = false) => {
  try {
    // 複数の日記をまとめて分析用テキストに整形
    const combinedText = journalTexts.map((journal, index) => 
      `【${index + 1}日目】${journal.title}\n${journal.content}\n`
    ).join('\n---\n')

    // Stage 3以上の可能性がある場合は高精度モデル使用
    const model = useHighAccuracy ? "o4-mini-2025-04-16" : "gpt-4.1-mini-2025-04-14"
    
    const response = await openai.chat.completions.create({
      model: model,
      messages: [
        {
          role: "user",
          content: STAGE_ANALYSIS_PROMPT + combinedText
        }
      ],
      max_tokens: 800,
      temperature: 0.1
    })

    const result = JSON.parse(response.choices[0].message.content)
    
    // Stage 3以上の場合、o3で二重チェック
    if (result.stage >= 3 && !useHighAccuracy) {
      console.log('Stage 3以上検出 - o3で二重チェック実行')
      return await analyzeJournalForStage(journalTexts, true)
    }

    return {
      success: true,
      data: {
        ...result,
        model_used: model,
        analysis_date: new Date().toISOString()
      }
    }
  } catch (error) {
    return {
      success: false,
      message: `メンタルステージ分析エラー: ${error.message}`
    }
  }
}

// アクティブレスト提案機能
export const generateActiveRestRecommendations = async (stage, timeOfDay = 'morning') => {
  try {
    const prompt = ACTIVE_REST_PROMPT
      .replace('{stage}', stage)
      .replace('{timeOfDay}', timeOfDay)

    const response = await openai.chat.completions.create({
      model: "gpt-4.1-mini-2025-04-14",
      messages: [
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 1000,
      temperature: 0.7
    })

    const result = JSON.parse(response.choices[0].message.content)
    return {
      success: true,
      data: result
    }
  } catch (error) {
    return {
      success: false,
      message: `アクティブレスト提案エラー: ${error.message}`
    }
  }
} 