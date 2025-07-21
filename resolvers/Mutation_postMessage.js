import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const user = ctx.identity?.username || "guest";
  
  if (!ctx.args.text || ctx.args.text.length > 500) {
    util.error("textは1～500文字で入力してください", "ValidationError");
  }
  
  const id = util.uuid();
  const createdAt = util.time.nowISO8601();
  
  return {
    operation: 'PutItem',
    key: util.dynamodb.toMapValues({ id }),
    attributeValues: util.dynamodb.toMapValues({
      id,
      text: ctx.args.text,
      user,
      createdAt,
      roomId: ctx.args.roomId
    })
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  return ctx.result;
}
