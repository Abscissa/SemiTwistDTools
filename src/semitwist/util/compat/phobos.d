// SemiTwist Library
// Written in the D programming language.

/++
This module does NOT and is NOT intended to make SemiTwist D Tools
compatible with Phobos (Sorry!). It is merely to aid in migration.

SemiTwist D Tools does plan to switch from D1 to D2.

All code in this "semitwist.util.compat" package should avoid accessing any
other part of SemiTwist D Tools, because doing so might trigger DMD's
forward reference bugs.
+/

module semitwist.util.compat.phobos;

import semitwist.util.compat.d2;

version(Tango) {}
else
{
	import std.format;
	import std.regexp;
	import std.stdio;
	import std.utf;
	import cstdio = std.c.stdio;
	
	version = Phobos;
	
	FormatOutput!(char) Stdout;
	FormatOutput!(char) Stderr;
	static this()
	{
		Stdout = new FormatOutput!(char)();
		Stderr = new FormatOutput!(char)();
	}

	class FormatOutput(T)
	{
		alias print opCall;
		
		this()
		{
			layout = new Layout!(T)();
		}
		
		typeof(this) newline()
		{
			writefln();
			return this;
		}
		
		typeof(this) flush()
		{
			cstdio.fflush(cstdio.stdout);
			return this;
		}
		
		typeof(this) format(T[] formatStr, ...)
		{
			display(formatStr, _arguments, _argptr);
			return this;
		}
		
		typeof(this) formatln(T[] formatStr, ...)
		{
			display(formatStr, _arguments, _argptr);
			newline();
			return this;
		}
		
/+		typeof(this) print(...)
		{
			//TODO: Implement this
			return this;
		}
+/
		private Layout!(T) layout;
		private void display(T[] formatStr, TypeInfo[] ti, void* args)
		{
			try
			{
				auto str = layout(formatStr, ti, args);
				writef("%s", str);
			}
			catch(StdioException e)
			{
				throw new IOException(e.msg);
			}
		}
	}
	
	string toPhobosFormat(string str)
	{
		string convertSequence(RegExp m)
		{
			auto str = m.match(1);
			if(str != "")
				throw new Exception("Format style '"~m.match(0)~"' not supported.");
			return "%s";
		}
		str.sub(`\{([^\}]*)\}`, &convertSequence, "g");
		return str;
	}
	
	class Layout(T)
	{
		alias convert opCall;
		public alias uint delegate(T[]) Sink;
		
		public T[] convert(...)
		{
			return convert(_arguments, _argptr);
		}

		public uint convert(Sink sink, ...)
		{
			return convert(sink, _arguments, _argptr);
		}

		public T[] convert(TypeInfo[] ti, void* args)
		{
			T[] output;

			uint sink(T[] s)
			{
				output ~= s;
				return s.length;
			}

			convert(&sink, ti, args);
			return output;
		}

		public uint convert(Sink sink, TypeInfo[] ti, void* args)
		{
			if(ti[0] != typeid(T[]))
				throw new Exception("First varadic arg must be a '"~T.stringof~"[]', not '"~ti[0].toString()~"'");
				
			T[]* formatStrPtr = cast(T[]*)args;
			*formatStrPtr = toPhobosFormat(*formatStrPtr);
			
			dstring buffer;
			void putc(dchar c)
			{
				buffer ~= c;
			}
			doFormat(&putc, ti, args);

			uint length;
			static if(is(T==char))
				length = sink(toUTF8(buffer));
			else static if(is(T==wchar))
				length = sink(toUTF16(buffer));
			else static if(is(T==dchar))
				length = sink(buffer);
			else
				static assert("Layout!(T): 'T' must be 'char', 'wchar' or 'dchar', not '"~T.stringof~"'");
				
			return length;
		}
	}

	class PlatformException : Exception
	{
		this(string msg) { super(msg); }
	}
	class IOException : PlatformException
	{
		this(string msg)  { super(msg); }
	}
}
