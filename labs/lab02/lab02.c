//#define WOKWI             // Uncomment if running on Wokwi RP2040 emulator.

#include <stdio.h>
#include <stdlib.h>
#include "pico/stdlib.h"


/**
 * @brief wallis_float
 *        Uses the wallis formula to calculate the approximate value of pi in single precision 
 *        (a) times.
 * @param a number of iterations the function will execute
 * @return The approximate single precision value of pi in float
 */
float wallis_float(int a){
    float pi = 1.0;
    for(int n = 1; n <= a; n++){
        pi *= (float)(n * 2) / (n * 2.0 - 1.0);
        pi *= (float)(n * 2) / (n * 2.0 + 1.0);
    }
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
    double pi = 1.0;
    for(int n = 1; n <= a; n++){
        pi *= (double)(n * 2) / (n * 2.0 - 1.0);
        pi *= (double)(n * 2) / (n * 2.0 + 1.0);
    }
    return pi * 2.0;
}
/**

 * @brief Main
 *       Initializes the IO then calls the wallis float and double function to calculate the 
 *       approximate value of pi in single and double precision and prints the value calculated and the 
 *       error between the result and the given value to the console.
 * @return int Application return code (zero for success).
*/

int main() {

#ifndef WOKWI
    // Initialise the IO as we will be using the UART
    // Only required for hardware and not needed for Wokwi
    stdio_init_all();
#endif

    float pi_float = wallis_float(100000);
    printf("Pi in single precision = %.10f\n", pi_float);
    printf("Approximation error in single precision = %.10f\n", abs(pi_float - 3.14159265359));

    double pi_double = wallis_double(100000);
    printf("Pi in double precision %.10lf\n", pi_double);
    printf("Approximation error in double precision = %.10lf\n", abs(pi_double - 3.14159265359));
    // Returning zero indicates everything went okay.
    return 0;
}
