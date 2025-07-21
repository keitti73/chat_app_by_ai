import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const roomIds = ctx.stash.roomIds || [];
  
  if (roomIds.length === 0) {
    return {
      operation: "GetItem",
      key: util.dynamodb.toMapValues({ id: "dummy" })
    };
  }
  
  return {
    operation: "BatchGetItem",
    tables: {
      "Room": {
        keys: roomIds.map(id => util.dynamodb.toMapValues({ id }))
      }
    }
  };
}

export function response(ctx) {
  if (ctx.error) {
    util.error(ctx.error.message, ctx.error.type);
  }
  
  const roomIds = ctx.stash.roomIds || [];
  
  if (roomIds.length === 0) {
    return [];
  }
  
  // BatchGetItemの結果を処理
  const rooms = ctx.result.data?.Room || [];
  
  return rooms;
}
