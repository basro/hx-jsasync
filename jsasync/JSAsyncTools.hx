package jsasync;

class JSAsyncTools {
    public static extern inline function await<T>(promise: js.lib.Promise<T>): T {
        return js.Syntax.code("(await {0})", promise);
    }
}
