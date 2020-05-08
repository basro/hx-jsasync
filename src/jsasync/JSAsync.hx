package jsasync;

import haxe.macro.Compiler;
import haxe.macro.Expr;

class JSAsync {
	/** Use this macro with function expressions to turn them into async functions. */
	public static macro function func(e:Expr) {
		return jsasync.impl.Macro.asyncFuncMacro(e);
	}

	#if macro
	/**
		This macro can be used with `@:build()` compiler metadata to add support for `@:jsasync`
		metadata in a class methods.

		Alternatively you can use the IJSAsync interface.
	*/
	static macro function build(packagePath:String = "") : Array<Field> {
		return jsasync.impl.Macro.build();
	}


	/** 
		Call this function with the compiler option `--macro jsasync.JSAsync.use("my.package.name")` to automatically
		add the JSAsync.build macro to all classes in the specified package.
	*/
	static function use(packagePath:String = "") {
		Compiler.addGlobalMetadata(packagePath, "@:build(jsasync.JSAsync.build())");
	}
	#end
}
