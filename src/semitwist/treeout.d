// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

// DMD output capturing for Programmer's Notepad:
// %f\(%l\):

module semitwist.treeout;

import tango.io.Stdout;
import tango.text.Util; //char[] indent, char[] newline

import semitwist.util;

abstract class TreeFormatter
{
	char[] fullIndent(int nodeDepth)
	{
		return strip()? "" : indent().repeat(nodeDepth);
	}
	
	char[] newline()
	{
		return strip()? "" : "\n";
	}
	
	char[] indent();
	bool strip();
	char[] processData(char[] content, int nodeDepth);
	char[] processComment(char[] content, int nodeDepth);
	char[] processAttribute(char[] name, char[] value, int nodeDepth);
	char[] processNode(char[] name, char[] attributes, char[] content, int nodeDepth);
	char[] reduceAttributes(char[][] attributes, int nodeDepth);
	char[] reduceNodes(char[][] nodes, int nodeDepth);
	char[] finalize(char[] content);
}

class XMLFormatter(bool _strip, char[] _indent="\t") : TreeFormatter
{
	char[] toValidName(char[] str)
	{
		str = str.map
		(
			(char a)
		    { return isAlphaNumeric(a)? a : '_'; }
		);

		// Can XML names start with an underscore?
		// Seems to work.
		if(str.length > 0 && !isAlphaNumeric(str[0]) && str[0] != '_')
			str = "_"~str;
		
		return str;
	}
	
	char[] indent()
	{
		return _indent;
	}
	
	bool strip()
	{
		return _strip;
	}
	
	char[] processData(char[] content, int nodeDepth)
	{
		return fullIndent(nodeDepth)~"<![CDATA["~content~"]]>"~newline;
	}
	
	char[] processComment(char[] content, int nodeDepth)
	{
		return fullIndent(nodeDepth)~"<!--"~content~"-->"~newline;
	}
	
	char[] processAttribute(char[] name, char[] value, int nodeDepth)
	{
		return ` {}="{}"`.stformat(name.toValidName(), value);
	}
	
	char[] processNode(char[] name, char[] attributes, char[] content, int nodeDepth)
	{
		auto formatStr =
			(content=="")? 
			"{0}<{2}{3} />{1}"
			:
			"{0}<{2}{3}>{1}"
			"{4}"
			"{0}</{2}>{1}";
			
		return formatStr.stformat(fullIndent(nodeDepth), newline(), name.toValidName(), attributes, content);
	}
	
	char[] reduceAttributes(char[][] attributes, int nodeDepth)
	{
		return reduce!(`a~b`)(attributes);
//		return attributes.reduce!(`a~" "~b`)(); // Don't work
	}
	
	char[] reduceNodes(char[][] nodes, int nodeDepth)
	{
		return reduce!(`a~b`)(nodes);
	}
	
	char[] finalize(char[] content)
	{
		return content;
	}
}

class JSONFormatter(bool _strip, char[] _indent="\t") : TreeFormatter
{
	override char[] fullIndent(int nodeDepth)
	{
		return super.fullIndent(nodeDepth+1);
	}

	char[] indent()
	{
		return _indent;
	}
	
	bool strip()
	{
		return _strip;
	}
	
	char[] processString(char[] content)
	{
		return `"` ~ content.substitute(`"`, `\"`) ~ `"`;
	}
	
	char[] processList(char[][] elements, int nodeDepth)
	{
		return elements.length==0? "" :
			elements.reduce
			(
				(char[] a, char[] b)
				{ return a~", "~newline~fullIndent(nodeDepth)~b; }
			);
	}
	
	char[] processPair(char[] name, char[] content)
	{
		return "{}: {}".stformat(name.processString(), content);
	}
	
	char[] processComment(char[] content, int nodeDepth)
	{
		return "";
	}

	char[] processData(char[] content, int nodeDepth)
	{
		return content.processString();
	}
	
	char[] processAttribute(char[] name, char[] value, int nodeDepth)
	{
		return processPair(name, value.processString());
	}
	
	char[] processNode(char[] name, char[] attributes, char[] content, int nodeDepth)
	{
		return processNode(name, attributes, content, nodeDepth, false);
	}
	
	char[] processNode(char[] name, char[] attributes, char[] content, int nodeDepth, bool nameless)
	{
		char[] attrAndContent = 
			(attributes == "" && content == "")? "" :
			(attributes != "" && content == "")? fullIndent(nodeDepth+1)~attributes~newline :
			(attributes == "" && content != "")? fullIndent(nodeDepth+1)~content~newline :
				fullIndent(nodeDepth+1)~attributes~", "~newline~fullIndent(nodeDepth+1)~content~newline;
		
		name = nameless? "" : name.processString()~": ";
			
		return
			"{2}{{{1}"
			"{3}"
			"{0}}"
			.stformat
			(
				fullIndent(nodeDepth), newline,
				name, attrAndContent
			);
	}
	
	char[] reduceAttributes(char[][] attributes, int nodeDepth)
	{
		return attributes.processList(nodeDepth+1);
	}
	
	char[] reduceNodes(char[][] nodes, int nodeDepth)
	{
		return nodes.processList(nodeDepth+1);
	}
	
	char[] finalize(char[] content)
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
	abstract char[] toString(TreeFormatter formatter, char[] content, int nodeDepth);
}

/// NOTE: Might not be implemented correctly by the formatters, atm.
class TreeNodeData : TreeNodeBase 
{
	char[] data;
	
	this(){}
	
	// ctor templates don't seem to work
/*	this(T)(T data)
	{
		char[] dataStr;
		
		static if(is(T:char[]))
			dataStr = data;
		else
			dataStr = stformat("{}", data);
		
		this.data = dataStr;
	}
*/
	this(char[] data)
	{
		this.data = data;
	}

	char[] toString(TreeFormatter formatter, char[] content, int nodeDepth)
	{
		return formatter.processData(content, nodeDepth);
	}
}

class TreeNodeComment : TreeNodeData
{
	this(){}
	this(char[] data)
	{
		super(data);
	}

	char[] toString(TreeFormatter formatter, char[] content, int nodeDepth)
	{
		return formatter.processComment(content, nodeDepth);
	}
}

class TreeNode : TreeNodeBase
{
	char[] name;
	char[][char[]] attributes;
	
	TreeNodeBase[] subNodes;
	
/*	this(char[] name, TreeNode subNodes=null)
	{
		TreeNode[] contentArray;
		if(subNodes !is null)
			contentArray ~= subNodes;
			
		this(name, contentArray);
	}
	
	this(char[] name, TreeNode[] subNodes)
	{
		mixin(initMember!(name, subNodes));
	}
*/	
	this(char[] name, char[][char[]] attributes)
	{
		this(name, cast(TreeNode)null, attributes);
	}
	
	this(char[] name, TreeNodeBase subNodes=null, char[][char[]] attributes=null)
	{
		TreeNodeBase[] contentArray;
		if(subNodes !is null)
			contentArray ~= subNodes;

		this(name, contentArray, attributes);
	}
	
	this(char[] name, TreeNodeBase[] subNodes, char[][char[]] attributes=null)
	{
		mixin(initMember!(name, subNodes, attributes));
	}
	
	TreeNode addAttribute(T, U)(T name, U value)
	{
		char[] nameStr;
		char[] valueStr;
		
		static if(is(T:char[]))
			nameStr = name;
		else
			nameStr = stformat("{}", name);
			
		static if(is(U:char[]))
			valueStr = value;
		else
			valueStr = stformat("{}", value);
			
		attributes[nameStr] = valueStr;
		return this;
	}
	
	TreeNode addAttributes(char[][char[]] attributes)
	{
		foreach(char[] key, char[] value; attributes)
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
	
	char[] format(TreeFormatter formatter)
	{
		return formatter.finalize(this.toString(formatter, "", 0));
	}
	
	char[] toString(TreeFormatter formatter, char[] content, int nodeDepth)
	{
		auto reduceAttributes = &formatter.reduceAttributes;
		auto reduceNodes      = &formatter.reduceNodes;
		
		//TODO: tango.core.Traits.ElementTypeOfArray doesn't seem to be defined
		alias typeof(attributes[""]) AttributeType;
		alias typeof(subNodes[0])    SubNodeType;
		
		auto attrStr =
			attributes
			.mapAAtoA((AttributeType a, AttributeType b) {
				return formatter.processAttribute(a, b, nodeDepth);
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
