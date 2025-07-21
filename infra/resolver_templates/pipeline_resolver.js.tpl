/**
 * Pipeline Resolver Template for ${resolver_name}
 * このテンプレートは複数のステップを組み合わせる
 * パイプラインリゾルバー用のテンプレートです
 */

export function request(ctx) {
    // パイプラインの開始時に実行される処理
    return {
        payload: ctx.arguments
    };
}

export function response(ctx) {
    // パイプラインの最終結果を処理
    if (ctx.error) {
        console.error("Pipeline error:", ctx.error);
        util.error(ctx.error.message, ctx.error.type, ctx.result);
    }
    
    return ctx.result;
}
