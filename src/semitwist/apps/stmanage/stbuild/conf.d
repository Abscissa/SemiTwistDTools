// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

module semitwist.apps.stmanage.stbuild.conf;

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
		throw new Exception("Internal Error: Unexpected Build Tool #{}".sformat(tool));
	}
}

class STBuildConfException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}

class Conf
{
	string[] targets;
	private Switch[][string][string] flags;
	
	string[] errors;

	const string targetAll   = "all";
	const string modeRelease = "release";
	const string modeDebug   = "debug";
	const string modeAll     = "all";
	const string[] predefTargets = [targetAll];
	const string[] modes = [modeRelease, modeDebug, modeAll];

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
				"{} error(s) in conf file '{}'"
					.sformat(parser.errors.length, filename)
			);
		}

		targetAllElems = targets.allExcept(targetAll);
		modeAllElems   = modes.allExcept(modeAll);
	}
	
	private Switch[] getFlagsSafe(string target, string mode)
	{
		if(target in flags && mode in flags[target])
		{
			Switch[] ret = flags[target][mode].dup;
			foreach(int i, Switch sw; ret)
				ret[i].data = ret[i].data.dup;

			return ret;
		}
			
		return [];
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
		auto numRemoved = switches.removePrefix(fromSwitch);
		if(numRemoved > 0)
			return switches.convertPrefix(fromPrefix, toPrefix);
		return 0;
	}
	
	private static int splitPrefix(ref Switch[] switches, string fromPrefix, string toPrefix, string toSwitch)
	{
		auto numConverted = switches.convertPrefix(fromPrefix, toPrefix);
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
			switches.convertPrefix("-oq", "-od");
			switches.convertPrefix("+o", "-of");
			switches.convertPrefix("+O", "-od");
			switches.convertPrefix("-C",  ""  );
			switches.convertPrefix("-v", "--chatty");
			switches.convertPrefix("+v", "--chatty");
			switches.convertPrefix("+nolink", "-c");
			switches.removePrefix("+");
			
			// Source file must come last
			switches.moveSourceFileToEnd();
			
			break;

		case BuildTool.rebuild:
			switches.combinePrefix("+O", "+q", "-oq");
			switches.convertPrefix("+o", "-of");
			switches.convertPrefix("+O", "-od");
			switches.convertPrefix("--chatty", "-v");
			switches.convertPrefix("+nolink", "-c");
			switches.removePrefix("+");
			switches.removePrefix("--");
			break;
			
		case BuildTool.xfbuild:
			//switches.splitPrefix("-oq", "+O", "+q"); //Doesn't work for DMD
			switches.convertPrefix("-oq", "+O");
			
			switches.convertPrefix("-C",  ""  );
			switches.convertPrefix("-of", "+o");
			switches.convertPrefix("-od", "+O");
			switches.convertPrefix("--chatty", "+v");
			switches.convertPrefix("-c", "+nolink");
			switches.removePrefix("--");
			break;
			
		default:
			throw new Exception("Internal Error: Unexpected Build Tool #{}".sformat(tool));
		}
	}
	
	private static string switchesToString(Switch[] switches)
	{
		return
			switches
				.map( (Switch sw) { return sw.toString(); } )
				.join(" ");
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
		
		switches = ConfParser.splitSwitches(start);
		switches.convert(BuildTool.rebuild);
		mixin(deferEnsure!(`switches.switchesToString()`, `_ == re`));
		
		switches = ConfParser.splitSwitches(start);
		switches.convert(BuildTool.xfbuild);
		mixin(deferEnsure!(`switches.switchesToString()`, `_ == xf`));
		
		switches = ConfParser.splitSwitches(start2);
		switches.convert(BuildTool.rebuild);
		mixin(deferEnsure!(`switches.switchesToString()`, `_ == re2`));
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
		switches.addDefault("-oq", "obj/{0}/{1}");
		switches.addDefault("+D", "obj/{0}/{1}/deps");
		switches.addDefault("--build-only", "");
	}
	
	private static string fixSlashes(string str)
	{
		version(Windows)
			str.replace('/', '\\');
		else
			str.replace('\\', '/');
		return str;
	}
	
	string getFlags(string target, string mode, BuildTool tool)
	{
		auto isTargetAll = (target == targetAll);
		auto isModeAll   = (mode   == modeAll  );

		Switch[] switches = getFlagsSafe(target, mode);
		if(!isTargetAll)               switches ~= getFlagsSafe(targetAll, mode   );
		if(!isModeAll  )               switches ~= getFlagsSafe(target,    modeAll);
		if(!isTargetAll && !isModeAll) switches ~= getFlagsSafe(targetAll, modeAll);

		switches.addDefaults();
		switches.convert(tool);

		return
			switches
				.switchesToString()
				.fixSlashes()
				.sformat(target, mode, enumOSToString(os), "");
	}
	
	struct Switch
	{
		string data;
		bool quoted;
		string toString()
		{
			return quoted? `"`~data~`"` : data;
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
					if(isWhitespace(c))
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
					else if(!isWhitespace(c))
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
			mixin(initMember!(conf, filename));

			if(cmd.dir.folder(filename).exists || !cmd.dir.file(filename).exists)
				throw new STBuildConfException(
					"Can't find configuration file '{}'".sformat(filename)
				);

			auto input = cast(string)File.get(cmd.dir.file(filename).toString);
			uint lineno = 1;
			foreach(string line; lines(input))
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
			auto stmt = line[0..commentStart].trim();

			version(verbose)
			{
				Stdout.format("{}: ", lineno);
				
				if(stmt == "")
					Stdout.format("BlankLine ");
				else
					Stdout.format("Statement[{}] ", stmt);

				if(commentStart < line.length)
					Stdout.format("Comment[{}] ", line[commentStart..$]);
				
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
				version(verbose) if(partialStmt !is null) Stdout.formatln("\nFullStmt[{}] ", stmt);
				partialStmt = null;
				
				if(stmt[0] == '[' && stmt[$-1] == ']')
				{
					stmt = stmt[1..$-1];
					auto delimIndex = stmt.locate(':');
					if(delimIndex == stmt.length)
						error("Rule definition header must be of the form [target(s):mode(s)]");
					else
					{
						currTargets = stmt[0..delimIndex].parseCSV();
						currModes = stmt[delimIndex+1..$].parseCSV();
					}
				}
				else
				{
					auto stmtParts = stmt.delimit(whitespaceChars!(char));
					auto stmtCmd = stmtParts[0];
					auto stmtPred = stmt[stmtCmd.length..$].trim();
					switch(stmtCmd)
					{
					case "target":
						setList(targets, stmtCmd, stmtPred, conf.predefTargets);
						break;
					case "flags":
						if(currTargets is null)
							error("'{}' must be in a target definition".sformat(stmtCmd));
						else
						{
							foreach(string target; currTargets)
							foreach(string mode;   currModes)
								conf.flags[target][mode] ~= stmtPred.splitSwitches();
						}
						break;
					default:
						error("Unsupported command '{}'".sformat(stmtCmd));
						break;
					}
				}
			}
		}

		private void error(string msg)
		{
			errors ~= "{}({}): {}".sformat(filename, stmtLineNo, msg);
		}
		
		private string[] parseCSV(string str)
		{
			string[] ret;
			foreach(string name; str.delimit(","))
				if(name.trim() != "")
					ret ~= name.trim();
			return ret;
		}

		private void setList(ref string[] set, string command, string listStr, string[] predefined)
		{
			if(currTargets !is null)
			{
				error("Statement '{}' must come before the rule definitions".sformat(command));
				return;
			}
				
			if(set !is null)
			{
				error("List '{}' has already been set".sformat(command));
				return;
			}

			set ~= listStr.parseCSV();
			foreach(int i, string elem; set)
			{
				if(predefined.contains(elem))
					error("'{}' is a reserved value for '{}'".sformat(elem, command));
				else
				{
					if(set[0..i].contains(elem))
						error("'{}' is defined more than once in list '{}'".sformat(elem, command));
				}
			}
		}
	}
}
