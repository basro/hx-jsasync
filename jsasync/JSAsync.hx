package jsasync;

/** Implement this interface to enable @:js.async type checking on the class methods */
@:autoBuild(jsasync.JSAsyncMacro.build())
interface JSAsync {}
