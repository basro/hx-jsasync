# 1.3.1

* Register metadata and defines documentation using init macro instead of haxelib.json, fixes lix installs of jsasync.

# 1.3.0

* Add custom metadata and defines documentation (for haxe 4.3.0)

# 1.2.3

* Improves performance of the %%async_marker%% post processing pass, useful when dealing with very large js files.

# 1.2.2

* Avoids running the macro on functions that contain the display position to improve haxe completion reliability.

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