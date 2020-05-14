package jsasync.impl;

import haxe.macro.Expr;
#if !macro
import js.lib.Promise;

/**
 * In javascript async functions returning a Promise<T> doesn't result in a Promise<Promise<T>>,
 * instead the promise gets awaited automatically.
 * This abstract implicit casts from T or Promise<T> achieving the same result in the Haxe type system.
 */
abstract PromiseReturnValue<T>(Dynamic) from T from Promise<T> {}
#end

class Helper {
	#if !macro
	public extern static inline function makeAsync<T>(func: T): T {
		return js.Syntax.code("(async {0})", func);
	}

	public extern static inline function unwrapPromiseType<T>(value: PromiseReturnValue<T>) : T {
		return cast value;
	}
	#end

	public static macro function method(e:Expr) {
		return jsasync.impl.Macro.asyncMethodMacro(e);
	}
}
