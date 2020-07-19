package jsasync;

class JSAsyncTools {
	/** Awaits a JS Promise. (only valid inside an async function) */
	@:deprecated("JSAsyncTools.await is deprecated, use JSAsyncTools.jsawait instead")
	@:noCompletion
	public static extern inline function await<T>(promise: js.lib.Promise<T>): T {
		return js.Syntax.code("(await {0})", promise);
	}

	/** Awaits a JS Promise. (only valid inside an async function) */
	public static extern inline function jsawait<T>(promise: js.lib.Promise.Thenable<T>): T {
		return js.Syntax.code("(await {0})", promise);
	}
}
