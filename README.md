# MK24F12 dummy project

	mkdir build
	cd build
	cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain.cmake ..
	make
	make flash
	make gdbserver
	<another terminal>
	make gdb

