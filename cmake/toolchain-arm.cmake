include(CMakeForceCompiler)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR ARM)

set(TRIPLET arm-none-eabi)

CMAKE_FORCE_C_COMPILER(${TRIPLET}-gcc GNU)
CMAKE_FORCE_CXX_COMPILER(${TRIPLET}-g++ GNU)

set(CMAKE_OBJCOPY ${TRIPLET}-objcopy CACHE INTERNAL "objcopy tool")
set(CMAKE_OBJDUMP ${TRIPLET}-objdump CACHE INTERNAL "objdump tool")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mabi=aapcs -ffunction-sections -fdata-sections -fno-builtin -Wno-main -fplan9-extensions")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mabi=aapcs -ffunction-sections -fdata-sections -fno-builtin -Wno-main -fplan9-extensions")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -fno-rtti -fno-exceptions")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mabi=aapcs -ffunction-sections -fdata-sections -fno-builtin -Wno-main")

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -fwhole-program --specs=nano.specs --specs=nosys.specs -lgcc -Xlinker --defsym=__ram_vector_table__=1")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
