/**
 * Windows stuff.
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

module ae.sys.windows;

import std.string;
import std.utf;

import win32.windows;

class WindowsException : Exception { private this(string msg) { super(msg); } }

T wenforce(T)(T cond, string str=null)
{
	if (cond)
		return cond;

	auto code = GetLastError();

	wchar *lpMsgBuf = null;
	FormatMessageW(
		FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
		null,
		code,
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		cast(LPWSTR)&lpMsgBuf,
		0,
		null);

	auto message = toUTF8(lpMsgBuf[0..wcslen(lpMsgBuf)]);
	if (lpMsgBuf)
		LocalFree(lpMsgBuf);

	message = strip(message);
	message ~= format(" (error %d)", code);
	if (str)
		message = str ~ ": " ~ message;
	throw new WindowsException(message);
}
