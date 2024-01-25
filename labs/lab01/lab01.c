#include "pico/stdlib.h"

/**
 * @brief TOGGLE
 *        Takes the LED pin (LED_PIN) number and the delay (LED_DELAY)
 *        as parameters in milliseconds. The subroutine turns the 
 *        LED on and off for LED_DELAY milliseconds.
 */

 void TOGGLE(const uint LED_PIN, const uint LED_DELAY) {
    //Turning the LED on
    gpio_put(LED_PIN, 1); 
    //Sleep delay
    sleep_ms(LED_DELAY);

    //Turning the LED off
    gpio_put(LED_PIN, 0);
    //Sleep delay
    sleep_ms(LED_DELAY);
}
/**
* @brief Main
 *        Initialzes the constants PIN number and the sleep delay 
 *        and sets up the LED pin as an output then enters
 *        an infinite while loop that toggles the LED.
 * 
 * @return int  Application return code (zero for success).
 */

int main() {

    // Specify the PIN number and sleep delay
    const uint LED_PIN   =  25;
    const uint LED_DELAY = 500;

    // Setup the LED pin as an output.
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    // Do forever...
    while (true) {
        TOGGLE(LED_PIN, LED_DELAY);
    }
    return 0;
}



