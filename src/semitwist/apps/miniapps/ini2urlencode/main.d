// SemiTwist D Tools
// ini2urlencode: INI To URL Encode
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This is very basic:
- Every line that doesn't have an equals sign is ignored.
- If a value if surrounded by double-quotes, the double-quotes are trimmed.
- Double-quotes can be used inside a double-quoted value without being escaped.
  (And no escape sequences are recognized anyway.)
- If a value consists of nothing but one double-quote, the double-quote is
  not trimmed.
- Whitespace that's not inside a name or a value is trimmed.
- There is no way to embed a newline in the name or value.

This has been tested to work with DMD 2.052 and 2.053
+/

module semitwist.apps.miniapps.ini2urlencode.main;

import semitwist.cmd.all;

enum appVerStr = "0.03.1";
Ver appVer;
static this()
{
	appVer = appVerStr.toVer();
}

void main(string[] args)
{
	if(args.length != 2)
	{
		cmd.echo("INI To URL Encode (ini2urlencode) v"~appVerStr);
		cmd.echo("Copyright (c) 2010 Nick Sabalausky");
		cmd.echo("See LICENSE.txt for license info");
		cmd.echo("Site: http://www.dsource.org/projects/semitwist");
		cmd.echo();
		cmd.echo("Sample Usages:");
		cmd.echo("  ini2urlencode input.ini");
		cmd.echo("  ini2urlencode input.ini > output.txt");
		cmd.echo();
		cmd.echo("See src/semitwist/apps/miniapps/ini2urlencode/main.d for extra information.");
		return;
	}
	
	string iniData = cast(string)read(args[1]);
	auto iniLines = iniData.split("\n");
	bool needAmp = false;
	foreach(string line; iniLines)
	{
		line = line.strip();
		if(line == "")
			continue;
		
		auto indexEq = line.locate('=');
		if(indexEq == line.length)
			continue;
			
		auto name = line[ 0         .. indexEq ].strip();
		auto val  = line[ indexEq+1 .. $       ].strip();
		if(val.length > 1 && val[0] == '"' && val[$-1] == '"')
			val = val[1..$-1];
		
		if(needAmp)
			write("&");
		else
			needAmp = true;
		
		outputEncoded(name);
		write("=");
		outputEncoded(val);
	}
}

void outputEncoded(string str)
{
	foreach(char c; str)
	{
		if( (c >= 'a' && c <= 'z') ||
			(c >= 'A' && c <= 'Z') ||
			(c >= '0' && c <= '9') ||
			!"-_.~".find(c).empty )
		{
			write(c);
		}
		else
		{
			write("%");
			writef("%.2X", c);
		}
	}
}
