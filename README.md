# AVR_ADC_TemperatureProbe
The goal of this project is to incorporate a temperature sensor and servo motor into the atmega32a MCU environment. The analog signal of the temperature sensor will be converted into digital, which will then be read and displayed on the LEDs. Depending on current temperature read, the servo motor will be rotated the appropriate angle to match as well. 

----------------------------------------------------------------------------------------------------

## ASSUMPTIONS FOR ALL CALCULATIONS:
1. Target MCU: AVR atmega32a
2. Target MCU Clock: 1 MHz
## Target Equipment Links:
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

### FOR ALL PERIODS OF 20 MS (ASSUMING NON-INVERTING PWM FOR ALL):

    WGM01 WGM00 = 11 (for fast PWM)
    COM01 COM00 (for non-inverting on OC0) = 10

    Period = 20 ms ; frequency = 1/20ms - > 50 Hz

    Prescalar: 50 Hz = 1 MHz / N * 256  -> N = 78.125 ~= 64

    CS02 CS01 CS00 = 0 1 1 

    1 MHz / (64 * 256) = 61 Hz

    TCCR0 = 01101011 = 0x6B

    Period of Timer: 1/ 61 Hz = 16.39344 ms

### OCR0 Calculations: 

>[EQUATIONS]
>1. Duty Cycle = (Time High)/(Period of Timer) * 100
>2. OCR0 = (Duty Cycle * 256)/100 - 1

	0 Degrees: Output a positive pulse width of 0.667 ms and period of 20 ms continuously:
		OCR0 = 8

	30 Degrees: Output a positive pulse width of 0.832 ms and a period of 20 ms continously:
		OCR0 = 12

	60 Degrees: Output a positive pulse width of 1.153 ms and period of 20 ms continously
		OCR0 = 17

	90 Degrees: Output a positive pulse width of 1.409 ms and period of 20 ms continously 
		OCR0 = 21

	120 Degrees: Output a positive pulse width of 1.729 ms and period of 20 ms continously
		OCR0 = 26

	150 Degrees: Output a positive pulse width of 2 ms and period of 20 ms continously
		OCR0 = 30

	180 Degrees: Output a positive pulse width of 2.241 ms and period of 20 ms continously 
		OCR0 = 34

-----------------------------------------------------------------------------------------------------

## ANALOG TO DIGITAL CONVERSION: CALCULATIONS BASED ON TARGET HARDWARE TEMPERATURE SENSOR:
1. Goal: Read analog voltage from the output of temperature sensor that outputs 10 mV/F:
2. Assumption: Single Ended Voltage Range from 0 to 2.56 

### Calculations:
	Range = VRH - VRL = 2.56 - 0 = 2.56 V

	Resolution = Range/[2n] = 2.56/[2^(10)] mV = 2.5 mV

	(ADMUX)  REFS1 REFS0 = 1 1    <- internal 2.56 voltage reference

	50 kHz < F(A/D) < 200 kHz <- F(A/D) must be within this range

	F(A/D)=Fclk(I/O)/(division factor) = 1 MHz / 8 = 125 kHz   

	Division Factor of 8: (ADCSRA)  ADPS2 ADPS1 ADPS0 = 0 1 1

	Right Adjust: (ADMUX) ADLAR = 1

	PA0: (ADMUX) MUX4 MUX3 MUX2 MUX1 MUX0 = 0 0 0 0 0 

		ADMUX:  
			REFS1      REFS0      ADLAR       MUMX4      MUX3     MUX2      MUX1       MUX0 
			1          1          1           0         0        0          0          0
		ADMUX = 0xE0

		Assuming auto-trigger will be used: (ADCSRA) ADATE = 1
		ADCSRA:	
			ADEN     ADSC       ADATE      ADIF    ADIE      ADPS2       ADPS1      ADPS0  
			1        0           1         1       0          0           1          1
		ADCSRA = 0xB3 

>[!NOTE]
>1. Do not start conversion during this (write 0 to ADSC) 
>2. Clear interrupt flag (tells you when conversion is finished, may have unknown value != 0 at start)
>3. Do not enable interrupts (ADIE)

	Now setup the special function I/O register for ADATE:

		We will complete a conversion for ADIF, or when one conversion finishes (Normal Mode)

		(SFIO) ADTS2 ADTS1 ADTS0 = 0 0 0 
		SFIO: 
			ADTS2 ADTS1 ADTS0 ... ... ... ... ...
			  0     0     0   (KEEP ALL OTHER BITS THE SAME)

