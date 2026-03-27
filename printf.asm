section .text

global MyPrintf
extern printf
default rel

oct_mask          equ 0111b
bin_mask          equ 1b
hex_mask          equ 1111b

precision         equ 1000000

dbl_exp_mask      equ 0x7ff0000000000000
dbl_mant_mask     equ 0x000fffffffffffff

;-----------------------------------------------------------------------
; Моя функция printf, принимает аргументы по стандарту System V
; Входные данные:  rdi, rsi, rdx, rcx, r8, r9, +стек
;                  xmm0 - xmm7, в них лежат первые 8 аргументов типа float и double
;                               остальные на стеке
; Выходные данные: rax - количество выведенных символов
; Изменяет: r8, r9, r10, r12, r13, r14, r15, rax
;-----------------------------------------------------------------------
MyPrintf:
                push rbp
                mov rbp, rsp                ;адрес начала аргументов с порядковым номером больше 6

                sub rsp, 16 * 8

                lea r11, [rsp - 8]          ;адрес начала первых 5 аргументов
                lea r15, [rsp]              ;адрес начала первых 8 float аргументов

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
                push rdi

                mov r10, rdi            ; форматная строка 

                lea r14, [buffer]         ;адрес буфера вывода

                xor r12, r12            ;порядковый номер не стековых аргументов типа float
                xor r13, r13            ;порядковый номер не стековых аргументов всех типов кроме float
                xor rcx, rcx            ;общее число обработанных аргументов
                
.write_loop:
                mov al, [r10]           ;в al будем хранить текущей символ из форматной строки
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
                lea rsi, [buffer]
                mov rdx, r14
                sub rdx, rsi            
                syscall

                mov rax, rdx

                pop rdi
                pop r9
                pop r8
                pop rcx
                pop rdx
                pop rsi

                movdqu xmm0, [rsp]     
                movdqu xmm1, [rsp + 16]
                movdqu xmm2, [rsp + 32]
                movdqu xmm3, [rsp + 48]
                movdqu xmm4, [rsp + 64]
                movdqu xmm5, [rsp + 80]
                movdqu xmm6, [rsp + 96]
                movdqu xmm7, [rsp + 112]

                mov rsp, rbp
                pop rbp   

                mov r14, rax            ; сохраняем возвращаемое значение MyPrintf
                pop r15                 ; сохраняем адрес возврата функции MyPrintf 

                call printf wrt ..plt

                mov rax, r14
                push r15

                ret

;-----------------------------------------------------------------------
; Функция для получания аргумента под номером rax, сохраняет в rax
; Входные данные: rcx - порядковый номер элемента
;                 al  - символ спецификатора
; Выходные данные: rdx - сам аргумент
; Изменяет: r11, r12, r13, r15, rcx, rdx
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
; Выходные данные: bl - (2 ^ bl), если спецификатор был для систем счистления степени 2 -ки
; Изменяет: r10, rax, rbx
;-----------------------------------------------------------------------
 ChooseSpecifier:
                xor rax, rax
                xor rbx, rbx

                inc r10
                mov al, [r10]
                inc r10

                cmp al, '%'
                jne .not_perc

                mov byte [r14], '%'
                inc r14

                ret
                
.not_perc:
                cmp al, 'x'
                ja DefaultCase

                cmp al, 'b'
                jb DefaultCase

                lea r8, [jump_table]
                jmp [r8 + (rax - 'b') * 8]
                ret

CaseBin:
                mov bl, 1
                mov al, bin_mask
                call BinOctHexSpecifier
                ret

CaseOct:
                mov bl, 3
                mov al, oct_mask
                call BinOctHexSpecifier
                ret

CaseHex:
                mov bl, 4
                mov al, hex_mask
                call BinOctHexSpecifier
                ret

DefaultCase:              
                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора строки (%s) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Изменяет: rdx, rax, r14
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
; Изменяет: rdx, r14
;-----------------------------------------------------------------------
CharSpecifier:

                call GetNextArg

                mov [r14], rdx
                inc r14

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора десятичного числа (%d) в printf
; Входные данные: rcx - номер аргумента для вывода
; Выходные данные: -
; Изменяет: rdx, rax, r14
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
                call ParseInDec

                ret

;-----------------------------------------------------------------------
; Функция обработки спецификатора символа (%f) в printf
; Входные данные: -
; Выходные данные: -
; Изменяет: rax, rdi, rdx
;-----------------------------------------------------------------------
DoubleSpecifier:
                call GetNextArg

                push rcx

                test rdx, rdx
                jnz .positive

                mov byte [r14], '-'
                inc r14             
.positive:
                mov r8, rdx
                mov r9, rdx

                mov rax, dbl_mant_mask
                and r9, rax

                mov rax, dbl_exp_mask
                and r8, rax                     ; оставляем 11 бит экспоненты

                cmp r8, rax
                jne .norm

                cmp r9, 0
                jne .is_nan

                mov dword [r14], 'INF'
                add r14, 3

                pop rcx

                ret
.is_nan:
                mov dword [r14], 'NAN'
                add r14, 3

                pop rcx
                
                ret
.norm:
                movq xmm0, rdx
                
                cvttsd2si rdx, xmm0  ; выделяем целую часть

                call ParseInDec      ;пишем в буфер целую часть

                mov byte [r14], '.'
                inc r14
                
                cvtsi2sd xmm1, rdx    ; преобразуем целую часть в double
                subsd xmm0, xmm1      ; вычитаем из всего числа целую часть, чтобы получить остаток 

                mov rax, precision    ; домножаем на точность 
                cvtsi2sd xmm1, rax    

                mulsd xmm0, xmm1
                roundsd xmm0, xmm0, 0   ; округляем дробную часть
                cvttsd2si rdx, xmm0

                call ParseInDec         ; выводим остаток

                pop rcx

                ret
;-----------------------------------------------------------------------
; Функция перевода из 16 ричного числа в rdx в 10-ое и сохранение в буфер в r14
; Входные данные: rdx - число в 16 ричной форме
;                 r14 - буффер для вывода
; Выходные данные: -
; Изменяет: r14
;-----------------------------------------------------------------------
ParseInDec:

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
; Функция обработки спецификатора символа (%x, %o, %b) в printf
; Входные данные: bl - (2 ^ bl) - основание системы
;                 al - маска для каждоый СС
; Выходные данные: -
; Изменяет: rax, rdi, rsi
;-----------------------------------------------------------------------
BinOctHexSpecifier:

                call GetNextArg

                push rcx
                xor rcx, rcx

.parse_loop:
                mov rdi, rdx
                and rdi, rbx

                cmp rdi, 0ah
                jae .parse_verb

                add rdi, '0'
                jmp .end_parse_digit

.parse_verb:
                add rdi, 'A' - 10

.end_parse_digit:

                push rdi
                inc rcx

                push rcx
                mov cl, al
                shr rdx, cl
                pop rcx

                cmp rdx, 0h
                je .end_loop

                jmp .parse_loop
.end_loop:

.print:
                pop rdi
                mov [r14], rdi
                inc r14

                loop .print

                pop rcx

                ret
                
section .data

buffer          db 512 dup(0)

jump_table:
                            dq CaseBin                         ;b
                            dq CharSpecifier                   ;c
                            dq DecSpecifier                    ;d
                            dq DefaultCase                     ;skip e
                            dq DoubleSpecifier                 ;f
times ('o' - 'f' - 1)       dq DefaultCase                     ;skip f - o
                            dq CaseOct                         ; o
times ('s' - 'o' - 1)       dq DefaultCase                     ;skip o - s
                            dq StringSpecifier                 ;s
times ('x' - 's' - 1)       dq DefaultCase                     ;skip x - s
                            dq CaseHex                         ;x