CXXFLAGS += -I/usr/local/include
CXXFLAGS += -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS
CXXFLAGS += -std=c++1y -fno-rtti -g
CXX = eg++

LDLIBS += \
  -lclangFrontendTool -lclangFrontend -lclangDriver \
  -lclangSerialization -lclangCodeGen -lclangParse \
  -lclangSema -lclangStaticAnalyzerFrontend \
  -lclangStaticAnalyzerCheckers -lclangStaticAnalyzerCore \
  -lclangAnalysis -lclangARCMigrate -lclangRewriteCore -lclangRewriteFrontend \
  -lclangEdit -lclangAST -lclangLex -lclangBasic -lclangTooling \
  -lLLVMOption -lLLVMMCParser -lLLVMTransformUtils -lLLVMMC -lLLVMBitReader -lLLVMCore -lLLVMSupport \
  -lpthread -lz

instrument: instrument.cpp

clean:
	rm instrument
