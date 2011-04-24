// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

// this must come before the #includes!

#ifndef _WIN32
# define _FILE_OFFSET_BITS 64
#endif

// cross-platform includes

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ** Windows section **

#ifdef _WIN32

// windows-specific includes

# include "targetver.h"

// windows memory leak detection
# define CRTDBG_MAP_ALLOC
# include <crtdbg.h>

// tchar.h

# include <tchar.h>

# include <fcntl.h>
# include <io.h>

# include <Shlobj.h>

// our own cross-platform functions

# define get_config_path		win_get_config_path

// fseek / ftell

typedef __int64		seek_type;
# define ftello		_ftelli64

# define HAVE_SCPRINTF 1

// ** *nix section **

#else

// *nix-specific includes

# include <unistd.h>

# if defined(sun) || defined(__sun)

#  if defined(__SVR4) || defined(__svr4__)

    // WikiMedia Toolserver runs Solaris
#   define HAVE_GOOD_SNPRINTF 1

#  else
#   error SunOS not supported
#  endif

# elif defined(__linux)

   // there's really no guarantee asprintf() exists just coz we're on Linux!
#  define HAVE_ASPRINTF

# endif

// where Windows and *nix function names differ

# define _strdup		strdup

// tchar.h

# define _ftprintf	fprintf
# define _taccess   access
# define _tcscmp     strcmp
# define _tcsdup		strdup
# define _tcsstr         strstr
# define _tfopen     fopen
# define _tmain      main
typedef char		_TCHAR;
# define _T(x)       (x)

// our own cross-platform functions

# define get_config_path unix_get_config_path

// fseek / ftell

typedef off_t		seek_type;

#endif

