import js.lib.Promise;


class Util {
	public static function timer(msec:Int) {
		return new Promise<jsasync.Nothing>( function(resolve, reject) {
			js.Node.setTimeout(resolve, msec);
		});
	}
}