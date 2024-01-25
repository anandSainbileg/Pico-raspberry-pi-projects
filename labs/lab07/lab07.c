#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.
#include "pico/multicore.h" // Required for using multiple cores on the RP2040.

/**
 * @brief This function acts as the main entry-point for core #1.
 *        A function pointer is passed in via the FIFO with one
 *        incoming int32_t used as a parameter. The function will
 *        provide an int32_t return value by pushing it back on 
 *        the FIFO, which also indicates that the result is ready.
 */
// Function to get the enable status of the XIP cache
bool get_xip_cache_en();
// Function to set the enable status of the XIP cache
bool set_xip_cache_en(bool cache_en);

// Get the enable status of the XIP cache
bool get_xip_cache_en() {
    uint8_t *p = (uint8_t *)(XIP_CTRL_BASE);
    return (*p & 0x1); // return the LSB of the value at the memory-mapped address
}
// Set the enable status of the XIP cache
bool set_xip_cache_en(bool cache_en) {
    uint8_t *p = (uint8_t *)(XIP_CTRL_BASE);
    *p = (cache_en ? 0x1 : 0x0); // set the LSB of the value at the memory-mapped address
    return cache_en;
}

void core1_entry() {
    while (1) {
        // 
        int32_t (*func)() = (int32_t(*)()) multicore_fifo_pop_blocking();
        int32_t p = multicore_fifo_pop_blocking();
        int32_t result = (*func)(p);
        multicore_fifo_push_blocking(result);
    }
}

/**
 * @brief wallis_float
 *        Uses the wallis formula to calculate the approximate value of pi in single precision 
 *        (a) times.
 * @param a number of iterations the function will execute
 * @return The approximate single precision value of pi in float
 */
float wallis_float(int a){
    uint64_t timeStart = time_us_64();
    float pi = 1.0;
    for(int n = 1; n <= a; n++){
        pi *= ((2 * n) / (2 * n - 1)) * ((2 * n) / (2 * n + 1));
    }
    uint64_t timeEnd = time_us_64();
    double timeUsed = timeEnd - timeStart;
    printf("Single precision time: %.0f microseconds\n", timeUsed);
    return pi * 2.0;
}

/**
 * @brief wallis_double
 *        Uses the wallis formula to calculate the approximate value of pi in double precision 
 *        (a) times.
 * @param a number of iterations the function will execute
 * @return The approximate double precision value of pi in double
 */
double wallis_double(int a){
    uint64_t timeStart = time_us_64();
    double pi = 1.0;
    for(int n = 1; n <= a; n++){
        pi *= ((2 * n) / (2 * n - 1)) * ((2 * n) / (2 * n + 1));
    }
    uint64_t timeEnd = time_us_64();
    double timeUsed = timeEnd - timeStart;
    printf("Double precision time: %.0f microseconds\n", timeUsed);
    return pi * 2.0;
}

/**
 * @brief main
 *        Entry point for the application.
 * @return 0 if successful.
*/
// Main code entry point for core0.
int main() {
    uint64_t timeStart, timeEnd, timeStartParallel, timeEndParallel;
    double timeUsed, timeUsedParallel;
    const int    ITER_MAX   = 100000;
    stdio_init_all();
    multicore_launch_core1(core1_entry);
    // Code for sequential run goes here…
    // Cache enabled
    set_xip_cache_en(1);
    //    Take snapshot of timer and store
    timeStart = time_us_64();
    //    Run the single-precision Wallis approximation
    wallis_float(ITER_MAX);
    //    Run the double-precision Wallis approximation
    wallis_double(ITER_MAX);
    //    Take snapshot of timer and store
    timeEnd = time_us_64();
    timeUsed = (double) (timeEnd - timeStart);
    //    Display time taken for application to run in sequential mode
    printf("Single core total time for the functions with cache enabled: %.0f microseconds\n", timeUsed);


    // Cache disabled
    set_xip_cache_en(0);
    //    Take snapshot of timer and store
    timeStart = time_us_64();
    //    Run the single-precision Wallis approximation
    wallis_float(ITER_MAX);
    //    Run the double-precision Wallis approximation
    wallis_double(ITER_MAX);
    //    Take snapshot of timer and store
    timeEnd = time_us_64();
    timeUsed = (double) (timeEnd - timeStart);
    //    Display time taken for application to run in sequential mode
    printf("Single core total time for the functions with cache disabled: %.0f microseconds\n", timeUsed);


    // Code for parallel run goes here…
    // Cache enabled
    set_xip_cache_en(1);
    //    Take snapshot of timer and store
    timeStartParallel = time_us_64();
    //    Run the single-precision Wallis approximation on one core
    multicore_fifo_push_blocking((uintptr_t) &wallis_float);
    multicore_fifo_push_blocking(ITER_MAX);
    //    Run the double-precision Wallis approximation on the other core
    wallis_double(ITER_MAX);
    multicore_fifo_pop_blocking();
    //    Take snapshot of timer and store
    timeEndParallel = time_us_64();
    timeUsedParallel = (double) (timeEndParallel - timeStartParallel);
    //    Display time taken for application to run in parallel mode
    printf("Parallel core total time for the functions with cache enabled: %.0f microseconds\n", timeUsedParallel);


    // Cache disabled
    set_xip_cache_en(0);
    //    Take snapshot of timer and store
    timeStartParallel = time_us_64();
    //    Run the single-precision Wallis approximation on one core
    multicore_fifo_push_blocking((uintptr_t) &wallis_float);
    multicore_fifo_push_blocking(ITER_MAX);
    //    Run the double-precision Wallis approximation on the other core
    wallis_double(ITER_MAX);
    multicore_fifo_pop_blocking();
    //    Take snapshot of timer and store
    timeEndParallel = time_us_64();
    timeUsedParallel = (double) (timeEndParallel - timeStartParallel);
    //    Display time taken for application to run in parallel mode
    printf("Parallel core total time for the functions with cache disabled: %.0f microseconds\n", timeUsedParallel);
    return 0;
}