package demo;

import haxe.Json;
import jsasync.IJSAsync;
import jsasync.JSAsync;
import js.lib.Promise;
import js.Browser;

using jsasync.JSAsyncTools;

class Main {
	@:jsasync public static function main() {
		count(10).await();

		var things = Promise.all([
			fetchURLAsText("https://twitter.github.io/"),
			fetchURLAsText("https://twitter.github.io/projects"),
			fetchURLAsText("https://thisurlwillsurelyfail.com/")
		]).await();

		trace( things.map(text -> text.length) );

		// Use JSAsync.func macro to create anonymous async functions
		var localAsyncFunction = JSAsync.func(function(name:String) {
			trace("Running local async function " + name);
			timer(1000).await();
			return name + " done!";
		});

		trace(localAsyncFunction("A").await());
		trace(localAsyncFunction("B").await());

		var randomWait = JSAsync.func(function() {
			if ( Math.random() > 0.5 ) {
				return;
			}
			timer(1000).await();
		});

		randomWait().await();

		var a = localAsyncFunction("C");
		var b = localAsyncFunction("D");
		trace( a.await() + " " + b.await() );
	}

	@:jsasync static function count(numbers:Int) {
		trace('Counting up to $numbers');
		for ( i in 0...10 ) {
			trace(i);
			timer(1000).await();
		}
	}

	static function timer(msec:Int) {
		return new Promise( function(resolve, reject) {
			Browser.window.setTimeout(resolve, msec);
		});
	}

	@:jsasync static function fetchURLAsText(url:String) {
		try {
			trace('Fetching $url');
			var text = Browser.window.fetch(url).await().text();
			trace('Fetched $url');
			return text;
		} catch(e : Any) {
			trace('Failed to fetch $url');
		}
		return "";
	}

	@:jsasync static function fetchJSon(url : String) {
		var text = Browser.window.fetch(url).await().text().await();
		return Json.parse(text);
	}
}

