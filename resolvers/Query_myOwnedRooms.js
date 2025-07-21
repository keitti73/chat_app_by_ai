import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const username = ctx.identity?.username;
  if (!username) {
    util.error("認証ユーザーのみ", "UnauthorizedError");
  }
  
  return {
    operation: "Query",
    query: {
      expression: "owner = :owner",
      expressionValues: util.dynamodb.toMapValues({
        ":owner": username
      })
    },
    index: "owner-index"
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  return ctx.result.items;
}
