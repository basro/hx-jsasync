package jsasync.impl;

#if macro
import sys.io.File;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import jsasync.impl.Doc;

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;

typedef PromiseTypes = {
	promise: ComplexType,
	inner: ComplexType
}

class Macro {

	/** Implementation of JSAsync.jsasync macro */
	static public function asyncFuncMacro(e : Expr) {
		if ( Context.containsDisplayPosition(e.pos) ) {
			return e;
		}

		// Convert FArrow into FAnonymous
		switch e.expr {
			case EFunction(FArrow, f):
				f.expr = macro @:pos(e.pos) return ${f.expr};
				e.expr = EFunction(FAnonymous, f);
			default:
		}

		switch e.expr {
			case EFunction(FAnonymous, f): f.expr = modifyFunctionBody(f, e.pos);
			default: Context.error("Argument should be an anonymous function of arrow function", e.pos);
		}

		return macro @:pos(e.pos) std.jsasync.impl.Helper.makeAsync(${e});
	}

	/**
		Implementation of Helper.method macro
		Used by JSAsync build macro to modify method bodies.
	*/
	static public function asyncMethodMacro(e : Expr) {
		return switch e.expr {
			default: Context.error("Invalid expression", e.pos);
			case EFunction(FAnonymous, f):
				var body = modifyFunctionBody(f, e.pos);
				if ( useMarkers() )
					macro @:pos(e.pos) {
						std.js.Syntax.code("%%async_marker%%");
						${body};
					}
				else
					macro @:pos(e.pos) return std.jsasync.impl.Helper.makeAsync(function() ${body})();
		}
	}

	/**
		Figure out the Promise type a function
	*/
	static function getPromiseTypes(f:Function, pos: Position) {
		var retType = if ( f.ret != null ) {
			switch f.ret.toType() {
				case null: null;
				case t: t.follow().toComplexType();
			}
		}else {
			var te =
			try {
				var funcExpr = {expr: EFunction(FAnonymous,f), pos:pos};
				Context.typeExpr(macro {var jsasync_dummy_func = $funcExpr; jsasync_dummy_func;});
			}catch( error : haxe.macro.Error ) {
				Context.error("JSASync: " + error.message, error.pos);
			}

			switch te.t {
				case TFun(_, ret):
					var ct = ret.follow().toComplexType();
					ct == null? null : macro : js.lib.Promise<$ct>;
				default: null;
			}
		}

		return switch retType {
			case null: Context.error("JSAsync: Function has unknown type", pos);
			case TPath({name: "Promise", pack: ["js", "lib"], params: [TPType(innerType)] }):
				{promise: retType, inner: innerType};
			default:
				Context.error('JSASync: Function should have return type js.lib.Promise\nHave: ${retType.toString()}', pos);
		}
	}

	/** Implementation of JSAsync.build macro */
	static public function build():Array<Field> {
		var c = Context.getLocalClass();
		if ( c == null ) return null;
		var c = c.get();
		if ( c.meta.has(":jsasync_processed") ) return null;
		c.meta.add(":jsasync_processed", [], Context.currentPos());

		var fields = Context.getBuildFields();

		for ( field in fields ) {
			var m = Lambda.find(field.meta, m -> m.name == ":jsasync");
			if ( m == null ) continue;

			if (Context.containsDisplayPosition(field.pos)) {
				continue;
			}

			switch field.kind {
				case FFun(func):
					var funcExpr = {expr: EFunction(FAnonymous, {args: [], ret:func.ret, expr: func.expr} ), pos: field.pos}
					func.expr = macro std.jsasync.impl.Helper.method(${funcExpr});
				default:
			}
		}

		return fields;
	}

	static function useMarkers() {
		return !Context.defined("jsasync-no-markers");
	}

	static function mapReturns(e: Expr, returnMapper: (re: Null<Expr>, pos: Position) -> Expr) : Expr {
		function mapper(e: Expr)
			return switch e.expr {
				case EReturn(sub): returnMapper( sub == null? null : sub.map(mapper), e.pos );
				case EFunction(kind, f): e;
				default: e.map(mapper);
			}

		return mapper(e);
	}

	/** Modifies a function body so that all return expressions are of type js.lib.Promise */
	static function wrapReturns(e : Expr, types : PromiseTypes) {
		var found = false;
		var expr = mapReturns(e, (re, pos) ->
			if ( re != null ) {
				found = true;
				var innerCT = types.inner;
				var promiseCT = types.promise;
				macro @:pos(pos) return (cast (${re} : $innerCT) : $promiseCT);
			}
			else
				makeReturnNothingExpr(pos, false)
		);

		return {
			expr: expr,
			found: found
		};
	}

	/** Converts a function body to turn it into an async function */
	static function modifyFunctionBody(f:Function, pos: Position) : Expr {
		function retMapper(re:Null<Expr>, pos:Position) {
			return
				if ( re == null ) macro @:pos(pos) return;
				else macro @:pos(pos) return std.jsasync.impl.Helper.unwrapPromiseType(${re});
		}

		var f : Function = {
			args: f.args,
			ret: f.ret,
			expr: mapReturns(f.expr, retMapper),
			params: f.params
		}
		var types = getPromiseTypes(f,pos);

		var wrappedReturns = wrapReturns(f.expr, types);
		var exprs = [wrappedReturns.expr];
		if ( !wrappedReturns.found ) exprs.push(makeReturnNothingExpr(pos, true));
		return macro $b{exprs}
	}
	
	static function makeReturnNothingExpr(pos: Position, isLast : Bool) : Expr {
		var valueExpr = ( useMarkers() && isLast ) ? "%%async_nothing%%" : "";
		return macro @:pos(pos) return (std.js.Syntax.code($v{valueExpr}) : js.lib.Promise<std.jsasync.Nothing>);
	}

	public static function init() {
		if ( !Context.defined("display") ) {
			Context.onAfterGenerate( fixOutputFile );
		}

		#if (haxe_ver >= 4.30) 
		for (md in metadatas) {
			Compiler.registerCustomMetadata(md,"jsasync");
		}

		for (d in defines) {
			Compiler.registerCustomDefine(d,"jsasync");
		}
		#end
	}

	/** 
		Modifies the js output file.
		Adds "async" to functions marked with %%async_marker%% and removes "return %%async_nothing%%;"
	*/
	static function fixOutputFile() {
		if ( Context.defined("jsasync-no-fix-pass") || Context.defined("jsasync-no-markers") || Sys.args().indexOf("--no-output") != -1 ) return;
		var output = Compiler.getOutput();

		/**
		* markerRegEx broken down:
		* ( # Start of group 1, this will be reinserted on replacement
		*   (?:function )? # Optionally match a "function " prefix
		*   (?:
		*     "(?:[^"\\]|\\.)*" # Match a double quoted string (functions could be quoted strings when their names include special characters)
		*     |                 # Or
		*     \w+               # Match an identifier
		*   )
		*   \s*\([^()]*\)            # Match the function params as anything between parenthesis.
		*   \s*{                     # Match the first curly bracket after the function arguments.
		*   (?:[^{}]|{[^{}]*?})*?    # Match everything after the function's opening curly bracket. Is lazy and matches as few
		*                            # characters as possible.
		*                            # It will allow 1 level of nested balanced curly brackets. This is necesary because 
		*                            # optional arguments will generate `if ( argument == null ) { argument = defaultValue }` between
		*                            # the function's opening curly bracket and the %%async_marker%%
		* ) # End of group 1
		* $ # End of this string (where the marker was found)
		*/
		var functionRegEx = ~/((?:function )?(?:"(?:[^"\\]|\\.)*"|\w+)\s*\([^()]*\)\s*{(?:[^{}]|{[^{}]*?})*?)$/;
		var returnNothingRegEx = ~/\s*return %%async_nothing%%;/g;
		var outputContent = sys.io.File.getContent(output);

		var splitOutput = outputContent.split("%%async_marker%%;");
		for ( i in 0...(splitOutput.length - 1) ) {
			// functionRegEx crashes if searching too long a string
			var cutoff = splitOutput[i].length - 3000;
			var sub = splitOutput[i].substr(cutoff);

			if ( functionRegEx.match(sub) ) {
				sub = functionRegEx.matchedLeft() + "async " + functionRegEx.matched(1);
				splitOutput[i] = splitOutput[i].substr(0, cutoff) + sub;
			} else throw "Function arguments longer than 3000 characters.";
		}
		outputContent = splitOutput.join("");

		outputContent = returnNothingRegEx.replace(outputContent, "");
		File.saveContent(output, outputContent);
	}
}
#end