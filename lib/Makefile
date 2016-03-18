LIB = scv
SRCS = runtime.c

SHLIB_MAJOR = 0
SHLIB_MINOR = 0

CFLAGS += -pthread
LDADD += -pthread

# OS X bsdmake squabbles over this
NO_PROFILE = 1
NOPROFILE = 1
.include <bsd.lib.mk>
