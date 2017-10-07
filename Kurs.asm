;**********************************************************************************************
;MUL16
;DIVIDE
;ADD_16_16_16
;INT16_TO_TIME_STRING
;CURSOR_BACK
;**********************************************************************************************
.include "m8515def.inc" ;oaee ii?aaaeaiee ATmega8515 

.equ SECUND = 1 
.equ FREQUANCY = 4000000 / SECUND 
.equ FREQUANCY_DIV = 1024 
.equ MINUTE = 60 * SECUND 
.equ HOUR = 60 * MINUTE 
.equ STRUCT_LEN = 3 
.equ MEM_START = 0x60

.equ TIME_INTERVAL_STATE = 0
.equ TIME_COUNTING_STATE = 1
.equ OUT_RESULT_STATE = 2

.def temp = r16 
.def temp0 = r16 
.def temp1 = r17 
.def temp2 = r18 
.def temp3 = r19 
.def temp4 = r20 
.def temp5 = r21 
.def temp6 = r22 
.def temp7 = r23 
.def temp8 = r24 

.org $000 
	rjmp INIT_INTERRUPT 
.org $001 
	rjmp ON_BUTTON_PRESSED_INTERRUPT 
.org $004
	rjmp TIMER_A_INTERRUPT
.org $00C
	rjmp TIMER_A_INTERRUPT
.org $00E
	rjmp TIMER_A_INTERRUPT
.org $010
	rjmp TIMER_A_INTERRUPT

MY_SLEEP: 
	;push temp 
	;ldi temp, (1<< SE) 
	;out MCUCR, temp 
	;pop temp 
	;sleep 
	ret 

INIT_INTERRUPT: 
	ldi temp7, 0x00 
	ldi temp8, 0xFF  
	ldi temp,low(RAMEND) 
	out SPL,temp 
	ldi temp,high(RAMEND) 
	out SPH,temp 
 
	ldi ZH, 0x00 
	ldi ZL, 0x00 

	ldi temp, 0x00 
	out DDRD, temp 
	ldi temp, 0xFF 
	out PORTD, temp 
	ldi temp,(1<<INT0) 
	out GICR,temp 

	ser temp 
	out DDRB, temp 
	out PORTB, temp 

	ser temp 
	out DDRC, temp 
	clr temp 
	out PORTC, temp 

;Iano?ieea oaeia?a 
	ldi temp, 0xFF
	out TIMSK, temp 
	ldi temp, 0x00 
	out TCNT1H, temp 
	out TCNT1L, temp 

	ldi temp, 0x10
	out OCR1AH, temp 
	ldi temp, 0x10
	out OCR1AL, temp 

	rcall INIT_DISPLAY 
	ldi ZL, LOW(SELECT_TIME_MODE << 1) 
	ldi ZH, HIGH(SELECT_TIME_MODE << 1) 
	ldi temp5, 0x00
	rcall DRAW	
	ldi ZL, LOW(MEM_START) 
	ldi ZH, HIGH(MEM_START) 
	ldi temp, 0x01 
	rcall INIT_VARIABLES
	
	;**test
	ldi ZL, LOW(MEM_START)
	ldi ZH, HIGH(MEM_START)
	ldi temp, 25
	std Z+1 + 0 * STRUCT_LEN, temp
	ldi temp, 50
	std Z+1 + 1 * STRUCT_LEN, temp
	ldi temp, 75
	std Z+1 + 2 * STRUCT_LEN, temp

	ldi temp, 0
	rcall DRAW_PORTION
	;**test
	;ldi temp, 0
	;rcall DRAW_CURRENT_TIME

	ldi temp0, 0x00 
	ldi temp2, 0x01
	ldi temp5, 0x00 


	sei 


LOOP: 
	;rcall MY_SLEEP 
	rjmp LOOP 
	ret 


TIMER_A_INTERRUPT:
	push temp2
	rcall CURSOR_BACK 
	ldi temp, 0x00 
	out TCNT1H, temp 
	out TCNT1L, temp 

	ldi temp, 0x10
	out OCR1AH, temp 
	ldi temp, 0x10
	out OCR1AL, temp

	sbrc temp2, 7
	ldi temp, 3
	sbrc temp2, 6
	ldi temp, 2
	sbrc temp2, 5
	ldi temp, 1
	sbrc temp2, 4
	ldi temp, 0
	rcall DRAW_CURRENT_TIME

;end

	ldi ZH, HIGH(0 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(0 * STRUCT_LEN + MEM_START) 
	rcall ADD16

	ldi ZH, HIGH(1 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(1 * STRUCT_LEN + MEM_START) 
	rcall ADD16 

	ldi ZH, HIGH(2 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(2 * STRUCT_LEN + MEM_START) 
	rcall ADD16 

	ldi ZH, HIGH(3 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(3 * STRUCT_LEN + MEM_START) 
	rcall MINUS16 
	pop temp2
	reti 


ADD16: 
	ldd temp1, Z+0 
	ldd temp2, Z+1 
	ldd temp3, Z+2 
	add temp3, temp1 
	adc temp2, temp7

ADD16_END: 
	std Z+1, temp2 
	std Z+2, temp3 
	ret 

MINUS16: 
	ldd temp1, Z+0 
	ldd temp2, Z+1 
	ldd temp3, Z+2
	com temp1
	inc temp1
	add temp3, temp1 
	adc temp2, temp8

MINUS16_END: 
	std Z+1, temp2 
	std Z+2, temp3 
	ret 

;temp from what
DRAW_PORTION:
	push ZL
	push ZH
	push temp1
	push temp2
	push temp3
	push temp4
	push temp5
	push temp6
	ldi ZH, HIGH(MEM_START) 
	ldi ZL, LOW(MEM_START) 
	ldi temp1, HIGH(STRUCT_LEN)
	ldi temp2, LOW(STRUCT_LEN)
	ldd temp1,Z + 0 * STRUCT_LEN + 1
	ldd temp2,Z + 0 * STRUCT_LEN + 2
	ldd temp3,Z + 1 * STRUCT_LEN + 1
	ldd temp4,Z + 1 * STRUCT_LEN + 2
	ldd temp5,Z + 2 * STRUCT_LEN + 1
	ldd temp6,Z + 2 * STRUCT_LEN + 2
	std Z+(5 * STRUCT_LEN + 0), temp1 
	std Z+(5 * STRUCT_LEN + 1), temp2 
	std Z+(5 * STRUCT_LEN + 2), temp3 
	std Z+(5 * STRUCT_LEN + 3), temp4 
	std Z+(5 * STRUCT_LEN + 4), temp5 
	std Z+(5 * STRUCT_LEN + 5), temp6

	ldi ZH,HIGH(5 * STRUCT_LEN + MEM_START)
	ldi ZL,LOW(5 * STRUCT_LEN + MEM_START)
	rcall ADD_16_16_16
	ldd temp1,Z+0
	ldd temp2,Z+1
	std Z+2, temp1
	std Z+3, temp2
	ldi ZL, LOW(MEM_START)
	ldi ZH, HIGH(MEM_START)
	ldi temp1, HIGH(STRUCT_LEN)
	ldi temp2, LOW(STRUCT_LEN)
draw_propotion_adding:
	tst temp
	breq draw_propotion_adding_end
	dec temp
	add ZL, temp2
	adc ZH, temp1
	rjmp draw_propotion_adding
draw_propotion_adding_end:
	ldd temp1, Z+1
	ldd temp2, Z+2
	ldi ZH, HIGH(5 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(5 * STRUCT_LEN + MEM_START) 
	std Z+0, temp1
	std Z+1, temp2
	rcall DIVIDE_FLOAT
	rcall FLOAT_16_TO_STR 
	ldi temp5, 0x00
	rcall DRAW2
	pop temp6
	pop temp5
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	pop ZH
	pop ZL
	ret
;temp from what
DRAW_CURRENT_TIME:
	push ZL
	push ZH
	push temp1
	push temp2
	ldi ZH, HIGH(MEM_START) 
	ldi ZL, LOW(MEM_START) 
	ldi temp1, HIGH(STRUCT_LEN)
	ldi temp2, LOW(STRUCT_LEN)
draw_current_time_adding:
	tst temp
	breq draw_current_time_adding_end
	dec temp
	add ZL, temp2
	adc ZH, temp1
	rjmp draw_current_time_adding
draw_current_time_adding_end:
	ldd temp1, Z+1
	ldd temp2, Z+2
	ldi ZH, HIGH(5 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(5 * STRUCT_LEN + MEM_START) 
	std Z+0, temp1
	std Z+1, temp2
	rcall INT16_TO_TIME_STRING 
	ldi temp5, 0x00
	rcall DRAW2
	pop temp2
	pop temp1
	pop ZH
	pop ZL
	ret

;temp - auai? ?a?eia 1 - 1?an, 1 - 2?ana, 2 - 3?ana 
INIT_VARIABLES: 
	push temp 

	ldi temp, 1 
	std Z+0, temp 
	ldi temp, 0 
	std Z+1, temp 
	std Z+2, temp

	ldi temp, 1 
	std Z+3, temp 
	ldi temp, 0 
	std Z+4, temp 
	std Z+5, temp
	
	ldi temp, 1 
	std Z+6, temp 
	ldi temp, 0 
	std Z+7, temp 
	std Z+8, temp

	pop temp 
	push temp
	std Z+9, temp 
	ldi temp, HIGH(HOUR * 3) 
	std Z+10, temp 
	ldi temp, LOW(HOUR * 3) 
	std Z+11, temp 

	pop temp
	std Z+12, temp 
	ldi temp, HIGH(HOUR * 3) 
	std Z+13, temp 
	ldi temp, LOW(HOUR * 3) 
	std Z+14, temp 
	ret 

SHOW_RESULTS: 
;Inoaiiaea oaeia?a 
;lm016l 
	ldi temp,0x00 
	out TCCR1A, temp 
	ret 


;temp - used 
;temp1 - used 
;temp2 - state 
ON_BUTTON_PRESSED_INTERRUPT: 
	in temp1, PIND 
	sbrs temp1, 3 
	rcall ON_BUTTON3_PRESSED 
	sbrs temp1, 4 
	rcall ON_BUTTON4_PRESSED 
	sbrs temp1, 5 
	rcall ON_BUTTON5_PRESSED 
	sbrs temp1, 6 
	rcall ON_BUTTON6_PRESSED 
	sbrs temp1, 7 
	rcall ON_BUTTON7_PRESSED 
	reti 


;aee??aai oaeia?u 
ON_BUTTON3_PRESSED: 
	push temp0 
	push temp1 

	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button3_pressed_start_timing
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button3_nop
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button3_nop 

	pop temp1
	pop temp0
	ret
on_button3_pressed_start_timing:
	rcall CURSOR_BACK 
	ldi ZL, LOW(BUTTON_3_RPRESSED << 1) 
	ldi ZH, HIGH(BUTTON_3_RPRESSED <<  1) 
	ldi temp5, 0x00 
	rcall DRAW 
	ldi temp, 0x00 
	out TCCR1A, temp 
	ldi temp, 0x05 
	out TCCR1B, temp
	lsl temp2
	ret
on_button3_nop:
	ldi temp, 0x03
	rcall DRAW_CURRENT_TIME
	andi temp2, 0x0F
	ori temp2, 0x80
	ret


;inoaiiaeou oaeia? 1 
ON_BUTTON4_PRESSED: 
	push temp1
	
	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button4_pressed_set_1hour_interval
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button4_out_counting_time
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button4_out_proportion
	pop temp1
	ret
on_button4_pressed_set_1hour_interval:
	push temp
	ldi temp, 3
	rcall SET_HOURS
	ldi temp, 0x03
	rcall DRAW_CURRENT_TIME
	pop temp
	ret
on_button4_out_counting_time:
	ldi temp, 0x00
	rcall DRAW_CURRENT_TIME
	andi temp2, 0x0F
	ori temp2, 0x40
	ret
on_button4_out_proportion:
	ret




;inoaiiaeou oaeia? 2 
ON_BUTTON5_PRESSED: 
	push temp1
	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button5_pressed_set_1hour_interval
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button5_out_counting_time
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button5_out_proportion
	pop temp1
	ret
on_button5_pressed_set_1hour_interval:
	push temp
	ldi temp, 2
	rcall SET_HOURS
	ldi temp, 0x03
	rcall DRAW_CURRENT_TIME
	pop temp
	ret
on_button5_out_counting_time:
	ldi temp, 0x01
	rcall DRAW_CURRENT_TIME
	ldi temp, 0x0F
	andi temp2, 0x0F
	ori temp2, 0x20
on_button5_out_proportion:
	ret


;inoaiiaeou oaeia? 3 
ON_BUTTON6_PRESSED: 
	push temp1
	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button6_pressed_set_1hour_interval
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button6_out_counting_time
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button6_out_proportion
	pop temp1
	ret
on_button6_pressed_set_1hour_interval:
	push temp
	ldi temp, 1
	rcall SET_HOURS
	ldi temp, 0x03
	rcall DRAW_CURRENT_TIME
	pop temp
	ret
on_button6_out_counting_time:
	ldi temp, 0x01
	rcall DRAW_CURRENT_TIME
	andi temp2, 0x0F
	ori temp2, 0x10
on_button6_out_proportion:
	ret


;auaanoe neaao?uea aaiiua 
;ZH:ZL - ia?aei ianneaa aaiiuo 
;[adder, HL, LH, LL]-oaeia? 1 
;[adder, HL, LH, LL]-oaeia? 2 
;[adder, HL, LH, LL]-oaeia? 3 
;[adder, HL, LH, LL]-oaeia? iauee 
ON_BUTTON7_PRESSED: 
	push temp1 
	rcall CURSOR_BACK 
	ldi ZL, LOW(BUTTON_7_RPRESSED << 1) 
	ldi ZH, HIGH(BUTTON_7_RPRESSED << 1) 
	ldi temp5, 0x00 
	rcall DRAW 
	ldd temp1, Z+(4 * STRUCT_LEN + 1) 
	ldd temp2, Z+(4 * STRUCT_LEN + 2)
	std Z+(5 * STRUCT_LEN + 0), temp1 
	std Z+(5 * STRUCT_LEN + 1), temp2 
case_1: 
	dec temp 
	brne case_2 
	ldd temp1, Z+(0 * STRUCT_LEN + 1) 
	ldd temp2, Z+(0 * STRUCT_LEN + 2) 
	ldd temp3, Z+(1 * STRUCT_LEN + 1) 
	ldd temp4, Z+(1 * STRUCT_LEN + 2) 
	ldd temp5, Z+(2 * STRUCT_LEN + 1) 
	ldd temp6, Z+(2 * STRUCT_LEN + 2)
	std Z+(5 * STRUCT_LEN + 0), temp1 
	std Z+(5 * STRUCT_LEN + 1), temp2 
	std Z+(5 * STRUCT_LEN + 2), temp3 
	std Z+(5 * STRUCT_LEN + 3), temp4 
	std Z+(5 * STRUCT_LEN + 4), temp5 
	std Z+(5 * STRUCT_LEN + 5), temp6
	ldi ZL, LOW(5 * STRUCT_LEN + 0)
	ldi ZH, HIGH(5 * STRUCT_LEN + 0)
	rcall ADD_16_16_16 
	rcall OUT_ADD_RESULT 
	rjmp on_button7_pressed_end 

case_2: 
	dec temp 
	brne case_3 
	ldd temp4, Z+(0 * STRUCT_LEN + 1) 
	ldd temp5, Z+(0 * STRUCT_LEN + 2) 
	std Z+(5 * STRUCT_LEN + 3), temp4 
	std Z+(5 * STRUCT_LEN + 4), temp5  
	rcall DIFERENCE16 
	rjmp on_button7_pressed_end 
case_3: 
	dec temp 
	brne case_4 
	ldd temp4, Z+(1 * STRUCT_LEN + 1) 
	ldd temp5, Z+(1 * STRUCT_LEN + 2) 
	std Z+(5 * STRUCT_LEN + 3), temp4 
	std Z+(5 * STRUCT_LEN + 4), temp5 
	rcall DIFERENCE16 
	rcall OUT_RESULT 
	rjmp on_button7_pressed_end 
case_4: 
	dec temp 
	brne case_5 
	ldd temp4, Z+(2 * STRUCT_LEN + 1) 
	ldd temp5, Z+(2 * STRUCT_LEN + 2)  
	std Z+(5 * STRUCT_LEN + 3), temp4 
	std Z+(5 * STRUCT_LEN + 4), temp5 
	rcall DIFERENCE16 
	rcall OUT_RESULT 
	rjmp on_button7_pressed_end 
case_5: 
	dec temp 
	rcall DIFERENCE16 
	rcall OUT_RESULT 
	rjmp on_button7_pressed_end 
on_button7_pressed_end: 
	pop temp1 
	ret 


SET_HOURS:
	push ZL
	push ZH
	push temp3
	push temp4
	ldi ZL, LOW(3 * STRUCT_LEN + MEM_START)
	ldi ZH, HIGH(3 * STRUCT_LEN + MEM_START)
	ldi temp3,HIGH(HOUR)
	ldi temp4,LOW(HOUR)
	ldi temp5,HIGH(HOUR)
	ldi temp6,LOW(HOUR)

adding:
	dec temp
	breq adding_end
	add temp3, temp5
	adc temp4, temp6
	rjmp adding
adding_end:
	std Z+1, temp3
	std Z+2, temp4
	pop temp4
	pop temp3
	pop ZH
	pop ZL
	ret
;temp1-HByte
;temp2-LByte
;temp3-HByte
;temp4-LByte
;temp1-OutHByte
;temp2-OutLByte
DIFERENCE16:
	push temp3
	push temp4
	add temp4, temp8 
	adc temp3, temp8 
	com temp4 
	com temp3 
	add temp2, temp4 
	adc temp1, temp3 
	pop temp4
	pop temp3
	ret 


SUM16: 
	add temp2, temp4 
	adc temp1, temp3 
	ret 

MUL2_16:
	push temp1
	push temp2
	ldd temp1, Z+0
	ldd temp2, Z+1
	lsl temp2
	rol temp1
	std Z+0, temp1
	std Z+1, temp2
	pop temp2
	pop temp1
	ret
;temp0
;temp1
;temp2
;temp3
;temp4
;temp5
;temp6
;
;
;

;temp1
;temp2
FLOAT_16_TO_STR:
	push temp
	push temp1
	push temp2
	push temp3
	push temp4
	push ZH
	push ZL

	ldi temp1, 0x00
	ldi temp2, 0x0A
	std Z+2, temp1
	std Z+3, temp2
	rcall MUL16
	ldd temp1, Z+2
	ldd temp2, Z+3
	std Z+0, temp1
	std Z+1, temp2
	ldd temp, Z+4
	push temp

	ldi temp1, 0x00
	ldi temp2, 0x0A
	std Z+2, temp1
	std Z+3, temp2
	rcall MUL16
	ldd temp1, Z+2
	ldd temp2, Z+3
	std Z+0, temp1
	std Z+1, temp2
	ldd temp, Z+4
	push temp 

	ldi temp1, 0x00
	ldi temp2, 0x0A
	std Z+2, temp1
	std Z+3, temp2
	rcall MUL16
	ldd temp1, Z+2
	ldd temp2, Z+3
	std Z+0, temp1
	std Z+1, temp2
	ldd temp, Z+4
	push temp 

	ldi temp1, 0x00
	ldi temp2, 0x0A
	std Z+2, temp1
	std Z+3, temp2
	rcall MUL16
	ldd temp1, Z+2
	ldd temp2, Z+3
	std Z+0, temp1
	std Z+1, temp2
	ldd temp, Z+4
	push temp 
	

	
	pop temp1
	pop temp2
	pop temp3
	pop temp4

	ldi ZL, LOW(NUMBERS << 1)
	ldi ZH, HIGH(NUMBERS << 1)
	add ZL, temp1
	adc ZH, temp7
	lpm temp1, Z+0

	ldi ZL, LOW(NUMBERS << 1)
	ldi ZH, HIGH(NUMBERS << 1)
	add ZL, temp2
	adc ZH, temp7
	lpm temp2, Z+0

	ldi ZL, LOW(NUMBERS << 1)
	ldi ZH, HIGH(NUMBERS << 1)
	add ZL, temp3
	adc ZH, temp7
	lpm temp3, Z+0

	ldi ZL, LOW(NUMBERS << 1)
	ldi ZH, HIGH(NUMBERS << 1)
	add ZL, temp4
	adc ZH, temp7
	lpm temp4, Z+0

	pop ZL
	pop ZH

	std Z+0, temp4
	std Z+1, temp3
	ldi temp, ','
	std Z+2, temp
	std Z+3, temp2
	std Z+4, temp1
	ldi temp, '%'
	std Z+5, temp
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	pop temp
	ret
;return 16bits from
DIVIDE_FLOAT:
	push temp 
	push temp1 
	push temp2 
	push temp3 
	push temp4 
	push temp5 
	push temp6 
	ldd temp1, Z+0
	ldd temp2, Z+1
	ldi temp, 0x00
	std Z+0, temp
	std Z+1, temp
	ldd temp3, Z+2
	ldd temp4, Z+3
	ldi temp5, 0x00
	ldi temp6, 0x00
	ldi temp, 16

divide_float_circle:
	lsl temp2
	rol temp1
	rcall DIFERENCE16 
	brcc recov_float
	inc temp5
divide_float_circle_tail:
	dec temp 
	breq divide_float_circle_end
	lsl temp6
	rol temp5
	rjmp divide_float_circle
divide_float_circle_end:
	std Z+0, temp5
	std Z+1, temp6
	pop temp6 
	pop temp5 
	pop temp4 
	pop temp3 
	pop temp2 
	pop temp1 
	pop temp 
	ret
recov_float: 
	rcall SUM16
	rjmp divide_circle_tail



DIVIDE: 
	push temp 
	push temp1 
	push temp2 
	push temp3 
	push temp4 
	push temp5 
	push temp6 

	ldi temp, 16
	ldi temp1, 0x00
	ldi temp2, 0x00
	ldd temp3, Z+2
	ldd temp4, Z+3
	ldi temp5, 0x00
	ldi temp6, 0x00

divide_circle:
	rcall MUL2_16
	rol temp2
	rol temp1
	rcall DIFERENCE16 
	brcc recov
	adc temp6, temp7
	adc temp5, temp7
divide_circle_tail:
	dec temp 
	breq divide_circle_end
	lsl temp6 
	rol temp5 
	rjmp divide_circle
divide_circle_end:
	std Z+0, temp5
	std Z+1, temp6
	pop temp6 
	pop temp5 
	pop temp4 
	pop temp3 
	pop temp2 
	pop temp1 
	pop temp 

	ret 
recov: 
	rcall SUM16
	rjmp divide_circle_tail

;!!!��������� ���������� � Z+2 Z+3 Z+4!!!
;!!!Z+4 OVERFLOW
MUL16:
	push temp
	push temp1
	push temp2
	push temp3
	push temp4
	push temp5
	push temp6
	push temp7

	ldd temp1, Z+0
	ldd temp2, Z+1
	ldd temp3, Z+2
	ldd temp4, Z+3
	ldi temp5, 0x00
	ldi temp6, 0x00
	ldi temp7, 0x00
	ldi temp, 16
mul16_loop:
	lsl temp4
	rol temp3
	brcs mul16_add
mul16_con:
	dec temp
	breq mul16_end

	lsl temp6
	rol temp5
	rol temp7
	
	rjmp mul16_loop
mul16_end:
	std Z+2, temp5
	std Z+3, temp6
	std Z+4, temp7

	pop temp7
	pop temp6
	pop temp5
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	pop temp
	ret
mul16_add:
	add temp6, temp2
	adc temp5, temp1
	brcc mul16_con
	inc temp7
	rjmp mul16_con
	

ADD_16_16_16:
	push temp1
	push temp2
	push temp3
	push temp4
	push temp5
	push temp6
 
	ldd temp1, Z+0 
	ldd temp2, Z+1 
	ldd temp3, Z+2 
	ldd temp4, Z+3 
	ldd temp5, Z+4
	ldd temp6, Z+5

	add temp2, temp4 
	adc temp1, temp3  
 
	add temp2, temp6 
	adc temp1, temp5

	std Z+0, temp1
	std Z+1, temp2

	pop temp6
	pop temp5
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	ret 

OUT_RESULT: 
ret 

OUT_ADD_RESULT: 
ret 

;Z+0-HIGH 
;Z+1-LOW
;...-used 
;Z+X-out data str 
INT16_TO_TIME_STRING:
	push temp0
	push temp1
	push temp2
	push temp3
	push temp4
	push temp5
	push temp6
	push ZH
	push ZL
	ldd temp1, Z+0
	ldd temp2, Z+1
	ldi temp, HIGH(60 * 60)
	std Z+2, temp
	ldi temp, LOW(60 * 60)
	std Z+3, temp
	rcall DIVIDE
	;[div result]:[60 * 60 * 2]
	ldd temp, Z+0
	push temp 
	ldd temp, Z+1
	push temp
	rcall MUL16
	;[div result]:[div result * 60 * 60]
	ldd temp3, Z+2
	ldd temp4, Z+3
	;[data]:[data_pat]
	rcall DIFERENCE16

	;[diferense][data_pat]
	std Z+0, temp1
	std Z+1, temp2
	ldi temp, HIGH(60)
	std Z+2, temp
	ldi temp, LOW(60)
	std Z+3, temp
	rcall DIVIDE
	;[div result]:[60 * 60]
	ldd temp, Z+0
	push temp 
	ldd temp, Z+1
	push temp
	rcall MUL16
	;[div result]:[div result * 60 * 60]
	ldd temp3, Z+2
	ldd temp4, Z+3
	;[data]:[data_pat]
	rcall DIFERENCE16
	;[diferense][data_pat]
	std Z+0, temp1
	std Z+1, temp2
	ldi temp, HIGH(1)
	std Z+2, temp
	ldi temp, LOW(1)
	std Z+3, temp
	rcall DIVIDE
	ldd temp, Z+0
	push temp 
	ldd temp, Z+1
	push temp
	;[div result]:[60 * 60 * 2]
	rcall MUL16
	;[div result]:[div result * 60 * 60 *2]
	ldd temp3, Z+2
	ldd temp4, Z+3
	;[data]:[data_pat]
	rcall DIFERENCE16
	;[diferense][data_pat]
	
 	pop temp
	ldi ZH, HIGH(TIME_SET << 1)
	ldi ZL, LOW(TIME_SET << 1)
	add ZL, temp
	adc ZH, temp7
	add ZL, temp
	adc ZH, temp7
	lpm temp1, Z+0
	lpm temp2, Z+1
	 
	pop temp
	pop temp
	ldi ZH, HIGH(TIME_SET << 1)
	ldi ZL, LOW(TIME_SET << 1)
	add ZL, temp
	adc ZH, temp7
	add ZL, temp
	adc ZH, temp7
	lpm temp3, Z+0
	lpm temp4, Z+1

	pop temp
	pop temp
	ldi ZH, HIGH(TIME_SET << 1)
	ldi ZL, LOW(TIME_SET << 1)
	add ZL, temp
	adc ZH, temp7
	add ZL, temp
	adc ZH, temp7
	lpm temp5, Z+0
	lpm temp6, Z+1
	pop temp

	pop ZL
	pop ZH

	ldi temp, ':'
	std Z+0, temp5
	std Z+1, temp6
	std Z+2, temp
	std Z+3, temp3
	std Z+4, temp4
	std Z+5, temp
	std Z+6, temp1
	std Z+7, temp2
	ldi temp, 0x00
	std Z+8, temp
	pop temp6
	pop temp5
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	pop temp0
	ret 

.equ CLEAR_DISPLAY = 0x01 
.equ CURSOR_TO_DEFAULT_POS = 0x02 

.equ CURSOR_AUTO_MOVE = 0x04 
.equ CURSOR_AUTO_MOVE_RIGHT = 0x02;else left 
.equ CURSOR_AUTO_MOVE_ENABLE = 0x01;else disable 

.equ ACTIVATE_DISPLAY = 0x08 
.equ ACTIVATE_ACTIVATE = 0x04; else deactivate 
.equ ACTIVATE_DISPLAY_CURSOR_VISIABLE = 0x02;else unvisiable 
.equ ACTIVATE_DISPLAY_CURSOR_MIGAET = 0x01;rlse ne migaet 

.equ MOVE_DISPLAY = 0x18 
.equ MOVE_CURSOR = 0x10 
.equ MOVE_CURSOR_RIGHT = 0x04 
.equ MOVE_DISPLAY_RIGHT = MOVE_CURSOR_RIGHT 

.equ SET_WIND_PARAMS = 0x20 
.equ SET_8_BIT = 0x10;else 4 bit 
.equ SET_2_LINES = 0x08;else 1 line 
.equ SET_5_7PX = 0x04; else 5x10px 

.equ WRITE_IN_SGRAM = 0x40 

.equ WRITE_IN_DDRAM = 0x80 

.equ WRITE_IN_BOTTOM = 0x40

INIT_DISPLAY: 
	push temp0 
	push temp1 
	push temp2 
	push temp3 
	push temp4 
	rcall WAIT 

	ldi temp0, 0 
	ldi temp1, 1 
	ldi temp2, 2 
	ldi temp3, 3 

	out PORTC, temp0 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp4, SET_WIND_PARAMS | SET_8_BIT | SET_2_LINES 
	out PORTB, temp4 
	out PORTC, temp0 
	rcall WAIT_SMALL 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp4,ACTIVATE_DISPLAY 
	out PORTB, temp4 
	out PORTC, temp0 
	rcall WAIT_SMALL 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp4, CLEAR_DISPLAY 
	out PORTB, temp4 
	out PORTC, temp0 
	rcall WAIT_SMALL 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp4, CURSOR_AUTO_MOVE | CURSOR_AUTO_MOVE_RIGHT 
	out PORTB, temp4 
	out PORTC, temp0 
	rcall WAIT_SMALL 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp4, ACTIVATE_DISPLAY | ACTIVATE_ACTIVATE 
	out PORTB, temp4 
	out PORTC, temp0 
	rcall WAIT_SMALL 

	pop temp4 
	pop temp3 
	pop temp2 
	pop temp1 
	pop temp0 

	ret 

CURSOR_BACK: 
	push temp0 
	push temp1 
	push temp2 
	push temp3 
	push temp4 

	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp4, CURSOR_TO_DEFAULT_POS 
	out PORTB, temp4 
	out PORTC, temp0 
	rcall WAIT_SMALL 

	pop temp4 
	pop temp3 
	pop temp2 
	pop temp1 
	pop temp0 
	ret 

DRAW: 
	push temp0 
	push temp1 
	push temp2 
	push temp3 
	push temp6 
	
	ldi temp0, 0 
	ldi temp1, 1 
	ldi temp2, 2 
	ldi temp3, 3 

	out PORTC, temp0 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp6, WRITE_IN_DDRAM 
	add temp5, temp6 
	out PORTB, temp5 
	out PORTC, temp0 
	rcall WAIT_SMALL 

draw_str: 
	lpm temp4, Z+ 
	tst temp4 
	breq draw_end 
	out PORTC, temp3 
	rcall WAIT_SMALL 
	out PORTB, temp4 
	out PORTC, temp1 
	rcall WAIT_SMALL 
	rjmp draw_str 

draw_end: 
	pop temp6 
	pop temp3 
	pop temp2 
	pop temp1 
	pop temp0 
	ret 


DRAW2: 
	push temp0 
	push temp1 
	push temp2 
	push temp3 
	push temp6
	push ZH
	push ZL 

	ldi temp0, 0 
	ldi temp1, 1 
	ldi temp2, 2 
	ldi temp3, 3 

	out PORTC, temp0 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	ldi temp6, WRITE_IN_DDRAM | WRITE_IN_BOTTOM
	add temp5, temp6 
	out PORTB, temp5 
	out PORTC, temp0 
	rcall WAIT_SMALL 

draw2_str:
	ld temp4, Z+ 
	tst temp4 
	breq draw2_end 
	out PORTC, temp3 
	rcall WAIT_SMALL 
	out PORTB, temp4 
	out PORTC, temp1 
	rcall WAIT_SMALL 
	rjmp draw2_str 

draw2_end:
	pop ZL
	pop ZH 
	pop temp6 
	pop temp3 
	pop temp2 
	pop temp1 
	pop temp0 
	ret 

WAIT: 

	push temp1 
	push temp2 
	push temp3 
	ldi temp1, 0xFD 
wait_loop1: 
	inc temp1 
	breq wait_end 
	ldi temp2, 0x80 
wait_loop2: 
	inc temp2 
	breq wait_loop1 
	ldi temp3, 0x00 
wait_loop3: 
	inc temp3 
	breq wait_loop2 
	rjmp wait_loop3 

wait_end: 
	pop temp3 
	pop temp2 
	pop temp1 
	ret 


WAIT_SMALL: 

	push temp1 
	push temp2 
	push temp3 
	ldi temp1, 0xFE 
wait_loop11: 
	inc temp1 
	breq wait_end1 
	ldi temp2, 0xF0 
wait_loop21: 
	inc temp2 
	breq wait_loop11 
	ldi temp3, 0x00
wait_loop31: 
	inc temp3 
	breq wait_loop21 
	rjmp wait_loop31 

wait_end1: 
	pop temp3 
	pop temp2 
	pop temp1 
	ret 


SELECT_TIME_MODE: 
.db "v1.2", 0 
TIME_LEFT: 
.db "Time Left",0 
TOTAL_TIME: 
.db "Total Time", 0 
BUTTON_RPRESSED: 
.db "Button pressed", 0 
BUTTON_0_RPRESSED: 
.db "Button 0 pressed", 0 
BUTTON_1_RPRESSED: 
.db "Button 1 pressed", 0 
BUTTON_2_RPRESSED: 
.db "Button 2 pressed", 0 
BUTTON_3_RPRESSED: 
.db "Timers are working", 0 
BUTTON_4_RPRESSED: 
.db "Button 4 pressed", 0 
BUTTON_5_RPRESSED: 
.db "Button 5 pressed", 0 
BUTTON_6_RPRESSED: 
.db "Button 6 pressed", 0 
BUTTON_7_RPRESSED: 
.db "Button 7 pressed", 0 
HOUR_STR: 
.db "hour", 0 
HOURS_STR: 
.db "hours", 0
TIME_SET:
.db "00010203040506070809"
.db "10111213141516171819"
.db "20212223242526272829"
.db "30313233343536373839"
.db "40414243444546474849"
.db "50515253545556575859"
.db "60616263646566676869",0
NUMBERS:
.db "0123456789",0
