#ifndef __CREGEX_H
#define __CREGEX_H

#include <regex.h>
#include <stdalign.h>

// zig can not get the size cool!
const size_t sizeof_regex_t = 64;
const size_t alignof_regex_t = alignof(regex_t);

#endif
