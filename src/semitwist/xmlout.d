// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

// DMD output capturing for Programmer's Notepad:
// %f\(%l\):

module semitwist.xmlout;

import tango.io.Stdout;
import util = tango.text.Util;

import semitwist.util;

// Note: This does no validation. GIGO.

abstract class XmlNodeBase
{
	abstract char[] toString();
}

class XmlNodeData : XmlNodeBase 
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

	char[] toString()
	{
		return data;
	}
}

class XmlNodeCData : XmlNodeData
{
	this(){}
	this(char[] data)
	{
		super(data);
	}

	char[] toString()
	{
		return "<![CDATA["~data~"]]>";
	}
}

class XmlNodeComment : XmlNodeData
{
	this(){}
	this(char[] data)
	{
		super(data);
	}

	char[] toString()
	{
		return "<!--"~data~"-->";
	}
}

class XmlNode : XmlNodeBase 
{
	char[] name;
	char[][char[]] attributes;
	
//	char[] content;
	XmlNodeBase[] content;
	
/*	this(char[] name, XmlNode content=null)
	{
		XmlNode[] contentArray;
		if(content !is null)
			contentArray ~= content;
			
		this(name, contentArray);
	}
	
	this(char[] name, XmlNode[] content)
	{
		mixin(initMember!(name, content));
	}
*/	
	this(char[] name, char[][char[]] attributes)
	{
		this(name, cast(XmlNode)null, attributes);
	}
	
	this(char[] name, XmlNodeBase content=null, char[][char[]] attributes=null)
	{
		XmlNodeBase[] contentArray;
		if(content !is null)
			contentArray ~= content;

		this(name, contentArray, attributes);
	}
	
	this(char[] name, XmlNodeBase[] content, char[][char[]] attributes=null)
	{
		mixin(initMember!(name, content, attributes));
	}
	
	XmlNode addAttribute(T, U)(T name, U value)
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
	
	XmlNode addAttributes(char[][char[]] attributes)
	{
		foreach(char[] key, char[] value; attributes)
			this.attributes[key] = value;
			
		return this;
	}
	
	XmlNode addContent(XmlNodeBase content)
	{
		this.content ~= content;
		return this;
	}
	
	XmlNode addContent(XmlNodeBase[] content)
	{
		foreach(XmlNodeBase node; content)
			this.content ~= node;
			
		return this;
	}
	
	char[] toString()
	{
		return toString(true);
	}
	
	char[] toString(bool strip)
	{
		auto strs = toStrings(strip);
		char[] ret;
		foreach(char[] str; strs)
		{
			ret ~= str;
			if(!strip)
				ret ~= '\n';
		}
		return ret;
	}
	
	char[][] toStrings(bool strip=true)
	{
		const char[] indent = "    ";
		
		char[] attrStr;
		bool isFirst=true;
		foreach(char[] key, char[] value; attributes)
		{
			if(isFirst)
				isFirst = false;
			else
				attrStr ~= " ";

			attrStr ~= stformat(`{}="{}"`, key, value);
		}
		if(attrStr.length != 0)
			attrStr = " "~attrStr;
		
		char[][] contentStrs;
		foreach(XmlNodeBase node; content)
		{
			if(cast(XmlNode)node)
			{
				if(strip)
					contentStrs ~= (cast(XmlNode)node).toString(strip);
				else
				{
					foreach(char[] str; (cast(XmlNode)node).toStrings(strip))
						contentStrs ~= indent~str; 
				}
			}
			else
			{
				if(strip)
					contentStrs ~= node.toString();
				else
					contentStrs ~= indent~node.toString();
			}
		}
		
		char[][] strs;
		if(content.length == 0)
			strs ~= stformat("<{}{} />", name, attrStr);
		else
		{
			if(strip)
				strs ~= stformat("<{0}{1}>{2}</{0}>", name, attrStr, util.join(contentStrs));
			else
			{
				strs ~= stformat("<{}{}>", name, attrStr);
				strs ~= contentStrs;
				strs ~= stformat("</{}>", name);
			}
		}
		
		return strs;
	}
}
