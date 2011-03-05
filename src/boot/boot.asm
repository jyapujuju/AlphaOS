; Alpha Loader
; Version 0.11
; -------------------------------------------------------
; Copyright (c) 2011, Robert Schofield and Matthew Carey
; All rights reserved.

[BITS 16]
[ORG 0x7C00]

MOV AX, 03                       ; Clears the screen
INT 10h                          ; Screen interrupt.
MOV SI, Welcome
CALL PrintString
CALL KeyBoardHandle


; 16 Bit Calls
KeyBoardHandle:
  MOV AH, 00h
  INT 16h
  CMP AL, 0Dh
  JZ EnterKeyPressed
  CALL KeyBoardHandle

EnterKeyPressed:
  MOV SI, Boot
  CALL PrintString
  CLI
  XOR AX, AX
  MOV DS, AX
  LGDT [GDTDESC]
  MOV EAX, CR0
  OR EAX,1
  MOV CR0,EAX
  JMP 08h:BootMain

PrintString:
  next_character:
    MOV AL, [SI]
    INC SI
    OR AL, AL
    JZ ExitFunction
    CALL PrintChar
    JMP next_character

PrintChar:
  MOV AH, 0x0E
  MOV BH, 00
  MOV BL, 05
  INT 10h
  RET

ExitFunction:
  RET

Welcome db 'Alpha Loader v0.11',13,10,'Created by: Robert Schofield and Matthew Carey',13,10,13,10,'Press the Enter Key to boot.',13,10,0
Boot db 'Booting into the kernel...',13,10,0

; Now below we load the things required for our kernel.
; The GDT, A20 Line, and Protected Mode
; Currently, only the GDT and Protected Mode have been
; enabled. A20 will come a little later, and is 
; currently listed as: to-do.
; -----------------------------------------------------

[BITS 32]

BootMain:
  mov ax, 10h             ; Save data segment identifyer
  mov ds, ax              ; Move a valid data segment into the data segment register
  mov ss, ax              ; Move a valid data segment into the stack segment register
  mov esp, 090000h        ; Move the stack pointer to 090000h
  CALL enable_A20
  CALL A20Check
  ;mov byte [ds:0B8000h], 'P'      ; Move the ASCII-code of 'P' into first video memory
  ;mov byte [ds:0B8001h], 0Bh      ; Assign a color code
  
  
  JMP $

GDT:

GDTNULL:
  dd 0
  dd 0

GDTCODE:
  DW 0FFFFh
  DW 0
  DB 0
  DB 10011010b
  DB 11001111b
  DB 0

GDTDATA:
  DW 0FFFFh     ; Limit it to 4 GB
  DW 0          ; Base 0h bits of 16-31 of segment descriptor (SD)
  DB 0          ; Base addr of seg 16-23 of 32bit addr,32-39 of SD
  DB 10010010b  
  DB 11001111b  
  DB 0

GDTEND:

GDTDESC: 
  DW GDTEND - GDT -1 ; Limit (size)
  DD GDT


  enable_A20:
        cli
 
        call    a20wait
        mov     al,0xAD
        out     0x64,al
 
        call    a20wait
        mov     al,0xD0
        out     0x64,al
 
        call    a20wait2
        in      al,0x60
        push    eax
 
        call    a20wait
        mov     al,0xD1
        out     0x64,al
 
        call    a20wait
        pop     eax
        or      al,2
        out     0x60,al
 
        call    a20wait
        mov     al,0xAE
        out     0x64,al
 
        call    a20wait
        sti
        ret
 
a20wait:
        in      al,0x64
        test    al,2
        jnz     a20wait
        ret
 
 
a20wait2:
        in      al,0x64
        test    al,1
        jz      a20wait2
        ret

A20Check:
  xor AX, AX
  in AL, 60h
  bt ax,1
  jc A20Success


A20Success:
  mov byte [ds:0B8000h], 'W'   
  mov byte [ds:0B8001h], 0Bh  
  mov byte [ds:0B8002h], 'o'    
  mov byte [ds:0B8003h], 0Bh   
  mov byte [ds:0B8004h], 'r'      
  mov byte [ds:0B8005h], 0Bh      
  mov byte [ds:0B8006h], 'k'      
  mov byte [ds:0B8007h], 0Bh   
  mov byte [ds:0B8008h], 's'      
  mov byte [ds:0B8009h], 0Bh      


TIMES 510 - ($ - $$) db 0
DW 0xAA55