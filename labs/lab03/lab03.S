.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment

.equ    SLEEP_TIME, 10         @ Specify the amount of ms that we want to sleep for in the loop
.equ    LED_GPIO_PIN, 25        @ Specifiy the physical GPIO pin that the LED is connected to
.equ    LED_GPIO_OUT, 1         @ Specify the direction that we want to set the GPIO pin to
.equ    LED_VALUE_ON, 1         @ Specify the value that turns the LED "on"
.equ    LED_VALUE_OFF, 0        @ Specify the value that turns the LED "off"
.equ    BUTTON_PIN, 21
.equ    BUTTON_STATE, 0


@ Entry point to the ASM portion of the program
main_asm:
    movs    r0, #LED_GPIO_PIN           @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #LED_GPIO_PIN           @ This value is the GPIO LED pin on the PI PICO board
    movs    r1, #LED_GPIO_OUT           @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    movs    r0, #BUTTON_PIN             @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #BUTTON_PIN             @ This value is the GPIO BUTTON pin on the PI PICO board
    movs    r1, #BUTTON_STATE           @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    movs    r0, #BUTTON_PIN             @ This value is the GPIO BUTTON pin on the PI PICO board    
    bl      asm_gpio_get                @ Get current the value of the BUTTON GPIO pin (returns to r0)
    
loop:
    movs    r4, r0                      @ Save previous state of the button PIN (either 1 or 0)
    ldr     r0, =SLEEP_TIME             @ Set the value of SLEEP_TIME we want to wait for
    bl      sleep_ms                    @ Sleep until SLEEP_TIME has elapsed then toggle the LED GPIO pin
    movs    r0, #BUTTON_PIN             @ This value is the GPIO BUTTON pin on the PI PICO board      
    bl      asm_gpio_get                @ Get current the value of the BUTTON GPIO pin (current state)  
    cmp     r4, #0                      @ Compare the previous state with 0 to see if the button was pressed (0 if pressed)
    bne     loop                        @ If previous state does not equal 0 then repeat loop (to wait for the LED to turn on or off until button is pressed)
    cmp     r0, #1                      @ Compare the previous state with 1 to see if the button was released (1 after 0 if pressed)
    bne     loop                        @ If current state does not equal 0 then repeat loop (to wait for the LED to turn on or off until button is pressed)   
    bl      sub_toggle                  @ If current state equals to 1 and previous state equals to 0 then it means that the button has been pressed and released
    bl      loop                        @ Repeat the loop to keep the LED on or off until the next button press.
                     
    
@ Subroutine to toggle the LED GPIO pin value
sub_toggle:
    push    {lr}                       @ Store the link register to the stack as we will call nested subroutines
    movs    r0, #LED_GPIO_PIN           @ Set the LED GPIO pin number to r0 for use by asm_gpio_get
    bl      asm_gpio_get                @ Get current the value of the LED GPIO pin (returns to r0)
    cmp     r0, #LED_VALUE_OFF          @ Check if the LED GPIO pin value is "off"
    beq     led_set_on                  @ If it is "off" then then jump code to to turn it on
led_set_off:
    movs    r1, #LED_VALUE_OFF          @ The LED is currently "on" so we want to turn it "off"
    b       led_set_state               @ Jump to portion of code where we set the state of the LED
led_set_on:
    movs    r1, #LED_VALUE_ON           @ The LED is currently "off" so we want to turn it "on"
led_set_state:
    movs    r0, #LED_GPIO_PIN           @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
    bl      asm_gpio_put                @ Update the the value of the LED GPIO pin (based on value in r1)
    pop     {pc}                        @ Pop the link register from the stack to the program counter


@ Set data alignment
.data
    .align 4
