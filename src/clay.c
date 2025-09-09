#define CLAY_IMPLEMENTATION
#include "clay/clay.h"

// Clay_Context* context;

// Clay_String Clay__InternString(Clay_String string) {
//     if (Clay__dynamicStringData.length + string.length > Clay__dynamicStringData.capacity)
//     {
//         return CLAY_STRING("OOM");
//     }

//     char *chars = (char *)(Clay__dynamicStringData.internalArray + Clay__dynamicStringData.length);
//     memcpy(chars, string.chars, string.length);
//     Clay__dynamicStringData.length += string.length;
//     return CLAY__INIT(Clay_String) { .length = string.length, .chars = chars };
// }
