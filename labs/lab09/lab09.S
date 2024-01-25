#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified
.cpu    cortex-m0plus
.thumb
.global main_asm
.align  4

.equ    DFLT_state_STRT, 1          @ Default state when program starts
.equ    DFLT_state_STOP, 0          @ Default state when program stops
.equ    GPIO_DIR_IN,   0            @ GPIO input direction
.equ    GPIO_DIR_OUT,  1            @ GPIO output direction
.equ    LED_VAL_ON,    1            @ LED on value
.equ    LED_VAL_OFF,   0            @ LED off value
.equ    DFLT_state_STRT,1           @ Default state when program starts
.equ    DFLT_ALARM_TIME,1000000     @ Default alarm time
.equ    COLOR_ONE, 0X3D             @ RGB color 1
.equ    COLOR_TWO, 0X1D             @ RGB color 2
.equ    GPIO_ISR_OFFSET, 0x74       @ GPIO interrupt service routine offset
.equ    ALRM_ISR_OFFSET, 0x40       @ Timer alarm interrupt service routine offset

main_asm:
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
    bl      read_adc

temperature:                     
    @ Set LED color to COLOR_ONE if temperature is less than or equal to 10
    movs     r0, #0X00
    movs     r1, COLOR_ONE      
    movs     r2, #0X00
    bl       set_colour
    @ Jump to end_loop
    b        end

high_temperature:
    @ Set LED color to red (255, 165, 0) for high temperature
    movs     r0, #255
    movs     r1, #165           
    movs     r2, #0X00
    bl       set_colour
    @ Jump to end_loop
    b        end
while:
    @ Load address of lstate into r2
    ldr     r2, =lstate             
    @ Load value of lstate into r0 and convert it to temperature value
    ldr     r0, [r2]                 
    bl      convert_raw_adc_value 
    @ Store the converted temperature value in r3
    movs    r3, r0                      

    @ Compare r3 to 10, if less than or equal to 10, jump to temperature
    movs     r1, #10  
    cmp      r3, r1
    ble      temperature   
    @ Compare r3 to 10 again, if less than or equal to 10, jump to high_temperature
    movs     r1, #10
    cmp      r3, r1
    ble      high_temperature    
    @ Set LED color to COLOR_TWO if temperature is higher than 10
    movs     r0, COLOR_TWO
    movs     r1, #0X00             
    movs     r2, #0X00
    bl       set_colour
    @ Jump to end_loop
    b        end

end:   
    @ Call delay function
    bl       delay
    @ Jump back to loop label
    b        while
.thumb_func
timer_isr:
    @ Save registers r0-r5 and lr on the stack
    push    {r0-r5,lr}
    @ Call read_adc function
    bl      read_adc
    @ Load address of lstate into r1 and store the converted ADC value in lstate
    ldr     r1, =lstate    
    str     r0, [r1]   


























    
                
end_alarm:
   @ Load address of TIMER_INTR_OFFSET into r5 and enable timer interrupt
    ldr     r5, =(TIMER_BASE+TIMER_INTR_OFFSET)
    ldr     r0, [r5]       
    ldr     r1, =0X00000001 
    orrs    r0, r1, r0      
    str     r0, [r5]      
    @ Load address of TIMER_TIMELR_OFFSET into r4 and load timer reload value into r3
    ldr     r4, =(TIMER_BASE+TIMER_TIMELR_OFFSET)  
    ldr     r3, [r4]            
    @ Load address of TIMER_ALARM0_OFFSET into r4, load ltimer value into r5, add r3 and r5 and store the result in TIMER_ALARM0_OFFSET
    ldr     r4, =(TIMER_BASE+TIMER_ALARM0_OFFSET)
    ldr     r5, =ltimer        
    ldr     r5, [r5]           
    add     r5, r3, r5
    str     r5, [r4]            
    @ Restore registers r0-r5 and pc from         
    pop    {r0-r5,pc}



@ Set data alignment
.align 4

msg:    .asciz "Hello World!\n"
@ Set data alignment 
.data   
lstate: .word   DFLT_state_STRT
ltimer: .word   DFLT_ALARM_TIME