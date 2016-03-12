PROG = scv_viewer
SRCS = viewer.cxx shader_utils.cxx text.cxx af_unix.cxx

CXX = eg++ -std=c++1y
CXXFLAGS += -I/usr/X11R6/include
CXXFLAGS += -I/usr/X11R6/include/freetype2
CXXFLAGS += -I/usr/X11R6/include/libdrm
CXXFLAGS += -I/usr/local/include

LDFLAGS += -L/usr/local/lib -L/usr/X11R6/lib
LDADD += -lGL -lGLU -lGLEW -lfreetype -lz -lglut

.include <bsd.prog.mk>
