global _main
extern _printf
extern _system
extern _memset
extern _SetCursorPos
extern _Sleep
extern _GetAsyncKeyState
extern _GetStdHandle
extern _SetConsoleCursorPosition

section .data
message_title db "TicTacToe - x86 Assembly", 0Dh, 0Ah, 0 
message_win_x db "The game is over! X is the winner!", 0Dh, 0Ah, 0 
message_win_o db "The game is over! O is the winner!", 0Dh, 0Ah, 0 
message_draw db "The game is over! It's a draw!", 0Dh, 0Ah, 0
message_line_break db 0Dh, 0Ah, 0

format_map db "%c", 0

vk_left_state dd 0
vk_right_state dd 0
vk_up_state dd 0
vk_down_state dd 0
vk_return_state dd 0
vk_escape_state dd 0

; Used for cursor
x_pos dd 0
y_pos dd 0
index_pos dd 0

map_width dd 3
map_height dd 3
map_size dd 9
map_array times 9 db 0
map_cursor db 254

brick_turn db 'X' 
brick_x db 'X'
brick_o db 'O'

; Used in for loops
index dd 0
index_x dd 0
index_y dd 0

; Used in check_win
arr_brick_turn db 0
count_x dd 0
count_y dd 0
count_xy dd 0
count_yx dd 0
count_draw dd 0

win_amount dd 3
win_state db 0
win_return db 0

code_cls db "cls", 0

section .bss
section .text

_main:
	; Stack
	push ebp
	mov ebp, esp

label_main_loop:
	;* Gets keyboard states for arrow keys and store their states in memory    *;
	;***************************************************************************;

	; Gets keyboard state for left arrow key
	mov esi, esp
	push 25h ; VK_LEFT
	call _GetAsyncKeyState
	and eax, 1h
	mov dword[vk_left_state], eax

	; Gets keyboard state for right arrow key
	mov esi, esp
	push 27h ; VK_RIGHT
	call _GetAsyncKeyState
	and eax, 1h
	mov dword[vk_right_state], eax

	; Gets keyboard state for up arrow key
	mov esi, esp
	push 26h ; VK_UP
	call _GetAsyncKeyState
	and eax, 1h
	mov dword[vk_up_state], eax

	; Gets keyboard state for down arrow key
	mov esi, esp
	push 28h ; VK_DOWN 
	call _GetAsyncKeyState
	and eax, 1h
	mov dword[vk_down_state], eax

	; Gets keyboard state for return key
	mov esi, esp
	push 0dh ; VK_RETURN
	call _GetAsyncKeyState
	and eax, 1h
	mov dword[vk_return_state], eax

	; Gets keyboard state for escape key
	mov esi, esp
	push 1bh ; VK_ESCAPE
	call _GetAsyncKeyState
	and eax, 1h
	mov dword[vk_escape_state], eax

	; Calculates 2d cursor position index for current x_pos and y_pos (y * width + x) 
	mov edx, dword[map_width]
	mov eax, dword[y_pos]
	mul edx
	mov edx, dword[x_pos]
	add eax, edx
	mov dword[index_pos], eax

	;* Changes the cursor position if keystates is 1, and is position is in bound of map *;
	;*************************************************************************************;

	; Subtracts x_pos if left arrow key is not pressed and checks if is in bound of map
	cmp dword[vk_left_state], 0
	jz label_if_not_left_keystate

	cmp dword[x_pos], 0
	jz label_if_not_left_keystate

	sub dword[x_pos], 1

label_if_not_left_keystate:
	; Adds x_pos if right arrow key is not pressed and checks if is in bound of map
	cmp dword[vk_right_state], 0
	jz label_if_not_right_keystate

	mov eax, dword[map_width]
	sub eax, 1
	cmp dword[x_pos], eax
	jz label_if_not_right_keystate

	add dword[x_pos], 1

label_if_not_right_keystate:
	; Subtracts y_pos if up arrow key is not pressed and checks if is in bound of map
	cmp dword[vk_up_state], 0
	jz label_if_not_up_keystate

	cmp dword[y_pos], 0
	jz label_if_not_up_keystate

	sub dword[y_pos], 1

label_if_not_up_keystate:
	; Adds y_pos if down arrow key is not pressed and checks if is in bound of map
	cmp dword[vk_down_state], 0
	jz label_if_not_down_keystate

	mov eax, dword[map_height]
	sub eax, 1
	cmp dword[y_pos], eax
	jz label_if_not_down_keystate

	add dword[y_pos], 1

label_if_not_down_keystate:

	;* Selection logic														   *;
	;***************************************************************************;

	; Checks if return is not pressed
	cmp dword[vk_return_state], 0
	jz label_if_not_return_keystate

	; Checks if win_state is true
	cmp byte[win_state], 1
	je label_map_reset

	; Puts index position into register
	mov edx, dword[index_pos]

	; Checks if not brick already exists at current index position
	cmp byte[map_array + edx], 0
	jnz label_if_not_return_keystate

label_if_not_brick_exists:
	; Places x brick in map_array at cursor position
	mov ah, byte[brick_turn]
	mov byte[map_array + edx], ah

	; Checks brick turn x or o
	mov ah, byte[brick_turn]
	cmp byte[brick_o], ah
	jz label_if_not_brick_x

	; Switches brick turn to o
	mov ah, byte[brick_o]
	mov byte[brick_turn], ah

	jmp label_if_not_return_keystate

label_if_not_brick_x:
	; Switches brick turn to x
	mov ah, byte[brick_x]
	mov byte[brick_turn], ah
label_if_not_return_keystate:

	;* Reset logic														   *;
	;***************************************************************************;
	
	; Checks if not escape is pressed
	cmp dword[vk_escape_state], 0
	jz label_if_not_escape_keystate

label_map_reset:
	; Clears console
	push  code_cls
	call _system

	; Sets win state to false
	mov byte[win_state], 0

	; Fills map_array with zeros
	push dword[map_size]
	push 0
	push map_array
	call _memset

label_if_not_escape_keystate:

	;* Prints map array to console											   *;
	;***************************************************************************;

	; Prints title to console
	push message_title
	call _printf

	; Sets index_y to 0
	mov dword[index_y], 0

label_print_map_y:
		; Sets index_x to 0
		mov dword[index_x], 0

	label_print_map_x:
			; Calculates 2d index for current x and y (y * width + x) 
			mov edx, dword[map_width]
			mov eax, dword[index_y]
			mul edx
			mov edx, dword[index_x]
			add eax, edx
			mov dword[index], eax

			; Checks if cursor position index equals current index position
			mov eax, dword[index_pos]
			cmp dword[index], eax
			jnz label_if_not_index_equals_cursor_pos

			; Prints cursor to console
			push dword[map_cursor]
			push format_map
			call _printf
			add esp, 4
			jmp label_if_not_index_equals_cursor_pos_end

		label_if_not_index_equals_cursor_pos:
			; Prints map cell to console
			mov ebx, dword[index]
			push dword[map_array + ebx]
			push format_map
			call _printf
			add esp, 4
			add eax, 1

		label_if_not_index_equals_cursor_pos_end:
			; Indcrement index_x
			add dword[index_x], 1

			; Checks if index_x equal width
			mov eax, dword[index_x]
			cmp dword[map_width], eax
			jnz label_print_map_x

		; Prints line break to console
		push message_line_break
		call _printf
		add esp, 4

		; Indcrement index_y
		add dword[index_y], 1

		; Checks if index_y equal height
		mov eax, dword[index_y]
		cmp dword[map_height], eax
		jnz label_print_map_y

	;* Checks and print win messages										   *;
	;***************************************************************************;

	; Checks win for brick_x *************************
	mov ah, byte[brick_x]
	call _check_win
	cmp byte[win_return], 1
	jne label_if_win_is_not_brick_x

	; Prints win message for brick_x
	push message_win_x
	call _printf
	jmp label_win_end

label_if_win_is_not_brick_x:
	; Checks win for brick_o *************************
	mov ah, byte[brick_o]
	call _check_win
	cmp byte[win_return], 1
	jne label_if_win_is_not_brick_o

	; Prints win message for brick_o
	push message_win_o
	call _printf
	jmp label_win_end

label_if_win_is_not_brick_o:
	; Checks for a draw ******************************
	mov ah, 1 ; Should not be 0, brick_x or brick_o
	call _check_win
	mov eax, dword[map_size]
	cmp dword[count_draw], eax
	jne label_win_end

	; Sets win_state to true
	mov byte[win_state], 1

	; Prints draw message
	push message_draw
	call _printf
	jmp label_win_end

label_win_end:

	;* Misc section															   *;
	;***************************************************************************;

	; Sleeps for 10 ms
	mov esi, esp 
	push 10
	call _Sleep

	; Sets console cursor to 0, 0
	push -11
	call _GetStdHandle
	mov ecx, 0
	push ecx
	push eax
	call _SetConsoleCursorPosition

	; Main loop end
	jmp label_main_loop

	; Return
	mov esp, ebp
	pop ebp
	ret

_check_win: ; boolean_t check_win(char brick_turn)
	; Stack
	push ebp
	mov ebp, esp

	; Arguments
	mov byte[arr_brick_turn], ah

	;* Checks for win														   *;
	;***************************************************************************;

	; Sets draw count to 0
	mov dword[count_draw], 0

	; Sets index_y to 0
	mov dword[index_y], 0

label_check_map_y:
		; Sets index_x to 0
		mov dword[index_x], 0

		; Sets count values to 0
		mov dword[count_x], 0
		mov dword[count_y], 0
		mov dword[count_xy], 0
		mov dword[count_yx], 0

		label_check_map_x:
			; Calculates 2d index (y * width + x) 
			mov edx, dword[map_width]
			mov eax, dword[index_y]
			mul edx
			mov edx, dword[index_x]
			add eax, edx

			; Increments count_draw if current index is not 0
			cmp byte[map_array + eax], 0
			je label_if_not_count_draw
			add dword[count_draw], 1

		label_if_not_count_draw:
			; Increments count_x if current index is brick
			mov ch, byte[arr_brick_turn]
			cmp byte[map_array + eax], ch
			jne label_if_not_count_x
			add dword[count_x], 1

		label_if_not_count_x:
			; Calculates 2d index (x * width + y) 
			mov edx, dword[map_width]
			mov eax, dword[index_x]
			mul edx
			mov edx, dword[index_y]
			add eax, edx
			mov dword[index], eax

		; Increments count_y if current index is brick
			mov ch, byte[arr_brick_turn]
			cmp byte[map_array + eax], ch
			jne label_if_not_count_y
			add dword[count_y], 1

		label_if_not_count_y:
			; Calculates 2d calculate diagonally index (x * width + x) 
			mov edx, dword[map_width]
			mov eax, dword[index_x]
			mul edx
			mov edx, dword[index_x]
			add eax, edx
			mov dword[index], eax

			; Increments count_xy if current index is brick
			mov ch, byte[arr_brick_turn]
			cmp byte[map_array + eax], ch
			jne label_if_not_count_xy
			add dword[count_xy], 1

		label_if_not_count_xy:
			; Calculates 2d calculate diagonally index (x * WIDTH + (WIDTH - x - 1)) 
			mov edx, dword[map_width]
			mov eax, dword[index_x]
			mul edx 
			mov edx, dword[map_width]
			sub edx, dword[index_x]
			sub edx, 1
			add eax, edx
			mov dword[index], eax

			; Increments count_yx if current index is brick
			mov ch, byte[arr_brick_turn]
			cmp byte[map_array + eax], ch
			jne label_if_not_count_yx
			add dword[count_yx], 1

		label_if_not_count_yx:
			; Indcrement index_x
			add dword[index_x], 1

			; Checks if index_x equal width
			mov eax, dword[index_x]
			cmp dword[map_width], eax
			jnz label_check_map_x

		; Checks win count values: if ((count_x == map_win) || (count_y == map_win) || (count_xy == map_win) || (count_yx == map_win))
		mov eax, dword[win_amount]
		cmp dword[count_x], eax
		je label_if_win_true
		
		mov eax, dword[win_amount]
		cmp dword[count_y], eax
		je label_if_win_true

		mov eax, dword[win_amount]
		cmp dword[count_xy], eax
		je label_if_win_true

		mov eax, dword[win_amount]
		cmp dword[count_yx], eax
		jne label_if_win_false

	label_if_win_true:
		; Sets win_state to true
		mov byte[win_state], 1
		mov byte[win_return], 1

		; Return
		mov esp, ebp
		pop ebp
		ret

	label_if_win_false:
		; Indcrement index_y
		add dword[index_y], 1

		; Checks if index_y equal height
		mov eax, dword[index_y]
		cmp dword[map_height], eax
		jnz label_check_map_y

	; Return
	mov byte[win_return], 0
	mov esp, ebp
	pop ebp
	ret