; MoomOS Kernel - Entry point
org 0x0000
bits 16

%define ENDL 0x0D, 0x0A
%define BACKSPACE 0x08
%define ENTER 0x0D
%define MAX_CMD_LEN 32

; Kernel entry point
start:
	; Set up segments
	mov ax, 0x1000      ; We are loaded at 0x1000:0x0000
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0xFFF0      ; Set stack at end of segment

	; Clear screen
	call clear_screen

	; Print kernel startup message
	mov si, msg_kernel_start
	call puts

	; Print menu
	call print_menu

main_loop:
	; Print prompt
	mov si, prompt
	call puts

	; Read command into buffer
	call read_command

	; Process command
	call process_command

	jmp main_loop

; Clear screen function
clear_screen:
	pusha
	mov ah, 0x00
	mov al, 0x03    ; 80x25 text mode
	int 0x10
	popa
	ret

; Print string function
puts:
	pusha
.loop:
	lodsb
	or al, al
	jz .done

	mov ah, 0x0e
	mov bh, 0
	int 0x10

	jmp .loop
.done:
	popa
	ret

; Print menu
print_menu:
	pusha
	mov si, menu_text
	call puts
	popa
	ret

; Read command into buffer with backspace support
read_command:
	pusha
	mov di, command_buffer
	mov cx, 0           ; Character counter

.read_loop:
	mov ah, 0x00
	int 0x16            ; Read keystroke

	cmp al, ENTER
	je .done

	cmp al, BACKSPACE
	je .handle_backspace

	; Regular character
	cmp cx, MAX_CMD_LEN-1
	jge .read_loop      ; Buffer full, ignore

	; Store character
	mov [di], al
	inc di
	inc cx

	; Echo character
	mov ah, 0x0e
	mov bh, 0
	int 0x10

	jmp .read_loop

.handle_backspace:
	cmp cx, 0
	je .read_loop       ; Nothing to delete

	; Move cursor back and erase
	dec di
	dec cx
	mov ah, 0x0e
	mov al, BACKSPACE
	int 0x10
	mov al, ' '         ; Space to erase
	int 0x10
	mov al, BACKSPACE   ; Back again
	int 0x10

	jmp .read_loop

.done:
	; Null terminate
	mov byte [di], 0
	
	; Print newline
	mov si, newline
	call puts
	popa
	ret

; Compare strings with length (SI = str1, DI = str2, CX = length) - returns ZF=1 if equal
strncmp:
	pusha
.loop:
	cmp cx, 0
	jz .equal
	
	mov al, [si]
	mov bl, [di]
	cmp al, bl
	jne .not_equal
	
	inc si
	inc di
	dec cx
	jmp .loop

.not_equal:
	popa
	mov al, 1           ; Set non-zero flag
	ret

.equal:
	popa
	xor al, al          ; Set zero flag
	ret

; Compare strings (SI = str1, DI = str2) - returns ZF=1 if equal
strcmp:
	pusha
.loop:
	mov al, [si]
	mov bl, [di]
	cmp al, bl
	jne .not_equal
	
	test al, al         ; Check for null terminator
	jz .equal
	
	inc si
	inc di
	jmp .loop

.not_equal:
	popa
	mov al, 1           ; Set non-zero flag
	ret

.equal:
	popa
	xor al, al          ; Set zero flag
	ret

; Process command function
process_command:
	pusha
	
	; Check for empty command
	mov al, [command_buffer]
	test al, al
	jz .done

	; Compare with known commands
	mov si, command_buffer
	
	; Check "help" command
	mov di, cmd_help
	call strcmp
	jz .cmd_help
	
	; Check "clear" command
	mov di, cmd_clear
	call strcmp
	jz .cmd_clear
	
	; Check "hello" command
	mov di, cmd_hello
	call strcmp
	jz .cmd_hello
	
	; Check "halt" command
	mov di, cmd_halt
	call strcmp
	jz .cmd_halt
	
	; Check "mem" command
	mov di, cmd_mem
	call strcmp
	jz .cmd_mem
	
	; Check "info" command
	mov di, cmd_info
	call strcmp
	jz .cmd_info
	
	; Check "echo" command (first 4 chars)
	mov di, cmd_echo
	mov cx, 4
	call strncmp
	jz .cmd_echo_check

	; Unknown command
	mov si, msg_command_unknown
	call puts
	jmp .done

.cmd_help:
	call print_menu
	jmp .done

.cmd_clear:
	call clear_screen
	jmp .done

.cmd_hello:
	mov si, msg_hello
	call puts
	jmp .done

.cmd_halt:
	mov si, msg_halting
	call puts
	cli
	hlt

.cmd_mem:
	call show_memory_info
	jmp .done

.cmd_info:
	call show_system_info
	jmp .done

.cmd_echo_check:
	; Check if it's exactly "echo" or "echo " with arguments
	mov al, [command_buffer + 4]
	cmp al, 0               ; Just "echo"
	je .cmd_echo_empty
	cmp al, ' '             ; "echo " with space
	je .cmd_echo
	jmp .cmd_help           ; Not a valid echo command, show help

.cmd_echo_empty:
	mov si, newline         ; Just print a newline for empty echo
	call puts
	jmp .done

.cmd_echo:
	call echo_command
	jmp .done

.done:
	popa
	ret

; Echo command - prints everything after "echo "
echo_command:
	pusha
	mov si, command_buffer + 5  ; Skip "echo "
	
	; Check if there's actually text to echo
	mov al, [si]
	test al, al
	jz .no_text
	
	call puts
	jmp .done

.no_text:
	; Just print newline if no text after "echo "
	
.done:
	mov si, newline
	call puts
	popa
	ret

; Show memory information
show_memory_info:
	pusha
	mov si, msg_mem_info
	call puts
	
	; Show stack pointer
	mov si, msg_stack_ptr
	call puts
	mov ax, sp
	call print_hex
	mov si, newline
	call puts
	
	popa
	ret

; Show system information
show_system_info:
	pusha
	mov si, msg_sys_info
	call puts
	popa
	ret

; Print hex number (AX register)
print_hex:
	pusha
	mov dx, ax          ; Save original value
	mov cx, 4           ; 4 hex digits
	
.loop:
	push cx             ; Save loop counter
	
	mov ax, dx          ; Restore original value
	dec cx              ; cx = 3, 2, 1, 0
	shl cx, 2           ; cx = 12, 8, 4, 0 (shift amounts)
	shr ax, cl          ; Get the nibble we want
	and al, 0x0F        ; Keep only low 4 bits
	
	cmp al, 9
	jle .digit
	add al, 'A' - '0' - 10
.digit:
	add al, '0'
	
	mov ah, 0x0e
	mov bh, 0
	int 0x10
	
	pop cx              ; Restore loop counter
	loop .loop
	
	popa
	ret

; Data section
msg_kernel_start: db "Welcome to MoomOS Kernel v1.0!", ENDL, ENDL, 0

menu_text: db "Available commands:", ENDL
          db "  help  - Show this help", ENDL  
          db "  clear - Clear screen", ENDL
          db "  hello - Say hello", ENDL
          db "  halt  - Shutdown system", ENDL
          db "  mem   - Show memory info", ENDL
          db "  info  - Show system info", ENDL
          db "  echo  - Echo text", ENDL, ENDL, 0

prompt: db "MoomOS> ", 0
msg_command_unknown: db "Unknown command. Type 'help' for available commands.", ENDL, 0
msg_hello: db "Hello from MoomOS! The system is running smoothly.", ENDL, 0
msg_halting: db "Shutting down MoomOS... Goodbye!", ENDL, 0
msg_mem_info: db "=== Memory Information ===", ENDL, 0
msg_stack_ptr: db "Stack Pointer: 0x", 0
msg_sys_info: db "=== System Information ===", ENDL
             db "OS: MoomOS v1.0", ENDL
             db "Architecture: x86 16-bit", ENDL
             db "Mode: Real Mode", ENDL
             db "Kernel loaded at: 0x1000", ENDL, 0
newline: db ENDL, 0

; Command strings
cmd_help: db "help", 0
cmd_clear: db "clear", 0
cmd_hello: db "hello", 0
cmd_halt: db "halt", 0
cmd_mem: db "mem", 0
cmd_info: db "info", 0
cmd_echo: db "echo", 0

; Command buffer
command_buffer: times MAX_CMD_LEN db 0

times 1536 - ($ - $$) db 0  ; Pad to 3 sectors (1536 bytes)
