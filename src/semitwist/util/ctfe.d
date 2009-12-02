// SemiTwist Library
// Written in the D programming language.

module semitwist.util.ctfe;

import tango.core.Version;
import tango.io.Stdout;

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

/// tango.text.Util.locate() and tango.core.Array.find() don't work at compile-time.
size_t ctfe_find(T)(T[] collection, T elem, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(collection[i] == elem)
			return i;
	}
	return collection.length;
}

//TODO: Test on wchar/dchar
T[] ctfe_join(T)(T[][] strs, T[] delim)
{
	T[] value = "";
	
	foreach(T[] str; strs)
		value ~= (value.length==0?"":delim) ~ str;
	
	return value;
}

T[] ctfe_substitute(T)(T[] str, T[] match, T[] replace)
{
	T[] value = "";
	
	if(str.length < match.length)
		return str.dup;
	
	int i;
	for(i=0; i<=str.length-match.length; i++)
	{
		if(str[i..i+match.length] == match)
		{
			value ~= replace;
			i += match.length-1;
		}
		else
			value ~= str[i];
	}
	value ~= str[i..$];
	return value;
}

/// ctfe_subMapJoin("Hi WHO. ", "WHO", ["Joey"[], "Q", "Sue"])
/// --> "Hi Joey. Hi Q. Hi Sue. "
T[] ctfe_subMapJoin(T)(T[] str, T[] match, T[][] replacements)
{
	T[] value = "";
	foreach(T[] replace; replacements)
		value ~= ctfe_substitute(str, match, replace);

	return value;
}

unittest
{
	// ctfe_pad ---------------------------
	
	const char[] ctfe_pad_test_1 = ctfe_pad("Hi", 5);
	mixin(deferEnsure!(`ctfe_pad_test_1`, `_ == "   Hi"`));

	const char[] ctfe_pad_test_2 = ctfe_pad("Hi", 5, "-");
	mixin(deferEnsure!(`ctfe_pad_test_2`, `_ == "---Hi"`));

	const char[] ctfe_pad_test_3 = ctfe_pad("Hi", 1, "-");
	mixin(deferEnsure!(`ctfe_pad_test_3`, `_ == "Hi"`));

	const char[] ctfe_pad_test_4 = ctfe_pad("Hi", 4, false);
	mixin(deferEnsure!(`ctfe_pad_test_4`, `_ == "Hi  "`));

	const char[] ctfe_pad_test_5 = ctfe_pad("Hi", 1, false);
	mixin(deferEnsure!(`ctfe_pad_test_5`, `_ == "Hi"`));

	const char[] ctfe_pad_test_6 = ctfe_pad("Hi", 5, false, "+");
	mixin(deferEnsure!(`ctfe_pad_test_6`, `_ == "Hi+++"`));

	const wchar[] ctfe_pad_test_7 = ctfe_pad("Hi"w, 5);
	mixin(deferEnsure!(`ctfe_pad_test_7`, `_ == "   Hi"w`));

	const dchar[] ctfe_pad_test_8 = ctfe_pad("Hi"d, 5);
	mixin(deferEnsure!(`ctfe_pad_test_8`, `_ == "   Hi"d`));

/+
	// Fails right now
	const char[] ctfe_pad_test_9 = ctfe_pad("日本語", 5, "五");
	mixin(deferEnsure!(`ctfe_pad_test_9`, `_ == "五五日本語"`));
+/

	// ctfe_repeat ---------------------------
	
	const char[] ctfe_repeat_test_aneg1 = ctfe_repeat("a", -1);
	mixin(deferEnsure!(`ctfe_repeat_test_aneg1`, `_ == ""`));

	const char[] ctfe_repeat_test_a2 = ctfe_repeat("a", 2);
	mixin(deferEnsure!(`ctfe_repeat_test_a2`, `_ == "aa"`));

	const char[] ctfe_repeat_test_Ab5 = ctfe_repeat("Ab", 5);
	mixin(deferEnsure!(`ctfe_repeat_test_Ab5`, `_ == "AbAbAbAbAb"`));

	const char[] ctfe_repeat_test_Ab0 = ctfe_repeat("Ab", 0);
	mixin(deferEnsure!(`ctfe_repeat_test_Ab0`, `_ == ""`));

	const wchar[] ctfe_repeat_test_a4w = ctfe_repeat("a"w, 4);
	mixin(deferEnsure!(`ctfe_repeat_test_a4w`, `_ == "aaaa"w`));

	const dchar[] ctfe_repeat_test_a4d = ctfe_repeat("a"d, 4);
	mixin(deferEnsure!(`ctfe_repeat_test_a4d`, `_ == "aaaa"d`));

	const char[] ctfe_repeat_test_日本語3 = ctfe_repeat("日本語", 3);
	mixin(deferEnsure!(`ctfe_repeat_test_日本語3`, `_ == "日本語日本語日本語"`));
	
	// ctfe_subMapJoin ---------------------------
	
	const char[] ctfe_subMapJoin_test_c = ctfe_subMapJoin("Hi WHO. ", "WHO", ["Joey"[], "Q", "Sue"]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_c`, `_ == "Hi Joey. Hi Q. Hi Sue. "`));
	
	const wchar[] ctfe_subMapJoin_test_w = ctfe_subMapJoin("Hi WHO. "w, "WHO"w, ["Joey"w[], "Q"w, "Sue"w]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_w`, `_ == "Hi Joey. Hi Q. Hi Sue. "w`));
	
	const dchar[] ctfe_subMapJoin_test_d = ctfe_subMapJoin("Hi WHO. "d, "WHO"d, ["Joey"d[], "Q"d, "Sue"d]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_d`, `_ == "Hi Joey. Hi Q. Hi Sue. "d`));

	const char[] ctfe_subMapJoin_test_cj = ctfe_subMapJoin("こんにちわ、 だれさん。 ", "だれ", ["わたなべ"[], "ニク", "あおい"]);
	mixin(deferEnsure!(`ctfe_subMapJoin_test_cj`, `_ == "こんにちわ、 わたなべさん。 こんにちわ、 ニクさん。 こんにちわ、 あおいさん。 "`));
}

static if(Tango.Major == 0 && Tango.Minor <= 998)
{
	/// These ctfe_i2a functions are included here directly from a trunk version
	/// of Tango because they are required by SemiTwist D Tools, but do not
	/// exist in the latest official Tango release (0.99.8).
	
	/// compile time integer to string
	char [] ctfe_i2a(int i){
		char[] digit="0123456789";
		char[] res="";
		if (i==0){
			return "0";
		}
		bool neg=false;
		if (i<0){
			neg=true;
			i=-i;
		}
		while (i>0) {
			res=digit[i%10]~res;
			i/=10;
		}
		if (neg)
			return '-'~res;
		else
			return res;
	}
	/// ditto
	char [] ctfe_i2a(long i){
		char[] digit="0123456789";
		char[] res="";
		if (i==0){
			return "0";
		}
		bool neg=false;
		if (i<0){
			neg=true;
			i=-i;
		}
		while (i>0) {
			res=digit[cast(size_t)(i%10)]~res;
			i/=10;
		}
		if (neg)
			return '-'~res;
		else
			return res;
	}
	/// ditto
	char [] ctfe_i2a(uint i){
		char[] digit="0123456789";
		char[] res="";
		if (i==0){
			return "0";
		}
		bool neg=false;
		while (i>0) {
			res=digit[i%10]~res;
			i/=10;
		}
		return res;
	}
	/// ditto
	char [] ctfe_i2a(ulong i){
		char[] digit="0123456789";
		char[] res="";
		if (i==0){
			return "0";
		}
		bool neg=false;
		while (i>0) {
			res=digit[cast(size_t)(i%10)]~res;
			i/=10;
		}
		return res;
	}
}