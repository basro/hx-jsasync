# 1.1.0

* Rename `JSAsync.func` to `jsasync` and `JSAsyncTools.await` to `jsawait`. Trying to keep away from the names `await` and `async` since they could become keywords in future haxe versions.
* Prefix macro-injected calls to static functions with `std.` to prevent name collisions.

# 1.0.0

* Library made public