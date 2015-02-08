# MK24F12 dummy project

## Requirements

	* Freescale Kinetis SDK 1.1.0
	* ARM GCC Embedded

## Building

	mkdir build
	cd build
	cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain.cmake ..
	make

## Flashing

Put the board in DFU mode

	make flash

OR use gdb to load the elf

## Debugging

	make gdbserver
	<another terminal>
	make gdb
