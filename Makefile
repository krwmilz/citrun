CXXFLAGS += -I/usr/local/include
CXXFLAGS += -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS
CXXFLAGS += -std=c++1y -fno-rtti -g
CXX = eg++

LDLIBS += \
  -lclangFrontend -lclangDriver -lclangSerialization -lclangParse \
  -lclangSema -lclangAnalysis -lclangRewriteCore -lclangRewriteFrontend \
  -lclangEdit -lclangAST -lclangLex -lclangBasic -lclangTooling \
  -lLLVMOption -lLLVMMCParser -lLLVMTransformUtils -lLLVMMC -lLLVMBitReader \
  -lLLVMCore -lLLVMSupport \
  -lpthread -lz

instrument: instrument.cpp

test: instrument
	sh run_tests.sh

clean:
	rm instrument
