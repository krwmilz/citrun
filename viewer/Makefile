PROG = scv_viewer
SRCS = viewer.cpp shader_utils.cpp text.cpp af_unix.cpp

CXX = eg++ -std=c++1y
CXXFLAGS += -I/usr/X11R6/include
CXXFLAGS += -I/usr/X11R6/include/freetype2
CXXFLAGS += -I/usr/X11R6/include/libdrm
CXXFLAGS += -I/usr/local/include

LDFLAGS += -L/usr/local/lib -L/usr/X11R6/lib
LDADD += -lGL -lGLU -lGLEW -lfreetype -lz -lglut

.include <bsd.prog.mk>
