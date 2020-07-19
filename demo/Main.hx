package demo;

import haxe.Json;
import js.lib.Promise;
import js.Browser;

#if(haxe >= "4.2")
@:jsasync function moduleLevelFunction() {
	Main.timer(1000).jsawait();
	trace("tick");
	Main.timer(1000).jsawait();
	trace("tock");
}
#end

class Main {
	public static function main() {
		mainAsync();
		#if ( haxe >= "4.2" )
		moduleLevelFunction();
		#end
	}

	@:jsasync public static function mainAsync() {
		count(10).jsawait();

		var things = Promise.all([
			fetchURLAsText("https://twitter.github.io/"),
			fetchURLAsText("https://twitter.github.io/projects"),
			fetchURLAsText("https://thisurlwillsurelyfail.com/")
		]).jsawait();

		trace( things.map(text -> text.length) );

		var localAsyncFunction = jsasync(function(name:String) {
			trace("Running local async function " + name);
			timer(1000).jsawait();
			return name + " done!";
		});

		trace(localAsyncFunction("A").jsawait());
		trace(localAsyncFunction("B").jsawait());

		var randomWait = jsasync(function() {
			if ( Math.random() > 0.5 ) {
				return;
			}
			timer(1000).jsawait();
		});

		randomWait().jsawait();

		var a = localAsyncFunction("C");
		var b = localAsyncFunction("D");
		trace( a.jsawait() + " " + b.jsawait() );
	}

	@:jsasync static function count(numbers:Int) {
		trace('Counting up to $numbers');
		for ( i in 0...10 ) {
			trace(i);
			timer(1000).jsawait();
		}
	}

	public static function timer(msec:Int) {
		return new Promise<jsasync.Nothing>( function(resolve, reject) {
			Browser.window.setTimeout(resolve, msec);
		});
	}

	@:jsasync static function fetchURLAsText(url:String) {
		try {
			trace('Fetching $url');
			var text = Browser.window.fetch(url).jsawait().text().jsawait();
			trace('Fetched $url');
			return text;
		} catch(e : Any) {
			trace('Failed to fetch $url');
		}
		return "";
	}

	@:jsasync static function fetchJSon(url : String) : Promise<Dynamic> {
		var text = Browser.window.fetch(url).jsawait().text().jsawait();
		return Json.parse(text);
	}
}

