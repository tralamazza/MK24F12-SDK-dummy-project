if (NOT DEFINED KSDK_ROOT)
	MESSAGE(FATAL_ERROR "You MUST set KSDK_ROOT")
endif()

if (WITH_KSDK)
	return()
endif()
set(WITH_KSDK 1)

ENABLE_LANGUAGE(ASM)

set(KSDK_DEFINITIONS -DFSL_RTOS_FREE_RTOS)

if (NOT DEFINED KSDK_CHIP)
	set(KSDK_CHIP K24F12)
	set(KSDK_DEFINITIONS ${KSDK_DEFINITIONS} -DCPU_MK24FN1M0VDC12 -D__STACK_SIZE=0x2000 -D__HEAP_SIZE=0x30000)
endif()

set(KSDK_SYSTEM_MODULES clock hwtimer interrupt power)

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
	${KSDK_FREERTOS_ROOT}/port/gcc/port.c
	${KSDK_FREERTOS_ROOT}/port/gcc/portasm.S
)

set(KSDK_SOURCES
	${KSDK_ROOT}/platform/osa/src/fsl_os_abstraction_free_rtos.c
	${KSDK_SOURCES_FREERTOS}
	${KSDK_ROOT}/platform/startup/startup.c
	${KSDK_ROOT}/platform/startup/M${KSDK_CHIP}/system_M${KSDK_CHIP}.c
	${KSDK_ROOT}/platform/startup/M${KSDK_CHIP}/gcc/startup_M${KSDK_CHIP}.S
)

set(KSDK_INCLUDES
	${KSDK_ROOT}/platform/osa/inc
	${KSDK_FREERTOS_ROOT}/include
	${KSDK_FREERTOS_ROOT}/port/gcc
	${KSDK_FREERTOS_ROOT}/config/${KSDK_CHIP}/gcc
	${KSDK_ROOT}/platform/startup
	${KSDK_ROOT}/platform/startup/M${KSDK_CHIP}
	${KSDK_ROOT}/platform/utilities/inc
    ${KSDK_ROOT}/platform/CMSIS/Include
    ${KSDK_ROOT}/platform/CMSIS/Include/device
    ${KSDK_ROOT}/platform/system/inc
    ${KSDK_ROOT}/platform/hal/inc
    ${KSDK_ROOT}/platform/drivers/inc
)

# system/clock
set(KSDK_SOURCES_SYSTEM_CLOCK ${KSDK_ROOT}/platform/system/src/clock)
list(APPEND KSDK_SOURCES ${KSDK_SOURCES_SYSTEM_CLOCK}/M${KSDK_CHIP}/fsl_clock_M${KSDK_CHIP}.c)
list(APPEND KSDK_INCLUDES ${KSDK_SOURCES_SYSTEM_CLOCK}/M${KSDK_CHIP})

# system
foreach(comp ${KSDK_SYSTEM_MODULES})
	file(GLOB KSDK_SOURCES_SYSTEM_${comp}_src ${KSDK_ROOT}/platform/system/src/${comp}/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_SYSTEM_${comp}_src})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/system/${comp})
endforeach()

# hal/sim
if (";${KSDK_HAL_MODULES};" MATCHES ";sim;")
	file(GLOB KSDK_SOURCES_HAL_SIM_M${KSDK_CHIP} ${KSDK_ROOT}/platform/hal/src/sim/M${KSDK_CHIP}/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_HAL_SIM_M${KSDK_CHIP}})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/hal/sim/src/M${KSDK_CHIP})
endif()

# hal
foreach(comp ${KSDK_HAL_MODULES})
	file(GLOB KSDK_SOURCES_HAL_${comp} ${KSDK_ROOT}/platform/hal/src/${comp}/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_HAL_${comp}})
endforeach()

# drivers/dspi
if (";${KSDK_DRIVER_MODULES};" MATCHES ";dspi;")
	set(KSDK_SOURCES_DRIVER_dspi ${KSDK_ROOT}/platform/drivers/src/dspi)
	list(APPEND KSDK_SOURCES
		${KSDK_SOURCES_DRIVER_dspi}/fsl_dspi_common.c
		${KSDK_SOURCES_DRIVER_dspi}/fsl_dspi_irq.c
		${KSDK_SOURCES_DRIVER_dspi}/fsl_dspi_master_driver.c
		${KSDK_SOURCES_DRIVER_dspi}/fsl_dspi_shared_function.c
		${KSDK_SOURCES_DRIVER_dspi}/fsl_dspi_slave_driver.c)
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/drivers/src/${comp})
	list(REMOVE_ITEM KSDK_DRIVER_MODULES "dspi")
endif()

# drivers
foreach(comp ${KSDK_DRIVER_MODULES})
	file(GLOB KSDK_SOURCES_DRIVER_${comp} ${KSDK_ROOT}/platform/drivers/src/${comp}/*.c)
	list(APPEND KSDK_SOURCES ${KSDK_SOURCES_DRIVER_${comp}})
	list(APPEND KSDK_INCLUDES ${KSDK_ROOT}/platform/drivers/src/${comp})
endforeach()

list(REMOVE_DUPLICATES KSDK_SOURCES)
list(REMOVE_DUPLICATES KSDK_INCLUDES)
