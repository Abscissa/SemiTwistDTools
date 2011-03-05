// SemiTwist Library
// Written in the D programming language.

module semitwist.cmdlineparser;

import std.math;
import std.string;
import std.conv;
import std.stdio;

public import semitwist.refbox;
import semitwist.util.all;

//TODO: This module's API needs a serious overhaul.

//TODO: Add "switch A implies switches B and C"
//TODO: Add in some good ideas from the cmd parser in tango scrapple

//TODO: Convert the following sample code into an actual sample app
/**
----- THIS IS PROBABLY OUTDATED -----
Usage:

void main(string[] args)
{
	bool help;
	bool detailhelp;
	int myInt = 2; // Default value == 2
	bool myBool;   // Default value == bool.init (ie, false)
	string myStr;  // Default value == (string).init (ie, "")

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
  -help               Displays a help summary and exits
  -detailhelp         Displays a detailed help message and exits
  -num:<int>          An integer (default: 2)
  -flag               A flag
  -str:<string>       A string
  
*/

enum ArgFlag
{
	Optional   = 0b0000_0000,
	Required   = 0b0000_0001,
	//Unique = 0b0000_0100,
	ToLower    = 0b0000_1000, // If arg is string, the value gets converted to all lower-case (for case-insensitivity)
	Advanced   = 0b0001_0000,
}

template defineArg(alias cmdLineParser, string name, alias var, int flags = cast(int)ArgFlag.Optional, string desc = "")
//template defineArg(alias cmdLineParser, string name, alias var, ArgFlag flags = ArgFlag.Optional, string desc = "")
{
	//TODO: Is there a better way to do this? Ex. "static if(typeof(var) !contained_in listOfSupportedTypes)"
	static if(!is(typeof(var) == int   ) && !is(typeof(var) == int[]   ) && 
	          !is(typeof(var) == bool  ) && !is(typeof(var) == bool[]  ) && 
			  !is(typeof(var) == string) && !is(typeof(var) == string[]) )
	{
		static assert(false, `Attempted to pass variable '`~var.stringof~`' of type '`~typeof(var).stringof~`' to defineArg's 'var' param.`"\n"
		                     `(The type must be one of, or an array of, one of the following: 'int' 'bool' 'string')`);
	}
	else
	{
		const string defineArg = "\n"~
			"auto _cmdarg_refbox_"~name~" = new "~nameof!(RefBox)~"!("~typeof(var).stringof~")(&"~var.stringof~");\n"~
			"auto _cmdarg_"~name~" = new Arg(_cmdarg_refbox_"~name~`, "`~name~`", `~desc.stringof~`);`~"\n"~
			cmdLineParser.stringof~".addArg(_cmdarg_"~name~", cast(ArgFlag)("~flags.stringof~"));\n";
	}
}

template setArgAllowableValues(string name, allowableValues...)
{
	const string setArgAllowableValues =
		PreventStaticArray!(typeof(allowableValues[0])).stringof~"[] _cmdarg_allowablevals_"~name~";\n"
		~_setArgAllowableValues!(name, allowableValues)
		~"_cmdarg_"~name~".setAllowableValues(_cmdarg_allowablevals_"~name~");\n";
}

private template _setArgAllowableValues(string name, allowableValues...)
{
	static if(allowableValues.length == 0)
		const string _setArgAllowableValues = "";
	else
		const string _setArgAllowableValues =
			"_cmdarg_allowablevals_"~name~" ~= "~allowableValues[0].stringof~";\n"
			~ _setArgAllowableValues!(name, allowableValues[1..$]);
}

//TODO? Add float, double, byte, short, long, and unsigned of each.
//TODO: For numeric types, make sure provided values can fit in the type. (Using "to!()"?)
//TODO: Think about way to (or the need to) prevent adding
//      the same Arg instance to multiple Parsers.

class Arg
{
	string name;
	string altName;
	string desc;

	bool isSwitchless  = false;
	bool isRequired    = false;
	bool arrayUnique   = false;
	bool toLower       = false;
	bool isAdvanced    = false;
	
	private Object value;
	private Object defaultValue;
	private Object[] allowableValues;
	
	bool isSet = false;
	
	this(Object value, string name, string desc="")
	{
		mixin(initMember("value", "name", "desc"));
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
			throw new Exception("Param to Arg contructor must be "~RefBox.stringof~", where T is int, bool or string or an array of such types.");
		}
		
		void ensureValidName(string name)
		{
			if(!CmdLineParser.isValidArgName(name))
				throw new Exception(`Tried to define an invalid arg name: "%s". Arg names must be "[a-zA-Z0-9_?]*"`.format(name));
		}
		ensureValidName(name);
		ensureValidName(altName);
	}
}

class CmdLineParser
{
	private Arg[] args;
	private Arg[string] argLookup;
	
	private bool switchlessArgExists=false;
	private size_t switchlessArg;
	
	mixin(getter!(bool, "success"));
	mixin(getter!(string, "errorMsg"));

	private enum Prefix
	{
		Invalid, DoubleDash, SingleDash, Slash
	}
	
	enum ParseArgResult
	{
		Done, NotFound, Error
	}
	
	static bool isValidArgName(string name)
	{
		foreach(char c; name)
		{
			if(!inPattern(c, "a-zA-Z0-9") && c != '_' && c != '?')
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

		bool isSwitchless = arg.name == "";
		bool isRequired   = ((flags & ArgFlag.Required)   != 0);
		bool toLower      = ((flags & ArgFlag.ToLower)    != 0);
		bool isAdvanced   = ((flags & ArgFlag.Advanced)   != 0);
		
		mixin(initMemberTo("arg", "isRequired", "toLower", "isAdvanced"));
		
		if(isSwitchless)
		{
			if(switchlessArgExists)
				args[switchlessArg].isSwitchless = false;
			
			switchlessArgExists = true;
			switchlessArg = args.length-1;
			arg.isSwitchless = true;
		}
	}
	
	private void addToArgLookup(string name, Arg argDef)
	{
		if(name in argLookup)
			throw new Exception(`Argument name "%s" defined more than once.`.format(name));

		argLookup[name] = argDef;
	}
	
	private void splitArg(string fullArg, out Prefix prefix, out string name, out string suffix)
	{
		string argNoPrefix;

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
		auto suffixIndex = reduce!"a<b?a:b"( [
			locate(argNoPrefix, ':'),
			locate(argNoPrefix, '+'),
			locate(argNoPrefix, '-')
		] );
		name = argNoPrefix[0..suffixIndex];
		suffix = suffixIndex < argNoPrefix.length ?
				 argNoPrefix[suffixIndex..$] : "";
	}
	
	//TODO: Detect and error when numerical arg is passed an out-of-range value
	private ParseArgResult parseArg(string cmdArg, string cmdName, string suffix)
	{
		ParseArgResult ret = ParseArgResult.Error;

		void HandleMalformedArgument()
		{
			_errorMsg ~= `Invalid value: "%s"`.formatln(cmdArg);
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
				string val;
				if(suffix.length > 1 && suffix[0] == ':')
				{
					val = strip(suffix[1..$]);

					if(argDef.toLower)
						val = val.tolower();
					
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
					string trimmedSuffix = strip(suffix[1..$]);
					auto copyTrimmedSuffix = trimmedSuffix;
					val = std.conv.parse!int(copyTrimmedSuffix);
					parseAte = trimmedSuffix.length - copyTrimmedSuffix.length;
					//val = cast(int)convInt.parse(trimmedSuffix, 0, &parseAte);
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
			_errorMsg ~= `Unknown switch: "%s"`.formatln(cmdArg);
			ret = ParseArgResult.NotFound;
		}
		
		return ret;
	}

	//TODO: response file

	public bool parse(string[] args)
	{
		bool error=false;
		
		ensureValid();
		populateLookup();
		genDefaultValues();
		
		foreach(string argStr; args[1..$])
		{
			string suffix;
			string argName;
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
					_errorMsg ~= `Unexpected value: "%s"`.formatln(argStr);
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
				throw new Exception("Unexpected ParseArgResult: (%s)".format(result));
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
				_errorMsg ~=
					`Missing switch: %s (%s)`
						.formatln(
							arg.name=="" ? "<"~getArgTypeName(arg)~">" : arg.name,
							arg.desc
						);
				error = true;
			}
		}
		
		return !error;
	}
	
	//TODO: Make function to get the maximum length of the arg names

	private string switchTypesMsg =
`Switch types:
  flag (default):
    Set s to true: -s -s+ -s:true
    Set s to false: -s- -s:false
    Default value: false (unless otherwise noted)

  text:
    Set s to "Hello": -s:Hello
    Default value: "" (unless otherwise noted)
    Case-sensitive unless otherwise noted.

  num:
    Set s to 3: -s:3
    Default value: 0 (unless otherwise noted)
  
  If "[]" appears at the end of the type,
  this means multiple values are accepted.
  Example:
    -s:<text[]>: -s:file1 -s:file2 -s:anotherfile
`;

	string getArgTypeName(Arg arg)
	{
		string typeName = getRefBoxTypeName(arg.value);
		return
			(typeName == "string"  )? "text"   :
			(typeName == "string[]")? "text[]" :
			(typeName == "char[]"  )? "text"   :
			(typeName == "char[][]")? "text[]" :
			(typeName == "bool"    )? "flag"   :
			(typeName == "bool[]"  )? "flag[]" :
			(typeName == "int"     )? "num"    :
			(typeName == "int[]"   )? "num[]"  :
			typeName;
	}
	
	//TODO: Fix word wrapping
	string getUsage(int nameColumnWidth=20)
	{
		string ret;
		string indent = "  ";
		string basicArgStr;
		string advancedArgStr;
		
		ret ~=
			"Switches:\n"~
			"(Prefixes can be '/', '-' or '--')\n"~
			"('[]' means multiple switches are accepted)\n"; //TODO: Only show this line if such a switch exists

		foreach(Arg arg; args)
		{
			string* argStr = arg.isAdvanced? &advancedArgStr : &basicArgStr;
			
			// For some reason, unbox can't see Arg's private member "defaultValue"
			auto argDefaultValue = arg.defaultValue;
			mixin(unbox!(argDefaultValue, "val"));

			string defaultVal;
			if(valAsInt)
				defaultVal = "%s".format(valAsInt());
			else if(valAsBool)
				defaultVal = valAsBool() ? "true" : "";
			else if(valAsStr)
				defaultVal = valAsStr() == "" ? "" : `"%s"`.format(valAsStr());
			
			string defaultValStr = defaultVal == "" ?
				"" : " (default: %s)".format(defaultVal);
				
			string requiredStr = arg.isRequired ?
				"(Required) " : "";
			
			string argType = "<"~getArgTypeName(arg)~">";
			string argSuffix = valAsBool ? "" : (":"~argType);

			string argName;
			if(arg.name=="")
				argName = argType;
			else
				argName = "-"~arg.name~argSuffix;
			if(arg.altName != "")
				argName ~= ", -"~arg.altName~argSuffix;
	
			string nameColumnWidthStr = "%s".format(nameColumnWidth);
			*argStr ~= format("%s%-"~nameColumnWidthStr~"s%s%s\n",
			                  indent, argName~" ", requiredStr~arg.desc, defaultValStr);
		}
		if(basicArgStr != "" && advancedArgStr != "")
		{
			basicArgStr = "\nBasic: \n"~basicArgStr;
			advancedArgStr = "\nAdvanced: \n"~advancedArgStr;
		}
		return ret~basicArgStr~advancedArgStr;
	}

	string getDetailedUsage()
	{
		string ret;
		string indent = "  ";
		string basicArgStr;
		string advancedArgStr;
		
		ret ~= "Switches: (prefixes can be '/', '-' or '--')\n";
		foreach(Arg arg; args)
		{
			string* argStr = arg.isAdvanced? &advancedArgStr : &basicArgStr;

			string argName = arg.isSwitchless? "" : "-"~arg.name;
			if(arg.altName != "")
				argName ~= ", -"~arg.altName;
			if(!arg.isSwitchless || arg.altName != "")
				argName ~= " ";
	
			// For some reason, unbox can't see Arg's private member "defaultValue"
			auto argDefaultValue = arg.defaultValue;
			mixin(unbox!(argDefaultValue, "val"));

			string defaultVal;
			string requiredStr;
			string toLowerStr;
			string switchlessStr;
			string advancedStr;

			if(valAsInt)
				defaultVal = "%s".format(valAsInt());
			else if(valAsInts)
				defaultVal = "%s".format(valAsInts());
			else if(valAsBool)
				defaultVal = "%s".format(valAsBool());
			else if(valAsBools)
				defaultVal = "%s".format(valAsBools());
			else if(valAsStr)
				defaultVal = `"%s"`.format(valAsStr());
			else if(valAsStrs)  //TODO: Change this one from [ blah ] to [ "blah" ]
				defaultVal = "%s".format(valAsStrs());

			defaultVal    = arg.isRequired   ? "" : ", Default: "~defaultVal;
			requiredStr   = arg.isRequired   ? "Required" : "Optional";
			toLowerStr    = arg.toLower      ? ", Case-Insensitive" : "";
			switchlessStr = arg.isSwitchless ? ", Nameless" : "";
			advancedStr   = arg.isAdvanced   ? ", Advanced" : ", Basic";
			
			*argStr ~= "\n";
			*argStr ~= format("%s(%s), %s%s%s%s%s\n",
			                  argName, getArgTypeName(arg),
			                  requiredStr, switchlessStr, toLowerStr, advancedStr, defaultVal);
			*argStr ~= format("%s\n", arg.desc);
		}
		ret ~= basicArgStr;
		ret ~= advancedArgStr;
		ret ~= "\n";
		ret ~= switchTypesMsg;
		return ret;
	}
}
