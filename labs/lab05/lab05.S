#include "hardware/regs/addressmap.h"
#include "hardware/regs/m0plus.h"

.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment

.equ    SLEEP_TIME, 500         @ Specify the sleep time (in ms)
.equ    LED_GPIO_PIN, 25        @ Specify the pin that the LED is connected to
.equ    LED_GPIO_OUT, 1         @ Specify the direction of the GPIO pin
.equ    LED_VALUE_ON, 1         @ Specify the value that turns the LED "on"
.equ    LED_VALUE_OFF, 0        @ Specify the value that turns the LED "off"
.equ    SVC_ISR_OFFSET, 0x2C    @ The SVC is entry 11 in the vector table
.equ    SVC_MAX_INSTRS, 0x01    @ Maximum allowed SVC subroutines

@ Entry point to the ASM portion of the program
main_asm:
    bl      init_gpio_led       @ Initialise the GPIO LED pin
    bl      install_svc_isr     @ Install the SVC interrupt service routine
loop:
    svc     #0                  @ Call the SVC ISR with value 0 (turns on LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Short pause before proceeding
    svc     #1                  @ Call the SVC ISR with value 1 (turns off LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Add a short pause before proceeding
    b       loop                @ Always jump back to the start of the loop

@ Subroutine used to introduce a short delay in the application
do_sleep:
    push    {lr}
    ldr     r0, =SLEEP_TIME
    bl      sleep_ms
    pop     {pc}

@ Subroutine used to initialise the PI Pico built-in LED
init_gpio_led:
    push    {lr}
    movs    r0, #LED_GPIO_PIN           @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #LED_GPIO_PIN           @ This value is the GPIO LED pin on the PI PICO board
    movs    r1, #LED_GPIO_OUT           @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    pop     {pc}
@ Subroutine used to install the SVC interrupt service handler
install_svc_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)    @ Load the vector table offset (PPB_BASE + M0PLUS_VTOR_OFFSET) to r2
    ldr     r1, [r2]                                @ Load the value of the vector table offset to r1
    movs    r2, #SVC_ISR_OFFSET                     @ Set the SVC_ISR_OFFSET (SVC handler offset) to r2
    add     r2, r1                                  @ Add the vector table offset to the SVC handler offset
    ldr     r0, =svc_isr                            @ Load the svc_isr address to r0
    str     r0, [r2]                                @ Store the address of svc_isr (interrupt handler) to the vector offset table
    bx      lr                                      @ Return back to the program

@ SVC interrupt service handler routine
.thumb_func                     @ Required for all interrupt service routines
svc_isr:
    push    {lr}                @ Push the address of the subroutine to the stack
    ldr     r0, [sp, #0x1C]     @ Load the content of sp + #0x1C to r0
    subs    r0, #0x2            @ Subtract 2 from sp + #0x1C (PC)
    ldr     r0, [r0]            @ Load the svc number to r0
    ldr     r1, =#0xFF          @ Load the mask to r1
    ands    r0, r1              @ Mask all bits except the 8 rightmost bits in r0
    cmp     r0, #SVC_MAX_INSTRS @ Compare the SVC_MAX_INSTRS (Max svc instruction) to the svc number
    bgt     svc_done            @ Branch to svc_done if svc number is greater than SVC_MAX_INSTRS
    adr     r1, svc_jmptbl      @ Load the address of svc_jmptbl subroutine to r1
    lsls    r0, #2              @ Left shift the content of r0 to obtain the offset
    ldr     r1, [r1, r0]        @ Load the address of the subroutine to r1
    mov     pc, r1              @ Set the subroutine address
svc_done:
    pop     {pc}                @ Pop the stack to return

@ First function of SVC subroutine - turn on the LED
svc_num0:
    movs    r0, #LED_GPIO_PIN
    movs    r1, #LED_VALUE_ON   @ The LED is currently "off" so we want to turn it "on"
    bl      asm_gpio_put        @ Update the the value of the LED GPIO pin (based on value in r1)
    b       svc_done            @ Branch back to the main ISR when done

@ Second function of SVC subroutine - turn off the LED
svc_num1:
    movs    r0, #LED_GPIO_PIN
    movs    r1, #LED_VALUE_OFF  @ The LED is currently "on" so we want to turn it "off"
    bl      asm_gpio_put        @ Update the the value of the LED GPIO pin (based on value in r1)
    b       svc_done            @ Branch back to the main ISR when done

@ SVC function entry jump table.
.align 2
svc_jmptbl:
    .word svc_num0              @ Entry zero goes to SVC function #0.
    .word svc_num1              @ Entry one goes to SVC function #1.
    .word 0                     @ Null termination of the jump table.

@ Set data alignment
.data
    .align 4