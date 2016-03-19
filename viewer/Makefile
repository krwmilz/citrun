PROG = scv_viewer
SRCS = viewer.cxx text.cxx af_unix.cxx demo-atlas.cxx demo-buffer.cxx
SRCS += demo-font.cxx demo-glstate.cxx demo-shader.cxx demo-view.cxx trackball.c
SRCS += matrix4x4.c

CXXFLAGS += -std=c++11
CXXFLAGS += `pkg-config gl glew freetype2 --cflags`

LDFLAGS += `pkg-config gl glew freetype2 --libs`
LDADD += -lstdc++ -lz -lglut ../glyphy/libglyphy.a

.include <bsd.prog.mk>
