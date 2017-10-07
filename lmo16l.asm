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
.equ MOVE_DISPLAY_RIGHT = MOVE_UCURSOR_RIGHT

.equ SET_WIND_PARAMS = 0x20
.equ SET_8_BIT = 0x10;else 4 bit
.equ SET_2_LINES = 0x08;else 1 line
.equ SET_5_7PX = 0x04; else 5x10px

.equ WRITE_IN_SGRAM = 0x40

.equ WRITE_IN_DDRAM = 0x80
 
INIT_DISPLAY:
;20ms
		ldi temp0, 0
		ldi temp1, 1
		ldi temp2, 2
		ldi temp3, 3

		out PORTC, temp0
		out PORTC, temp2
		out PORTB, SET_8_BIT | SET_2_LINES | SET_5_7PX
		out PORTC, temp0
		rcall WAIT
		out PORTC, temp2
		out PB, ACTIVATE_DISPLAY
		out PORTC, temp0
		rcall WAIT
		out PORTC, temp2
		out PORTB, CLEAR_DISPLAY
		out PORTC, temp0
		rcall WAIT
		out PORTC, temp2
		out PORTB, CURSOR_AUTO_MOVE
		out PORTC, temp0
		rcall WAIT
		out PORTC, temp2
		out PORTB, ACTIVATE_DISPLAY | ACTIVATE_ACTIVATE
		out PORTC, temp0
		rcall WAIT

		ret

;temp4 - char
;temp5 - pos
DRAW:
		out PORTC, temp0
		out PORTC, temp2
		add temp5, 0x80
		add temp5, WRITE_IN_DDRAM
		out PORTB, temp5
		out PORTC, temp0
		rcall WAIT
		out PORTC, temp3
		out PB, temp4
		out PORTC, temp1
		rcall WAIT
		ret

WAIT:
		push temp1
		push temp2
		ldi temp1, 0x00
wait_loop1:
		inc temp1
		brne wait_end
		ldi temp2, 0x00
wait_loop2:
		inc temp2
		brne wait_loop2
		rjmp wait_loop1
wait_end:
		pop temp2
		pop temp1

