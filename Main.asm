JMP Init:

.ORG 0x002A
Init:
; Initialize PB3 as output (for OC0) 
SBI DDRB, 3 

; Set TIMER0 to fast PWM with a default pulse width of 1 ms
LDI R16, 15
OUT OCR0, R16
LDI R16, 0x6B
OUT TCCR0, R16

; Set up LEDs to output on PORTD
LDI R16, 0xFF;
OUT DDRD, R16

CBI DDRA, 0  ; declare PA0 as input for analog voltage *** NO PULL UP RESISTOR
LDI R16, 0xE0          ; set up the ADMUX
OUT ADMUX, R16

IN R16, SFIOR    ; set up the SFIOR while retaining previous 4 downto 0 bits
ANDI R16, 0x1F
OUT SFIOR, R16

; Set up ADCSRA register according to previous calculations specific to target hardware
LDI R16, 0xB3
OUT ADCSRA, R16

SBI ADCSRA, 6 ; begin first conversion 

Loop: SBIS ADCSRA, 4 ; check if ADIF is set
    rjmp Loop

    IN R16, ADCL
    IN R17, ADCH
    COM R17
    OUT PORTD, R17 ; output the digital binary representation of temp onto LEDs

    SBI ADCSRA, 4 ; clears the ADIF (allow for free running mode to continue)

    Range8190:              ;8190 refers to a temperature range of 81 -> 90 degrees Fahrenheit
        CPI R17, 0x51       ; this format for range labels is true for the following ones as well
        BRLO Range7180
        RJMP SW6
    Range7180:
        CPI R17, 0x47
        BRLO Range6170
        RJMP SW5
    Range6170:
        CPI R17, 0x3D
        BRLO Range5160
        RJMP SW4
    Range5160:
        CPI R17, 0x33
        BRLO Range41-50
        RJMP SW3
    Range41-50:
        CPI R17, 0x29
        BRLO Range32-40
        RJMP SW2
    Range32-40:
        CPI R17, 0x20
        BRLO Range0-31
        RJMP SW1
    Range0-31:
        RJMP SW0

; The following will turn the servo motor the corresponding number of degrees from angle 0 degree axis
    SW0:
        LDI R18, 15
        OUT OCR0, R18
        rjmp Loop
    SW1: 
        LDI R18, 17
        OUT OCR0, R18
        rjmp Loop
    SW2: 
        LDI R18, 20
        OUT OCR0, R18
        rjmp Loop
    SW3: 
        LDI R18, 22
        OUT OCR0, R18
        rjmp Loop
    SW4: 
        LDI R18, 25
        OUT OCR0, R18
        rjmp Loop
    SW5: 
        LDI R18, 28
        OUT OCR0, R18
        rjmp Loop
    SW6: 
    LDI R18, 30
        OUT OCR0, R18
        rjmp Loop

end: rjmp end
