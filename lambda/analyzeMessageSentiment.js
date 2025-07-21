/**
 * Lambda Function: メッセージ感情分析
 * 
 * このLambda関数は以下の高度な機能を提供します：
 * 1. AWS Comprehend による感情分析
 * 2. メッセージフィルタリング（不適切コンテンツ検出）
 * 3. 言語検出
 * 4. 複雑なビジネスロジック処理
 */

const AWS = require('aws-sdk');

// AWS サービスクライアントの初期化
const comprehend = new AWS.Comprehend({ region: process.env.AWS_REGION });
const dynamodb = new AWS.DynamoDB.DocumentClient();

/**
 * メイン処理: メッセージに感情分析を実行
 */
exports.handler = async (event) => {
    console.log('Lambda Function: analyzeMessageSentiment', JSON.stringify(event, null, 2));
    
    try {
        const { messageId, text } = event.arguments;
        const { username } = event.identity;
        
        // 入力バリデーション
        if (!messageId) {
            throw new Error('メッセージIDが必要です');
        }
        
        if (!text) {
            throw new Error('分析対象テキストが必要です');
        }
        
        if (!username) {
            throw new Error('認証が必要です');
        }
        
        // 1. 並列処理で感情分析と言語検出を実行
        const [sentimentResult, languageResult] = await Promise.all([
            analyzeSentiment(text),
            detectLanguage(text)
        ]);
        
        // 2. 不適切コンテンツ検出
        const moderationResult = await moderateContent(text);
        
        // 3. 分析結果をDynamoDBに保存
        const analysisResult = {
            messageId: messageId,
            sentiment: sentimentResult.Sentiment,
            sentimentScore: sentimentResult.SentimentScore,
            language: languageResult.Languages[0],
            moderation: moderationResult,
            analyzedAt: new Date().toISOString(),
            analyzedBy: username,
            ttl: Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60) // 90日後に自動削除
        };
        
        await saveAnalysisResult(analysisResult);
        
        // 4. 結果を返却
        return {
            messageId: messageId,
            sentiment: sentimentResult.Sentiment,
            sentimentScore: {
                positive: sentimentResult.SentimentScore.Positive,
                negative: sentimentResult.SentimentScore.Negative,
                neutral: sentimentResult.SentimentScore.Neutral,
                mixed: sentimentResult.SentimentScore.Mixed
            },
            language: languageResult.Languages[0].LanguageCode,
            languageConfidence: languageResult.Languages[0].Score,
            isAppropriate: moderationResult.isAppropriate,
            moderationFlags: moderationResult.flags,
            analyzedAt: analysisResult.analyzedAt
        };
        
    } catch (error) {
        console.error('感情分析エラー:', error);
        
        // エラーログをCloudWatchに送信
        await logError(error, event);
        
        throw new Error(`感情分析に失敗しました: ${error.message}`);
    }
};

/**
 * AWS Comprehend で感情分析を実行
 */
async function analyzeSentiment(text) {
    // テキストの長さ制限チェック（Comprehendの制限：5000文字）
    if (text.length > 5000) {
        text = text.substring(0, 5000);
    }
    
    const params = {
        Text: text,
        LanguageCode: 'ja' // 日本語を主軸とするが、自動検出も併用
    };
    
    try {
        return await comprehend.detectSentiment(params).promise();
    } catch (error) {
        // 日本語で失敗した場合は英語で再試行
        if (error.code === 'UnsupportedLanguageException') {
            params.LanguageCode = 'en';
            return await comprehend.detectSentiment(params).promise();
        }
        throw error;
    }
}

/**
 * AWS Comprehend で言語検出を実行
 */
async function detectLanguage(text) {
    const params = { Text: text };
    return await comprehend.detectDominantLanguage(params).promise();
}

/**
 * コンテンツモデレーション（不適切コンテンツ検出）
 */
async function moderateContent(text) {
    // シンプルなキーワードベースのフィルタリング
    const inappropriateKeywords = [
        'スパム', 'spam', '詐欺', 'scam',
        '暴力', 'violence', '脅迫', 'threat'
    ];
    
    const flags = [];
    const lowerText = text.toLowerCase();
    
    inappropriateKeywords.forEach(keyword => {
        if (lowerText.includes(keyword.toLowerCase())) {
            flags.push(keyword);
        }
    });
    
    // 将来的にはAWS Rekognition Text Moderation等を使用可能
    return {
        isAppropriate: flags.length === 0,
        flags: flags,
        confidence: flags.length === 0 ? 1.0 : 0.8
    };
}

/**
 * 分析結果をDynamoDBに保存
 */
async function saveAnalysisResult(analysisResult) {
    const params = {
        TableName: process.env.SENTIMENT_ANALYSIS_TABLE_NAME,
        Item: analysisResult,
        ConditionExpression: 'attribute_not_exists(messageId)' // 重複防止
    };
    
    try {
        await dynamodb.put(params).promise();
    } catch (error) {
        if (error.code !== 'ConditionalCheckFailedException') {
            throw error;
        }
        // 既に分析済みの場合は無視
        console.log('分析結果は既に存在します:', analysisResult.messageId);
    }
}

/**
 * エラーログをCloudWatchに記録
 */
async function logError(error, event) {
    const errorLog = {
        timestamp: new Date().toISOString(),
        error: error.message,
        stack: error.stack,
        event: event,
        functionName: 'analyzeMessageSentiment'
    };
    
    console.error('Lambda Error Log:', JSON.stringify(errorLog, null, 2));
}
