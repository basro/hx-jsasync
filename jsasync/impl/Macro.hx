package jsasync.impl;

import haxe.macro.TypedExprTools;
import sys.io.File;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;

class Macro {

	/** Implementation of JSAsync.func macro */
	static public function asyncFuncMacro(e : Expr) {
		registerFixOutputFile();

		switch(e.expr) {
			case EFunction(kind, f): f.expr = modifyFunctionBody(f.expr);
			default: Context.error("Argument should be a function expression", e.pos);
		}
		return e;
	}

	/** Implementation of JSAsync.build macro */
	static public function build():Array<Field> {
		var fields = Context.getBuildFields();
		var foundAsync = false;

		for ( field in fields ) {
			var m = Lambda.find(field.meta, m -> m.name == ":jsasync");
			if ( m == null ) continue;
			field.meta.remove(m);

			switch(field.kind) {
				case FFun(func):
					func.expr = modifyFunctionBody(func.expr);
					foundAsync = true;
				default:
			}
		}

		if (foundAsync) registerFixOutputFile();
		return fields;
	}

	/** Modifies a function body so that all return expressions are wrapped by Helper.wrapReturn */
	static function wrapReturns(e : Expr) {
		var found = false;

		function mapFunc(e: Expr) {
			return switch(e.expr) {
				case EReturn(sub): 
					found = true;
					macro return jsasync.impl.Helper.wrapReturn(${sub.map(mapFunc)});
				case EFunction(kind, f): e; // Don't modify returns inside other functions
				default: e.map(mapFunc);
			}
		}

		return {
			expr: mapFunc(e),
			found: found
		};
	}

	/** Adds a marker at the start of a function and wraps the return expressions */
	static function modifyFunctionBody(e:Expr) {
		var wrappedReturns = wrapReturns(e);

		var insertReturn = if ( wrappedReturns.found ) macro {} else macro return (js.Syntax.code("%%async_nothing%%"):js.lib.Promise<jsasync.Nothing>);

		var result = macro {
			js.Syntax.code("%%async_marker%%");
			${wrappedReturns.expr};
			${insertReturn}
		};
		return result;
	}

	static var fixOutputFileRegistered = false;
	static function registerFixOutputFile() {
		if ( !fixOutputFileRegistered ) {
			Context.onAfterGenerate( fixOutputFile );
			fixOutputFileRegistered = true;
		}
	}

	/** 
		Modifies the js output file.
		Adds "async" to functions marked with %%async_marker%% and removes "return %%async_nothing%%;"
	*/
	static function fixOutputFile() {
		var output = Compiler.getOutput();
		var markerRegEx = ~/((?:"(?:[^"\\]|\\.)*"|\w+)\s*\([^)]*\)\s*{[^{}]*?)\s*%%async_marker%%;/g;
		var returnNothingRegEx = ~/\s*return %%async_nothing%%;/g;
		var outputContent = sys.io.File.getContent(output);
		outputContent = markerRegEx.replace(outputContent, "async $1");
		outputContent = returnNothingRegEx.replace(outputContent, "");
		File.saveContent(output, outputContent);
	}
}
