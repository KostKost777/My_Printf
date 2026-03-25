section .text

global MyPrintf

oct_mask          equ (0111b)
precision         equ 1000000
;-----------------------------------------------------------------------
; Моя функция printf, принимает аргументы по стандарту System V
; Входные данные:  rdi, rsi, rdx, rcx, r8, r9, +стек
; Выходные данные: -
; Портит: r10, rcx
;-----------------------------------------------------------------------
MyPrintf:
                push rbp
                mov rbp, rsp                ;адрес начала аргументов с порядковым номером больше 6

                sub rsp, 16 * 8

                lea r11, [rsp - 8]          ;адрес начала первых 5 аргументов
                lea r15, [rsp]              ;адрес начала первых 8 float аогументов

                movdqu [rsp],       xmm0
                movdqu [rsp + 16],  xmm1
                movdqu [rsp + 32],  xmm2
                movdqu [rsp + 48],  xmm3
                movdqu [rsp + 64],  xmm4
                movdqu [rsp + 80],  xmm5
                movdqu [rsp + 96],  xmm6
                movdqu [rsp + 112], xmm7
      
                push rsi
                push rdx
                push rcx
                push r8
                push r9

                mov r10, rdi                ; форматная строка 

                mov r14, buffer             ;адрес буфера вывода

                xor r12, r12        ;порядковый номер не стековых аргументов типа float
                xor r13, r13        ;порядковый номер не стековых аргументов всех типов кроме float
                xor rcx, rcx        ;общее число обработанных аргументов
                
.write_loop:
                mov al, [r10]               ;в al будем хранить текущей символ из форматной строки
                cmp al, 0
                je .end_write_loop

                cmp al, '%'
                jne .not_spec 
                call ChooseSpecifier
                jmp .skip_print
.not_spec:

                mov [r14], al

                inc r14
                inc r10

.skip_print:
                jmp .write_loop

.end_write_loop:

                mov rax, 1              ;выводим весь буфер
                mov rdi, 1
                mov rsi, buffer
                mov rdx, r14
                sub rdx, buffer              
                syscall

                mov rax, rdx

                add rsp, 162             ;пропускаем все аргументы

                mov rsp, rbp
                pop rbp

                ret

;-----------------------------------------------------------------------
; Функция для получания аргумента под номером rax, сохраняет в rax
; Входные данные: rcx - порядковый номер элемента
;                 al  - символ спецификатора
; Выходные данные: rdx - сам аргумент
; Портит: r12, r13, rcx, rdx
;-----------------------------------------------------------------------
GetNextArg:
                xor rdx, rdx

                cmp al, 'f'
                jne .not_float

                cmp r12, 8
                jae .stack_arg

                movdqu xmm0, [r15]
                movq rdx, xmm0 
                add r15, 16

                inc rcx
                inc r12

                ret

.not_float:
                cmp r13, 5
                jae .stack_arg

                mov rdx, [r11]
                sub r11, 8

                inc rcx
                inc r13

                ret

.stack_arg:     
                push rcx

                sub rcx, r12
                sub rcx, r13

                lea rcx, [rbp + rcx * 8 + 16]
                mov rdx, [rcx]

                pop rcx

                inc rcx

                ret

;-----------------------------------------------------------------------
; Функция для обработки всех спецификаторов ввода в Printf
; Входные данные: r10 - адрес начала спецификатора
; Выходные данные: -
; Портит: r10, rax
;-----------------------------------------------------------------------
 ChooseSpecifier:
                inc r10
                mov al, [r10]
                inc r10

                movzx rax, al
                jmp [jump_table + rax * 8]

default_case:              
                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора строки (%s) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rdx, rax, rdi, rsi
;-----------------------------------------------------------------------
StringSpecifier:

                call GetNextArg

.print_str_loop:

                mov al, [rdx]
                cmp al, 0
                je .end_print_str

                mov [r14], al
                inc r14

                inc rdx
                jmp .print_str_loop

.end_print_str:

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора символа (%c) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rdx, rax, rdi, rsi
;-----------------------------------------------------------------------
CharSpecifier:

                call GetNextArg

                mov [r14], rdx
                inc r14

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора 16-ричного числа (%x) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rdx, rax, rdi, rsi
;-----------------------------------------------------------------------
HexSpecifier:

                call GetNextArg

                push rcx
                xor rcx, rcx

.parse_hex_loop:
                xor rax, rax
                mov al, dl
                and al, 0fh

                cmp rax, 0ah
                jae .parse_verb

                add rax, '0'
                jmp .end_parse_digit

.parse_verb:
                add rax, 'A' - 10

.end_parse_digit:

                push rax
                inc rcx
                shr rdx, 4

                cmp rdx, 0h
                je .end_hex_loop

                jmp .parse_hex_loop

.end_hex_loop:


.print_hex:
                pop rax 
                mov [r14], al
                inc r14

                loop .print_hex

                pop rcx

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора восьмиричного числа (%o) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rdx, rax, rdi, rsi
;-----------------------------------------------------------------------
OctSpecifier:

                call GetNextArg

                push rcx
                xor rcx, rcx

.parse_oct:
                xor rax, rax

                mov al, dl
                and al, oct_mask
                add rax, '0'
                push rax
                inc rcx

                shr rdx, 3

                cmp rdx, 0h
                je .end_parse_oct

                jmp .parse_oct

.end_parse_oct:

.print_oct:
                pop rax 

                mov [r14], al
                inc r14

                loop .print_oct

                pop rcx

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора десятичного числа (%d) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rdx, rax, rdi, rsi
;-----------------------------------------------------------------------
DecSpecifier:

                call GetNextArg

                movsxd  rdx, edx
                test rdx, rdx
                jns .positive

                mov byte [r14], '-'
                inc r14

                neg rdx

.positive:
                call ParseDec

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора двоичного числа (%b) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rdx, rax, rdi, rsi
;-----------------------------------------------------------------------
BinSpecifier:

                call GetNextArg

                push rcx
                xor rcx, rcx

.parse_bin:
                mov rax, rdx
                and rax, 1b
                add rax, '0'
                push rax
                inc rcx

                shr rdx, 1

                cmp rdx, 0h
                je .end_parse_bin

                jmp .parse_bin

.end_parse_bin:

.print_bin:
                pop rax 
                
                mov [r14], al
                inc r14

                loop .print_bin

                pop rcx

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора символа (%f) в printf
; Входные данные: -
; Выходные данные: -
; Портит: rax, rdi, rsi
;-----------------------------------------------------------------------
DoubleSpecifier:

                push rax
                push rbx

                call GetNextArg

                push rcx

                test rdx, rdx
                jnz .positive

                mov byte [r14], '-'
                inc r14

                xorps xmm0, xmm0
                xorps xmm1, xmm1

                movq xmm0, rdx
.positive:
                
                cvttsd2si rdx, xmm0

                call ParseDec

                mov byte [r14], '.'
                inc r14
                
                cvtsi2sd xmm1, rdx    ; преобразуем целую часть в double
                subsd xmm0, xmm1  

                mov rax, precision
                cvtsi2sd xmm1, rax

                mulsd xmm0, xmm1
                roundsd xmm0, xmm0, 0
                cvttsd2si rdx, xmm0

                call ParseDec

                pop rcx
                pop rbx
                pop rax

                ret


;-----------------------------------------------------------------------
; Функция перевода из 16 ричного числа  в rdx в 10-ое и сохранение в буфер в r14
; Входные данные: rdx - число в 16 ричной форме
;                 r14 - буффер для вывода
; Выходные данные: -
; Портит: -
;-----------------------------------------------------------------------
ParseDec:

                push rax
                push rdx
                push rcx
                push rbx

                xor rcx, rcx
.parse_dec:
                mov rax, rdx
                xor rdx, rdx
                mov rbx, 10
                div rbx

                add rdx, '0'
                push rdx
                inc rcx

                mov rdx, rax

                cmp rdx, 0h
                je .end_parse_dec

                jmp .parse_dec

.end_parse_dec:

.print_dec:
                pop rax 
                
                mov [r14], al
                inc r14

                loop .print_dec

                pop rbx
                pop rcx
                pop rdx
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора символа (%%) в printf
; Входные данные: -
; Выходные данные: -
; Портит: rax, rdi, rsi
;-----------------------------------------------------------------------
PercSpecifier:

                mov byte [r14], '%'
                inc r14
                
                ret
                
section .data

buffer          db 512 dup(0)

jump_table:
    times ('b' - 0)             dq default_case                          ;0 - 'b'
                                dq BinSpecifier                     ;b
                                dq CharSpecifier                    ;c
                                dq DecSpecifier                     ;d
                                dq default_case                          ;e - skip
                                dq DoubleSpecifier                  ;f
    times ('o' - 'f' - 1)       dq default_case                          ; skip между f и o
                                dq OctSpecifier                     ; o
    times ('s' - 'o' - 1)       dq default_case                          ;skip между o и s
                                dq StringSpecifier                  ;s
    times ('x' - 's' - 1)       dq default_case                          ; skip между x и s
                                dq HexSpecifier                     ;x
    times (256 - 'x' + 1)       dq default_case                          ; все остальные возможные