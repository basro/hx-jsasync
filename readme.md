
# JSAsync

This library lets you use native Javascript async functions in your haxe code in an ergonomic and type safe way.

For example using JSAsync this haxe code:
```haxe
@:jsasync static function fetchText(url : String) {
    return Browser.window.fetch(url).await().text();
}
```
Has return type `js.lib.Promise<String>`

and compiles to the following js:
```js
static async fetchText(url) {
    return (await window.fetch(url)).text();
}
```

# Usage

JSAsync will convert haxe functions into async functions that return `js.lib.Promise<T>`. Inside of an async function it is possible to await other promises.

## Async local functions

Use the `JSAsync.func` macro to convert a local function declaration into a javascript async function.

Example:
```haxe
var myFunc = JSAsync.func(function(val:Int) {
    return val;
});
```

## Async methods

Annotate your class methods with `@:jsasync` to convert them into async functions.

For the `@:jsasync` metadata to take effect your class needs to be processed with the `JSAsync.build()` type-building macro.

You can achieve this in three different ways:

### Use the @:build compiler metadata
Add `@:build(jsasync.JSAsync.build())` metadata to your class.
```haxe 
@:build(jsasync.JSAsync.build())
class MyClass {
    @:jsasync static function() {
        return "hi";
    }
}
```

### Implement `jsasync.IJSAsync`
For convenience you can implement the interface `jsasync.IJSAsync` which will automatically add the `@:build` metadata to your class.

```haxe
import jsasync.IJSAsync;

class MyClass implements IJSAsync {
    @:jsasync static function() {
        return "hi";
    }
}
```

### Use the JSAsync.use initialization macro

Add `--macro jsasync.JSAsync.use("my.package.name")` to your haxe compiler options to automatically add the `JSAsync.build` macro to all classes inside the specified package name and all of its subpackages.

## Await a promise

Inside of an async function you can await a `js.lib.Promise` using the `JSAsyncTools.await` method:

```haxe
import jsasync.IJSAsync;
import jsasync.JSAsyncTools;

class MyClass implements IJSAsync {
    @:jsasync static function example() {
        var result = JSAsyncTools.await(js.lib.Promise.resolve(10));
        trace(result); // 10
    }
}
```

The `JSAsyncTools.await(promise)` function compiles into `(await promise)` in Javascript.

JSAsyncTools.await() is meant to be used as a static extension:

```haxe
import jsasync.IJSAsync;
using jsasync.JSAsyncTools;

class MyClass implements IJSAsync {
    @:jsasync static function example() {
        var result = js.lib.Promise.resolve(10).await();
        trace(result); // 10
    }
}
```
