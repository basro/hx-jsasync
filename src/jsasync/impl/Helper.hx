package jsasync.impl;

import js.lib.Promise;

/**
 * In javascript async functions returning a Promise<T> doesn't result in a Promise<Promise<T>>,
 * instead the promise gets awaited automatically.
 * This abstract implicit casts from T or Promise<T> achieving the same result in the Haxe type system.
 */
private abstract PromiseReturnValue<T>(Dynamic) from T from Promise<T> {}

class Helper {

    /** JSAsync Macro will wrap all return values with this function, allowing the Haxe compiler to infer the types correctly. */
    public extern static inline function wrapReturn<T>(value: PromiseReturnValue<T>): Promise<T> {
        return cast value;
    }

    public extern static inline function makeAsync<T>(func: T): T {
        return js.Syntax.code("async {0}", func);
    }
}
