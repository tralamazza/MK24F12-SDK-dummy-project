#include <stdio.h>
#include "fsl_os_abstraction.h"
#include "fsl_gpio_driver.h"
#include "fsl_port_hal.h"
#include "fsl_clock_manager.h"

#define LED_PIN 		29
#define BLINK_TASK_STACK_SIZE	512
#define BLINK_TASK_PRIO		5

enum gpio_pins {
	gpio_pins_LED = GPIO_MAKE_PIN(HW_GPIOA, LED_PIN)
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
		.pinName = GPIO_PINS_OUT_OF_RANGE,
	}
};

OSA_TASK_DEFINE(task_blink, BLINK_TASK_STACK_SIZE);

static void task_blink(task_param_t param) {
	for (;;) {
		OSA_TimeDelay(1000);
		// printf("blink\n");
		GPIO_DRV_TogglePinOutput(gpio_pins_LED);
	}
}

static void
board_init(void)
{
	/* enable clock for PORTs */
	for (uint8_t i = 0; i < HW_PORT_INSTANCE_COUNT; i++) {
		CLOCK_SYS_EnablePortClock(i);
	}
}

int main (void)
{
	OSA_Init();

	board_init();
	// dbg_uart_init();
	// segger_rtt_init();

	GPIO_DRV_Init(NULL, outPins);
	PORT_HAL_SetMuxMode(PORTA_BASE, LED_PIN, kPortMuxAsGpio);

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

	for(;;) {}
}
