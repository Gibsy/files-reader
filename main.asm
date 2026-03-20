extern _CreateFileA@28, _ReadFile@20, _WriteFile@20
extern _GetStdHandle@4, _GetCommandLineA@0, _ExitProcess@4

%macro wr 2             ; wr ptr, len - write to stdout (ebx)
    push dword 0
    push r
    push dword %2
    push %1
    push ebx
    call _WriteFile@20
%endmacro

%macro rd 2             ; rd handle, buf - read 1 byte
    push dword 0
    push r
    push dword 1
    push %2
    push %1
    call _ReadFile@20
%endmacro

;msg
section .data
msg    db 13,10,"Press Enter to exit...",0
msglen equ $-msg
errmsg db "Drag a file onto the exe!",13,10,0
errlen equ $-errmsg
nofile db "File not found!",13,10,0
noflen equ $-nofile

section .bss
h resd 1
b resb 1
r resd 1

section .text
global Start
Start:
    push dword -11
    call _GetStdHandle@4
    mov ebx, eax                ; ebx = stdout

    call _GetCommandLineA@0
    mov esi, eax

    ; skip exe name
    cmp byte [esi], '"'
    jne .skip_plain
    inc esi
.skip_q: inc esi
    cmp byte [esi-1], '"'
    jne .skip_q
    jmp .skip_sp
.skip_plain:
    cmp byte [esi], ' '
    je  .skip_sp
    cmp byte [esi], 0
    je  no_arg
    inc esi
    jmp .skip_plain

    ; skip spaces
.skip_sp:
    cmp byte [esi], ' '
    jne .check
    inc esi
    jmp .skip_sp
.check:
    cmp byte [esi], 0
    je  no_arg

    ; deletes surrounding quotes from path
    cmp byte [esi], '"'
    jne open_file
    inc esi
    mov edi, esi
.fq: cmp byte [edi], '"'
    je  .eq
    cmp byte [edi], 0
    je  open_file
    inc edi
    jmp .fq
.eq: mov byte [edi], 0          ; null-terminate

open_file:
    push dword 0
    push dword 0x80
    push dword 3                ; OPEN_EXISTING
    push dword 0
    push dword 1                ; FILE_SHARE_READ
    push dword 0x80000000       ; GENERIC_READ
    push esi
    call _CreateFileA@28
    mov [h], eax
    cmp eax, -1
    je  file_not_found		

read_loop:
    rd dword [h], b
    cmp dword [r], 0
    je  end_file
    push dword 0
    push r
    push dword 1
    push b
    push ebx
    call _WriteFile@20 ; print byte to cmd
    jmp read_loop
	
; errors
end_file:
    wr msg, msglen
    jmp wait_enter

file_not_found:
    wr nofile, noflen
    jmp wait_enter

no_arg:
    wr errmsg, errlen
    jmp wait_enter

wait_enter:
    push dword -10
    call _GetStdHandle@4
    rd eax, b                   ; wait for Enter key thn exit
    push dword 0
    call _ExitProcess@4 