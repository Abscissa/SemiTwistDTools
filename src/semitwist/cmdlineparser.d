// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.cmdlineparser;

import tango.core.Array;
import tango.math.Math;
import tango.text.Unicode;
import tango.text.Util;
import convInt = tango.text.convert.Integer;

public import semitwist.refbox;
import semitwist.util.all;

//TODO: Add "switch A implies switches B and C"
//TODO: Don't show "Basic:" or "Advanced:" label if only one type exists

//TODO: Convert the following sample code into an actual sample app
/**
OUTDATED COMMENT
Usage:

void main(char[][] args)
{
	bool help;
	bool detailhelp;
	int myInt = 2; // Default value == 2
	bool myBool;   // Default value == bool.init (ie, false)
	char[] myStr;  // Default value == (char[]).init (ie, "")

	auto cmd = new CmdLineParser();
	mixin(defineArg!(cmd, help,       "help",       "Displays a help summary and exits" ));
	mixin(defineArg!(cmd, detailhelp, "detailhelp", "Displays a detailed help message and exits" ));
	mixin(defineArg!(cmd, myInt,  "num",  "An integer"));
	mixin(defineArg!(cmd, myBool, "flag", "A flag"));
	mixin(defineArg!(cmd, myStr,  "str",  "A string"));
	
	if(!cmd.parse(args) || help)
	{
		Stdout.format("{}", cmd.getUsage());
		return;
	}
	if(detailhelp)
	{
		Stdout.format("{}", cmd.getDetailedUsage());
		return;
	}

	Stdout.formatln("num:  {}", myInt);
	Stdout.formatln("flag: {}", myBool);
	Stdout.formatln("str:  {}", myStr);
}

Sample Command Lines (All these are equivalent):
> myApp.exe /num:5 /flag /str:blah
> myApp.exe -flag:true -str:blah -num=5
> myApp.exe --num=5 /flag+ "-str:blah"
num:  5
flag: true
str:  blah

> myApp.exe "/str:Hello World"
num:  2
flag: false
str:  Hello World

> myApp.exe /foo
Unknown switch: "/foo"
Switches: (prefixes can be '/', '-' or '--')
  /help               Displays a help summary and exits
  /detailhelp         Displays a detailed help message and exits
  /num:<int>          An integer (default: 2)
  /flag               A flag
  /str:<char[]>       A string
  
*/

enum ArgFlag
{
	Optional   = 0b0000_0000,
	Required   = 0b0000_0001,
	Switchless = 0b0000_0010, // There can be only one [arg set to Switchless]
	//Unique = 0b0000_0100,
	ToLower    = 0b0000_1000, // If arg is char[], the value gets converted to all lower-case (for case-insensitivity)
	RequiredSwitchless = ArgFlag.Required | ArgFlag.Switchless,
	Advanced   = 0b0001_0000,
}

template defineArg(alias cmdLineParser, char[] name, alias var, int flags = cast(int)ArgFlag.Optional, char[] desc = "")
//template defineArg(alias cmdLineParser, char[] name, alias var, ArgFlag flags = ArgFlag.Optional, char[] desc = "")
{
	//TODO: Is there a better way to do this? Ex. "static if(typeof(var) !contained_in listOfSupportedTypes)"
	static if(!is(typeof(var) == int   ) && !is(typeof(var) == int[]   ) && 
	          !is(typeof(var) == bool  ) && !is(typeof(var) == bool[]  ) && 
			  !is(typeof(var) == char[]) && !is(typeof(var) == char[][]) )
	{
		static assert(false, `Attempted to pass variable '`~var.stringof~`' of type '`~typeof(var).stringof~`' to defineArg's 'var' param.`"\n"
		                     `(The type must be one of, or an array of, one of the following: 'int' 'bool' 'char[]')`);
	}
	else
	{
		const char[] defineArg = "\n"~
			"auto _cmdarg_refbox_"~name~" = new "~nameof!(RefBox)~"!("~typeof(var).stringof~")(&"~var.stringof~");\n"~
			"auto _cmdarg_"~name~" = new Arg(_cmdarg_refbox_"~name~`, "`~name~`", `~desc.stringof~`);`~"\n"~
			cmdLineParser.stringof~".addArg(_cmdarg_"~name~", cast(ArgFlag)("~flags.stringof~"));\n";
		//pragma(msg, "defineArg: " ~ defineArg);
	}
}

template setArgAllowableValues(char[] name, allowableValues...)
{
	const char[] setArgAllowableValues =
		PreventStaticArray!(typeof(allowableValues[0])).stringof~"[] _cmdarg_allowablevals_"~name~";\n"
		~_setArgAllowableValues!(name, allowableValues)
		~"_cmdarg_"~name~".setAllowableValues(_cmdarg_allowablevals_"~name~");\n";
	//pragma(msg, "setArgAllowableValues:\n" ~ setArgAllowableValues);
}

private template _setArgAllowableValues(char[] name, allowableValues...)
{
	static if(allowableValues.length == 0)
		const char[] _setArgAllowableValues = "";
	else
		const char[] _setArgAllowableValues =
			"_cmdarg_allowablevals_"~name~" ~= "~allowableValues[0].stringof~";\n"
			~ _setArgAllowableValues!(name, allowableValues[1..$]);
	//	pragma(msg, "_setArgAllowableValues:" ~ _setArgAllowableValues);
}

//TODO: Add float, double, byte, short, long, and unsigned of each.
//TODO: For numeric types, make sure provided values can fit in the type. (Using "to!()"?)
//TODO: Think about way to (or the need to) prevent adding
//      the same Arg instance to multiple Parsers.

class Arg
{
	char[] name;
	char[] altName;
	char[] desc;

	bool isSwitchless  = false;
	bool isRequired    = false;
	bool arrayUnique   = false;
	bool toLower       = false;
	bool isAdvanced    = false;
	
	private Object value;
	private Object defaultValue;
	private Object[] allowableValues;
	
	bool isSet = false;
	
	this(Object value, char[] name, char[] desc="")
	{
		mixin(initMember!(value, name, desc));
		ensureValid();
	}
	
	private void genDefaultValue()
	{
		if(!isRequired)
		{
			mixin(dupRefBox!(value, "val", defaultValue));
		}
	}
	
	// Note: AllowableValues are ignored for bool and bool[]
	private void setAllowableValues(T)(T[] allowableValues)
	{
		this.allowableValues.length = 0;
		foreach(T val; allowableValues)
		{
			auto box = new RefBox!(T)();
			box = val;
			this.allowableValues ~= box;
		}
	}
	
	void ensureValid()
	{
		//TODO: arrayMultiple and arrayUnique cannot both be set
		//TODO: ensure each of allowableValues is the same type as value
		//TODO: enforce allowableValues on defaultValue
		//TODO: reflect allowableValues in generated help
		
		if(!isKnownRefBox!(value))
		{
			throw new Exception("Param to Arg contructor must be "~RefBox.stringof~", where T is int, bool or char[] or an array of such types.");
		}
		
		void ensureValidName(char[] name)
		{
			if(!CmdLineParser.isValidArgName(name))
				throw new Exception(`Tried to define an invalid arg name: "{}". Arg names must be "[a-zA-Z0-9_?]+"`.sformat(name));
		}
		ensureValidName(name);
		ensureValidName(altName);
		
		if(name == "")
			throw new Exception(`Tried to define a blank arg name`);
	}
}

class CmdLineParser
{
	private Arg[] args;
	private Arg[char[]] argLookup;
	
	private bool switchlessArgExists=false;
	private size_t switchlessArg;
	
	mixin(getter!(bool, "success"));
	mixin(getter!(char[], "errorMsg"));

	private enum Prefix
	{
		Invalid, DoubleDash, SingleDash, Slash
	}
	
	enum ParseArgResult
	{
		Done, NotFound, Error
	}
	
	static bool isValidArgName(char[] name)
	{
		foreach(char c; name)
		{
			if(!isAlphaNumeric(c) && c != '_' && c != '?')
				return false;
		}
		return true;
	}
	
	private void ensureValid()
	{
		foreach(Arg arg; args)
		{
			arg.ensureValid();
		}
	}
	
	private void populateLookup()
	{
		foreach(Arg arg; args)
		{
			addToArgLookup(arg.name, arg);
			
			if(arg.altName != "")
				addToArgLookup(arg.altName, arg);
		}
	}

	private void genDefaultValues()
	{
		foreach(Arg arg; args)
		{
			arg.genDefaultValue();
		}
	}

	public void addArg(Arg arg, ArgFlag flags = ArgFlag.Optional)
	{
		args ~= arg;

		bool isSwitchless = ((flags & ArgFlag.Switchless) != 0);
		bool isRequired   = ((flags & ArgFlag.Required)   != 0);
		bool toLower      = ((flags & ArgFlag.ToLower)    != 0);
		bool isAdvanced   = ((flags & ArgFlag.Advanced)   != 0);
		
		mixin(initMemberTo!(arg, isRequired, toLower, isAdvanced));
		
		if(isSwitchless)
		{
			if(switchlessArgExists)
				args[switchlessArg].isSwitchless = false;
			
			switchlessArgExists = true;
			switchlessArg = args.length-1;
			arg.isSwitchless = true;
		}
	}
	
	private void addToArgLookup(char[] name, Arg argDef)
	{
		if(name in argLookup)
			throw new Exception(`Argument name "{}" defined more than once.`.sformat(name));

		argLookup[name] = argDef;
	}
	
	private void splitArg(char[] fullArg, out Prefix prefix, out char[] name, out char[] suffix)
	{
		char[] argNoPrefix;

		// Get prefix
		if(fullArg.length > 2 && fullArg[0..2] == "--")
		{
			argNoPrefix = fullArg[2..$];
			prefix = Prefix.DoubleDash;
		}
		else if(fullArg.length > 1)
		{
			argNoPrefix = fullArg[1..$];
			
			if(fullArg[0] == '-')
				prefix = Prefix.SingleDash;
			else if(fullArg[0] == '/')
				prefix = Prefix.Slash;
			else
			{
				prefix = Prefix.Invalid;
				argNoPrefix = fullArg;
			}
		}
		
		// Get suffix and arg name
		auto suffixIndex = min( tango.core.Array.find(argNoPrefix, ':'),
								tango.core.Array.find(argNoPrefix, '+'),
								tango.core.Array.find(argNoPrefix, '-') );
		name = argNoPrefix[0..suffixIndex];
		suffix = suffixIndex < argNoPrefix.length ?
				 argNoPrefix[suffixIndex..$] : "";
	}
	
	//TODO: Detect and error when numerical arg is passed an out-of-range value
	private ParseArgResult parseArg(char[] cmdArg, char[] cmdName, char[] suffix)
	{
		ParseArgResult ret = ParseArgResult.Error;

		void HandleMalformedArgument()
		{
			_errorMsg ~= `Invalid value: "{}"`.sformatln(cmdArg);
			ret = ParseArgResult.Error;
		}
		
		if(cmdName in argLookup)
		{
			auto argDef = argLookup[cmdName];
			
			// For some reason, unbox can't see Arg's private member "value"
			auto argDefValue = argDef.value;
			mixin(unbox!(argDefValue, "val"));

			ret = ParseArgResult.Done;
			if(valAsBool || valAsBools)
			{
				bool val;
				bool isMalformed=false;
				switch(suffix)
				{
				case "":
				case "+":
				case ":+":
				case ":true":
					val = true;
					break;
				case "-":
				case ":-":
				case ":false":
					val = false;
					break;
				default:
					HandleMalformedArgument();
					isMalformed = true;
					break;
				}
				
				if(!isMalformed)
				{
					if(valAsBool)
						valAsBool = val;
					else
						valAsBools = valAsBools() ~ val;
				}
			}
			else if(valAsStr || valAsStrs)
			{
				char[] val;
				if(suffix.length > 1 && suffix[0] == ':')
				{
					val = trim(suffix[1..$]);

					if(argDef.toLower)
						val = val.toLower();
					
					//TODO: DRY this
					if(argDef.allowableValues.length > 0)
					{
						bool matchFound=false;
						foreach(Object allowedObj; argDef.allowableValues)
						{
							mixin(unbox!(allowedObj, "allowedVal"));
							if(val == allowedValAsStr)
							{
								matchFound = true;
								break;
							}
						}
						if(!matchFound)
							HandleMalformedArgument();
					}

					if(valAsStr)
						valAsStr = val;
					else
						valAsStrs = valAsStrs() ~ val;
				}
				else
					HandleMalformedArgument();
			}
			else if(valAsInt || valAsInts)
			{
				int val;
				uint parseAte;
				if(suffix.length > 1 && suffix[0] == ':')
				{
					char[] trimmedSuffix = trim(suffix[1..$]);
					val = cast(int)convInt.parse(trimmedSuffix, 0, &parseAte);
					if(parseAte == trimmedSuffix.length)
					{
						//TODO: DRY this
						if(argDef.allowableValues.length > 0)
						{
							bool matchFound=false;
							foreach(Object allowedObj; argDef.allowableValues)
							{
								mixin(unbox!(allowedObj, "allowedVal"));
								if(val == allowedValAsInt)
								{
									matchFound = true;
									break;
								}
							}
							if(!matchFound)
								HandleMalformedArgument();
						}

						if(valAsInt)
							valAsInt = val;
						else
							valAsInts = valAsInts() ~ val;
					}
					else
						HandleMalformedArgument();
				}
				else
					HandleMalformedArgument();
			}
			else
				throw new Exception("Internal Error: Failed to process an Arg.value type that hasn't been set as unsupported.");

			argDef.isSet = true;
		}
		else
		{
			_errorMsg ~= `Unknown switch: "{}"`.sformatln(cmdArg);
			ret = ParseArgResult.NotFound;
		}
		
		return ret;
	}

	//TODO: check for response file

	public bool parse(char[][] args)
	{
		bool error=false;
		
		ensureValid();
		populateLookup();
		genDefaultValues();
		
		foreach(char[] argStr; args[1..$])
		{
			char[] suffix;
			char[] argName;
			Prefix prefix;
			
			splitArg(argStr, prefix, argName, suffix);
			if(prefix == Prefix.Invalid)
			{
				if(switchlessArgExists)
				{
					argName = this.args[switchlessArg].name;
					suffix = ":"~argStr;
				}
				else
				{
					_errorMsg ~= `Unexpected value: "{}"`.sformatln(argStr);
					error = true;
					continue;
				}
			}
			//mixin(traceVal!("argStr ", "prefix ", "argName", "suffix "));
			
			auto result = parseArg(argStr, argName, suffix);
			switch(result)
			{
			case ParseArgResult.Done:
				continue;
				
			case ParseArgResult.Error:
			case ParseArgResult.NotFound:
				error = true;
				break;
				
			default:
				throw new Exception("Unexpected ParseArgResult: ({})".sformat(result));
			}
		}
		
		if(!verify())
			error = true;
		
		_success = !error;
		return _success;
	}
	
	private bool verify()
	{
		bool error=false;
		
		foreach(Arg arg; this.args)
		{
			if(arg.isRequired && !arg.isSet)
			{
				_errorMsg ~= `Missing switch: {} ({})`.sformatln(arg.name, arg.desc);
				error = true;
			}
		}
		
		return !error;
	}
	
	//TODO: Make function to get the maximum length of the arg names

	private char[] switchTypesMsg =
`Switch types:
  flag (default):
    Set s to true: /s /s+ /s:true
    Set s to false: /s- /s:false
    Default value: false (unless otherwise noted)

  text:
    Set s to "Hello": /s:Hello
    Default value: "" (unless otherwise noted)
    Case-sensitive unless otherwise noted.

  num:
    Set s to 3: /s:3
    Default value: 0 (unless otherwise noted)
  
  If "[]" appears at the end of the type,
  this means multiple values are accepted.
  Example:
    /s:<text[]>: /s:file1 /s:file2 /s:anotherfile
  
  Switchless: This means the "/s:" portion can be omitted
  Example:
    /s:true -> true
    /s:Hello -> Hello
    /s:12 -> 12
`;

	char[] getArgTypeName(Arg arg)
	{
		char[] typeName = getRefBoxTypeName(arg.value);
		return
			(typeName == "char[]"  )? "text"   :
			(typeName == "char[][]")? "text[]" :
			(typeName == "bool"    )? "flag"   :
			(typeName == "bool[]"  )? "flag[]" :
			(typeName == "int"     )? "num"    :
			(typeName == "int[]"   )? "num[]"  :
			typeName;
	}
	
	//TODO: Fix word wrapping
	char[] getUsage(int nameColumnWidth=20)
	{
		char[] ret;
		char[] indent = "  ";
		char[] basicArgStr;
		char[] advancedArgStr;
		
		ret ~= "Switches: (prefixes can be '/', '-' or '--')\n";
		if(switchlessArgExists)
			ret ~= "Switchless arg: {} ({})\n".sformat(args[switchlessArg].name, args[switchlessArg].desc);

		foreach(Arg arg; args)
		{
			char[]* argStr = arg.isAdvanced? &advancedArgStr : &basicArgStr;
			
			// For some reason, unbox can't see Arg's private member "defaultValue"
			auto argDefaultValue = arg.defaultValue;
			mixin(unbox!(argDefaultValue, "val"));

			char[] defaultVal;
			if(valAsInt)
				defaultVal = "{}".sformat(valAsInt());
			else if(valAsBool)
				defaultVal = valAsBool() ? "true" : "";
			else if(valAsStr)
				defaultVal = valAsStr() == "" ? "" : `"{}"`.sformat(valAsStr());
			
			char[] defaultValStr = defaultVal == "" ?
				"" : " (default: {})".sformat(defaultVal);
				
			char[] requiredStr = arg.isRequired ?
				"(Required) " : "";
			
			char[] argSuffix = valAsBool ? "" : ":<"~getArgTypeName(arg)~">" ;

			char[] argName = "/"~arg.name~argSuffix;
			if(arg.altName != "")
				argName ~= ", /"~arg.altName~argSuffix;
			
			char[] switchless = arg.isSwitchless? " (Switch name can be omitted)" : "";
	
			char[] nameColumnWidthStr = "{}".sformat(nameColumnWidth);
			*argStr ~= sformat("{}{,-"~nameColumnWidthStr~"}{}{}\n",
			                    indent, argName~" ", requiredStr~arg.desc~switchless, defaultValStr);
		}
		if(basicArgStr != "") basicArgStr = "\nBasic: \n"~basicArgStr;
		if(advancedArgStr != "") advancedArgStr = "\nAdvanced: \n"~advancedArgStr;
		return ret~basicArgStr~advancedArgStr;
	}

	char[] getDetailedUsage()
	{
		char[] ret;
		char[] indent = "  ";
		char[] basicArgStr;
		char[] advancedArgStr;
		
		ret ~= "Switches: (prefixes can be '/', '-' or '--')\n";
		foreach(Arg arg; args)
		{
			char[]* argStr = arg.isAdvanced? &advancedArgStr : &basicArgStr;

			char[] argName = "/"~arg.name;
			if(arg.altName != "")
				argName ~= ", /"~arg.altName;
	
			// For some reason, unbox can't see Arg's private member "defaultValue"
			auto argDefaultValue = arg.defaultValue;
			mixin(unbox!(argDefaultValue, "val"));

			char[] defaultVal;
			char[] requiredStr;
			char[] toLowerStr;
			char[] switchlessStr;
			char[] advancedStr;

			if(valAsInt)
				defaultVal = "{}".sformat(valAsInt());
			else if(valAsInts)
				defaultVal = "{}".sformat(valAsInts());
			else if(valAsBool)
				defaultVal = "{}".sformat(valAsBool());
			else if(valAsBools)
				defaultVal = "{}".sformat(valAsBools());
			else if(valAsStr)
				defaultVal = `"{}"`.sformat(valAsStr());
			else if(valAsStrs)  //TODO: Change this one from [ blah ] to [ "blah" ]
				defaultVal = "{}".sformat(valAsStrs());

			defaultVal    = arg.isRequired   ? "" : ", Default: "~defaultVal;
			requiredStr   = arg.isRequired   ? "Required" : "Optional";
			toLowerStr    = arg.toLower      ? ", Case-Insensitive" : "";
			switchlessStr = arg.isSwitchless ? ", Switchless" : "";
			advancedStr   = arg.isAdvanced   ? ", Advanced" : ", Basic";
			
			*argStr ~= "\n";
			*argStr ~= sformat("{} ({}), {}{}{}{}\n",
			                   argName, getArgTypeName(arg),
							   requiredStr, switchlessStr, toLowerStr, advancedStr, defaultVal);
			*argStr ~= sformat("{}\n", arg.desc);
		}
		ret ~= basicArgStr;
		ret ~= advancedArgStr;
		ret ~= "\n";
		ret ~= switchTypesMsg;
		return ret;
	}
}
