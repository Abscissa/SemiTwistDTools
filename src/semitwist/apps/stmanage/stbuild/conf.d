// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

module semitwist.apps.stmanage.stbuild.conf;

import std.conv;
import std.string;
import std.file;

import semitwist.cmd.all;

enum BuildTool
{
	rdmd,
	rebuild,
	xfbuild,
}

string buildToolExecName(BuildTool tool)
{
	switch(tool)
	{
	case BuildTool.rdmd:
		return "rdmd";
	case BuildTool.rebuild:
		return "rebuild";
	case BuildTool.xfbuild:
		return "xfbuild";
	default:
		throw new Exception("Internal Error: Unexpected Build Tool #%s".format(tool));
	}
}

class STBuildConfException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}

string quoteArg(string str)
{
	version(Windows)
		return '"' ~ str ~ '"';
	else
		return '\'' ~ str ~ '\'';
}

class Conf
{
	string[] targets;
	private Switch[][string][string] flags;
	
	string[] errors;

	enum string targetAll   = "all";
	enum string modeRelease = "release";
	enum string modeDebug   = "debug";
	enum string modeAll     = "all";
	enum string[] predefTargets = [targetAll];
	enum string[] modes = [modeRelease, modeDebug, modeAll];

	// GDC workaround
	string[] getPredefTargets()
	{
		return predefTargets;
	}

	// GDC workaround
	string[] getModes()
	{
		return modes;
	}

	string[] targetAllElems;
	string[] modeAllElems;

	this(string filename)
	{
		auto parser = new ConfParser();
		parser.doParse(this, filename);
		
		if(parser.errors.length > 0)
		{
			foreach(string error; parser.errors)
				cmd.echo(error);
				
			throw new STBuildConfException(
				"%s error(s) in conf file '%s'"
					.format(parser.errors.length, filename)
			);
		}

		version(GNU)
		{
			foreach(e; std.algorithm.filter!((a) {return a != targetAll; } )(targets))
				targetAllElems ~= e;
			foreach(e; std.algorithm.filter!((a) {return a != modeAll; } )(modes))
				modeAllElems ~= e;
		}
		else
		{
			targetAllElems = array(std.algorithm.filter!(
				(a) { return a != targetAll; })(targets)
			);//targets.allExcept(targetAll);
			modeAllElems   = array(std.algorithm.filter!(
				(a) { return a != modeAll; })(modes)
			);//modes.allExcept(modeAll);
		}
	}
	
	private Switch[] getFlagsSafe(string target, string mode)
	{
		if(target in flags && mode in flags[target])
		{
			Switch[] ret = flags[target][mode].dup;
			//foreach(int i, Switch sw; ret)
			//	ret[i].data = ret[i].data.dup;

			return ret;
		}
			
		return [];
	}
	
	private static int convertSwitch(ref Switch[] switches, string fromStr, string toStr)
	{
		int numConverted = 0;
		foreach(ref Switch sw; switches)
		{
			if(sw.data == fromStr)
			{
				sw.data = toStr;
				numConverted++;
			}
		}
		return numConverted;
	}
	
	private static int convertPrefix(ref Switch[] switches, string fromPrefix, string toPrefix)
	{
		int numConverted = 0;
		foreach(ref Switch sw; switches)
		{
			if(sw.data.length >= fromPrefix.length)
			if(sw.data[0..fromPrefix.length] == fromPrefix)
			{
				sw.data = toPrefix~sw.data[fromPrefix.length..$];
				numConverted++;
			}
		}
		return numConverted;
	}
	
	private static int removePrefix(ref Switch[] switches, string prefix)
	{
		int[] switchIndicies = [];
		foreach(int index, Switch sw; switches)
		{
			if(sw.data.length >= prefix.length)
			if(sw.data[0..prefix.length] == prefix)
				switchIndicies ~= index;
		}
		if(switchIndicies.length > 0)
		{
			foreach_reverse(int index; switchIndicies)
				switches = switches[0..index] ~ switches[index+1..$];
		}
		return switchIndicies.length;
	}

	private static int combinePrefix(ref Switch[] switches, string fromPrefix, string fromSwitch, string toPrefix)
	{
		auto numRemoved = removePrefix(switches, fromSwitch);
		if(numRemoved > 0)
			return convertPrefix(switches, fromPrefix, toPrefix);
		return 0;
	}
	
	private static int splitPrefix(ref Switch[] switches, string fromPrefix, string toPrefix, string toSwitch)
	{
		auto numConverted = convertPrefix(switches, fromPrefix, toPrefix);
		if(numConverted > 0)
			switches ~= Switch(toSwitch, false);
		return numConverted;
	}
	
	private static void moveSourceFileToEnd(ref Switch[] switches)
	{
		int sourceIndex = switches.length;
		
		foreach(int i, Switch sw; switches)
		if( !sw.data.startsWith("-") && !sw.data.startsWith("+") )
		{
			sourceIndex = i;
			break;
		}
		
		if(sourceIndex < switches.length-1)
		{
			switches =
				switches[0..sourceIndex] ~
				switches[sourceIndex+1..$] ~
				switches[sourceIndex];
		}
	}

	private static void convert(ref Switch[] switches, BuildTool tool)
	{
		switch(tool)
		{
		case BuildTool.rdmd:
			convertPrefix(switches, "-oq", "-od");
			convertPrefix(switches, "+o", "-of");
			convertPrefix(switches, "+O", "-od");
			convertPrefix(switches, "-C",  ""  );
			convertSwitch(switches, "-v", "--chatty");
			convertSwitch(switches, "+v", "--chatty");
			convertPrefix(switches, "+nolink", "-c");
			removePrefix(switches, "+");
			
			// Source file must come last
			moveSourceFileToEnd(switches);
			
			break;

		case BuildTool.rebuild:
			combinePrefix(switches, "+O", "+q", "-oq");
			convertPrefix(switches, "+o", "-of");
			convertPrefix(switches, "+O", "-od");
			convertPrefix(switches, "--chatty", "-v");
			convertPrefix(switches, "+nolink", "-c");
			removePrefix(switches, "+");
			removePrefix(switches, "--");
			break;
			
		case BuildTool.xfbuild:
			//switches.splitPrefix("-oq", "+O", "+q"); //Doesn't work for DMD
			convertPrefix(switches, "-oq", "+O");
			
			convertPrefix(switches, "-C",  ""  );
			convertPrefix(switches, "-of", "+o");
			convertPrefix(switches, "-od", "+O");
			convertPrefix(switches, "--chatty", "+v");
			convertPrefix(switches, "-c", "+nolink");
			removePrefix(switches, "--");
			break;
			
		default:
			throw new Exception("Internal Error: Unexpected Build Tool #%s".format(tool));
		}
	}
	
	private static string switchesToString(Switch[] switches)
	{
		return
			std.string.join(
				switches.map( (Switch sw) { return sw.toString(); } ),
				" "
			);
	}
	
	unittest
	{
		Switch[] switches;
		auto start  = `+foo "-od od" -foo +q +q +o_o -of_of -C_C -oq_oq +O_O +foo`;
		auto re     = `"-od od" -foo -of_o -of_of -C_C -oq_oq -oq_O`;
		//auto xf     = `+foo "+O od" -foo +q +q +o_o +o_of _C +O_oq +O_O +foo +q`; // See "Doesn't work for DMD" above
		auto xf     = `+foo "+O od" -foo +q +q +o_o +o_of _C +O_oq +O_O +foo`;
		auto start2 = `+foo -od_od -foo +o_o -of_of -C_C -oq_oq +O_O +foo`;
		auto re2    = `-od_od -foo -of_o -of_of -C_C -oq_oq -od_O`;
		
		version(Posix)
		{
			re = re.replace(`"`, `'`);
			xf = xf.replace(`"`, `'`);
		}
		
		switches = ConfParser.splitSwitches(start);
		convert(switches, BuildTool.rebuild);
		mixin(deferEnsure!(`switchesToString(switches)`, `_ == re`));
		
		switches = ConfParser.splitSwitches(start);
		convert(switches, BuildTool.xfbuild);
		mixin(deferEnsure!(`switchesToString(switches)`, `_ == xf`));
		
		switches = ConfParser.splitSwitches(start2);
		convert(switches, BuildTool.rebuild);
		mixin(deferEnsure!(`switchesToString(switches)`, `_ == re2`));
	}
	
	private static bool addDefault(ref Switch[] switches, string prefix, string defaultVal)
	{
		bool prefixFound=false;
		foreach(Switch sw; switches)
		if(sw.data.startsWith(prefix))
		{
			prefixFound = true;
			break;
		}
		if(!prefixFound)
			switches ~= Switch(prefix~defaultVal, false);
		return !prefixFound;
	}
	
	private static void addDefaults(ref Switch[] switches)
	{
		// Keep object and deps files from each target/mode
		// separate so things don't get screwed up.
		addDefault(switches, "-oq", "obj/$(TARGET)/$(MODE)/");
		addDefault(switches, "+D", "obj/$(TARGET)/$(MODE)/deps");
		addDefault(switches, "--build-only", "");
	}
	
	private static string fixSlashes(string str)
	{
		version(Windows)
			return std.array.replace(str, "/", "\\");
		else
			return std.array.replace(str, "\\", "/");
		//return str;
	}
	
	string getFlags(string target, string mode, BuildTool tool)
	{
		auto isTargetAll = (target == targetAll);
		auto isModeAll   = (mode   == modeAll  );

		Switch[] switches = getFlagsSafe(target, mode);
		if(!isTargetAll)               switches ~= getFlagsSafe(targetAll, mode   );
		if(!isModeAll  )               switches ~= getFlagsSafe(target,    modeAll);
		if(!isTargetAll && !isModeAll) switches ~= getFlagsSafe(targetAll, modeAll);

		addDefaults(switches);
		convert(switches, tool);
		auto flags = fixSlashes(switchesToString(switches));
		//mixin(traceVal!("flags"));
		flags = std.array.replace(flags, "$(TARGET)", target);
		flags = std.array.replace(flags, "$(MODE)",   mode);
		flags = std.array.replace(flags, "$(OS)",     enumOSToString(os));
		flags = std.array.replace(flags, "$()",       "");
		return flags;
/+		return
			//fixSlashes(switchesToString(switches))
			x
				.replace("$(TARGET)", target)
				.replace("$(MODE)",   mode)
				.replace("$(OS)",     enumOSToString(os))
				.replace("$()",       "");
				//.format(target, mode, enumOSToString(os), "");+/
	}
	
	struct Switch
	{
		string data;
		bool quoted;
		string toString()
		{
			return quoted? quoteArg(data) : data;
		}
	}
	
	private class ConfParser
	{
		private Conf conf;
		private string filename;
		
		private uint stmtLineNo;
		private string partialStmt=null;
		
		string[] currTargets;
		string[] currModes;
		
		string[] targets=null;
		string[] modes=null;
		
		string[] errors;

		static Switch[] splitSwitches(string str)
		{
			Switch[] ret = [];
			bool inPlainSwitch=false;
			bool inQuotedSwitch=false;
			foreach(dchar c; str)
			{
				if(inPlainSwitch)
				{
					if(iswhite(c))
						inPlainSwitch = false;
					else
						ret[$-1].data ~= to!(string)(c);
				}
				else if(inQuotedSwitch)
				{
					if(c == `"`d[0])
						inQuotedSwitch = false;
					else
						ret[$-1].data ~= to!(string)(c);
				}
				else
				{
					if(c == `"`d[0])
					{
						ret ~= Switch("", true);
						inQuotedSwitch = true;
					}
					else if(!iswhite(c))
					{
						ret ~= Switch(to!(string)(c), false);
						inPlainSwitch = true;
					}
				}
			}
			return ret;
		}
		
		private void doParse(Conf conf, string filename)
		{
			mixin(initMember("conf", "filename"));

			if(!exists(filename) || !isfile(filename))
				throw new STBuildConfException(
					"Can't find configuration file '%s'".format(filename)
				);

			auto input = cast(string)read(filename);
			uint lineno = 1;
			foreach(string line; input.splitlines())
			{
				parseLine(line, lineno);
				lineno++;
			}
			
			if(targets is null)
				error(`No targets defined (Forgot "target targetname1, targetname2"?)`);

			conf.targets = targets ~ predefTargets;
			//conf.modes   = modes;
			conf.errors  = errors;
		}
		
		private void parseLine(string line, uint lineno)
		{
			auto commentStart = line.locate('#');
			//if(commentStart == -1) commentStart = line.length;
			auto stmt = line[0..commentStart].strip();

			version(verbose)
			{
				writef("%s: ", lineno);
				
				if(stmt == "")
					writef("BlankLine ");
				else
					writef("Statement[%s] ", stmt);

				if(commentStart < line.length)
					writef("Comment[%s] ", line[commentStart..$]);
				
				scope(exit) Stdout.newline;
			}

			if(partialStmt is null)
				stmtLineNo = lineno;
			else
				stmt = partialStmt ~ " " ~ stmt;
			
			if(stmt != "")
			{
				if(stmt[$-1] == '_')
				{
					version(verbose) Stdout("TBC ");
					
					partialStmt = stmt[0..$-1];
					return;
				}
				version(verbose) if(partialStmt !is null) writefln("\nFullStmt[%s] ", stmt);
				partialStmt = null;
				
				if(stmt[0] == '[' && stmt[$-1] == ']')
				{
					stmt = stmt[1..$-1];
					auto delimIndex = stmt.indexOf(':');
					if(delimIndex == -1)
						error("Rule definition header must be of the form [target(s):mode(s)]");
					else
					{
						currTargets = parseCSV(stmt[0..delimIndex]);
						currModes = parseCSV(stmt[delimIndex+1..$]);
					}
				}
				else
				{
					auto stmtParts = stmt.split();
					auto stmtCmd = stmtParts[0];
					auto stmtPred = stmt[stmtCmd.length..$].strip();
					switch(stmtCmd)
					{
					case "target":
						setList(targets, stmtCmd, stmtPred, conf.getPredefTargets);
						break;
					case "flags":
						if(currTargets is null)
							error("'%s' must be in a target definition".format(stmtCmd));
						else
						{
							foreach(string target; currTargets)
							foreach(string mode;   currModes)
								conf.flags[target][mode] ~= splitSwitches(stmtPred);
						}
						break;
					default:
						error("Unsupported command '%s'".format(stmtCmd));
						break;
					}
				}
			}
		}

		private void error(string msg)
		{
			errors ~= "%s(%s): %s".format(filename, stmtLineNo, msg);
		}
		
		private string[] parseCSV(string str)
		{
			string[] ret;
			foreach(string name; str.split(","))
				if(name.strip() != "")
					ret ~= name.strip();
			return ret;
		}

		private void setList(ref string[] set, string command, string listStr, string[] predefined)
		{
			if(currTargets !is null)
			{
				error("Statement '%s' must come before the rule definitions".format(command));
				return;
			}
				
			if(set !is null)
			{
				error("List '%s' has already been set".format(command));
				return;
			}

			set ~= parseCSV(listStr);
			foreach(int i, string elem; set)
			{
				if(std.algorithm.find(predefined, elem) != [])
					error("'%s' is a reserved value for '%s'".format(elem, command));
				else
				{
					if(std.algorithm.find(set[0..i], elem) != [])
						error("'%s' is defined more than once in list '%s'".format(elem, command));
				}
			}
		}
	}
}
