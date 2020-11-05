# 1.2.1

* Fix bug where class methods with arguments that have default values caused the jsasync marker fix pass to break.

# 1.2.0

* Use Thenable instead of Promise as argument type of JSAsyncTools.jsawait

# 1.1.1

* Fix incorrect js output for module level functions.

# 1.1.0

* Rename `JSAsync.func` to `jsasync` and `JSAsyncTools.await` to `jsawait`. Trying to keep away from the names `await` and `async` since they could become keywords in future haxe versions.
* Prefix macro-injected calls to static functions with `std.` to prevent name collisions.

# 1.0.0

* Library made public