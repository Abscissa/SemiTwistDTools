// SemiTwist Library
// Written in the D programming language.

module semitwist.treeout;

import tango.core.Traits;
import tango.io.Stdout;
import tango.text.Unicode;
import tango.text.Util;
import tango.util.Convert;

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
		str = str.map
		(
			(char a)
		    { return isLetterOrDigit(a)? a : '_'; }
		);

		if(str.length > 0 && !isLetterOrDigit(str[0]) && str[0] != '_')
			str = "_"~str;
		
		return str;
	}
	
	string indent()
	{
		return _indent;
	}
	
	bool strip()
	{
		return _strip;
	}
	
	string processData(string content, int nodeDepth)
	{
		return fullIndent(nodeDepth)~"<![CDATA["~content~"]]>"~newline;
	}
	
	string processComment(string content, int nodeDepth)
	{
		return fullIndent(nodeDepth)~"<!--"~content~"-->"~newline;
	}
	
	string processAttribute(string name, string value, int nodeDepth)
	{
		return ` {}="{}"`.sformat(name.toValidName(), value);
	}
	
	string processNode(string name, string attributes, string content, int nodeDepth)
	{
		auto formatStr =
			(content=="")? 
			"{0}<{2}{3} />{1}"
			:
			"{0}<{2}{3}>{1}"
			"{4}"
			"{0}</{2}>{1}";
			
		return formatStr.sformat(fullIndent(nodeDepth), newline(), name.toValidName(), attributes, content);
	}
	
	string reduceAttributes(string[] attributes, int nodeDepth)
	{
		return reduce!(`a~b`)(attributes);
//		return attributes.reduce!(`a~" "~b`)(); // Don't work
	}
	
	string reduceNodes(string[] nodes, int nodeDepth)
	{
		return reduce!(`a~b`)(nodes);
	}
	
	string finalize(string content)
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

	string indent()
	{
		return _indent;
	}
	
	bool strip()
	{
		return _strip;
	}
	
	string processString(string content)
	{
		return `"` ~ content.substitute(`\`, `\\`).substitute(`"`, `\"`) ~ `"`;
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
		return "{}: {}".sformat(name.processString(), content);
	}
	
	string processComment(string content, int nodeDepth)
	{
		return "";
	}

	string processData(string content, int nodeDepth)
	{
		return content.processString();
	}
	
	string processAttribute(string name, string value, int nodeDepth)
	{
		return processPair(name, value.processString());
	}
	
	string processNode(string name, string attributes, string content, int nodeDepth)
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
		
		name = nameless? "" : name.processString()~": ";
			
		return
			"{2}{{{1}"
			"{3}"
			"{0}}"
			.sformat
			(
				fullIndent(nodeDepth), newline,
				name, attrAndContent
			);
	}
	
	string reduceAttributes(string[] attributes, int nodeDepth)
	{
		return attributes.processList(nodeDepth+1);
	}
	
	string reduceNodes(string[] nodes, int nodeDepth)
	{
		return nodes.processList(nodeDepth+1);
	}
	
	string finalize(string content)
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
			dataStr = sformat("{}", data);
		
		this.data = dataStr;
	}
*/
	this(string data)
	{
		this.data = data;
	}

	string toString(TreeFormatter formatter, string content, int nodeDepth)
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

	string toString(TreeFormatter formatter, string content, int nodeDepth)
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
		mixin(initMember!(name, subNodes, attributes));
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
	
	string toString(TreeFormatter formatter, string content, int nodeDepth)
	{
		auto reduceAttributes = &formatter.reduceAttributes;
		auto reduceNodes      = &formatter.reduceNodes;
		
		alias ValTypeOfAA!(typeof(attributes))      AttributeType;
		alias ElementTypeOfArray!(typeof(subNodes)) SubNodeType;
		
		auto attrStr =
			attributes
			.mapAAtoA((AttributeType val, AttributeType key) {
				return formatter.processAttribute(key, val, nodeDepth);
			})
			.reduceAttributes(nodeDepth);
		
		auto contentStr =
			subNodes
			.map((SubNodeType a){
				return a.toString(formatter, "", nodeDepth+1);
			})
			.reduceNodes(nodeDepth);
		
		return formatter.processNode(name, attrStr, contentStr, nodeDepth);
	}
}
