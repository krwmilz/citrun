SUBDIRS = instrument runtime viewer

all: make_subdirs

test: make_subdirs
	@sh run_tests.sh

clean:
	make -C instrument clean
	make -C runtime clean
	make -C viewer clean

make_subdirs:
	@make -C instrument
	@make -C runtime
	@make -C viewer
