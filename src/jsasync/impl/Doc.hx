package jsasync.impl;

#if (haxe_ver >= 4.30)
import haxe.macro.Compiler;

final defines : Array<DefineDescription> = [
	{
		define: "jsasync-no-markers",
		doc: "JSAsync will output code without any markers and won't require modifying the generated js file.",
		platforms: [Js]
	},
	{
		define: "jsasync-no-fix-pass",
		doc: "JSAsync will not run the final-file fixing post process even if markers were generated. The output will be invalid js, use this if you wish to inspect how the code looks before the fix pass.",
		platforms: [Js]
	}
];

final metadatas : Array<MetadataDescription> = [
	{
		"metadata": ":jsasync",
		"doc": "Converts a method into an asynchronous function.",
		"targets": [ClassField],
		"platforms": [Js]
	}
];
#end