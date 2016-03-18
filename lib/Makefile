LIB = scv
SRCS = runtime.c

SHLIB_MAJOR = 0
SHLIB_MINOR = 0

CFLAGS += -pthread

# OS X linker will not do runtime symbol lookup by default
LDFLAGS += -Wl,-U,_node0
LDADD += -pthread

# OS X bsdmake squabbles over this
NO_PROFILE = 1
NOPROFILE = 1
.include <bsd.lib.mk>
