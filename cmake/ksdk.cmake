if (WITH_KSDK)
	return()
endif()
set(WITH_KSDK 1)

ENABLE_LANGUAGE(ASM)

if (NOT DEFINED KSDK_ROOT)
	set(KSDK_ROOT ${PROJECT_SOURCE_DIR}/contrib/MK24F12-SDK)
endif()

set(KSDK_DEFINITIONS -DFSL_RTOS_FREE_RTOS)

if (NOT DEFINED KSDK_CHIP)
	set(KSDK_CHIP K24F12)
	set(KSDK_DEFINITIONS ${KSDK_DEFINITIONS} -DCPU_MK24FN1M0VDC12 -D__STACK_SIZE=0x4000 -D__HEAP_SIZE=0x8000)
endif()

set(KSDK_SYSTEM_MODULES hwtimer interrupt power)

if (NOT DEFINED KSDK_HAL_MODULES)
	set(KSDK_HAL_MODULES adc can dac dmamux dspi edma flextimer gpio i2c llwu lptmr mcg osc pdb pit pmc port rcm rtc sai sdhc sim smc uart wdog mpu)
endif()

if (NOT DEFINED KSDK_DRIVER_MODULES)
	set(KSDK_DRIVER_MODULES adc can dac dspi edma flextimer gpio i2c lptmr pdb pit rtc sai sdcard sdhc uart wdog mpu)
endif()

if (NOT DEFINED KSDK_LINKER_SCRIPT)
	set(KSDK_LINKER_SCRIPT ${KSDK_ROOT}/platform/linker/gcc/${KSDK_CHIP}/K24FN1M0xxx12_flash.ld)
endif()

set(KSDK_FREERTOS_ROOT ${KSDK_ROOT}/rtos/FreeRTOS)

set(KSDK_SOURCES_FREERTOS
	${KSDK_FREERTOS_ROOT}/src/heap_1.c
	${KSDK_FREERTOS_ROOT}/src/heap_2.c
	${KSDK_FREERTOS_ROOT}/src/heap_3.c
	${KSDK_FREERTOS_ROOT}/src/heap_4.c
	${KSDK_FREERTOS_ROOT}/src/croutine.c
	${KSDK_FREERTOS_ROOT}/src/event_groups.c
	${KSDK_FREERTOS_ROOT}/src/list.c
	${KSDK_FREERTOS_ROOT}/src/queue.c
	${KSDK_FREERTOS_ROOT}/src/tasks.c
	${KSDK_FREERTOS_ROOT}/src/timers.c
)

set(KSDK_SOURCES
	${KSDK_ROOT}/platform/osa/src/fsl_os_abstraction_free_rtos.c
	${KSDK_SOURCES_FREERTOS}
	${KSDK_FREERTOS_ROOT}/port/gcc/port.c
	${KSDK_FREERTOS_ROOT}/port/gcc/portasm.S
	${KSDK_ROOT}/platform/startup/startup.c
	${KSDK_ROOT}/platform/startup/M${KSDK_CHIP}/system_M${KSDK_CHIP}.c
	${KSDK_ROOT}/platform/startup/M${KSDK_CHIP}/gcc/startup_M${KSDK_CHIP}.S
)

set(KSDK_INCLUDES
	${KSDK_ROOT}/platform/osa
	${KSDK_FREERTOS_ROOT}/include
	${KSDK_FREERTOS_ROOT}/port/gcc
	${KSDK_FREERTOS_ROOT}/config/${KSDK_CHIP}/gcc
	${KSDK_ROOT}/platform/startup/M${KSDK_CHIP}
	${KSDK_ROOT}/platform/utilities
    ${KSDK_ROOT}/platform/CMSIS/Include
    ${KSDK_ROOT}/platform/CMSIS/Include/device
)

# system/clock
set(KSDK_SOURCES_SYSTEM_CLOCK ${KSDK_ROOT}/platform/system/clock)
list(APPEND KSDK_SOURCES
	${KSDK_SOURCES_SYSTEM_CLOCK}/fsl_clock_manager.c
	${KSDK_SOURCES_SYSTEM_CLOCK}/M${KSDK_CHIP}/fsl_clock_${KSDK_CHIP}.c
)
list(APPEND KSDK_INCLUDES
	${KSDK_SOURCES_SYSTEM_CLOCK}
	${KSDK_SOURCES_SYSTEM_CLOCK}/M${KSDK_CHIP}
)

# system
foreach(comp ${KSDK_SYSTEM_MODULES})
	file(GLOB KSDK_SOURCES_SYSTEM_${comp}_src ${KSDK_ROOT}/platform/system/${comp}/src/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_SYSTEM_${comp}_src})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/system/${comp})
endforeach()

# hal
foreach(comp ${KSDK_HAL_MODULES})
	file(GLOB KSDK_SOURCES_HAL_${comp} ${KSDK_ROOT}/platform/hal/${comp}/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_HAL_${comp}})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/hal/${comp})
endforeach()

if (";${KSDK_HAL_MODULES};" MATCHES ";sim;")
	# hal/sim (CPU specific)
	file(GLOB KSDK_SOURCES_HAL_SIM_M${KSDK_CHIP} ${KSDK_ROOT}/platform/hal/sim/M${KSDK_CHIP}/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_HAL_SIM_M${KSDK_CHIP}})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/hal/sim/M${KSDK_CHIP})
endif()

# drivers
foreach(comp ${KSDK_DRIVER_MODULES})
	file(GLOB KSDK_SOURCES_DRIVER_${comp}_ ${KSDK_ROOT}/platform/drivers/${comp}/*.c)
	file(GLOB KSDK_SOURCES_DRIVER_${comp}_src ${KSDK_ROOT}/platform/drivers/${comp}/src/*.c)
	file(GLOB KSDK_SOURCES_DRIVER_${comp}_common ${KSDK_ROOT}/platform/drivers/${comp}/common/*.c)
	list(APPEND KSDK_SOURCES
		${KSDK_SOURCES_DRIVER_${comp}_}
		${KSDK_SOURCES_DRIVER_${comp}_src}
		${KSDK_SOURCES_DRIVER_${comp}_common})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/drivers/${comp})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/drivers/${comp}/common)
endforeach()

if (";${KSDK_DRIVER_MODULES};" MATCHES ";dspi;")
	# drivers/dspi (extra)
	file(GLOB KSDK_SOURCES_DRIVER_dspi_master ${KSDK_ROOT}/platform/drivers/dspi/dspi_master/src/*.c)
	file(GLOB KSDK_SOURCES_DRIVER_dspi_slave ${KSDK_ROOT}/platform/drivers/dspi/dspi_slave/src/*.c)
	list(APPEND KSDK_SOURCES
		${KSDK_SOURCES_DRIVER_dspi_master}
		${KSDK_SOURCES_DRIVER_dspi_slave}
	)
	list(APPEND KSDK_INCLUDES
		${KSDK_ROOT}/platform/drivers/dspi/dspi_master
		${KSDK_ROOT}/platform/drivers/dspi/dspi_slave
	)
endif()

if (";${KSDK_DRIVER_MODULES};" MATCHES ";i2c;")
	# drivers/i2c (extra)
	file(GLOB KSDK_SOURCES_DRIVER_i2c_master ${KSDK_ROOT}/platform/drivers/i2c/i2c_master/src/*.c)
	file(GLOB KSDK_SOURCES_DRIVER_i2c_slave ${KSDK_ROOT}/platform/drivers/i2c/i2c_slave/src/*.c)
	list(APPEND KSDK_SOURCES
		${KSDK_SOURCES_DRIVER_i2c_master}
		${KSDK_SOURCES_DRIVER_i2c_slave}
	)
	list(APPEND KSDK_INCLUDES
		${KSDK_ROOT}/platform/drivers/i2c/i2c_master
		${KSDK_ROOT}/platform/drivers/i2c/i2c_slave
	)
endif()

list(REMOVE_DUPLICATES KSDK_SOURCES)
list(REMOVE_DUPLICATES KSDK_INCLUDES)
