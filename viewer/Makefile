CXXFLAGS += -I/usr/X11R6/include
CXXFLAGS += -I/usr/X11R6/include/freetype2
CXXFLAGS += -I/usr/X11R6/include/libdrm
CXXFLAGS += -I/usr/local/include
LDLIBS += -L/usr/local/lib -L/usr/X11R6/lib -lGL -lGLU -lGLEW
LDLIBS += -lfreetype -lz -lglut
CXX = eg++ -std=c++1y

BIN = viewer
SRCS = viewer.cpp shader_utils.cpp text.cpp
OBJS = $(SRCS:cpp=o)

$(BIN): $(OBJS)
	$(CXX) -o $(BIN) $(LDLIBS) $(OBJS)

clean:
	rm $(OBJS) $(BIN)

depend:
	mkdep $(CXXFLAGS) $(SRCS)
