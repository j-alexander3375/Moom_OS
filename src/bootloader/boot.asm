org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

jmp strict short start
nop

bdb_oem:                    db "MSWIN4.1"
bdb_bytes_per_sector: 	    dw 512
bdb_sectors_by_cluster:     db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0H
bdb_total_secotrs:          dw 2880
bdb_media_descriptor_type:  db 0F0H
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29H
ebr_volume_id:              db 12H, 34H, 56H, 78H
ebr_volume_label:           db "MOOM     OS"
ebr_system_id:              db "FAT12   "

start:
	jmp main

; Print string function
puts:
	push si
	push ax
	push bx

.loop:
	lodsb
	or al, al
	jz .done

	mov ah, 0x0e
	mov bh, 0
	int 0x10

	jmp .loop

.done:
	pop bx
	pop ax
	pop si
	ret

; Read disk sectors function
disk_read:
	pusha
	push dx
	
	mov ah, 0x02    ; BIOS read sector function
	mov al, 3       ; Number of sectors to read (kernel is now 3 sectors)
	mov ch, 0       ; Cylinder
	mov dh, 0       ; Head
	mov cl, 2       ; Sector (kernel starts at sector 2)
	
	int 0x13        ; BIOS disk interrupt
	jc disk_error   ; Jump if carry flag is set (error)
	
	pop dx
	popa
	ret

disk_error:
	mov si, disk_error_msg
	call puts
	jmp $

main:
   	; Set up segments
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00

	; Print boot message
	mov si, msg_loading
	call puts

	; Load kernel from disk
	mov bx, 0x1000      ; Load kernel at 0x1000
	mov es, bx
	mov bx, 0           ; ES:BX = 0x1000:0x0000
	call disk_read

	; Jump to kernel
	mov si, msg_kernel_loaded
	call puts
	
	; Jump to kernel entry point
	jmp 0x1000:0x0000

.halt:
    	jmp .halt

msg_loading: db "MoomOS Bootloader v1.0", ENDL, "Loading kernel...", ENDL, 0
msg_kernel_loaded: db "Kernel loaded! Jumping to kernel...", ENDL, 0
disk_error_msg: db "DISK READ ERROR!", ENDL, 0


times 510 - ($ - $$) db 0
dw 0xAA55
