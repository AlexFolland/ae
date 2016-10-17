﻿/**
 * Simple (ASCII-only) text-processing functions,
 * for speed and CTFE.
 *
 * License:
 *   This Source Code Form is subject to the terms of
 *   the Mozilla Public License, v. 2.0. If a copy of
 *   the MPL was not distributed with this file, You
 *   can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Authors:
 *   Vladimir Panteleev <vladimir@thecybershadow.net>
 */

module ae.utils.text.ascii;

import std.algorithm : max;
import std.exception : assumeUnique;
import std.traits : Unqual, isSigned;

// ************************************************************************

/// Semantic alias for an array of immutable bytes containing some
/// ASCII-based 8-bit character encoding. Might be UTF-8, but not
/// necessarily - thus, is a semantic superset of the D "string" alias.
alias string ascii;

// ************************************************************************

/// Maximum number of characters needed to fit the decimal
/// representation of any number of this basic integer type.
template DecimalSize(T : ulong)
{
	static if (is(T == ubyte))
		enum DecimalSize = 3;
	else
	static if (is(T == byte))
		enum DecimalSize = 4;
	else
	static if (is(T == ushort))
		enum DecimalSize = 5;
	else
	static if (is(T == short))
		enum DecimalSize = 6;
	else
	static if (is(T == uint))
		enum DecimalSize = 10;
	else
	static if (is(T == int))
		enum DecimalSize = 11;
	else
	static if (is(T == ulong))
		enum DecimalSize = 20;
	else
	static if (is(T == long))
		enum DecimalSize = 20;
	else
		static assert(false, "Unknown type for DecimalSize");
}

unittest
{
	template DecimalSize2(T : ulong)
	{
		import std.conv : text;
		enum DecimalSize2 = max(text(T.min).length, text(T.max).length);
	}

	static assert(DecimalSize!ubyte == DecimalSize2!ubyte);
	static assert(DecimalSize!byte == DecimalSize2!byte);
	static assert(DecimalSize!ushort == DecimalSize2!ushort);
	static assert(DecimalSize!short == DecimalSize2!short);
	static assert(DecimalSize!uint == DecimalSize2!uint);
	static assert(DecimalSize!int == DecimalSize2!int);
	static assert(DecimalSize!ulong == DecimalSize2!ulong);
	static assert(DecimalSize!long == DecimalSize2!long);
}

/// Writes n as decimal number to buf (right-aligned), returns slice of buf containing result.
char[] toDec(N : ulong, size_t U)(N o, ref char[U] buf)
{
	static assert(U >= DecimalSize!N, "Buffer too small to fit any " ~ N.stringof ~ " value");

	Unqual!N n = o;
	char* p = buf.ptr+buf.length;

	if (isSigned!N && n<0)
	{
		do
		{
			*--p = '0' - n%10;
			n = n/10;
		} while (n);
		*--p = '-';
	}
	else
		do
		{
			*--p = '0' + n%10;
			n = n/10;
		} while (n);

	return p[0 .. buf.ptr + buf.length - p];
}

/// CTFE-friendly variant.
char[] toDecCTFE(N : ulong, size_t U)(N o, ref char[U] buf)
{
	static assert(U >= DecimalSize!N, "Buffer too small to fit any " ~ N.stringof ~ " value");

	Unqual!N n = o;
	size_t p = buf.length;

	if (isSigned!N && n<0)
	{
		do
		{
			buf[--p] = '0' - n%10;
			n = n/10;
		} while (n);
		buf[--p] = '-';
	}
	else
		do
		{
			buf[--p] = '0' + n%10;
			n = n/10;
		} while (n);

	return buf[p..$];
}

/// Basic integer-to-string conversion.
string toDec(T : ulong)(T n)
{
	if (__ctfe)
	{
		char[DecimalSize!T] buf;
		return toDecCTFE(n, buf).idup;
	}
	else
	{
		static struct Buf { char[DecimalSize!T] buf; } // Can't put static array on heap, use struct
		return assumeUnique(toDec(n, (new Buf).buf));
	}
}

unittest
{
	import std.conv : to;
	assert(toDec(42) == "42");
	assert(toDec(int.min) == int.min.to!string());
	static assert(toDec(42) == "42", toDec(42));
}

/// Print an unsigned integer as a zero-padded, right-aligned decimal number into a buffer
void toDecFixed(N : ulong, size_t U)(N n, ref char[U] buf)
	if (!isSigned!N)
{
	import std.meta : Reverse;
	import ae.utils.meta : RangeTuple;

	// TODO: get rid of pow
	assert(n < 10^^U, "Number too large");

	foreach (i; Reverse!(RangeTuple!U))
	{
		buf[i] = cast(char)('0' + (n % 10));
		n /= 10;
	}
}

/// ditto
char[U] toDecFixed(size_t U, N : ulong)(N n)
	if (!isSigned!N)
{
	char[U] buf;
	toDecFixed(n, buf);
	return buf;
}

unittest
{
	assert(toDecFixed!6(12345u) == "012345");
}
