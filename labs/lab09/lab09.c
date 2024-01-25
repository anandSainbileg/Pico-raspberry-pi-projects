#include <stdio.h>
#include <stdlib.h>
#include "pico/stdlib.h"
#include "hardware/pio.h"
#include "hardware/clocks.h"
#include "lab09.pio.h"
#include "hardware/adc.h"

#define IS_RGBW true        // Will use RGBW format
#define NUM_PIXELS 1        // There is 1 WS2812 device in the chain
#define WS2812_PIN 28       // The GPIO pin that the WS2812 connected to
#define sleep 500



// Must declare the main assembly entry point before use.
void main_asm();

static inline void put_pixel(uint32_t pixel_grb) {
    pio_sm_put_blocking(pio0, 0, pixel_grb << 8u);
}

static inline uint32_t urgb_u32(uint8_t r, uint8_t g, uint8_t b) {
    return  ((uint32_t) (r) << 8)  |
            ((uint32_t) (g) << 16) |
            (uint32_t) (b);
}

/**
* @brief set_colour
*        Sets the color of a pixel in RGB format.
* @param r Red component of the pixel, range 0-255.
* @param g Green component of the pixel, range 0-255.
* @param b Blue component of the pixel, range 0-255.
* @return void
*/
void set_colour(uint8_t r, uint8_t g, uint8_t b){
    put_pixel(urgb_u32(r, g, b));
}

/**
* @brief read_adc 
*        Read the analog-to-digital converter (ADC) value
*        This function reads the ADC value and prints it to the console.
* @return uint16_t The raw ADC value
*/
uint16_t read_adc() {
    uint16_t raw_adc_value = adc_read();
    // Read the ADC value
    printf("Raw ADC value: %d \n", raw_adc_value);
    return raw_adc_value;
}

/** 
*   @brief convert_raw_adc_value
*          Converts the raw ADC value to temperature in Celsius
*   @param raw The raw ADC value to be converted
*   @return float The temperature in Celsius
*/
float convert_raw_adc_value(int raw) {
    const float conversion = 3.3f / (1 << 12);
    const float voltage_offset = 0.706f;
    const float temperature_offset = 27.0f;
    const float temperature_slope = 1.0f / 0.001721f;

    float voltage = raw * conversion;
    float temperature = temperature_offset - (voltage - voltage_offset) * temperature_slope;

    printf("Temperature: %f Celsius\n", temperature);

    return temperature;
}


   void delay()
   {
    sleep_ms(sleep);
   }

/**
 * @brief LAB #09 - TEMPLATE
 *        Main entry point for the code - calls the main assembly
 *        function where the body of the code is implemented.
 * 
 * @return int      Returns exit-status zero on completion.
 */
int main() {
    stdio_init_all();
    adc_init();
    adc_set_temp_sensor_enabled(true);
    adc_select_input(4);
    //WS2812 code initialization of pio
    PIO pio = pio0;
    uint offset = pio_add_program(pio, &ws2812_program);
    ws2812_program_init(pio, 0, offset, WS2812_PIN, 800000, IS_RGBW);
    main_asm();
    return 0;
}

