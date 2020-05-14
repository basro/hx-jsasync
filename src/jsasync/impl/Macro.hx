package jsasync.impl;

#if macro
import sys.io.File;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;

typedef PromiseTypes = {
	promise: ComplexType,
	inner: ComplexType
}

class Macro {
	static var helper = macro jsasync.impl.Helper;
	static var jsasyncClass = macro jsasync.JSAsync;
	static var jsSyntax = macro js.Syntax;

	/** Implementation of JSAsync.func macro */
	static public function asyncFuncMacro(e : Expr) {
		// Convert FArrow into FAnonymous
		switch(e.expr) {
			case EFunction(FArrow, f):
				f.expr = macro return ${f.expr};
				e.expr = EFunction(FAnonymous, f);
			default:
		}

		switch(e.expr) {
			case EFunction(FAnonymous, f):
				var types = getPromiseTypes(f,e.pos);
				f.expr = modifyFunctionBody(f.expr, types);
			default: Context.error("Argument should be an anonymous function of arrow function", e.pos);
		}

		return macro ${helper}.makeAsync(${e});
	}

	/** Implementation of JSAsync.method macro */
	static public function asyncMethodMacro(e : Expr) {
		return switch e.expr {
			default: Context.error("Invalid expression", e.pos);
			case EFunction(FAnonymous, f):
				function retMapper(re:Null<Expr>, pos:Position) {
					return
						if ( re == null ) macro return;
						else macro @:pos(p(pos)) return jsasync.impl.Helper.unwrapPromiseType(${re});
				}
	
				var f : Function = {
					args: f.args,
					ret: f.ret,
					expr: mapReturns(f.expr, retMapper),
					params: f.params
				}

				var types = getPromiseTypes(f,e.pos);
				macro {
					js.Syntax.code("%%async_marker%%");
					${modifyFunctionBody(f.expr, types)};
				}
		}
	}

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

			switch( te.t ) {
				case TFun(_, ret): ret.follow().toComplexType();
				default: null;
			}
		}

		return switch retType {
			case null: Context.error("JSAsync: Function has unknown type", pos);
			case TPath({name: "Promise", pack: ["js", "lib"], params: [TPType(innerType)] }):
				{promise: retType, inner: innerType};
			default:
				{
					promise: TPath({name:"Promise", pack: ["js", "lib"], params: [TPType(retType)]}),
					inner: retType
				}
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

			switch(field.kind) {
				case FFun(func):
					var funcExpr = {expr: EFunction(FAnonymous, {args: [], ret:func.ret, expr: func.expr} ), pos: field.pos}
					func.expr = macro jsasync.JSAsync.method(${funcExpr});
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

	/** Modifies a function body so that all return expressions are wrapped by Helper.wrapReturn */
	static function wrapReturns(e : Expr, types : PromiseTypes) {
		var found = false;
		var expr = mapReturns(e, (re, pos) ->
			if ( re != null ) {
				found = true;
				var innerCT = types.inner;
				var promiseCT = types.promise;
				macro @:pos(p(pos)) return (cast (${re} : $innerCT) : $promiseCT);
			}
			else
				macro @:pos(p(pos)) return (null : js.lib.Promise<jsasync.Nothing>)
		);

		return {
			expr: expr,
			found: found
		};
	}

	/** For some reason using @:pos during display tends to break completion, this is a work around for that.
		It's likely that this is a bug in the haxe compiler.
		TODO: try to make smaller code sample that reproduces this bug. */
	static function p(pos:Position) {
		return Context.defined("display")? Context.currentPos() : pos;
	}

	/** Converts a function body to turn it into an async function */
	static function modifyFunctionBody(e:Expr, types: PromiseTypes) {
		var wrappedReturns = wrapReturns(e, types);
		
		var insertReturn = if ( wrappedReturns.found ) {
			macro @:pos(p(e.pos)) {}
		}else {
			macro @:pos(p(e.pos)) return (null : js.lib.Promise<jsasync.Nothing>);//makeReturnNothingExpr(e.pos, useMarkers()? "%%async_nothing%%" : "");
		}

		return macro {
			${wrappedReturns.expr};
			${insertReturn};
		}
	}

	static function makeReturnNothingExpr(pos: Position, returnCode: String = "") {
		return macro @:pos(p(pos)) return ${helper}.makeNothingPromise(${jsSyntax}.code($v{returnCode}));
	}

	public static function init() {
		if ( !Context.defined("display") ) {
			Context.onAfterGenerate( fixOutputFile );
		}
	}

	/** 
		Modifies the js output file.
		Adds "async" to functions marked with %%async_marker%% and removes "return %%async_nothing%%;"
	*/
	static function fixOutputFile() {
		if ( Context.defined("jsasync-no-fix-pass") || Sys.args().indexOf("--no-output") != -1 ) return;
		var output = Compiler.getOutput();
		var markerRegEx = ~/((?:"(?:[^"\\]|\\.)*"|\w+)\s*\([^()]*\)\s*{[^{}]*?)\s*%%async_marker%%;/g;
		var returnNothingRegEx = ~/\s*return %%async_nothing%%;/g;
		var outputContent = sys.io.File.getContent(output);
		outputContent = markerRegEx.replace(outputContent, "async $1");
		outputContent = returnNothingRegEx.replace(outputContent, "");
		File.saveContent(output, outputContent);
	}
}
#end