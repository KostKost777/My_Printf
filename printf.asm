section .text

global MyPrintf

oct_mask            equ (0111b)
;-----------------------------------------------------------------------
; Моя функция printf, принимает аргументы по стандарту System V
; Входные данные:  rdi, rsi, rdx, rcx, r8, r9, +стек
; Выходные данные: -
; Портит: r10, rcx
;-----------------------------------------------------------------------
MyPrintf:
                push rbp
                mov rbp, rsp
                
                push r10
                push r11
                push r12
                push r13

                mov r10, rdi                ;форматная строка
                mov r11, rsi                ;1 аргумент
                mov r12, rdx                ;2 аргумент
                mov r13, rcx                ;3 аргумент
                                            ;r8 - 4
                                            ;r9 - 5
                                            ;остальное в стеке начиная с rbp + 16

                xor rcx, rcx                ;в нем будет храниться порядковый номер аргумента

.write_loop:
                mov al, [r10]               ;в al будем хранить текущей символ из форматной строки
                cmp al, 0
                je .end_write_loop

                cmp al, '%'
                jne .not_spec 
                call ChooseSpecifier
                jmp .skip_print
.not_spec:

                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, r10                 ;r10 - адрес начала спецификатора
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                inc r10

.skip_print:
                jmp .write_loop

.end_write_loop:

                pop r13
                pop r12
                pop r11
                pop r10

                pop rbp

                ret

;-----------------------------------------------------------------------
; Функция для получания аргумента под номером rax, сохраняет в rax
; Входные данные: rcx - порядковый номер элемента
; Аргументы должны лежать в таком порядке:
; 1 - r11
; 2 - r12
; 3 - r13
; 4 - r8
; 5 - r9
; отсальные - из стека начиная с rbp + 16
; Выходные данные: rdx - сам аргумент
; Портит: rcx, rdx
;-----------------------------------------------------------------------
GetNextArg:

                cmp rcx, 5
                jae stack_arg

                jmp [arg_jmp_table + rcx * 8]

first_arg:
                mov rdx, r11
                inc rcx
                ret

second_arg:
                mov rdx, r12
                inc rcx
                ret

third_arg:
                mov rdx, r13
                inc rcx
                ret

forth_arg:
                mov rdx, r8
                inc rcx
                ret

fifth_arg:
                mov rdx, r9
                inc rcx
                ret

stack_arg:     
                push rcx
                sub rcx, 5h

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

                cmp al, 's'
                jne .not_str_spec
                call StringSpecifier
                inc r10
                ret

.not_str_spec:

                cmp al, 'c'
                jne .not_char_spec
                call CharSpecifier
                inc r10
                ret

.not_char_spec:

                cmp al, 'x'
                jne .not_hex_spec
                call HexSpecifier
                inc r10
                ret

.not_hex_spec:

                cmp al, 'o'
                jne .not_oct_spec
                call OctSpecifier
                inc r10
                ret

.not_oct_spec:

                cmp al, 'd'
                jne .not_dec_spec
                call DecSpecifier
                inc r10
                ret

.not_dec_spec:

                cmp al, 'b'
                jne .not_bin_spec
                call BinSpecifier
                inc r10
                ret

.not_bin_spec:

                cmp al, '%'
                jne .not_perc_spec
                call PercSpecifier
                inc r10
                ret

.not_perc_spec:
                
                ret


;-----------------------------------------------------------------------
; Функция обработки спецификатора строки (%s) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
StringSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi

                push rdx
                call GetNextArg

.print_str_loop:

                mov al, [rdx]
                cmp al, 0
                je .end_print_str

                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, rdx
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                mov rdx, rsi

                inc rdx
                jmp .print_str_loop

.end_print_str:

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора символа (%c) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
CharSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi
                push rdx

                call GetNextArg

                push rcx
                push r11

                mov [buffer], rdx

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора 16-ричного числа (%x) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
HexSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi
                push rdx

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
                mov [buffer], al

                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                loop .print_hex

                pop rcx

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора восьмиричного числа (%o) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
OctSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi

                push rdx

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
                mov [buffer], al

                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                loop .print_oct

                pop rcx

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора десятичного числа (%d) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
DecSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi

                push rdx

                call GetNextArg

                push rcx
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
                mov [buffer], al
                
                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                loop .print_dec

                pop rcx

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора двоичного числа (%b) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
BinSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi

                push rdx

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
                mov [buffer], al
                
                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                loop .print_bin

                pop rcx

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора символа (%%) в printf
; Входные данные: -
; Выходные данные: -
; Портит: -
;-----------------------------------------------------------------------
PercSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi
                push rdx

                push rcx
                push r11

                mov byte [buffer], '%'

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                pop rdx
                pop rsi
                pop rdi
                pop rax

                ret
                
section .data

buffer          db 0

arg_jmp_table:
                dq first_arg
                dq second_arg
                dq third_arg
                dq forth_arg
                dq fifth_arg


