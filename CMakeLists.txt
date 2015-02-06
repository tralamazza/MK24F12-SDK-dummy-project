cmake_minimum_required(VERSION 3.0)

project("master firmware test")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Og -g -std=gnu11 -Wall -Werror")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Og -g -std=c++11 -Wall -Werror")

# set(KSDK_VERSION "1.0.0")
set(KSDK_VERSION "1.1.0")

get_filename_component(KSDK_ROOT "~/Freescale/KSDK_${KSDK_VERSION}" ABSOLUTE)

get_filename_component(KSDK_LINKER_SCRIPT "linker/KSDK_${KSDK_VERSION}/MK24FN1M0xxx12_flash.ld" ABSOLUTE)

set(KSDK_DRIVER_MODULES dspi edma flextimer gpio lptmr pit rtc uart)

include("${PROJECT_SOURCE_DIR}/cmake/ksdk_${KSDK_VERSION}.cmake")

add_library(ksdk STATIC ${KSDK_SOURCES})
target_include_directories(ksdk PUBLIC "include" ${KSDK_INCLUDES})
add_definitions(${KSDK_DEFINITIONS} -DCLOCK_SETUP=0)
include_directories("include" ${KSDK_INCLUDES})

add_executable(master main.c)
add_definitions(${KSDK_DEFINITIONS})
target_link_libraries(master ksdk)

set(CMAKE_EXECUTABLE_SUFFIX ".elf")

# we need "--whole-archive" here to import the IRQ handlers
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--whole-archive libksdk.a -Wl,--no-whole-archive")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-T,${KSDK_LINKER_SCRIPT}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker -Map=${PROJECT_BINARY_DIR}/master.map")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker --defsym=__heap_size__=0x30000")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker --defsym=__stack_size__=0x2000")
add_custom_command(TARGET master POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Oihex ${PROJECT_BINARY_DIR}/master.elf ${PROJECT_BINARY_DIR}/master.hex)
add_custom_command(TARGET master POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Obinary ${PROJECT_BINARY_DIR}/master.elf ${PROJECT_BINARY_DIR}/master.bin)

add_custom_target(flash dfu-util -d 15a2:1000 -D ${PROJECT_BINARY_DIR}/master.bin
	DEPENDS master)
add_custom_target(gdbserver JLinkGDBServer -if JTAG -device MK24FN1M0xxx12 -speed auto)
add_custom_target(gdb ${TRIPLET}-gdb master.elf -ex 'target remote :2331')
