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
		var localAsyncFunction = JSAsync.func(function() {
			trace("Running local async function");
			timer(1000).await();
			return "Done!";
		});

		trace(localAsyncFunction().await());
		trace(localAsyncFunction().await());

		var a = localAsyncFunction();
		var b = localAsyncFunction();
		trace( a.await() + b.await() );
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
