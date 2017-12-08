.include "m8515def.inc" ;oaee ii?aaaeaiee ATmega8515 

.equ SECUND = 1
.equ FREQUANCY = 8000000 / SECUND 
.equ FREQUANCY_DIV = 256
.equ MINUTE = 60 * SECUND 
.equ HOUR = 60 * MINUTE 
.equ STRUCT_LEN = 4
.equ MEM_START = 0x60

.equ TIME_SETUP_STATE = 0
.equ TIME_INTERVAL_STATE = 1
.equ TIME_COUNTING_STATE = 2
.equ OUT_RESULT_STATE = 3

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
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT
	rjmp TIMER_A_INTERRUPT


PUSHA:
	pop XL
	pop XH
	push temp
	push temp1
	push temp2
	push temp3
	push temp4
	push temp5
	push temp6
	push temp7
	push XH
	push XL
	ret

POPALL:
	pop XL
	pop XH
	pop temp7
	pop temp6
	pop temp5
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	pop temp
	push XH
	push XL
	ret

MY_SLEEP: 
	ldi temp, (1 << SE) | (2 << ISC00)
	out MCUCR, temp  
	sleep 
	ret 

TROLLEY_TIMER012:
	ldi ZH, HIGH(MEM_START) 
	ldi ZL, LOW(MEM_START) 
	ldd temp1,Z + 0 * STRUCT_LEN + 2
	ldd temp2,Z + 0 * STRUCT_LEN + 3
	ldd temp3,Z + 1 * STRUCT_LEN + 2
	ldd temp4,Z + 1 * STRUCT_LEN + 3
	ldd temp5,Z + 2 * STRUCT_LEN + 2
	ldd temp6,Z + 2 * STRUCT_LEN + 3
	std Z+(9 * STRUCT_LEN + 0), temp1 
	std Z+(9 * STRUCT_LEN + 1), temp2 
	std Z+(9 * STRUCT_LEN + 2), temp3 
	std Z+(9 * STRUCT_LEN + 3), temp4 
	std Z+(9 * STRUCT_LEN + 4), temp5 
	std Z+(9 * STRUCT_LEN + 5), temp6
	ret

INIT_INTERRUPT: 
	ldi temp, (1 << SE) | (2 << ISC00)
	out MCUCR, temp   
	ldi temp,low(RAMEND) 
	out SPL,temp 
	ldi temp,high(RAMEND) 
	out SPH,temp 
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
	ldi temp, 0xFF -4 -8 -16 -32
	out TIMSK, temp 
	ldi temp, 0x00 
	out TCNT1H, temp 
	out TCNT1L, temp 
	ldi temp, HIGH(FREQUANCY / FREQUANCY_DIV)
	out OCR1AH, temp 
	ldi temp, LOW(FREQUANCY / FREQUANCY_DIV)
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
	ldi temp, 3
	rcall DRAW_CURRENT_TIME
	ldi temp0, 0x00 
	ldi temp2, 0x01
	ldi temp3, 0x03
	ldi temp4, 0x00
	ldi temp5, 0x00 
	sei 


LOOP: 
	rcall MY_SLEEP 
	rjmp LOOP 
	ret 


TIMER_A_INTERRUPT:
	push temp2
	ldi temp, 0x00
	sbrc temp2, 3
	rjmp stop_counting_force
	ldi temp, 0x03
	pop temp2
	push temp2
	sbrc temp2, 7
	ldi temp, 3
	sbrc temp2, 6
	ldi temp, 5
	sbrc temp2, 5
	ldi temp, 6
	sbrc temp2, 4
	ldi temp, 7
	ldi ZL, LOW(MEM_START)
	ldi ZH, HIGH(MEM_START)
	ldi temp5, HIGH(STRUCT_LEN)
	ldi temp6, LOW(STRUCT_LEN)
	ldi temp7, 0x09

adding_circle:
	dec temp7
	breq adding_end2
	rcall ADD16
	add ZL, temp6
	adc ZH, temp5
	rjmp adding_circle

adding_end2:
	ldi ZL, LOW(MEM_START + 3 * STRUCT_LEN)
	ldi ZH, HIGH(MEM_START + 3 * STRUCT_LEN)
	ldd temp6, Z+1
	tst temp6
	brne go_continue_counting
	ldd temp6, Z+2
	tst temp6
	brne go_continue_counting
	ldd temp6, Z+3
	tst temp6
	breq stop_counting
go_continue_counting:
	rcall DRAW_CURRENT_TIME
	pop temp2
	reti 

stop_counting:
	pop temp2;O_o
	lsl temp2
	push temp2
stop_counting_force:
	ldi temp, 0
	out TCCR1B, temp
	ldi ZL, LOW(FORCE_COUNTING_STOP << 1) 
	ldi ZH, HIGH(FORCE_COUNTING_STOP <<  1) 
	ldi temp5, 0x00 
	rcall DRAW 
	pop temp2;O_o
	reti

;Z012 - первое число и результат
;Z345 - второе число
;Zx старше Zx+1


ADD24:
	rcall PUSHA
	ldd temp1, Z+0 
	ldd temp2, Z+1 
	ldd temp3, Z+2 
	ldd temp4, Z+3 
	ldd temp5, Z+4
	ldd temp6, Z+5
	add temp3, temp6 
	adc temp2, temp5
	adc temp1, temp4
	std Z+0, temp1 
	std Z+1, temp2 
	std Z+2, temp3 
	rcall POPALL
	ret 

ADD16: 
	ldd temp1, Z+0 
	ldd temp2, Z+1 
	ldd temp3, Z+2
	ldd temp4, Z+3
	tst temp1
	brmi if_minus
	add temp4, temp1
	brcc add_16_i 
	inc temp3
	brcc add_16_i
	inc temp2
add_16_i:

ADD16_END: 
	std Z+1, temp2
	std Z+2, temp3 
	std Z+3, temp4 
add_16_cont:
	tst temp2
	brne r2253
	tst temp3
	brne r2253
	tst temp4
r2253:
	ret 

if_minus:
	push temp
	ldi temp, 0xFF 
	add temp4, temp1 
	adc temp3, temp
	adc temp2, temp
	std Z+1, temp2 
	std Z+2, temp3 
	std Z+3, temp4
	pop temp
	rjmp add_16_cont

;temp from what
DRAW_PORTION:
	rcall PUSHA
	rcall ADD_16_16_16
	ldd temp1,Z+0
	ldd temp2,Z+1
	std Z+3, temp1
	std Z+4, temp2
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
	ldd temp1, Z+2
	ldd temp2, Z+3
	ldi ZH, HIGH(9 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(9 * STRUCT_LEN + MEM_START)
	push temp
	ldd temp, Z+0
	std Z+3, temp
	ldd temp, Z+1
	std Z+4, temp
	ldi temp, 0x00
	std Z+0, temp
	pop temp 
	std Z+1, temp1
	std Z+2, temp2
	rcall DIVIDE
	rcall FLOAT_16_TO_STR 
	ldi temp5, WRITE_IN_BOTTOM
	rcall DRAW2
	rcall POPALL
	ret
;temp from what


DRAW_CURRENT_TIME:
	rcall PUSHA
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
	ldd temp, Z+1
	ldd temp1, Z+2
	ldd temp2, Z+3
	ldi ZH, HIGH(9 * STRUCT_LEN + MEM_START) 
	ldi ZL, LOW(9 * STRUCT_LEN + MEM_START)
	
	std Z+0, temp
	std Z+1, temp1
	std Z+2, temp2
	rcall INT24_TO_TIME_STRING 
	ldi temp5,  WRITE_IN_BOTTOM
	rcall DRAW2
	rcall POPALL
	ret

 
INIT_VARIABLES: 
	push temp4
	push temp 
	push temp1
	push ZL
	push ZH
	ldi temp1, 10
init_variables_loop:
	ldi temp, 1 
	st Z+, temp 
	ldi temp, 0 
	st Z+, temp 
	st Z+, temp
	st Z+, temp
	dec temp1
	brne init_variables_loop

	pop ZH
	pop ZL

	ldi temp, -1
	std Z + 3 * STRUCT_LEN, temp 
	ldi temp, 0
	std Z + 3 * STRUCT_LEN + 1, temp 
	ldi temp, HIGH(HOUR * 3) 
	std Z + 3 * STRUCT_LEN + 2, temp 
	ldi temp, LOW(HOUR * 3) 
	std Z + 3 * STRUCT_LEN + 3, temp 

	pop temp1
	pop temp
	pop temp4
	ret 

ON_BUTTON_PRESSED_INTERRUPT:
	ldi temp5, 0x03
	ldi temp6, 0x00
	ldi temp7, 0x40
	in temp1, PIND 
	sbrs temp1, 3 
	rjmp ON_BUTTON3_PRESSED 
	sbrs temp1, 4 
	rjmp ON_BUTTON4_PRESSED 
	sbrs temp1, 5 
	rjmp ON_BUTTON5_PRESSED 
	sbrs temp1, 6 
	rjmp ON_BUTTON6_PRESSED 
	sbrs temp1, 7 
	rjmp ON_BUTTON7_PRESSED

ON_BUTTON3_PRESSED:
	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button3_pressed_start_timing
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button3_nop
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button3_nop 
	sbrc temp2, TIME_SETUP_STATE
	rcall on_time_seup_state_start 
	reti

on_time_seup_state_start:
	inc temp4
	ret


on_button3_pressed_start_timing:
	ldi ZL, LOW(BUTTON_3_RPRESSED << 1) 
	ldi ZH, HIGH(BUTTON_3_RPRESSED <<  1) 
	ldi temp5, 0x00 
	rcall DRAW 
	ldi temp, 0x00 
	out TCCR1A, temp 
	ldi temp, 0x04 + 8
	out TCCR1B, temp
	ldi temp2, 1 << TIME_COUNTING_STATE 
	ret
on_button3_nop:
	ldi temp, 0x03
	rcall DRAW_CURRENT_TIME
	andi temp2, 0x0F
	ori temp2, 0x80
	ret

ON_BUTTON6_PRESSED:
	dec temp5
	inc temp6
	lsr temp7
ON_BUTTON5_PRESSED:
	dec temp5
	inc temp6
	lsr temp7
ON_BUTTON4_PRESSED: 
	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button4_pressed_set_1hour_interval
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button4_out_counting_time
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button4_out_proportion
	sbrc temp2, TIME_SETUP_STATE
	rcall on_button4_seup_state_start 
	reti

on_button4_seup_state_start:
	rcall PUSHA
	push temp4
	ldi ZH, HIGH(5 * STRUCT_LEN + MEM_START)
	ldi ZL, LOW(5 * STRUCT_LEN + MEM_START)
	tst temp4
	breq rr_t3
rr_t1:
	push temp1
	ldi temp1, STRUCT_LEN
	add ZL, temp1
	brcc rr_t1_i
	inc ZH
	rr_t1_i:
	pop temp1
	dec temp4
	brne rr_t1

rr_t3:
	push ZH
	push ZL
	tst temp6
	brne tg1
	ldi temp1, HIGH(HOUR)
	ldi temp2, LOW(HOUR)
	rjmp tg3
tg1:
	dec temp6
	brne tg2
	ldi temp1, HIGH(MINUTE)
	ldi temp2, LOW(MINUTE)
	rjmp tg3
tg2:
	dec temp6
	ldi temp1, HIGH(SECUND)
	ldi temp2, LOW(SECUND)
tg3:
	ldd temp3, Z+1
	ldd temp4, Z+2
	ldd temp5, Z+3
	ldi ZH, HIGH(8 * STRUCT_LEN + MEM_START)
	ldi ZL, LOW(8 * STRUCT_LEN + MEM_START)
	std Z+0, temp3
	std Z+1, temp4
	std Z+2, temp5
	push temp0
	ldi temp, 0x00
	std Z+3, temp0
	pop temp0
	std Z+4, temp1
	std Z+5, temp2
	rcall ADD24
	ldd temp1, Z+0
	ldd temp2, Z+1
	ldd temp3, Z+2
	pop ZL
	pop ZH
	std Z+1, temp1
	std Z+2, temp2
	std Z+3, temp3
	pop temp5
	ldi temp, 0x05
	add temp, temp5
	rcall DRAW_CURRENT_TIME
	rcall POPALL
	ret

on_button4_pressed_set_1hour_interval:
	mov temp, temp5
	rcall SET_HOURS
	ldi temp, 0x03
	rcall DRAW_CURRENT_TIME
	ret
on_button4_out_counting_time:
	ldi temp, 0x05
	add temp, temp6
	ldi temp6, 0x00
	rcall DRAW_CURRENT_TIME
	andi temp2, 0x0F
	or temp2, temp7
	ret
on_button4_out_proportion:
	mov temp, temp6
	rcall DRAW_PORTION
	ret

ON_BUTTON7_PRESSED:
	sbrc temp2, OUT_RESULT_STATE
	rcall on_button7_pressed_get_sum
	sbrc temp2, TIME_COUNTING_STATE
	rcall on_button7_pressed_stop_timer
	sbrc temp2, TIME_INTERVAL_STATE
	rcall on_button7_nop
	sbrc temp2, TIME_SETUP_STATE
	ldi temp2,1 << TIME_INTERVAL_STATE
	reti
on_button7_pressed_get_sum:
	push temp2
	rcall ADD_16_16_16
	push temp0
	push temp1
	push temp2
	ldi temp0, 0x00
	ldd temp1, Z+0
	ldd temp2, Z+1
	std Z+0, temp0
	std Z+1, temp1
	std Z+2, temp2
	pop temp2
	pop temp1
	pop temp0 
	rcall INT24_TO_TIME_STRING
	ldi temp, 0x05
	ldi temp5, WRITE_IN_BOTTOM
	rcall DRAW2
	pop temp2
	ret


on_button7_pressed_stop_timer:
	push temp2
	sbrc temp2, 7
	rjmp on_button7_stop_counting
	sbrc temp2, 6
	ldi temp, 0
	sbrc temp2, 5
	ldi temp, 1
	sbrc temp2, 4
	ldi temp, 2

	ldi ZL, LOW(MEM_START)
	ldi ZH, HIGH(MEM_START)
	push temp1
	push temp2
	ldi temp1, HIGH(STRUCT_LEN)
	ldi temp2, LOW(STRUCT_LEN)
on_button7_pressed_stop_timer_circl:
	tst temp
	breq on_button7_pressed_stop_timer_circl_end
	dec temp
	add ZL, temp2
	adc ZH, temp1
	rjmp on_button7_pressed_stop_timer_circl
on_button7_pressed_stop_timer_circl_end:
	std Z+0, temp
	std Z+STRUCT_LEN*5+0, temp
	pop temp2
	pop temp1
	pop temp2
	ret
on_button7_nop:
	nop
	ret
on_button7_stop_counting:
	pop temp2
	lsl temp2
	ret

SET_HOURS:
	push ZL
	push ZH
	push temp2
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
	ldi temp2, 0x00
	std Z+1, temp2
	std Z+2, temp3
	std Z+3, temp4
	pop temp4
	pop temp3
	pop temp2
	pop ZH
	pop ZL
	ret

DIFERENCE24:
    com temp2
	com temp1
	com temp0 
	add temp2, temp5
	adc temp1, temp4 
	adc temp0, temp3
	com temp2
	com temp1
	com temp0
	ret 
	

FLOAT_16_TO_STR:
	rcall PUSHA
	ldd temp7, Z+4
	ldd temp8, Z+5
	std Z+0, temp7
	std Z+1, temp8
	ldi temp5, 0x04
float_16_to_str_loop:
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
	dec temp5
	brne float_16_to_str_loop
	pop temp1
	pop temp2
	pop temp3
	pop temp4
	ldi temp, '0'
	add temp1, temp
	add temp2, temp
	add temp3, temp
	add temp4, temp
	std Z+0, temp4
	std Z+1, temp3
	ldi temp, ','
	std Z+2, temp
	std Z+3, temp2
	std Z+4, temp1
	ldi temp, '%'
	std Z+5, temp
	ldi temp, ' '
	std Z+6, temp
	std Z+7, temp
	std Z+8, temp
	ldi temp, 0
	std Z+9, temp
	rcall POPALL
	ret


DIVIDE: 
	rcall PUSHA
	ldi temp, 40
	std Z+6, temp
	ldi temp0, 0x00
	ldi temp1, 0x00
	ldi temp2, 0x00
	ldd temp3, Z+3
	ldd temp4, Z+4
	ldi temp5, 0x00
	ldi temp6, 0x00
	ldi temp7, 0x00
	ldi temp8, 0x00
divide_circle:
	push temp1
	push temp2
	push temp3
	ldd temp1, Z+0
	ldd temp2, Z+1
	ldd temp3, Z+2
	lsl temp3
	rol temp2
	rol temp1
	std Z+0, temp1
	std Z+1, temp2
	std Z+2, temp3
	pop temp3
	pop temp2
	pop temp1
	rol temp2
	rol temp1
	rol temp0
	push temp5
	push temp4
	push temp3
	mov temp5, temp4
	mov temp4, temp3
	ldi temp3, 0x00
	rcall DIFERENCE24
	pop temp3
	pop temp4
	pop temp5 
	brmi recov
	brcc divide_circle_tail
	inc temp8
	divide_circle_i:
divide_circle_tail:
	std Z+7, temp
	ldd temp, Z+6
	dec temp 
	breq divide_circle_end
	std Z+6, temp
	ldd temp, Z+7
	lsl temp8 
	rol temp7
	rol temp6
	rol temp5
	rjmp divide_circle
divide_circle_end:
	std Z+0, temp5
	std Z+1, temp6
	std Z+4, temp7
	std Z+5, temp8
	rcall POPALL
	ret 
recov: 
	push temp8
	ldi temp8, 0x00
	add temp2, temp4 
	adc temp1, temp3
	adc temp0, temp8
	pop temp8
	rjmp divide_circle_tail

;!!!сохраняет результаты в Z+2 Z+3 Z+4!!!
;!!!Z+4 OVERFLOW
MUL16:
	rcall PUSHA
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
	rcall POPALL
	ret
mul16_add:
	add temp6, temp2
	adc temp5, temp1
	brcc mul16_con
	inc temp7
	rjmp mul16_con
	
ADD_16_16_16:
	rcall TROLLEY_TIMER012
	ldi ZH,HIGH(9 * STRUCT_LEN + MEM_START)
	ldi ZL,LOW(9 * STRUCT_LEN + MEM_START)
	rcall PUSHA
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
	rcall POPALL
	ret 

INT24_TO_TIME_STRING:
	rcall PUSHA
	push ZH
	push ZL
	ldd temp0, Z+0
	ldd temp1, Z+1
	ldd temp2, Z+2
	ldi temp3, 0x00
	ldi temp4, 0x08
	mov r14, temp3
	mov r15, temp4
	mov YL, ZL
	mov YH, ZH
	add r15, ZL
	adc r14, ZH
	ldi temp4, HIGH(60 * 60)
	ldi temp5, LOW(60 * 60)
	rcall INT_24_TO_STRING_CORE
	ldi temp4, HIGH(60)
	ldi temp5, LOW(60)
	rcall INT_24_TO_STRING_CORE
	ldi temp4, HIGH(1)
	ldi temp5, LOW(1)
	rcall INT_24_TO_STRING_CORE
	pop ZL
	pop ZH
	ldi temp, 0x00
	std Z+8, temp
	rcall POPALL
	ret 

INT_24_TO_STRING_CORE:
	mov ZL, r15
	mov ZH, r14
	std Z+0, temp0
	std Z+1, temp1
	std Z+2, temp2
	push temp0
	std Z+3, temp4
	std Z+4, temp5
	rcall DIVIDE
	pop temp0
	ldd temp3, Z+1
	ldi ZH, HIGH(TIME_SET << 1)
	ldi ZL, LOW(TIME_SET << 1)
	add ZL, temp3
	brcc __16_40
	inc ZH
__16_40:
	add ZL, temp3
	brcc __16_41
	inc ZH
__16_41:
	push temp1
	push temp2
	push temp
	push ZH
	push ZL
	lpm temp1, Z+0
	lpm temp2, Z+1
	ldi temp, ':'
	mov ZL, YL
	mov ZH, YH
	st Z+, temp1
	st Z+, temp2
	st Z+, temp
	mov YH, ZH
	mov YL, ZL
	pop ZL
	pop ZH
	pop temp
	pop temp2
	pop temp1
	mov ZL, r15
	mov ZH, r14
	std Z+2, temp4
	std Z+3, temp5
	rcall MUL16
	ldd temp3, Z+4
	ldd temp4, Z+2
	push temp5
	ldd temp5, Z+3
	rcall DIFERENCE24
	pop temp5
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
	rcall PUSHA
	rcall WAIT 
	ldi temp0, 0 
	ldi temp1, 1 
	ldi temp2, 2 
	ldi temp3, 3 
	ldi temp4, SET_WIND_PARAMS | SET_8_BIT | SET_2_LINES 
	rcall SEND_BYTE_COMAND
	ldi temp4,ACTIVATE_DISPLAY 
	rcall SEND_BYTE_COMAND
	ldi temp4, CLEAR_DISPLAY 
	rcall SEND_BYTE_COMAND
	ldi temp4, CURSOR_AUTO_MOVE | CURSOR_AUTO_MOVE_RIGHT 
	rcall SEND_BYTE_COMAND
	ldi temp4, ACTIVATE_DISPLAY | ACTIVATE_ACTIVATE 
	rcall SEND_BYTE_COMAND
	rcall POPALL
	ret 

SEND_BYTE_COMAND:
	out PORTC, temp0 
	rcall WAIT_SMALL 
	out PORTC, temp2 
	rcall WAIT_SMALL 
	out PORTB, temp4 
	out PORTC, temp0
	ret

FLESH_STR_TO_MEM_STR:
	push temp4
	ldi XL, LOW(9 * STRUCT_LEN + MEM_START)
	ldi XH, HIGH(9 * STRUCT_LEN + MEM_START)
FLESH_STR_TO_MEM_STR_LOOP:
	lpm temp4, Z+
	st X+, temp4 
	tst temp4
	brne FLESH_STR_TO_MEM_STR_LOOP
	pop temp4
	ret

DRAW: 
	push temp5
	ldi temp5, 0x00
	rcall FLESH_STR_TO_MEM_STR
	ldi ZL, LOW(9 * STRUCT_LEN + MEM_START)
	ldi ZH, HIGH(9 * STRUCT_LEN + MEM_START)
	rcall DRAW2
	pop temp5
	ret 


DRAW2: 
	rcall PUSHA
	push ZH
	push ZL 
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
	rcall POPALL
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

TIME_SET:
.db "00010203040506070809"
.db "10111213141516171819"
.db "20212223242526272829"
.db "30313233343536373839"
.db "40414243444546474849"
.db "50515253545556575859"
.db "60616263646566676869"
SELECT_TIME_MODE: 
.db "v1.3", 0 
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
FORCE_COUNTING_STOP:
.db "Counting stoped",0
HOUR_STR: 
.db "hour", 0 
HOURS_STR: 
.db "hours", 0
COUNTING_STOP:
.db "Ready",0
