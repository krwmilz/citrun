CXXFLAGS += -I/usr/local/include
CXXFLAGS += -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS
CXXFLAGS += -fno-rtti -g
CXX = eg++ -std=c++1y

# clang has a circular dependencies here, use "linker group options" to avoid
LDLIBS += \
	-Wl,--start-group \
	-lclangAST \
	-lclangAnalysis \
	-lclangBasic \
	-lclangDriver \
	-lclangEdit \
	-lclangFrontend \
	-lclangFrontendTool \
	-lclangLex \
	-lclangParse \
	-lclangRewriteCore \
	-lclangRewriteFrontend \
	-lclangSema \
	-lclangSerialization \
	-lclangTooling \
	-Wl,--end-group \
	-lLLVMOption \
	-lLLVMMCParser \
	-lLLVMTransformUtils \
	-lLLVMMC \
	-lLLVMBitReader \
	-lLLVMCore \
	-lLLVMSupport \
	-lpthread -lz

BIN = instrument
SRCS = instrument.cpp
OBJS = $(SRCS:cpp=o)

$(BIN): $(OBJS)
	$(CXX) -o $(BIN) -L/usr/local/lib $(OBJS) $(LDLIBS)

clean:
	rm -f $(BIN) $(OBJS)

depend:
	mkdep $(CXXFLAGS) $(SRCS)
