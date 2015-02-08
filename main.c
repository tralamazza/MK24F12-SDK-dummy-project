#include <stdio.h>
#include <string.h>

#include "fsl_os_abstraction.h"
#include "fsl_gpio_driver.h"
#include "fsl_port_hal.h"
#include "fsl_clock_manager.h"
#include "fsl_dspi_master_driver.h"

enum {
	PIN_SPI_SLAVE_READY = 10,
	PIN_NRF_RESET = 24,
	PIN_LED = 29,
};

#define BLINK_TASK_STACK_SIZE	512
#define BLINK_TASK_PRIO		10

// SPI0_PCS0 -> PTA 14, 15, 16, 17
// SPI1_PCS0 -> PTE 1, 2, 3, 4
#define SPI_INST 0

enum gpio_pins {
	gpio_pins_LED = GPIO_MAKE_PIN(HW_GPIOA, PIN_LED),
	gpio_pins_NRF_RESET = GPIO_MAKE_PIN(HW_GPIOE, PIN_NRF_RESET),
	gpio_pins_SPI_SLAVE_READY = GPIO_MAKE_PIN(HW_GPIOA, PIN_SPI_SLAVE_READY),
};

const gpio_output_pin_user_config_t outPins[] = {
	{
		.pinName = gpio_pins_LED,
		.config.outputLogic = 1,
		.config.slewRate = kPortSlowSlewRate,
		.config.isOpenDrainEnabled = false,
		.config.driveStrength = kPortLowDriveStrength,
	},
	{
		.pinName = gpio_pins_NRF_RESET,
		.config.outputLogic = 1,
		.config.slewRate = kPortSlowSlewRate,
		.config.isOpenDrainEnabled = false,
		.config.driveStrength = kPortLowDriveStrength,
	},
	{
		.pinName = GPIO_PINS_OUT_OF_RANGE,
	}
};

const gpio_input_pin_user_config_t inputPins[] = {
	{
		.pinName = gpio_pins_SPI_SLAVE_READY,
		.config.isPullEnable = false,
		.config.pullSelect = kPortPullDown,
		.config.isPassiveFilterEnabled = false,
		.config.interrupt = kPortIntRisingEdge,
	},
	{
		.pinName = GPIO_PINS_OUT_OF_RANGE,
	}
};

OSA_TASK_DEFINE(task_blink, BLINK_TASK_STACK_SIZE);

static dspi_master_state_t dspiState;
static dspi_device_t dspiDevice = {
	.dataBusConfig.bitsPerFrame = 8,
	.dataBusConfig.clkPhase = kDspiClockPhase_SecondEdge,
	.dataBusConfig.clkPolarity = kDspiClockPolarity_ActiveHigh,
	.dataBusConfig.direction = kDspiMsbFirst,
	.bitsPerSec = 1000000,
}; // MODE1, 1000kbps, 8bits, MSB first
static uint8_t spiSendBuf[] = { 'b', 'a', 'n', 'a', 'n', 'a' };
static uint8_t spiReceiveBuf[sizeof(spiSendBuf)];

static void
nrf_reset(void)
{
	GPIO_DRV_SetPinDir(gpio_pins_NRF_RESET, kGpioDigitalOutput);
	// drive the pin low for 1 second
	GPIO_DRV_WritePinOutput(gpio_pins_NRF_RESET, 0);
	OSA_TimeDelay(1000);
	GPIO_DRV_WritePinOutput(gpio_pins_NRF_RESET, 1);
	// set it as input otherwise the JLink won't work
	GPIO_DRV_SetPinDir(gpio_pins_NRF_RESET, kGpioDigitalInput);
}

static void
task_blink(task_param_t param)
{
	nrf_reset();
	for (;;) {
		OSA_TimeDelay(1000);
		// printf("blink\n");
		memset(spiReceiveBuf, 0, sizeof(spiReceiveBuf));
		dspi_status_t status = DSPI_DRV_MasterTransferBlocking(SPI_INST,
			NULL,
			spiSendBuf,
			spiReceiveBuf,
			sizeof(spiSendBuf),
			500);
		if (status == kStatus_DSPI_Success) {
			GPIO_DRV_TogglePinOutput(gpio_pins_LED);
		}
	}
}

static void
board_init(void)
{
	/* enable clock for PORTs */
	for (uint8_t i = 0; i < HW_PORT_INSTANCE_COUNT; i++) {
		CLOCK_SYS_EnablePortClock(i);
	}

	GPIO_DRV_Init(inputPins, outPins);
	PORT_HAL_SetMuxMode(PORTA_BASE, PIN_LED, kPortMuxAsGpio);
	PORT_HAL_SetMuxMode(PORTA_BASE, PIN_SPI_SLAVE_READY, kPortMuxAsGpio);
	PORT_HAL_SetMuxMode(PORTE_BASE, PIN_NRF_RESET, kPortMuxAsGpio);

	NVIC_SetPriority(SPI0_IRQn, 4);
	NVIC_SetPriority(SPI1_IRQn, 4);

	// SPI0 ports
	PORT_HAL_SetMuxMode(PORTA_BASE, 14, kPortMuxAlt2);
	PORT_HAL_SetMuxMode(PORTA_BASE, 15, kPortMuxAlt2);
	PORT_HAL_SetMuxMode(PORTA_BASE, 16, kPortMuxAlt2);
	PORT_HAL_SetMuxMode(PORTA_BASE, 17, kPortMuxAlt2);

	// SPI1 ports
	PORT_HAL_SetMuxMode(PORTE_BASE, 1, kPortMuxAlt2); // OUT
	PORT_HAL_SetMuxMode(PORTE_BASE, 2, kPortMuxAlt2); // SCK
	PORT_HAL_SetMuxMode(PORTE_BASE, 3, kPortMuxAlt2); // IN
	PORT_HAL_SetMuxMode(PORTE_BASE, 4, kPortMuxAlt2); // PCS0

	const dspi_master_user_config_t dspiConfig = {
		.isChipSelectContinuous = true,
		.isSckContinuous = false,
		.pcsPolarity = kDspiPcs_ActiveLow,
		.whichCtar = kDspiCtar1,
		.whichPcs = kDspiPcs0,
	};
	DSPI_DRV_MasterInit(SPI_INST, &dspiState, &dspiConfig);
	uint32_t baud_rate, calculatedDelay;
	DSPI_DRV_MasterConfigureBus(SPI_INST, &dspiDevice, &baud_rate);
	/* set a delay between CSN and CLK of at least 7100 ns (NRF-RM section 8.8) */
	DSPI_DRV_MasterSetDelay(SPI_INST, kDspiPcsToSck, 7100, &calculatedDelay);
}

int
main(void)
{
	OSA_Init();
	board_init();

	if (OSA_TaskCreate(task_blink,
		(uint8_t*)"blink",
		BLINK_TASK_STACK_SIZE,
		task_blink_stack,
		BLINK_TASK_PRIO,
		(task_param_t)0,
		false,
		&task_blink_task_handler) == kStatus_OSA_Error) {
		return 1;
	}

	OSA_Start();

	for(;;) {
		/* NOTHING */
	}
}
