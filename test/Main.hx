import js.lib.Promise;
import utest.Async;
import utest.ui.Report;
import utest.Test;
import utest.Runner;
import utest.Assert;

import Util.timer;

class Main {
	public static function main() {
		var runner = new Runner();
		runner.addCase(new TestJSAsync());
		Report.create(runner);
		runner.run();
	}
}

class TestJSAsync extends Test {

	function testAnonymousAsyncFunction(async : Async) {
		var val = 0;
		var func = jsasync(function() {
			val = 1;
			timer(100).jsawait();
			val = 2;
		});

		var func2 = jsasync(function() {
			Assert.equals(val, 0);
			func().jsawait();
			Assert.equals(val, 2);
		});

		var func3 = jsasync(function(returnVal : Int) {
			timer(50).jsawait();
			return returnVal + 5;
		});

		var func4 = jsasync(function() {
			timer(50).jsawait();
			return func3(5);
		});

		var func5 = jsasync(function() {
			var v = func4().jsawait();
			Assert.equals(v, 10);
		});

		var run = jsasync(function() {
			Promise.all([func5(), func2()]).jsawait();
			async.done();
		});

		run();
		Assert.equals(val,1);
	}

	function testStaticAsyncFunctions(async : Async) {
		var run = jsasync(function() {
			var n1 = StaticAsyncFunctions.delayNumber(50,1);
			var n2 = StaticAsyncFunctions.delayNumber(40,2);
			var n3 = StaticAsyncFunctions.quotedFunctionName();
			Assert.equals(StaticAsyncFunctions.sumPromises(n1, n2).jsawait(), 3);
			Assert.equals(n3.jsawait(), 20);
			async.done();
		});

		run();
	}

	function testAsyncMethods(async : Async) {
		jsasync(function() {
			var obj = new AsyncMethods();
			Assert.equals(obj.getVal(), 0);
			var p = obj.addIntPromise(StaticAsyncFunctions.delayNumber(20,5));
			Assert.equals(obj.getVal(), 0);
			Assert.equals(p.jsawait(), 5);
			Assert.equals(obj.getVal(), 5);
			Assert.equals(obj.quotedMethod().jsawait(),"Val: 10");
			Assert.equals(obj.getVal(), 10);
			Assert.equals(obj.asyncMethodWithDefaultValueArgument().jsawait(), 2);
			Assert.equals(obj.asyncMethodWithDefaultValueArgument(1).jsawait(), 3);
			async.done();
		})();
	}
}

class StaticAsyncFunctions {
	@:jsasync public static function delayNumber(delayMsec : Int, num : Int ) {
		timer(delayMsec).jsawait();
		return num;
	}

	@:jsasync public static function sumPromises(a : Promise<Int>, b : Promise<Int> ) {
		return a.jsawait() + b.jsawait();
	}

	@:jsasync @:native("has-qouted-name") public static function quotedFunctionName() {
		return delayNumber(10, 10).jsawait() + 10;
	}
}

class AsyncMethods {
	var val = 0;
	public function new() {
	}

	public function getVal() return val;

	@:jsasync public function addIntPromise(num : Promise<Int>) {
		val += num.jsawait();
		return val;
	}

	@:native("quoted-method") @:jsasync public function quotedMethod() {
		return "Val: " + addIntPromise(StaticAsyncFunctions.delayNumber(50,5)).jsawait();
	}

	@:jsasync public function asyncMethodWithDefaultValueArgument(num : Int = 1) {
		timer(50).jsawait();
		return num + 1;
	}
}