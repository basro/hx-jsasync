package;

import jsasync.JSAsync;
import js.lib.Promise;
import js.Browser;

using jsasync.JSAsyncTools;

class Main implements JSAsync {
	public static function main() {
		asyncMethod();
	}

	static function timer(msec:Int) {
		return new Promise( function(resolve, reject) {
			Browser.window.setTimeout(resolve, msec);
		});
	}

	@:js.async static function asyncMethod() {
		trace("hello");
		timer(1000).await();
		trace("world");
		timer(1000).await();
		trace("fetching url");
		var text = fetchText("http://someurl").await();
		return "(" + text + ")";
	}

	@:js.async static function fetchText(url : String) {
		return Browser.window.fetch(url).await().text().await();
	}
}

