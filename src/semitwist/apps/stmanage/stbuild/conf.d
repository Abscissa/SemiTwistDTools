// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.apps.stmanage.stbuild.conf;

import semitwist.cmd.all;

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
	private char[][char[]][char[]] flags;
	
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
	
	private char[] getFlagsSafe(char[] target, char[] mode)
	{
		if(target in flags && mode in flags[target])
			return flags[target][mode];
			
		return "";
	}
	
	char[] getFlags(char[] target, char[] mode)
	{
		auto isTargetAll = (target == targetAll);
		auto isModeAll   = (mode   == modeAll  );

		char[][] flagSet = [ getFlagsSafe(target, mode) ];
		if(!isTargetAll)               flagSet ~= getFlagsSafe(targetAll, mode   );
		if(!isModeAll  )               flagSet ~= getFlagsSafe(target,    modeAll);
		if(!isTargetAll && !isModeAll) flagSet ~= getFlagsSafe(targetAll, modeAll);
		
		return flagSet.join(" ").sformat(target, mode, "");
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
								conf.flags[target][mode] = stmtPred;
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
