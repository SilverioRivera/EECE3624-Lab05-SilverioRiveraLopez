/**************************************************************************
 *	    File: Lab05.asm
 *  Lab Name: Pardon the Interruption...
 *    Author: Dr. Greg Nordstrom
 *   Created: 02/19/2021
 * Processor: ATmega128A (on the ReadyAVR board)
 *
 * Modified by: Silverio Rivera-Lopez
 * Modified on: 09/22/2026
 *
 * This program blinks the "BOOT" LED(connected to PORTA.7) at a rate of 1-15 Hz, adjustable in 15
 * steps, as the joystick is toggled up (faster) or down (slower), and that the blink rate
 * is displayed in 4-bit binary on LEDs 0-3, which are connected to PORTC.0(LSB) through PORTC.3(MSB)
 *
 *************************************************************************/

 /*********
 * Interrupt Jump Table

 *********/
.org 0x0000                 ; next instruction address is 0x0000
                            ; (the location of the reset vector)
rjmp main					; allow reset to run this program

.org 0x0004
	rjmp ISRJoystickDownINT1
.org 0x0008
	rjmp ISRJoystickUpINT3


/**********
* Main code
**********/
.def BlinkFreq = R20		; holds current blink rate (1-15 Hz)

.equ BlinkFreqMin = 1
.equ BlinkFreqMax = 15
.equ InitialBlinkFreq = BlinkFreqMin
.def BOOTLED = R22
.def UPDOWNJoystick = R23

.org 0x0020					; Move the "main" to 0x0020 to make room for ISRs
main:                       ; jump here on reset
    ldi R16, HIGH(RAMEND)   ; initialize stack (default RAMEND = 0x10FF)
    out SPH, R16
    ldi R16, low(RAMEND)
    out SPL, R16

	/* Additional Setup before Main Loop */
	ldi BlinkFreq, InitialBlinkFreq			; Added: BlinkFreq with value of 1-15 for 1 Hz blink rate
	; Step 3
	; the outputs for PORT A and PORT C
	sbi DDRA, PA7 
	sbi DDRC, PC0
	sbi DDRC, PC1
	sbi	DDRC, PC2
	sbi DDRC, PC3

	; the inputs for PORT A
	cbi DDRA, PA0
	cbi DDRA, PA1
	cbi DDRA, PA2
	cbi DDRA, PA3
	cbi DDRA, PA4
	cbi DDRA, PA5
	cbi DDRA, PA6

	; the inputs for PORT C
	cbi DDRC, PC4
	cbi DDRC, PC5
	cbi DDRC, PC6
	cbi DDRC, PC7


	; Lab Configuring Slide 

	; Configuring DDRB to set PIN1 and PIN3 as inputs
	cbi DDRB, PB1
	cbi DDRB, PB3

	; Configuring DDRD to set PIN1 and PIN3 as inputs
	; DOWN and UP
	cbi DDRD, PD1
	cbi DDRD, PD3

	; Configuring PORTB to set internal pulls up on PIN1 and PIN3
	; they have define as inputs before hand
	; DOWN and UP
	; these are jumped to PD1 and PD3
	sbi PORTB, PB1
	sbi PORTB, PB3

	; Set up the interrupt system
	; The 3 steps for interrupts!!

	; Configuring EICRA for INT1 and INT3 to RISING edge trigger
	; When should it trigger?
	ldi R16, (1<<ISC11)|(1<<ISC10)|(1<<ISC31)|(1<<ISC30)
	sts EICRA, R16

	; Configuring EIMSK for INT1 and INT3 to generate interrupts
	; Which interrupts are enabled?
	ldi R16, (1<<INT1)| (1<<INT3)
	out EIMSK, R16

	;Configuring SREG to enable interrupts GLOBALLY 
	sei 

	



    
mainLoop:
    CBI  PORTA, PORTA7       ; turn BOOT LED on (active low) by clearing PORTA.7

    ; kill some time
    ldi R16, 16             ; R16 is outer loop counter
	sub R16, BlinkFreq		; Modified: R16 set to 16 - BlinkFreq
	 

	
outer_loop1:
    ldi R24, low(0xFFFF)     ; load low and high parts of R25:R24 pair with (Modified value for 1 Hz blink rate)
    ldi R25, high(0xFFFF)    ; loop count by loading registers separately	(Modified value for 1 Hz blink rate)
    inner_loop1:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop1    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop1        ; loop back if R16 isn't zero

    sbi PORTA, PORTA7       ; turn BOOT LED off (active low) by setting PORTA.7

    ; kill some more time
    ldi R16, 16             ; R16 is outer loop counter
	sub R16, BlinkFreq      ; Modified: R16 set to 16 - BlinkFreq

outer_loop2:
    ldi R24, low(0xFFFF)     ; load low and high parts of R25:R24 pair with (Modified value for 1 Hz blink rate)
    ldi R25, high(0xFFFF)    ; loop count by loading registers separately (Modified value for 1 Hz blink rate)
    inner_loop2:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop2    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop2        ; loop back if R16 isn't zero

    rjmp mainLoop           ; play it again, Sam...

/**********
* ISR code
**********/
.org 0x0200							; Load the ISR code higher than main code
ISRJoystickDownINT1:							; ISRJoystickDown
	push r16						; Preserving register 16
	in r16, SREG
	push r16

	cpi BlinkFreq,BlinkFreqMin
	breq ISRJoystickDown
	dec Blinkfreq
	in R16, PORTC
	andi R16, 0xF0
	or R16, BlinkFreq
	out PORTC, R16

ISRJoystickDown:
	pop r16
	out SREG, r16
	pop r16
	reti							; restores the saved PC and re-enables Global Interrupts



ISRJoystickUpINT3:
	push r16
	in r16, SREG
	push r16

	cpi BlinkFreq,BlinkFreqMax
	breq ISRJoystickUp
	inc BlinkFreq

	in r16, PORTC
	andi r16, 0xF0
	or r16, BlinkFreq
	out PORTC, r16

ISRJoystickUp:
	pop r16
	out SREG, r16
	pop r16
	reti
