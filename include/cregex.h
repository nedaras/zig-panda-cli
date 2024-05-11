#ifndef __CREGEX_H
#define __CREGEX_H

#include <regex.h>
#include <stdalign.h>
#include <stdbool.h>

// zig can not get the size and allign cool!
const size_t sizeof_regex_t = 64;
const size_t alignof_regex_t = 8;

bool isMatch(regex_t* re, const char* input) {
  return regexec(re, input, 0, 0, 0) == 0;
}

void strip(regex_t* regex, const char* input) {
}

#endif
