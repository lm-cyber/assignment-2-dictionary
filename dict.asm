
%include 'lib.inc'

section .text

; Пройдёт по всему словарю в поисках подходящего ключа. 
; Если подходящее вхождение найдено, вернёт адрес начала 
; вхождения в словарь (не значения), иначе вернёт 0.
; rdi - Указатель на нуль-терминированную строку.
; rsi - Указатель на начало словаря.
global find_word
find_word:
    add rsi, 8
    push rax
    push rcx
    push r10
    push r11
    call string_equals
    pop r11
    pop r10
    pop rcx
    pop rax
    sub rsi, 8
    test rax, rax
    jnz .ret
    mov rsi, [rsi]
    test rsi, rsi
    jnz find_word
.ret:
    mov rax, rsi
    ret