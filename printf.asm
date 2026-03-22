section .text

global MyPrintf

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
                
                inc r10
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
; Функция обработки спецификатора строки (%c) в printf
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
; Функция обработки спецификатора строки (%x) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Портит: rcx
;-----------------------------------------------------------------------
HexSpecifier:
                push rax            ;сохраняем чтобы можно было юзать syscall
                push rdi
                push rsi
                push rdx
                push rax

                call GetNextArg

                mov rax, 0f000000000000000h

.skip_zero:
                test rdx, rax
                jnz .end_skip_zero
                shl rdx, 4
                jmp .skip_zero

.end_skip_zero:

.print_hex_loop:
                cmp rdx, 0h
                je .end_hex_str

                push rdx
                
                mov rax, 0f000000000000000h
                and rdx, rax
                shr rdx, 60

                cmp rdx, 0ah
                jae .parse_verb

                add rdx, '0'
                jmp .end_parse_digit

.parse_verb:
                add rdx, 'A' - 10

.end_parse_digit:

                mov [buffer], rdx
                push rcx
                push r11

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 1                     
                syscall

                pop r11
                pop rcx

                pop rdx

                shl rdx, 4

                jmp .print_hex_loop

.end_hex_str:

                pop rax
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


