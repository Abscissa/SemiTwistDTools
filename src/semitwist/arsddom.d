// SemiTwist Library
// Written in the D programming language.
//
// Helper tools for the arsd DOM module at: 
// https://github.com/adamdruppe/arsd/blob/master/dom.d

module semitwist.arsddom;

import std.string;
import arsd.dom;

void deactivateLink(Element link)
{
	link.removeAttribute("href");
	link.className = "inactive-link";
	link.tagName = "span";
}

void removeAll(Element elem, string selector)
{
	foreach(ref elemToRemove; elem.getElementsBySelector(selector))
		elemToRemove.outerHTML = "";
}

void setAttributes(Element elem, string[string] attributes)
{
	if(attributes != null)
	{
		foreach(key, value; attributes)
		{
			if(key.toLower() == "class")
				elem.addClass(value);
			else if(key.toLower() == "style")
				elem.style ~= value;
			else
				elem.setAttribute(key, value);
		}
	}
}

/++
Sample usage:

	struct Foo {
		int i; string s;
	}

	auto doc = new Document("
		<body>
			<h1>Foo:</h1>
			<div class="foo">
				<h2 class=".foo-int">(placeholder)</h2>
				<p class=".foo-str">(placeholder)</p>
				<hr />
			</div>
		</body>
		", true, true);

	fill!(Foo[])(
		doc.requireSelector(".foo"),
		[Foo(10,"abc"), Foo(20,"def")],
		(stamp, index, foo) {
			stamp.requireSelector(".foo-int").innerHTML = text("#", index, " ", foo.i);
			stamp.requireSelector(".foo-str").innerHTML = foo.s;
			return stamp;
		}
	)
	
	/+
	Result:
		<body>
			<h1>Foo:</h1>
			<div class="foo">
				<h2 class=".foo-int">#0: 10</h2>
				<p class=".foo-str">abc</p>
				<hr />
			</div>
			<div class="foo">
				<h2 class=".foo-int">#1: 20</h2>
				<p class=".foo-str">def</p>
				<hr />
			</div>
		</body>
	+/
	writeln(doc);
+/
//TODO: fill() needs a way to do a plain old 0..x with no data
void fill(T)(
	Element elem, T collection,
	Element delegate(Element, size_t, ElementType!T) dg
) if(isInputRange!T)
{
	auto elemTemplate = elem.cloned;
	string finalHtml;
	for(size_t i=0; !collection.empty; i++)
	{
		auto stamp = elemTemplate.cloned;
		auto newElem = dg(stamp, i, collection.front);
		finalHtml ~= newElem.toString();
		collection.popFront();
	}
	elem.outerHTML = finalHtml;
}

class MissingHtmlAttributeException : Exception
{
	Element elem;
	string attrName;
	string htmlFileName;
	
	this(string file=__FILE__, size_t line=__LINE__)(Element elem, string attrName, string htmlFileName=null)
	{
		super("", file, line);
		setTo(elem, attrName, htmlFileName);
	}
	
	void setTo(Element elem, string attrName, string htmlFileName)
	{
		this.elem         = elem;
		this.attrName     = attrName;
		this.htmlFileName = htmlFileName;

		auto msg = "Missing attribute '"~attrName~"' on <"~elem.tagName~"> element";
		if(htmlFileName != "")
			msg ~= " (in file '"~htmlFileName~"')";
		
		this.msg = msg;
	}
}

string requireAttribute(Element elem, string name)
{
	auto value = elem.getAttribute(name);
	if(value == "")
		throw new MissingHtmlAttributeException(elem, name);

	return value;
}
