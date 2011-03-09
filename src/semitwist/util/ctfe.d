// SemiTwist Library
// Written in the D programming language.

module semitwist.util.ctfe;

import std.array;
import std.stdio;
import std.string;
import std.traits;

import semitwist.util.all;

T[] ctfe_pad(T)(T[] str, int length, T[] padChar=" ")
{
	return ctfe_pad(str, length, true, padChar);
}
T[] ctfe_pad(T)(T[] str, int length, bool padLeft, T[] padChar=" ")
{
	if(str.length < length)
	{
		auto padding = ctfe_repeat!(T)(padChar, length - str.length);
		
		if(padLeft)
			str = padding ~ str;
		else
			str = str ~ padding;
	}
	
	return str;
}

/*T[] ctfe_repeat(T)(T chr, int count)
{
	return ctfe_repeat("" ~ chr, count);
}*/
T[] ctfe_repeat(T)(T[] str, int count)
{
	T[] ret = "";
	
	for(int i=0; i < count; i++)
		ret ~= str;
		
	return ret;
}

//size_t ctfe_find(T, TElem)(T collection, TElem elem, size_t start=0) if(isSomeString!T && is(unqual!T:TElem[]))
size_t ctfe_find(T)(const(T)[] collection, const(T) elem, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(collection[i] == elem)
			return i;
	}
	return collection.length;
}

size_t ctfe_find(T)(const(T)[] haystack, const(T)[] needle, size_t start=0) //if(isSomeString!T)
{
	if(haystack.length < needle.length)
		return haystack.length;

	for(size_t i=start; i <= haystack.length-needle.length; i++)
	{
		if(haystack[i..i+needle.length] == needle)
			return i;
	}
	return haystack.length;
}

T ctfe_join(T)(T[] strs, T delim) if(isSomeString!T)
{
	T value = "";
	
	foreach(i, str; strs)
		value ~= (i==0?"":delim) ~ str;
	
	return value;
}

T ctfe_substitute(T)(T str, T match, T replace) if(isSomeString!T)
{
	T value = "";
	
	static if(is(T == string))
		alias immutable(ubyte)[] BaseType;
	else static if(is(T == wstring))
		alias immutable(ushort)[] BaseType;
	else static if(is(T == dstring))
		alias immutable(uint)[] BaseType;
	else
		static void BaseType;
	
	if(str.length < match.length)
		return str;
	
	while(str.length >= match.length)
	{
		if(str[0..match.length] == match)
		{
			value ~= replace;
			str = str[match.length .. $];
		}
		else
		{
			// Can't do "value ~= str[0];" because of DMD Issue #5722
			static if(is(BaseType == void))
				cast(BaseType)value ~= (cast(BaseType)str)[0];
			else
				value ~= [ str[0] ];

			str = str[1 .. $];
		}
	}
	value ~= str;
	return value;
}

T[] ctfe_split(T)(T str, T delim) if(isSomeString!T)
{
	T[] arr;
	auto currStr = str;
	int index;
	while((index=ctfe_find(currStr, delim)) < currStr.length)
	{
		arr ~= currStr[0..index];
		currStr = currStr[index+delim.length..$];
	}
	arr ~= currStr;
	return arr;
}


/// ctfe_subMapJoin("Hi WHO. ", "WHO", ["Joey", "Q", "Sue"])
/// --> "Hi Joey. Hi Q. Hi Sue. "
T ctfe_subMapJoin(T)(T str, T match, T[] replacements) if(isSomeString!T)
{
	T value = "";
	foreach(T replace; replacements)
		value ~= ctfe_substitute(str, match, replace);

	return value;
}

bool ctfe_iswhite(dchar ch)
{
	foreach(i; 0..whitespace.length)
	if(ch == whitespace[i])
		return true;

	return false;
}


mixin(unittestSemiTwistDLib(q{

	// ctfe_find ---------------------------
	mixin(deferEnsure!(q{ ctfe_find("abcde", 'd' ) }, q{ _==3 }));
	mixin(deferEnsure!(q{ ctfe_find("abcde", 'X' ) }, q{ _==5 }));
	mixin(deferEnsure!(q{ ctfe_find("abcde", "d" ) }, q{ _==3 }));
	mixin(deferEnsure!(q{ ctfe_find("abcde", "cd") }, q{ _==2 }));
	mixin(deferEnsure!(q{ ctfe_find("abcde", "cX") }, q{ _==5 }));

	mixin(deferEnsure!(q{ ctfe_find("cdbcde", 'd' , 2) }, q{ _==4 }));
	mixin(deferEnsure!(q{ ctfe_find("cdbcde", "d" , 2) }, q{ _==4 }));
	mixin(deferEnsure!(q{ ctfe_find("cdbcde", "cd", 1) }, q{ _==3 }));
	mixin(deferEnsure!(q{ ctfe_find("cXbcde", "cX", 1) }, q{ _==6 }));

	mixin(deferEnsure!(q{ ctfe_find("abc", 'a')     }, q{ _==0 }));
	mixin(deferEnsure!(q{ ctfe_find("abc", 'c')     }, q{ _==2 }));
	mixin(deferEnsure!(q{ ctfe_find("abc", "a")     }, q{ _==0 }));
	mixin(deferEnsure!(q{ ctfe_find("abc", "c")     }, q{ _==2 }));
	mixin(deferEnsure!(q{ ctfe_find("aabbcc", "aa") }, q{ _==0 }));
	mixin(deferEnsure!(q{ ctfe_find("aabbcc", "cc") }, q{ _==4 }));

	mixin(deferEnsure!(q{ ctfe_find("abc", "abcde") }, q{ _==3 }));
	
	// ctfe_split ---------------------------
	mixin(deferEnsure!(q{ ctfe_split("a--b-b--ccc---d----e--", "--") }, q{ _==["a","b-b","ccc","-d","","e",""] }));
	mixin(deferEnsure!(q{ ctfe_split("-Xa", "-X") }, q{ _==["","a"] }));

	// ctfe_iswhite ---------------------------
	mixin(deferEnsure!(q{ ctfe_iswhite(' ')  }, q{ _==true  }));
	mixin(deferEnsure!(q{ ctfe_iswhite('\t') }, q{ _==true  }));
	mixin(deferEnsure!(q{ ctfe_iswhite('\r') }, q{ _==true  }));
	mixin(deferEnsure!(q{ ctfe_iswhite('\n') }, q{ _==true  }));
	mixin(deferEnsure!(q{ ctfe_iswhite('X')  }, q{ _==false }));
	
	// ctfe_join ---------------------------
	mixin(deferEnsure!(q{ ctfe_join([""," ","","A","","BC","","D"," ",""], "\n") }, q{ _=="\n \n\nA\n\nBC\n\nD\n \n" }));
	//mixin(traceVal!(q{ "\n"~ctfe_join([""," ","","A","","BC","","D"," ",""], "\n").escapeDDQS() }));

	// ctfe_substitute ---------------------------
	enum ctfe_substitute_test_1 = ctfe_substitute("hello", "X", "R");
	mixin(deferEnsure!(q{ ctfe_substitute_test_1 }, q{ _=="hello" }));
	
	enum ctfe_substitute_test_2 = ctfe_substitute("hello", "e", "e");
	mixin(deferEnsure!(q{ ctfe_substitute_test_2 }, q{ _=="hello" }));

	enum ctfe_substitute_test_3 = ctfe_substitute("hello", "e", "X");
	mixin(deferEnsure!(q{ ctfe_substitute_test_3 }, q{ _=="hXllo" }));
	
	enum ctfe_substitute_test_4 = ctfe_substitute("日本語", "X", "R");
	mixin(deferEnsure!(q{ ctfe_substitute_test_4 }, q{ _=="日本語" }));
	
	enum ctfe_substitute_test_5 = ctfe_substitute("こんにちわ", "X", "R");
	mixin(deferEnsure!(q{ ctfe_substitute_test_5 }, q{ _=="こんにちわ" }));
	
	enum ctfe_substitute_test_6 = ctfe_substitute("こんにちわ", "にち", "ばん");
	mixin(deferEnsure!(q{ ctfe_substitute_test_6 }, q{ _=="こんばんわ" }));
	
	enum wstring ctfe_substitute_test_7 = ctfe_substitute("こんにちわ"w, "にち"w, "ばん"w);
	mixin(deferEnsure!(q{ ctfe_substitute_test_7 }, q{ _=="こんばんわ"w }));
	
	enum dstring ctfe_substitute_test_8 = ctfe_substitute("こんにちわ"d, "にち"d, "ばん"d);
	mixin(deferEnsure!(q{ ctfe_substitute_test_8 }, q{ _=="こんばんわ"d }));
	
	
	// ctfe_pad ---------------------------
	enum ctfe_pad_test_1 = ctfe_pad("Hi", 5);
	mixin(deferEnsure!(`ctfe_pad_test_1`, `_ == "   Hi"`));

	enum ctfe_pad_test_2 = ctfe_pad("Hi", 5, "-");
	mixin(deferEnsure!(`ctfe_pad_test_2`, `_ == "---Hi"`));

	enum ctfe_pad_test_3 = ctfe_pad("Hi", 1, "-");
	mixin(deferEnsure!(`ctfe_pad_test_3`, `_ == "Hi"`));

	enum ctfe_pad_test_4 = ctfe_pad("Hi", 4, false);
	mixin(deferEnsure!(`ctfe_pad_test_4`, `_ == "Hi  "`));

	enum ctfe_pad_test_5 = ctfe_pad("Hi", 1, false);
	mixin(deferEnsure!(`ctfe_pad_test_5`, `_ == "Hi"`));

	enum ctfe_pad_test_6 = ctfe_pad("Hi", 5, false, "+");
	mixin(deferEnsure!(`ctfe_pad_test_6`, `_ == "Hi+++"`));

	enum wstring ctfe_pad_test_7 = ctfe_pad("Hi"w, 5);
	mixin(deferEnsure!(`ctfe_pad_test_7`, `_ == "   Hi"w`));

	enum dstring ctfe_pad_test_8 = ctfe_pad("Hi"d, 5);
	mixin(deferEnsure!(`ctfe_pad_test_8`, `_ == "   Hi"d`));

/+
	// Fails right now
	enum ctfe_pad_test_9 = ctfe_pad("日本語", 5, "五");
	mixin(deferEnsure!(`ctfe_pad_test_9`, `_ == "五五日本語"`));
+/

	// ctfe_repeat ---------------------------
	enum ctfe_repeat_test_aneg1 = ctfe_repeat("a", -1);
	mixin(deferEnsure!(`ctfe_repeat_test_aneg1`, `_ == ""`));

	enum ctfe_repeat_test_a2 = ctfe_repeat("a", 2);
	mixin(deferEnsure!(`ctfe_repeat_test_a2`, `_ == "aa"`));

	enum ctfe_repeat_test_Ab5 = ctfe_repeat("Ab", 5);
	mixin(deferEnsure!(`ctfe_repeat_test_Ab5`, `_ == "AbAbAbAbAb"`));

	enum ctfe_repeat_test_Ab0 = ctfe_repeat("Ab", 0);
	mixin(deferEnsure!(`ctfe_repeat_test_Ab0`, `_ == ""`));

	enum wstring ctfe_repeat_test_a4w = ctfe_repeat("a"w, 4);
	mixin(deferEnsure!(`ctfe_repeat_test_a4w`, `_ == "aaaa"w`));

	enum dstring ctfe_repeat_test_a4d = ctfe_repeat("a"d, 4);
	mixin(deferEnsure!(`ctfe_repeat_test_a4d`, `_ == "aaaa"d`));

	enum ctfe_repeat_test_日本語3 = ctfe_repeat("日本語", 3);
	mixin(deferEnsure!(`ctfe_repeat_test_日本語3`, `_ == "日本語日本語日本語"`));
	
	// ctfe_subMapJoin ---------------------------
	enum ctfe_subMapJoin_test_c = ctfe_subMapJoin("Hi WHO. ", "WHO", ["Joey"[], "Q", "Sue"]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_c`, `_ == "Hi Joey. Hi Q. Hi Sue. "`));
	
	enum wstring ctfe_subMapJoin_test_w = ctfe_subMapJoin("Hi WHO. "w, "WHO"w, ["Joey"w[], "Q"w, "Sue"w]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_w`, `_ == "Hi Joey. Hi Q. Hi Sue. "w`));
	
	enum dstring ctfe_subMapJoin_test_d = ctfe_subMapJoin("Hi WHO. "d, "WHO"d, ["Joey"d[], "Q"d, "Sue"d]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_d`, `_ == "Hi Joey. Hi Q. Hi Sue. "d`));

	enum ctfe_subMapJoin_test_cj = ctfe_subMapJoin("こんにちわ、 だれさん。 ", "だれ", ["わたなべ"[], "ニク", "あおい"]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_cj`, `_ == "こんにちわ、 わたなべさん。 こんにちわ、 ニクさん。 こんにちわ、 あおいさん。 "`));
}));
