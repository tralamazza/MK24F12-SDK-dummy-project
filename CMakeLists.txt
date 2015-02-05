cmake_minimum_required(VERSION 3.0)

project("master firmware test")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Os -g -std=gnu11 -Wall -Werror -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Os -g -std=c++11 -Wall -Werror -ffunction-sections -fdata-sections")

get_filename_component(KSDK_ROOT "../MK24F12-SDK" ABSOLUTE)

include(${PROJECT_SOURCE_DIR}/cmake/ksdk.cmake)

add_library(ksdk STATIC ${KSDK_SOURCES})
target_include_directories(ksdk PUBLIC ${KSDK_INCLUDES})
add_definitions(${KSDK_DEFINITIONS})
include_directories(${KSDK_INCLUDES})

add_executable(master main.c)
add_definitions(${KSDK_DEFINITIONS})
target_link_libraries(master ksdk)

set(CMAKE_EXECUTABLE_SUFFIX ".elf")

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-T,${KSDK_LINKER_SCRIPT}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker -Map=${PROJECT_BINARY_DIR}/master.map")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker --defsym=__heap_size__=0x8000")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Xlinker --defsym=__stack_size__=0x4000")
add_custom_command(TARGET master POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Oihex ${PROJECT_BINARY_DIR}/master.elf ${PROJECT_BINARY_DIR}/master.hex)
add_custom_command(TARGET master POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Obinary ${PROJECT_BINARY_DIR}/master.elf ${PROJECT_BINARY_DIR}/master.bin)

add_custom_target(flash dfu-util -d 15a2:1000 -D ${PROJECT_BINARY_DIR}/master.bin)
add_custom_target(gdbserver JLinkGDBServer -if SWD)
add_custom_target(gdb ${TRIPLET}-gdb master.elf -ex 'target extended-remote :2331')
