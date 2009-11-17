// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

module semitwist.apps.stmanage.stbuild.conf;

import semitwist.cmd.all;

enum BuildTool
{
	rebuild,
	xfbuild,
}

char[] buildToolExecName(BuildTool tool)
{
	switch(tool)
	{
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
	this(char[] msg)
	{
		super(msg);
	}
}

class Conf
{
	char[][] targets;
	private Switch[][char[]][char[]] flags;
	
	char[][] errors;

	const char[] targetAll   = "all";
	const char[] modeRelease = "release";
	const char[] modeDebug   = "debug";
	const char[] modeAll     = "all";
	const char[][] predefTargets = [targetAll];
	const char[][] modes = [modeRelease, modeDebug, modeAll];

	char[][] targetAllElems;
	char[][] modeAllElems;
	
	this(char[] filename)
	{
		auto parser = new ConfParser();
		parser.doParse(this, filename);
		
		if(parser.errors.length > 0)
		{
			foreach(char[] error; parser.errors)
				cmd.echo(error);
				
			throw new STBuildConfException(
				"{} error(s) in conf file '{}'"
					.sformat(parser.errors.length, filename)
			);
		}

		targetAllElems = targets.allExcept(targetAll);
		modeAllElems   = modes.allExcept(modeAll);
	}
	
	private Switch[] getFlagsSafe(char[] target, char[] mode)
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
	
	char[] getFlags(char[] target, char[] mode, BuildTool tool)
	{
		auto isTargetAll = (target == targetAll);
		auto isModeAll   = (mode   == modeAll  );

		Switch[] flagSet = getFlagsSafe(target, mode);
		if(!isTargetAll)               flagSet ~= getFlagsSafe(targetAll, mode   );
		if(!isModeAll  )               flagSet ~= getFlagsSafe(target,    modeAll);
		if(!isTargetAll && !isModeAll) flagSet ~= getFlagsSafe(targetAll, modeAll);

		switch(tool)
		{
		case BuildTool.rebuild:
			// Convert +q -od... to -oq...
			int[] plusIndicies = [];
			foreach(int index, Switch sw; flagSet)
			{
				if(sw.data == "+q")
					plusIndicies ~= index;
			}
			if(plusIndicies.length > 0)
			{
				foreach(int index; plusIndicies)
					flagSet = flagSet[0..index] ~ flagSet[index+1..$];
				foreach(ref Switch sw; flagSet)
				{
					if(sw.data.length >= 3 && sw.data[0..3] == "-od")
						sw.data = "-oq"~sw.data[3..$];
				}
			}
			
			// Remove all remaining +...
			plusIndicies = [];
			foreach(int index, Switch sw; flagSet)
			{
				if(sw.data.length >= 1 && sw.data[0] == '+')
					plusIndicies ~= index;
			}
			foreach(int index; plusIndicies)
				flagSet = flagSet[0..index] ~ flagSet[index+1..$];
			break;
			
		case BuildTool.xfbuild:
			foreach(int i, Switch sw; flagSet)
			{
				// Convert -oq... to -od...
				if(sw.data.length >= 3 && sw.data[0..3] == "-oq")
					flagSet[i].data = "-od"~sw.data[3..$];
				
				// Strip leading -C
				if(sw.data.length >= 2 && sw.data[0..2] == "-C")
					flagSet[i].data = sw.data[2..$];
			}
			break;
			
		default:
			throw new Exception("Internal Error: Unexpected Build Tool #{}".sformat(tool));
		}

		return
			flagSet
				.map( (Switch sw) { return sw.toString(); } )
				.join(" ")
				.sformat(target, mode, "");
	}
	
	struct Switch
	{
		char[] data;
		bool quoted;
		char[] toString()
		{
			return quoted? `"`~data~`"` : data;
		}
	}
	
	private class ConfParser
	{
		private Conf conf;
		private char[] filename;
		
		private uint stmtLineNo;
		private char[] partialStmt=null;
		
		char[][] currTargets;
		char[][] currModes;
		
		char[][] targets=null;
		char[][] modes=null;
		
		char[][] errors;

		private static Switch[] splitSwitches(char[] str)
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
						ret[$-1].data ~= to!(char[])(c);
				}
				else if(inQuotedSwitch)
				{
					if(c == `"`d[0])
						inQuotedSwitch = false;
					else
						ret[$-1].data ~= to!(char[])(c);
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
						ret ~= Switch(to!(char[])(c), false);
						inPlainSwitch = true;
					}
				}
			}
			return ret;
		}
		
		private void doParse(Conf conf, char[] filename)
		{
			mixin(initMember!(conf, filename));

			if(cmd.dir.folder(filename).exists || !cmd.dir.file(filename).exists)
				throw new STBuildConfException(
					"Can't find configuration file '{}'".sformat(filename)
				);

			auto input = cast(char[])File.get(cmd.dir.file(filename).toString);
			uint lineno = 1;
			foreach(char[] line; lines(input))
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
		
		private void parseLine(char[] line, uint lineno)
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
							foreach(char[] target; currTargets)
							foreach(char[] mode;   currModes)
								conf.flags[target][mode] = stmtPred.splitSwitches();
						}
						break;
					default:
						error("Unsupported command '{}'".sformat(stmtCmd));
						break;
					}
				}
			}
		}

		private void error(char[] msg)
		{
			errors ~= "{}({}): {}".sformat(filename, stmtLineNo, msg);
		}
		
		private char[][] parseCSV(char[] str)
		{
			char[][] ret;
			foreach(char[] name; str.delimit(","))
				if(name.trim() != "")
					ret ~= name.trim();
			return ret;
		}

		private void setList(ref char[][] set, char[] command, char[] listStr, char[][] predefined)
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
			foreach(int i, char[] elem; set)
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
