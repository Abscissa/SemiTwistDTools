// SemiTwist Library
// Written in the D programming language.

module semitwist.treeout;

import std.traits;//tango.core.Traits;
import std.stdio;//tango.io.Stdout;
//import tango.text.Unicode;
//import tango.text.Util;
//import tango.util.Convert;
import std.string;
import std.regex;
import std.iterator;

import semitwist.util.all;
import semitwist.util.compat.all;

abstract class TreeFormatter
{
	string fullIndent(int nodeDepth)
	{
		return strip()? "" : indent().repeat(nodeDepth);
	}
	
	string newline()
	{
		return strip()? "" : "\n";
	}
	
	string indent();
	bool strip();
	string processData(string content, int nodeDepth);
	string processComment(string content, int nodeDepth);
	string processAttribute(string name, string value, int nodeDepth);
	string processNode(string name, string attributes, string content, int nodeDepth);
	string reduceAttributes(string[] attributes, int nodeDepth);
	string reduceNodes(string[] nodes, int nodeDepth);
	string finalize(string content);
}

class XMLFormatter(bool _strip, string _indent="\t") : TreeFormatter
{
	string toValidName(string str)
	{
		str = replace(str, regex("[^a-zA-Z0-9]"), "_");
/+		std.algorithm.map!(
			(char a)
		    { return inPattern(a, [digits, letters])? a : '_'; }
		)(str);
+//+		str.map
		(
			(char a)
		    { return inPattern(a, [digits, letters])? a : '_'; }
		);+/

		if(str.length > 0 && !inPattern(str[0], [digits, letters]) && str[0] != '_')
			str = "_"~str;
		
		return str;
	}
	
	override string indent()
	{
		return _indent;
	}
	
	override bool strip()
	{
		return _strip;
	}
	
	override string processData(string content, int nodeDepth)
	{
		return fullIndent(nodeDepth)~"<![CDATA["~content~"]]>"~newline;
	}
	
	override string processComment(string content, int nodeDepth)
	{
		return fullIndent(nodeDepth)~"<!--"~content~"-->"~newline;
	}
	
	override string processAttribute(string name, string value, int nodeDepth)
	{
		return ` %s="%s"`.format(toValidName(name), value);
	}
	
	override string processNode(string name, string attributes, string content, int nodeDepth)
	{
		auto formatStr =
			(content=="")? 
			"%1$s<%3$s%4$s />%2$s"
			:
			"%1$s<%3$s%4$s>%2$s"
			"%5$s"
			"%1$s</%3$s>%2$s";
			
		return formatStr.format(fullIndent(nodeDepth), newline(), toValidName(name), attributes, content);
	}
	
	override string reduceAttributes(string[] attributes, int nodeDepth)
	{
		return reduce!(`a~b`)(attributes);
//		return attributes.reduce!(`a~" "~b`)(); // Don't work
	}
	
	override string reduceNodes(string[] nodes, int nodeDepth)
	{
		return reduce!(`a~b`)(nodes);
	}
	
	override string finalize(string content)
	{
		return content;
	}
}

class JSONFormatter(bool _strip, string _indent="\t") : TreeFormatter
{
	override string fullIndent(int nodeDepth)
	{
		return super.fullIndent(nodeDepth+1);
	}

	override string indent()
	{
		return _indent;
	}
	
	override bool strip()
	{
		return _strip;
	}
	
	string processString(string content)
	{
		return `"` ~ content.replace(`\`, `\\`).replace(`"`, `\"`) ~ `"`;
	}
	
	string processList(string[] elements, int nodeDepth)
	{
		return elements.length==0? "" :
			elements.reduce
			(
				(string a, string b)
				{
					a ~= ", "~newline~fullIndent(nodeDepth)~b;
					return a;
				}
			);
	}
	
	string processPair(string name, string content)
	{
		return "%s: %s".format(processString(name), content);
	}
	
	override string processComment(string content, int nodeDepth)
	{
		return "";
	}

	override string processData(string content, int nodeDepth)
	{
		return processString(content);
	}
	
	override string processAttribute(string name, string value, int nodeDepth)
	{
		return processPair(name, processString(value));
	}
	
	override string processNode(string name, string attributes, string content, int nodeDepth)
	{
		return processNode(name, attributes, content, nodeDepth, false);
	}
	
	string processNode(string name, string attributes, string content, int nodeDepth, bool nameless)
	{
		string attrAndContent = 
			(attributes == "" && content == "")? "" :
			(attributes != "" && content == "")? fullIndent(nodeDepth+1)~attributes~newline :
			(attributes == "" && content != "")? fullIndent(nodeDepth+1)~content~newline :
				fullIndent(nodeDepth+1)~attributes~", "~newline~fullIndent(nodeDepth+1)~content~newline;
		
		name = nameless? "" : processString(name)~": ";
			
		return
			"%3$s{%2$s"
			"%4$s"
			"%1$s}"
			.format
			(
				fullIndent(nodeDepth), newline,
				name, attrAndContent
			);
	}
	
	override string reduceAttributes(string[] attributes, int nodeDepth)
	{
		return processList(attributes, nodeDepth+1);
	}
	
	override string reduceNodes(string[] nodes, int nodeDepth)
	{
		return processList(nodes, nodeDepth+1);
	}
	
	override string finalize(string content)
	{
		return processNode("", "", content, -1, true);
	}
}

TreeFormatter formatterTrimmedXML;
TreeFormatter formatterPrettyXML;
TreeFormatter formatterTrimmedJSON;
TreeFormatter formatterPrettyJSON;
static this()
{
	formatterTrimmedXML  = new XMLFormatter !(true);
	formatterPrettyXML   = new XMLFormatter !(false);
	formatterTrimmedJSON = new JSONFormatter!(true);
	formatterPrettyJSON  = new JSONFormatter!(false);
}

abstract class TreeNodeBase
{
	abstract string toString(TreeFormatter formatter, string content, int nodeDepth);
}

/// NOTE: Might not be implemented correctly by the formatters, atm.
class TreeNodeData : TreeNodeBase 
{
	string data;
	
	this(){}
	
	// ctor templates don't seem to work
/*	this(T)(T data)
	{
		string dataStr;
		
		static if(is(T:string))
			dataStr = data;
		else
			dataStr = format("%s", data);
		
		this.data = dataStr;
	}
*/
	this(string data)
	{
		this.data = data;
	}

	override string toString(TreeFormatter formatter, string content, int nodeDepth)
	{
		return formatter.processData(content, nodeDepth);
	}
}

class TreeNodeComment : TreeNodeData
{
	this(){}
	this(string data)
	{
		super(data);
	}

	override string toString(TreeFormatter formatter, string content, int nodeDepth)
	{
		return formatter.processComment(content, nodeDepth);
	}
}

class TreeNode : TreeNodeBase
{
	string name;
	string[string] attributes;
	
	TreeNodeBase[] subNodes;
	
	this(string name, string[string] attributes)
	{
		this(name, cast(TreeNode)null, attributes);
	}
	
	this(string name, TreeNodeBase subNodes=null, string[string] attributes=null)
	{
		TreeNodeBase[] contentArray;
		if(subNodes !is null)
			contentArray ~= subNodes;

		this(name, contentArray, attributes);
	}
	
	this(string name, TreeNodeBase[] subNodes, string[string] attributes=null)
	{
		mixin(initMember("name", "subNodes", "attributes"));
	}
	
	TreeNode addAttribute(T, U)(T name, U value)
	{
		string nameStr;
		string valueStr;
		
		static if(is(T==string))
			nameStr = name;
		else
			nameStr = to!(string)(name);
			
		static if(is(U==string))
			valueStr = value;
		else
			valueStr = to!(string)(value);
			
		attributes[nameStr] = valueStr;
		return this;
	}
	
	TreeNode addAttributes(string[string] attributes)
	{
		foreach(string key, string value; attributes)
			this.attributes[key] = value;
			
		return this;
	}
	
	TreeNode addContent(TreeNodeBase subNodes)
	{
		this.subNodes ~= subNodes;
		return this;
	}
	
	TreeNode addContent(TreeNodeBase[] subNodes)
	{
		foreach(TreeNodeBase node; subNodes)
			this.subNodes ~= node;
			
		return this;
	}
	
	string format(TreeFormatter formatter)
	{
		return formatter.finalize(this.toString(formatter, "", 0));
	}
	
	override string toString(TreeFormatter formatter, string content, int nodeDepth)
	{
		auto reduceAttributes = &formatter.reduceAttributes;
		auto reduceNodes      = &formatter.reduceNodes;
		
		//alias ElementType!(typeof(attributes)) AttributeType;
		alias ElementType!(typeof(subNodes))   SubNodeType;
		alias string       AttributeType;
		//alias TreeNodeBase SubNodeType;
		
		auto attrStr =
			reduceAttributes(
				attributes
				.mapAAtoA((AttributeType val, AttributeType key) {
					return formatter.processAttribute(key, val, nodeDepth);
				}),
				nodeDepth
			);
		
		auto contentStr =
			reduceNodes(
				subNodes
				.map((SubNodeType a){
					return a.toString(formatter, "", nodeDepth+1);
				}),
				nodeDepth
			);
		
		return formatter.processNode(name, attrStr, contentStr, nodeDepth);
	}
}
