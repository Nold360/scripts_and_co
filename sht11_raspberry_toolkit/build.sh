#!/bin/bash
gcc -lm -o get_sht11_values bcm2835-1.22/src/bcm2835.c RPi_SHT1x.c get_sht11_values.c 
gcc -lm -o get_sht11_temp bcm2835-1.22/src/bcm2835.c RPi_SHT1x.c get_sht11_temp.c
gcc -lm -o get_sht11_hum bcm2835-1.22/src/bcm2835.c RPi_SHT1x.c get_sht11_hum.c
