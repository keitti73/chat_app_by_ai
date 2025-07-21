/**
 * AppSync JavaScript Resolver: Lambda呼び出し
 * メッセージ感情分析用のLambda関数を呼び出します
 */
import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const { messageId, text } = ctx.args;
  
  // 入力バリデーション
  if (!messageId || !text) {
    util.error("messageIdとtextが必要です", "ValidationError");
  }
  
  if (text.length > 1000) {
    util.error("テキストは1000文字以内で入力してください", "ValidationError");
  }
  
  // Lambda関数に渡すペイロード
  return {
    operation: 'Invoke',
    payload: {
      arguments: ctx.args,
      identity: ctx.identity,
      source: ctx.source,
      request: ctx.request
    }
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  
  return ctx.result;
}