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
		switch(e.expr) {
			case EFunction(FAnonymous, f): f.expr = modifyFunctionBody(f.expr);
			default: Context.error("Argument should be an anonymous function expression", e.pos);
		}
		return macro @:pos(e.pos) jsasync.impl.Helper.makeAsync(${e});
	}

	/** Implementation of JSAsync.build macro */
	static public function build():Array<Field> {
		var fields = Context.getBuildFields();

		for ( field in fields ) {
			var m = Lambda.find(field.meta, m -> m.name == ":jsasync");
			if ( m == null ) continue;
			field.meta.remove(m);

			switch(field.kind) {
				case FFun(func): func.expr = modifyMethodBody(func.expr);
				default:
			}
		}

		return fields;
	}

	static function useMarkers() {
		var useMarkers = !Context.defined("jsasync-no-markers");
		if ( useMarkers ) registerFixOutputFile();
		return useMarkers;
	}

	/** Modifies a function body so that all return expressions are wrapped by Helper.wrapReturn */
	static function wrapReturns(e : Expr) {
		var found = false;

		function mapFunc(e: Expr) {
			return switch(e.expr) {
				case EReturn(sub): 
					found = true;
					macro @:pos(e.pos) return jsasync.impl.Helper.wrapReturn(${sub.map(mapFunc)});
				case EFunction(kind, f): e; // Don't modify returns inside other functions
				default: e.map(mapFunc);
			}
		}

		return {
			expr: mapFunc(e),
			found: found
		};
	}

	/** Converts a function body to turn it into an async function */
	static function modifyFunctionBody(e:Expr) {
		var wrappedReturns = wrapReturns(e);

		var insertReturn = if ( wrappedReturns.found ) {
			macro @:pos(e.pos) {}
		}else {
			var returnCode = useMarkers()? "%%async_nothing%%" : "undefined";
			macro @:pos(e.pos) return (js.Syntax.code($v{returnCode}):js.lib.Promise<jsasync.Nothing>);
		}

		return macro @:pos(e.pos) {
			${wrappedReturns.expr};
			${insertReturn};
		}
	}

	static function modifyMethodBody(e:Expr) {
		var body = modifyFunctionBody(e);
		return if (useMarkers()) {
			macro @:pos(e.pos) {
				js.Syntax.code("%%async_marker%%");
				${body}
			};
		}else {
			macro @:pos(e.pos) return jsasync.impl.Helper.makeAsync(function() ${body})();
		}
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
		if ( Context.defined("jsasync-no-fix-pass") ) return;
		var output = Compiler.getOutput();
		var markerRegEx = ~/((?:"(?:[^"\\]|\\.)*"|\w+)\s*\([^()]*\)\s*{[^{}]*?)\s*%%async_marker%%;/g;
		var returnNothingRegEx = ~/\s*return %%async_nothing%%;/g;
		var outputContent = sys.io.File.getContent(output);
		outputContent = markerRegEx.replace(outputContent, "async $1");
		outputContent = returnNothingRegEx.replace(outputContent, "");
		File.saveContent(output, outputContent);
	}
}
