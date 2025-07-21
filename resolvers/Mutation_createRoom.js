import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const username = ctx.identity?.username || "guest";
  const id = util.uuid();
  const createdAt = util.time.nowISO8601();
  
  return {
    operation: 'PutItem',
    key: util.dynamodb.toMapValues({ id }),
    attributeValues: util.dynamodb.toMapValues({
      id,
      name: ctx.args.name,
      owner: username,
      createdAt
    })
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  return ctx.result;
}
