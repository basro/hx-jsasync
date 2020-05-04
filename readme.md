
This is an example of how a library would look like with support for @:js.async in the Haxe compiler.

using `JSAsyncTools` adds the .await() method to js promises.

Implementing `JSAsync` will run a macro that will fix the type checking for async methods in the class.


The haxe code:
```haxe
@:js.async static function asyncMethod() {
    trace("hello");
    timer(1000).await();
    trace("world");
    timer(1000).await();
    trace("fetching url");
    var text = fetchText("http://someurl").await();
    return "(" + text + ")";
}
```

Will have the return type `Promise<String>`
and will build into the following js:
```js
static async asyncMethod() {
    console.log("Main.hx:21:","hello");
    (await Main.timer(1000));
    console.log("Main.hx:23:","world");
    (await Main.timer(1000));
    console.log("Main.hx:25:","fetching url");
    let text = (await Main.fetchText("http://someurl"));
    return "(" + text + ")";
}
```

