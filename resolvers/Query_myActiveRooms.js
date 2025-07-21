import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const username = ctx.identity?.username;
  if (!username) {
    util.error("認証ユーザーのみ", "UnauthorizedError");
  }
  
  return {
    operation: "Query",
    query: {
      expression: "#user = :user",
      expressionNames: {
        "#user": "user"
      },
      expressionValues: util.dynamodb.toMapValues({
        ":user": username
      })
    },
    index: "user-index",
    limit: 1000
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  
  // ユニークなroomIdのリストを取得
  const roomIds = [...new Set(ctx.result.items.map(msg => msg.roomId))];
  
  // 後続のバッチ取得用にroomIdsを保存
  ctx.stash.roomIds = roomIds;
  
  return roomIds;
}
