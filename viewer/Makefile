PROG = scv_viewer
SRCS = viewer.cxx text.cxx af_unix.cxx

CXX = eg++
CXXFLAGS += -std=c++11
CXXFLAGS += -I/usr/X11R6/include
CXXFLAGS += -I/usr/X11R6/include/freetype2
CXXFLAGS += -I/usr/X11R6/include/libdrm
CXXFLAGS += -I/usr/local/include

LDFLAGS += -L/usr/local/lib -L/usr/X11R6/lib
LDADD += -lGL -lGLU -lGLEW -lftgl -lz -lglut

.include <bsd.prog.mk>
