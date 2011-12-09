// SemiTwist Library
// Written in the D programming language.

module semitwist.util.container;

import semitwist.util.all;

final class Stack(T)
{
	private T[] data;
	@property size_t capacity()
	{
		return data.length;
	}
	private size_t _length=0;
	@property size_t length()
	{
		return _length;
	}
	
	this(size_t initialCapacity=1024)
	{
		data.length = initialCapacity;
	}
	
	private this(Stack!T s)
	{
		data = s.data.dup;
		_length = s._length;
	}
	
	ref T opIndex(size_t i)
	{
		debug if(i >= _length)
			throw new Exception("Invalid index");
		
		return data[i];
	}
	
	T[] opSlice(size_t a, size_t b)
	{
		debug if(a >= _length || b > _length)
			throw new Exception("Invalid index");
		
		return data[a..b];
	}
	
	private void expand()
	{
		size_t numMore = data.length;
		if(numMore == 0)
			numMore = 1;
		data.length += numMore;
	}
	
	void clear()
	{
		_length = 0;
		data.clear();
	}
	
	void opOpAssign(string op)(T item) if(op=="~")
	{
		if(_length == data.length)
			expand();

		data[_length] = item;
		_length++;
	}
	
	void opOpAssign(string op)(T[] items) if(op=="~")
	{
		while(_length + items.length >= data.length)
			expand();

		data[ _length .. _length + items.length ] = items;
		_length += items.length;
	}
	
	void pop(size_t num=1)
	{
		debug if(num > _length)
			throw new Exception("Invalid index");
			
		_length -= num;
	}
	
	@property ref T top()
	{
		return data[_length-1];
	}
	
	@property bool empty()
	{
		return _length == 0;
	}
	
	void compact()
	{
		data.length = _length;
	}
	
	@property Stack!T dup()
	{
		return new Stack!T(this);
	}
	
	int opApply(int delegate(ref T) dg)
	{
		int result = 0;
		foreach(ref T item; data[0.._length])
		{
			result = dg(item);
			if(result)
				break;
		}
		return result;
	}
	
	int opApply(int delegate(ref size_t, ref T) dg)
	{
		int result = 0;
		foreach(size_t i, ref T item; data[0.._length])
		{
			result = dg(i, item);
			if(result)
				break;
		}
		return result;
	}
}
