.ifdef SCV_PATH
error_SCV_PATH
.endif

CXXFLAGS += -I/usr/X11R6/include
CXXFLAGS += -I/usr/X11R6/include/freetype2
CXXFLAGS += -I/usr/X11R6/include/libdrm
CXXFLAGS += -I/usr/local/include
LDLIBS += -L/usr/local/lib -L/usr/X11R6/lib -lGL -lGLU -lGLEW
LDLIBS += -lfreetype -lz -lglut
CXX = eg++ -std=c++1y

BIN = viewer
SRCS = viewer.cpp shader_utils.cpp text.cpp af_unix.cpp
OBJS = $(SRCS:cpp=o)

$(BIN): $(OBJS)
	$(CXX) -o $(BIN) $(LDLIBS) $(OBJS)

clean:
	rm -f $(OBJS) $(BIN)

depend:
	mkdep $(CXXFLAGS) $(SRCS)
