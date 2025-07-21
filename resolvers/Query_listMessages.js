import { util } from '@aws-appsync/utils';

export function request(ctx) {
  return {
    operation: "Query",
    query: {
      expression: "roomId = :roomId",
      expressionValues: util.dynamodb.toMapValues({
        ":roomId": ctx.args.roomId
      })
    },
    index: "room-index",
    scanIndexForward: false,
    limit: ctx.args.limit || 50
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  return ctx.result.items;
}
