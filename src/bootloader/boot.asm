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

puts:
	push si
	push ax

.loop:
	lodsb
	or al, al
	jz .done

	mov ah, 0x0e
	mov bh, 0
	int 0x10

	jmp .loop

.done:
	pop ax
	pop si
	ret

main:
   	xor ax, ax
	mov ds, ax
	mov es, ax
	
	mov ss, ax
	mov sp, 0x7C00

	hlt

.halt:
    	jmp .halt


times 510 - ($ - $$) db 0
dw 0xAA55
