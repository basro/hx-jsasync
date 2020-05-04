package jsasync;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;

class JSAsyncMacro {
	static function hasAsync(meta: Metadata) {
		for( m in meta ) {
			if ( m.name == ":js.async" ) return true;
		}
		return false;
	}

	// Modifies a function body so that all return expressions are wrapped by JSAsyncMacroHelper.wrapReturn
	static function modifyReturns(e : Expr) {
		return switch(e.expr) {
			case EReturn(sub): macro return jsasync.JSAsyncMacroHelper.wrapReturn(${sub.map(modifyReturns)});
			case EFunction(kind, f): e; // Don't modify returns inside other functions
			default: e.map(modifyReturns);
		}
	}

	macro static public function build():Array<Field> {
		var fields = Context.getBuildFields();

		for ( field in fields ) {
			if ( !hasAsync(field.meta) ) continue;

			switch(field.kind) {
				case FFun(func): func.expr = modifyReturns(func.expr);
				default: continue;
			}
		}
		return fields;
	}
}