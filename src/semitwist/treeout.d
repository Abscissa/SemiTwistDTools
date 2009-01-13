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
import tango.text.Util;

import semitwist.util;

abstract class TreeFormatter
{
	char[] indent();
	bool strip();
	char[] processData(char[] content, char[] indent, char[] newline);
	char[] processComment(char[] content, char[] indent, char[] newline);
	char[] processAttribute(char[] name, char[] value, char[] indent, char[] newline);
	char[] processNode(char[] name, char[] attributes, char[] content, char[] indent, char[] newline);
	char[] reduceAttributes(char[][] attributes, char[] indent, char[] newline);
	char[] reduceNodes(char[][] nodes, char[] indent, char[] newline);
	char[] finalize(char[] content);
}

class XMLFormatter(bool Strip) : TreeFormatter
{
	char[] indent()
	{
		return "    ";
	}
	
	bool strip()
	{
		return Strip;
	}
	
/*	char[] toComment(char[] data)
	{
		return "<!--"~data~"-->";
	}

	char[] toData(char[] data)
	{
		return "<![CDATA["~data~"]]>";
	}
*/	
	char[] processData(char[] content, char[] indent, char[] newline)
	{
		return indent~"<![CDATA["~content~"]]>"~newline;
	}
	
	char[] processComment(char[] content, char[] indent, char[] newline)
	{
		return indent~"<!--"~content~"-->"~newline;
	}
	
	char[] processAttribute(char[] name, char[] value, char[] indent, char[] newline)
	{
		return ` {}="{}"`.stformat(name, value);
	}
	
	char[] processNode(char[] name, char[] attributes, char[] content, char[] indent, char[] newline)
	{
		if(content == "")
			return 
				"{0}<{2}{3} />{1}"
				.stformat(indent, newline, name, attributes);
		else
			return
				"{0}<{2}{3}>{1}"
				"{4}"
				"{0}</{2}>{1}"
				.stformat(indent, newline, name, attributes, content);
	}
	
	char[] reduceAttributes(char[][] attributes, char[] indent, char[] newline)
	{
		return reduce!(`a~b`)(attributes);
//		return attributes.reduce!(`a~" "~b`)(); // Don't work
	}
	
	char[] reduceNodes(char[][] nodes, char[] indent, char[] newline)
	{
		return reduce!(`a~b`)(nodes);
	}
	
	char[] finalize(char[] content)
	{
		return content;
	}
}

class JSONFormatter(bool _strip) : TreeFormatter
{
	char[] indent()
	{
		return "    ";
	}
	
	bool strip()
	{
		return _strip;
	}
	
	char[] processString(char[] content)
	{
		return `"` ~ content.substitute(`"`, `\"`) ~ `"`;
	}
	
	char[] processObject(char[] content)
	{
		return "{"~content~"}";
	}
	
	char[] processList(char[][] elements, char[] indent, char[] newline)
	{
		return elements.length==0? "" :
			elements.reduce
			(
				(char[] a, char[] b)
				{ return a~", "~newline~indent~b; }
			);
	}
	
	char[] processPair(char[] name, char[] content)
	{
		return "{}: {}".stformat(name.processString(), content);
	}
	
	char[] processComment(char[] content, char[] indent, char[] newline)
	{
		return "";
	}

	char[] processData(char[] content, char[] indent, char[] newline)
	{
		return content.processString();
	}
	
	char[] processAttribute(char[] name, char[] value, char[] indent, char[] newline)
	{
		return processPair(name, value.processString());
	}
	
	char[] processNode(char[] name, char[] attributes, char[] content, char[] indent, char[] newline)
	{
		char[] attrAndContent =
			(attributes == "" && content == "")? "" :
			(attributes != "" && content == "")? indent~attributes~newline :
			(attributes == "" && content != "")? content :
				indent~attributes~", "~newline~content;
		
		return
			"{0}{2}: {{{1}"
			"{3}"
			"{0}}{1}"
			.stformat
			(
				indent, newline,
				name.processString(),
				attrAndContent
			);
	}
	
	char[] reduceAttributes(char[][] attributes, char[] indent, char[] newline)
	{
		return attributes.processList(indent, newline);
	}
	
	char[] reduceNodes(char[][] nodes, char[] indent, char[] newline)
	{
		return nodes.processList(indent, newline);
	}
	
	char[] finalize(char[] content)
	{
		return content.processObject();
	}
}

XMLFormatter!(true)   formatterTrimmedXML;
XMLFormatter!(false)  formatterPrettyXML;
JSONFormatter!(true)  formatterTrimmedJSON;
JSONFormatter!(false) formatterPrettyJSON;
static this()
{
	formatterTrimmedXML  = new XMLFormatter!(true);
	formatterPrettyXML   = new XMLFormatter!(false);
	formatterTrimmedJSON = new JSONFormatter!(true);
	formatterPrettyJSON  = new JSONFormatter!(false);
}

abstract class TreeNodeBase
{
	abstract char[] toString(TreeFormatter formatter, char[] content, char[] indent, char[] newline, uint subTreeLevel=0);
}

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

	char[] toString(TreeFormatter formatter, char[] content, char[] indent, char[] newline, uint subTreeLevel=0)
	{
		return formatter.processData(content, indent, newline);
	}
}

class TreeNodeComment : TreeNodeData
{
	this(){}
	this(char[] data)
	{
		super(data);
	}

	char[] toString(TreeFormatter formatter, char[] content, char[] indent, char[] newline, uint subTreeLevel=0)
	{
		return formatter.processComment(content, indent, newline);
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
	
	this(char[] name, TreeNodeBase content=null, char[][char[]] attributes=null)
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
		return formatter.finalize(this.toString(formatter, "", "", "", 0));
	}
	
	char[] toString(TreeFormatter formatter, char[] content, char[] indent, char[] newline, uint subTreeLevel=0)
	{
		auto reduceAttributes = &formatter.reduceAttributes;
		auto reduceNodes      = &formatter.reduceNodes;
		
		//TODO: tango.core.Traits.ElementTypeOfArray doesn't seem to be defined
		alias typeof(attributes[""]) AttributeType;
		alias typeof(subNodes[0])    SubNodeType;
		
		indent  = formatter.strip()? "" : formatter.indent().repeat(subTreeLevel);
		newline = formatter.strip()? "" : "\n";
			
		auto attrStr =
			attributes
			.mapAAtoA((AttributeType a, AttributeType b) {
				return formatter.processAttribute(a, b, indent, newline);
			})
			.reduceAttributes(indent, newline);
		
		auto contentStr =
			subNodes
			.map((SubNodeType a){
				return a.toString(formatter, "", indent, newline, subTreeLevel+1);
			})
			.reduceNodes(indent, newline);
		
		return formatter.processNode(name, attrStr, contentStr, indent, newline);
	}
}
