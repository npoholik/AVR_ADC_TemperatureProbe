# AVR_ADC_TemperatureProbe

The goal of this project is to incorporate a temperature sensor and servo motor into the atmega32a MCU environment. The analog signal of the temperature sensor will be converted into digital, which will then be read and displayed on the LEDs. Depending on current temperature read, the servo motor will be rotated the appropriate angle to match as well. 

----------------------------------------------------------------------------------------------------

## ASSUMPTIONS FOR ALL CALCULATIONS:
	1. Target MCU: AVR atmega32a
	2. Target MCU Clock: 1 MHz
## Links:
[MCU: AVR atmega32a](https://ww1.microchip.com/downloads/en/DeviceDoc/Atmega32A-DataSheet-Complete-DS40002072A.pdf)

[Servo Motor: Hitec RCD USA 31422](https://www.jameco.com/Jameco/Products/ProdDS/395786.pdf)
		
[Temperature Sensor: LM34CA](https://datasheet.octopart.com/LM34DH-National-Semiconductor-datasheet-22596.pdf)

> [!IMPORTANT] 
	> 1. Other servo motors will vary in required pulse width to accomplish the results listed below
	> 2. If servo motor becomes unstable, these calculations will have to be adjusted according to the spec sheet of the respective motor
	> 3. Other temperature sensors will have a different voltage range and will need to be accounted for

-----------------------------------------------------------------------------------------------------

## SERVO MOTOR CALCULATIONS/REGISTER VALUES: 

### The target servo motor hardware had a minimum pulse with of 1 ms for 0 degrees and a max of 2 ms for 180 degrees

	1. Other servo motors will vary in required pulse width to accomplish the results listed below
	2. If servo motor becomes unstable, these calculations will have to be adjusted according to the spec sheet of the respective motor

### FOR ALL PERIODS OF 20 MS (ASSUMING NON-INVERTING PWM FOR ALL):

    WGM01 WGM00 = 11 (for fast PWM)
    COM01 COM00 (for non-inverting on OC0) = 10

    Period = 20 ms ; frequency = 1/20ms - > 50 Hz

    Prescalar: 50 Hz = 1 MHz / N * 256  -> N = 78.125 ~= 64

    CS02 CS01 CS00 = 0 1 1 

    1 MHz / 64 = 15.625 kHz

    TCCR0 = 01101011 = 0x6B

    Period of Timer: 1/ 15.625 kHz = 64 us

### OCR0 Calculations: 
	0 Degrees: Output a pulse with a pulse width of 0.667 ms and period of 20 ms continuously:
		Duty Cycle: 1 ms / 20 ms * 100 = 5%  
		# of counts = 1 ms / 64 us = 15.625 ~= 16  
		OCR0 = # of counts - 1 = 16 - 1 = 15  

	30 Degrees: Output a pulse with a pulse width of  ms and a period of 20 ms continously:
		Duty Cycle: 1.17 ms / 20 ms * 100= 5.85%
		# of counts = 1.17 ms / 64 us = 18.28125 ~= 18
		OCR0 = # of counts - 1 = 18 - 1 = 17

	Output a pulse width of 1.33 ms and period of 20 ms continously
		Duty Cycle: 1.33 ms / 20 ms * 100 = 6.65%
		# of counts = 1.33 ms / 64 us = 20.78125 ~= 21
		OCR0 = # of counts - 1 = 21 - 1 = 20

	Output a pulse width of 1.5 ms and period of 20 ms continously 
		Duty Cycle: 1.5 ms / 20 ms * 100 = 7.5%
		# of counts = 1.5 ms / 64 us = 23.4375 ~= 23
		OCR0 = # of counts - 1 = 23 - 1 = 22

	Output a pulse width of 1.67 ms and period of 20 ms continously
	Duty Cycle: 1.67 ms / 20 ms * 100 = 8.35 %
	# of counts = 1.67 ms / 64 us = 26.09375 ~= 26
	OCR0 = # of counts - 1 = 26 - 1 = 25

	6. Output a pulse width of 1.84 ms and period of 20 ms continously
		Duty Cycle: 1.84 ms / 20 ms * 100 = 9.2%
		# of counts = 1.84 ms / 64 us = 28.75 ~= 29
		OCR0 = # of counts - 1 = 29 - 1 = 28

	Outputs a pulse width of 2 ms and period of 20 ms continously 
		Duty Cycle: 2 ms / 20 ms * 100 = 10%
		# of counts = 2 ms / 64 us = 31.25 ~= 31
		OCR0 = # of counts - 1 = 31 - 1 = 30

-----------------------------------------------------------------------------------------------------

## ANALOG TO DIGITAL CONVERSION: CALCULATIONS BASED ON TARGET HARDWARE TEMPERATURE SENSOR:
	1. Goal: Read analog voltage from the output of temperature sensor that outputs 10 mV/F:
	2. Assumption: Single Ended Voltage Range from 0 to 2.56 

Range = VRH - VRL = 2.56 - 0 = 2.56 V

Resolution = Range/[2n] = 2.56/[2^(10)] mV = 2.5 mV

(ADMUX)  REFS1 REFS0 = 1 1    <- internal 2.56 voltage reference

50 kHz < F(A/D) < 200 kHz <- F(A/D) must be within this range

F(A/D)=Fclk(I/O)/(division factor) = 1 MHz / 8 = 125 kHz   

Division Factor of 8: (ADCSRA)  ADPS2 ADPS1 ADPS0 = 0 1 1

Right Adjust: (ADMUX) ADLAR = 1

PA0: (ADMUX) MUX4 MUX3 MUX2 MUX1 MUX0 = 0 0 0 0 0 

ADMUX:  
	REFS1        REFS0     ADLAR         MUMX4       MUX3      MUX2      MUX1       MUX0 
      1            1          1            0          0          0        0          0
ADMUX = 0xE0

Assuming auto-trigger will be used: (ADCSRA) ADATE = 1

ADCSRA:	
		     ADEN     ADSC       ADATE      ADIF    ADIE      ADPS2       ADPS1        ADPS0  
              1         0          1         1        0         0           1            1
ADCSRA = 0xB3 

1. Do not start conversion during this (write 0 to ADSC) 

2. Clear interrupt flag (tells you when conversion is finished)

3. Do not enable interrupts ADIE

Now setup the special function I/O register for ADATE:

We will complete a conversion for compare match for Timer0/Counter0:

(SFIO) ADTS2 ADTS1 ADTS0 = 0 0 0 

SFIO: 
	ADTS2 ADTS1 ADTS0 ... ... ... ... ...
      0     0     0   (KEEP ALL OTHER BITS THE SAME)

