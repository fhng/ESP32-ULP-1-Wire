/* ULP Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include <stdio.h>
#include "esp_sleep.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "soc/soc.h"
#include "soc/rtc_io_reg.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp32/ulp.h"
#include "ulp_main.h"

RTC_DATA_ATTR static int counter; 

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

gpio_num_t one_wire_port = GPIO_NUM_32;

static void init_ulp_program();

void app_main()
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        printf("Not ULP wakeup, initializing ULP\n");
        init_ulp_program();
    } else {
	counter++;
	float temperatureC = 0.0;
	float temperatureF = 0.0;
	temperatureC = ulp_temperatureC & UINT16_MAX;
	temperatureF = ulp_temperatureF & UINT16_MAX;
	printf("<<<<<< Result: %d >>>>>>\n",counter);
	//printf("---- Extra_Hold --------- 0x%x\n", ulp_temperatureC & UINT16_MAX);
	printf("----- Temperature in C ----- %.2f\n", temperatureC /16 );
	printf("----- Temperature in F ----- %.2f\n", (temperatureF /16) *1.8 +32);
	printf("----- CRC8 Scratchpad value ---- 0x%x\n", ulp_crc8_value & UINT16_MAX);
	printf("----- CRC8 Checked result ---- 0x%x\n", ulp_crc8_check & UINT16_MAX);
	//return;
    }

    printf("Entering deep sleep\n\n");
    ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup());
    //ESP_ERROR_CHECK( ulp_run((&ulp_entry - RTC_SLOW_MEM) / sizeof(uint32_t)));

    esp_deep_sleep_start();
}

static void init_ulp_program()
{
    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    /* Initialize some variables used by ULP program.
     * Each 'ulp_xyz' variable corresponds to 'xyz' variable in the ULP program.
     * These variables are declared in an auto generated header file,
     * 'ulp_main.h', name of this file is defined in component.mk as ULP_APP_NAME.
     * These variables are located in RTC_SLOW_MEM and can be accessed both by the
     * ULP and the main CPUs.
     *
     * Note that the ULP reads only the lower 16 bits of these variables.
     */

    counter = 0;
    
    rtc_gpio_init(one_wire_port);
    // ESP-IDF has an typo error on RTC_GPIO_MODE_INPUT_OUTUT, missing P, fixed
    // Open drain mode(1-wire/ I2C), should get it to INPUT_ONLY
    rtc_gpio_set_direction(one_wire_port, RTC_GPIO_MODE_INPUT_ONLY);

    // If set RTC_GPIO_MODE_INPUT_OUTPUT pulldown and pullup won't matter 
    // so, right now, using RTC_GPIO_MODE_INPUT_ONLY for button
    // rtc_gpio_set_direction(one_wire_port, RTC_GPIO_MODE_INPUT_OUTPUT);
    //rtc_gpio_pulldown_dis(one_wire_port);
    //rtc_gpio_pullup_en(one_wire_port);
    //rtc_gpio_hold_en(one_wire_port);

    //rtc_gpio_output_enable(one_wire_port);
    //rtc_gpio_input_enable(one_wire_port);

    /* Set ULP wake up period to T = 20ms (3095 cycles of RTC_SLOW_CLK clock).
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    //REG_SET_FIELD(SENS_ULP_CP_SLEEP_CYC0_REG, SENS_SLEEP_CYCLES_S0, 3095);
    REG_SET_FIELD(SENS_ULP_CP_SLEEP_CYC0_REG, SENS_SLEEP_CYCLES_S0, 150000);

    /* Start the program */
    err = ulp_run((&ulp_entry - RTC_SLOW_MEM) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);
}

