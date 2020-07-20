
# JSAsync
![tests status](https://github.com/basro/hx-jsasync/workflows/Tests/badge.svg?branch=master)

This library lets you create native Javascript async functions in your haxe code in an ergonomic and type safe way.

For example using JSAsync this haxe code:
```haxe
@:jsasync static function fetchText(url : String) {
    return "Text: " + Browser.window.fetch(url).jsawait().text().jsawait();
}
```
Has return type `js.lib.Promise<String>`

and compiles to the following js:
```js
static async fetchText(url) {
    return "Text: " + (await (await window.fetch(url)).text());
}
```

# Installation

JSAsync requires haxe 4+

Install with haxelib
```
haxelib install jsasync
```

Then add it to your project's build.hxml
```
-lib jsasync
-js main.js
-main my.package.Main
```

# Usage

JSAsync will convert haxe functions into async functions that return `js.lib.Promise<T>`. Inside of an async function it is possible to await other promises.

## Async local functions

Use the `JSAsync.jsasync` macro to convert a local function declaration into a javascript async function.

Example:
```haxe
var myFunc = JSAsync.jsasync(function(val:Int) {
    return val;
});
```

To reduce verbosity consider directly importing the macro:

```haxe
import jsasync.JSAsync.jsasync;

/* ... */

var myFunc = jsasync(function(val:Int) {
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

Inside of an async function you can await a `js.lib.Promise` using the `JSAsyncTools.jsawait` method:

```haxe
import jsasync.IJSAsync;
import jsasync.JSAsyncTools;

class MyClass implements IJSAsync {
    @:jsasync static function example() {
        var result = JSAsyncTools.jsawait(js.lib.Promise.resolve(10));
        trace(result); // 10
    }
}
```

The `JSAsyncTools.jsawait(promise)` function compiles into `(await promise)` in Javascript.

JSAsyncTools.jsawait() is meant to be used as a static extension:

```haxe
import jsasync.IJSAsync;
using jsasync.JSAsyncTools;

class MyClass implements IJSAsync {
    @:jsasync static function example() {
        var result = js.lib.Promise.resolve(10).jsawait();
        trace(result); // 10
    }
}
```

Alternatively you can import the jsawait function:

```haxe
import jsasync.IJSAsync;
import jsasync.JSAsyncTools.jsawait;

class MyClass implements IJSAsync {
    @:jsasync static function example() {
        var result = jsawait(js.lib.Promise.resolve(10));
        trace(result); // 10
    }
}
```

You can mix both approaches too.

### Using await outside of async functions

Even though this is an error and will produce invalid JS code at this time JSAsync is not able to detect this. Future versions might improve on this.

On the bright side, this is a syntax error in javascript so it wont cause silent bugs in your js code.

## Typing

In most cases JSAsync is able to infer the return type of your async function automatically.

You can explicitly type an async function like you would normally, just remember to use `js.lib.Promise<T>` as your return type.

Example:
```haxe
@:jsasync function example() : Promise<Int> {
    return 10;
}
```

### Void functions

If the function you are converting to async has return type Void then JSAsync will use the type `jsasync.Nothing` as the promise return type.

Example:
```haxe
@:jsasync function example() : Promise<jsasync.Nothing> {
    trace("This function has no return");
}
```

### Returning Promise

In javascript async functions the code `return myPromise` is equivalent to `return await myPromise`. JSAsync takes this into consideration and will type your functions accordingly.

Example:
```haxe
@:jsasync function asyncInt() : Promise<Int> {
    return 10;
}

@:jsasync function example(test:Int) : Promise<Float> {
    switch test {
        case 1: return asyncInt(); // Promise gets unwrapped
        case 2: return asyncInt().jsawait();
        case 3: return 10.0;
    }
}
```

## Output

JSAsync will add markers of the form `%%jsasync_marker%%` to your functions. These markers are used to fix the .js file generated by haxe in a post processing pass.

### `jsasync-no-markers`
You can use the compiler option `-D jsasync-no-markers` to enable a different approach which doesn't use markers and produces valid code without the need to fix the generated .js file.

You can use this setting if the marker + fix pass causes problems with your pipeline.

The generated code without markers is correct but is less compact and possibly a little bit less efficient.

### `jsasync-no-fix-pass`

When using `-D jsasync-no-fix-pass` JSAsync will not run the final file fixing post process even if markers were generated. The output will be invalid js, use this if you wish to inspect how the code looks before the fix pass.


## Recommendations

### import.hx

For extra convenience consider adding an [import.hx file](https://haxe.org/manual/type-system-import-defaults.html) to the root of your project with jsasync imports in it.

```haxe
// import.hx
package my.project.root;

#if js // Only import if target is js to avoid breaking your macros.
import jsasync.JSAsync.jsasync;
import jsasync.JSAsyncTools.jsawait;
using jsasync.JSAsyncTools;
#end
```

This will automatically add these imports to all the modules in your project. In combination with `--macro jsasync.JSAsync.use("my.project.root")` this will significantly reduce verbosity in your project.

# License

This project is licensed under the terms of the MIT license.