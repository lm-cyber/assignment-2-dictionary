
section .text
extern string_equals

; Пройдёт по всему словарю в поисках подходящего ключа. 
; Если подходящее вхождение найдено, вернёт адрес начала 
; вхождения в словарь (не значения), иначе вернёт 0.
; rdi - Указатель на нуль-терминированную строку.
; rsi - Указатель на начало словаря.
global find_word
find_word:
    add rsi, 8
    call string_equals
    sub rsi, 8
    test rax, rax
    jnz .ret
    mov rsi, [rsi]
    test rsi, rsi
    jnz find_word
.ret:
    mov rax, rsi
    ret