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
                                ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi
                push r10
                push r11
                push r12
                push r13
                push r14

                mov r14, buffer

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

                pop r14
                pop r13
                pop r12
                pop r11
                pop r10
                pop rsi
                pop rdi

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
                xor rdx, rdx

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
                mov [buffer], al

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
                
                mov [r14], al
                inc r14

                loop .print_dec

                pop rcx

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
                mov [buffer], al
                
                mov [r14], al
                inc r14

                loop .print_bin

                pop rcx

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

arg_jmp_table:
                dq first_arg
                dq second_arg
                dq third_arg
                dq forth_arg
                dq fifth_arg