#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"
.syntax unified
.cpu cortex-m0plus
.thumb
.global main_asm
.align 4
.equ DFLT_STATE_STRT, 1 @ Specify the value to start flashing
.equ DFLT_STATE_STOP, 0 @ Specify the value to stop flashing
.equ DFLT_ALARM_TIME, 1000000 @ Specify the default alarm timeout
.equ GPIO_BTN_DN_MSK, 0x00040000 @ Bit-18 for falling-edge event on GP20
.equ GPIO_BTN_EN_MSK, 0x00400000 @ Bit-22 for falling-edge event on GP21
.equ GPIO_BTN_UP_MSK, 0x04000000 @ Bit-26 for falling-edge event on GP22
.equ GPIO_BTN_DN, 20 @ Specify pin for the "down" button
.equ GPIO_BTN_EN, 21 @ Specify pin for the "enter" button
.equ GPIO_BTN_UP, 22 @ Specify pin for the "up" button
.equ GPIO_LED_PIN, 25 @ Specify pin for the built-in LED
.equ GPIO_DIR_IN, 0 @ Specify input direction for a GPIO pin
.equ GPIO_DIR_OUT, 1 @ Specify output direction for a GPIO pin
.equ LED_VAL_ON, 1 @ Specify value that turns the LED "on"
.equ LED_VAL_OFF, 0 @ Specify value that turns the LED "off"
.equ GPIO_ISR_OFFSET, 0x74 @ GPIO is int #13 (vector table entry 29)
.equ ALRM_ISR_OFFSET, 0x40 @ ALARM0 is int #0 (vector table entry 16)
@ Entry point to the ASM portion of the program
main_asm:
    movs    r0, #GPIO_LED_PIN           @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_LED_PIN           @ This value is the GPIO LED pin on the PI PICO board
    movs    r1, #GPIO_DIR_OUT           @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    
    movs    r0, #GPIO_BTN_DN            @ Load the GPIO pin for the down button
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_BTN_DN            @ This value is the GPIO 20 LED pin on the PI PICO board
    movs    r1, #GPIO_DIR_IN            @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    ldr     r0, =GPIO_BTN_DN            @ This value is the GPIO 20 LED pin on the PI PICO board
    bl      asm_gpio_set_irq            @sets up the interrupt request for the pin specified by the value in register "r0"
    
    movs    r0, #GPIO_BTN_EN            @ Load the GPIO pin for the enable button
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_BTN_EN            @ This value is the GPIO 21 LED pin on the PI PICO board
    movs    r1, #GPIO_DIR_IN            @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    ldr     r0, =GPIO_BTN_EN            @ This value is the GPIO 21 LED pin on the PI PICO board
    bl      asm_gpio_set_irq            @sets up the interrupt request for the pin specified by the value in register "r0"

    movs    r0, #GPIO_BTN_UP            @ Load the GPIO pin for the up button
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_BTN_UP            @ This value is the GPIO 22 LED pin on the PI PICO board
    movs    r1, #GPIO_DIR_IN            @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    ldr     r0, =GPIO_BTN_UP            @ This value is the GPIO 22 LED pin on the PI PICO board
    bl      asm_gpio_set_irq            @sets up the interrupt request for the pin specified by the value in register "r0"

    @ install alarm isr
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)        @ Load the vector table by using the (PPB_BASE + M0PLUS_VTOR_OFFSET) register
    ldr     r1, [r2]                                    
    movs    r2, #ALRM_ISR_OFFSET                        @ Set the ALRM_ISR_OFFSET value to r2
    add     r2, r1                                      @ Add the (PPB_BASE + M0PLUS_VTOR_OFFSET) register to ALRM_ISR_OFFSET 
    ldr     r0, =alarm_isr                              
    str     r0, [r2]                                    @ Store the address of alarm_isr (interrupt handler) to the offset in the vector table for ALARM0
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)   @ Stopping the interrupt service (ALARM0 IRQ) by using the correct value and set it to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET) 
    movs    r1, #1
    str     r1, [r2]
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)   @ Starting the interrupt service (ALARM0 IRQ) by using the correct value and set it to (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
    movs    r1, #1
    str     r1, [r2]


    @install gpio isr
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)        @ Load the vector table by using the (PPB_BASE + M0PLUS_VTOR_OFFSET) register
    ldr     r1, [r2]                                    
    movs    r2, #GPIO_ISR_OFFSET                        @ Set the GPIO_ISR_OFFSET value to r2
    add     r2, r1                                      @ Add the (PPB_BASE + M0PLUS_VTOR_OFFSET) register to GPIO_ISR_OFFSET
    ldr     r0, =gpio_isr                               
    str     r0, [r2]                                    @ Store the address of gpio_isr (interrupt handler) to the offset in the vector table for ALARM0 
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)   @ Stopping the interrupt service (ALARM0 IRQ) by using the correct value and set it to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET) 
    movs    r1, #1
    lsls    r1, #13
    str     r1, [r2]
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)   @ Starting the interrupt service (ALARM0 IRQ) by using the correct value and set it to (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
    str     r1, [r2]
main_loop:
    ldr     r0, =ltimer                                   @ Get current timer
    ldr     r0, [r0]                                      
    movs    r1, #1
    ldr     r2, =(TIMER_BASE + TIMER_INTE_OFFSET)       @ Start the timer interrupts using the (TIMER_BASE + TIMER_INTE_OFFSET) register
    str     r1, [r2]
    ldr     r2, =(TIMER_BASE + TIMER_TIMELR_OFFSET)     @ Load the current timer count by using (TIMER_BASE + TIMER_TIMELR_OFFSET) register
    ldr     r1, [r2]
    adds    r0, r1                                      @ Adding a delay for the timer count to start 
    ldr     r2, =(TIMER_BASE + TIMER_ALARM0_OFFSET)   
    str     r0, [r2]                                    @ Add the sum which is the delay to the (TIMER_BASE + TIMER_ALARM0_OFFSET) to set up the delay 
    wfi                                                 @ wfi function waits for an interrupt to occur 
    b     main_loop                                         


sub_toggle:
    push    {lr}                                        @ Store the link register to the stack as we will call nested subroutines
    movs    r0, #GPIO_LED_PIN                           @ Set the LED GPIO pin number to r0 for use by asm_gpio_get
    bl      asm_gpio_get                                @ Get current the value of the LED GPIO pin (returns to r0)
    cmp     r0, #LED_VAL_OFF                            @ Check if the LED GPIO pin value is "off"
    beq     led_set_on                                  @ If it is "off" then then jump code to to turn it on
led_set_off:
    movs    r1, #LED_VAL_OFF                            @ The LED is currently "on" so we want to turn it "off"
    b       led_set_state                               @ Jump to portion of code where we set the state of the LED
led_set_on:
    movs    r1, #LED_VAL_ON                             @ The LED is currently "off" so we want to turn it "on"
led_set_state:
    movs    r0, #GPIO_LED_PIN                           @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
    bl      asm_gpio_put                                @ Update the the value of the LED GPIO pin (based on value in r1)
    pop     {pc}                                        @ Pop the link register from the stack to the program counter

.thumb_func                     @ Required for all interrupt service routines
@ This is the Interrupt Service Routine (ISR) for the ALARM0 timer, which signals an interrupt when it reaches its set time
alarm_isr:                                              @ The alarm interrupt service routine (This interrupt signals the ALARM0 timer which is waiting for an interrupt)
    push    {lr}
    ldr     r2, =TIMER_BASE                             @ Load the TIMER_BASE into r2            
    movs    r1, #1
    str     r1, [r2, #TIMER_INTR_OFFSET]                @ Store the correct value to (TIMER_BASE + TIMER_INTR_OFFSET) to Stop the IRQ from timer 
    ldr     r0, =lstate                                 @ Load the current state of the LED
    ldr     r0, [r0]                        
    cmp     r0, DFLT_STATE_STOP                         @ See if the LED is off   
    bne     blinking_on                                 @ If on then branch to toggle the LED
    ldr     r0, =string
    bl      printf
    pop     {pc}
blinking_on:
    bl      sub_toggle                                  @ toggle the LED light
    pop     {pc}

.thumb_func                     @ Required for all interrupt service routines
@ This is the Interrupt Service Routine (ISR) for a GPIO interrupt. When a GPIO interrupt occurs it will check 
@ which button was pressed by using the vector offset tables and by using AND on the mask to determine.
gpio_isr:                                                           @ The GPIO interrupt service routine (This interrupt signals the GPIO which is waiting for an interrupt)
    push    {lr}
    ldr     r0, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)      @ Read the value of the IO_BANK0_PROC0_INTS2_OFFSET register, which holds the state of the GPIO pins 
    ldr     r0, [r0]
    movs    r1, r0
    ldr     r2, =GPIO_BTN_DN_MSK                                    @ Load the GPIO_BTN_DN_MSK to r2
    ands    r0, r2                                                  @ Perform bitwise AND operation to determine if the GP20 button was pressed 
    cmp     r0, #1                                                  @ Compare it to 1
    beq     gp20_pressed                                            @ If it equals to 1 then we go to the function gp20_pressed to half the interval

    movs    r0, r1
    ldr     r2, =GPIO_BTN_EN_MSK                                    @ Load the GPIO_BTN_EN_MSK to r2
    ands    r0, r2                                                  @ Perform bitwise AND operation to determine if the GP21 button was pressed 
    cmp     r0, #0                                                  @ Compare it to 0
    bne     gp21_pressed                                            @ If it doesn't equal to 1 then we go to the function gp21_pressed to turn on or off the blinking

    movs    r0, r1
    ldr     r2, =GPIO_BTN_UP_MSK                                    @ Load the GPIO_BTN_UP_MSK to r2
    ands    r0, r2                                                  @ Perform bitwise AND operation to determine if the GP22 button was pressed 
    cmp     r0, #0                                                  @ Compare it to 0
    bne     gp22_pressed                                            @ If it doesn't equal to 1 then we go to the function gp22_pressed to double the interval

@ This subroutine will check if the LED is in DFLT_STATE_STRT or DFLT_STATE_STOP state and 
@ if its blinking (DFLT_STATE_STRT) then it will halve the blinking interval and if its not blinking (DFLT_STATE_STOP)
@ then it will reset the interval when the GP20 is pressed.
gp20_pressed:          
    ldr     r0, =gp20
    bl      printf                                             
    ldr     r0, =lstate                                             @ Get the current state of the LED
    ldr     r0, [r0]                                                
    cmp     r0, #DFLT_STATE_STRT                                    @ Compare it to #DFLT_STATE_STRT to check if the LED is blinking or off                          
    bne     end_half_interval                                       @ If it does not equal to #DFLT_STATE_STRT then we branch to end_half_interval and reset the interval
    ldr     r0, =ltimer                                             @ Get the current timer
    ldr     r1, [r0]
    lsrs    r1, #1                                                  @ Half the interval by shifting ltimer to the right by 1
    str     r1, [r0]
    ldr     r1, =GPIO_BTN_DN_MSK
    b       end
end_half_interval:                                                  @ When LED is not blinking
    ldr     r0, =ltimer                                             @ Get the current timer
    ldr     r1, =DFLT_ALARM_TIME                                    @ Load the DFLT_ALARM_TIME to r1
    str     r1, [r0]                                                @ Reset the interval back to default by storing DFLT_ALARM_TIME to the current timer
    ldr     r1, =GPIO_BTN_DN_MSK
    b       end


@ This subroutine will check if the LED is in DFLT_STATE_STOP or DFLT_STATE_STRT which is either blinking or not
@ and will turn the blinking off by setting DFLT_STATE_STOP when it is blinking and will turn the blinking on by setting
@ DFLT_STATE_STRT when it is not blinking when GP21 is pressed.
gp21_pressed:
    ldr     r0, =gp21
    bl      printf
    ldr     r0, =lstate                                             @ Get the current state of the LED
    ldr     r1, [r0]
    cmp     r1, #DFLT_STATE_STOP                                    @ Compare it to #DFLT_STATE_STOP to check if the LED is blinking or off 
    bne     led_on_off                                              @ If it does not equal to #DFLT_STATE_STOP then we branch to led_on_off and stop the blinking
    movs    r1, #DFLT_STATE_STRT                                    @ Else if it equals we set DFLT_STATE_STRT to r1 
    str     r1, [r0]                                                @ Turn on the blinking by storing DFLT_STATE_STRT to r0
    ldr     r1, =GPIO_BTN_EN_MSK
    b       end
led_on_off:                                                         @ When LED is blinking
    movs    r1, #DFLT_STATE_STOP                                    @ If it does not equals to DFLT_STATE_STOP we set r1 to DFLT_STATE_STOP to turn off the blinking 
    str     r1, [r0]                                                @ Turn off the blinking by storing DFLT_STATE_STOP to r0
    ldr     r1, =GPIO_BTN_EN_MSK
    b       end


@ This subroutine will check if the LED is in DFLT_STATE_STRT or DFLT_STATE_STOP state and 
@ if its blinking (DFLT_STATE_STRT) then it will double the blinking interval and if its not blinking (DFLT_STATE_STOP)
@ then it will reset the interval when the GP22 is pressed.
gp22_pressed:
    ldr     r0, =gp22
    bl      printf
    ldr     r0, =lstate                                             @ Get the current state of the LED
    ldr     r0, [r0]
    cmp     r0, #DFLT_STATE_STRT                                    @ Compare it to #DFLT_STATE_STRT to check if the LED is blinking or off 
    bne     end_double_interval                                     @ If it does not equal to #DFLT_STATE_STRT then we branch to end_double_interval and reset the interval
    ldr     r0, =ltimer                                             @ Get the current timer
    ldr     r1, [r0]
    lsls    r1, #1                                                  @ Double the interval by shifting ltimer to the left by 1
    str     r1, [r0]
    ldr     r1, =GPIO_BTN_UP_MSK
    b       end
end_double_interval:                                                @ When LED is not blinking
    ldr     r0, =ltimer                                             @ Get the current timer
    ldr     r1, =DFLT_ALARM_TIME                                    @ Load the DFLT_ALARM_TIME to r1
    str     r1, [r0]                                                @ Reset the interval back to default by storing DFLT_ALARM_TIME to the current timer
    ldr     r1, =GPIO_BTN_UP_MSK
    b       end

end:
    ldr     r0, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)            
    str     r1, [r0]                                                @ Get back to the program by storing r1 to the value of (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET) 
    pop     {pc}

.align 4
msg: .asciz "Hello World!\n"
string: .asciz "Alarm event\n"
gp20: .asciz "GP20 pressed\n"
gp21: .asciz "GP21 pressed\n"
gp22: .asciz "GP22 pressed\n"
.data
lstate: .word DFLT_STATE_STRT
ltimer: .word DFLT_ALARM_TIME
