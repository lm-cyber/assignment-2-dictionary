%define BUFFER_SIZE 256

extern read_char
extern print_string
extern print_error
extern string_length
extern print_newline
extern find_word
extern exit

section .data
%include 'words.inc'
initial_prompt_msg: db "Key to find in dictionary:", 0xA, 0
error_not_found_msg: db "The key you are looking for was not found in the dictionary", 0xA, 0
error_overflow_msg: db "The query you typed is longer than 255 characters", 0xA, 0
seperator: db " : ", 0

section .text

global _start
_start:
    mov rdi, initial_prompt_msg
    call print_string

    xor rcx, rcx                 ; Char count
    sub rsp, BUFFER_SIZE    ; Reserve space for input
.read_chars:
    push rcx
    call read_char
    pop rcx

    cmp rax, 0xA                  ; Check for line terminators
    je .terminate_input
    cmp rax, 0x0
    je .terminate_input

    cmp rcx, BUFFER_SIZE-1     ; Check for overflow
    jge .overflow_error
    mov [rsp+rcx], al
    inc rcx
    jmp .read_chars
.overflow_error:
    mov rdi, error_overflow_msg   ; Print error msg to stderr
    call print_error
    jmp .exit
.terminate_input:
    mov byte [rsp+rcx], 0
.find_in_dict:
    mov rdi, rsp
    mov rsi, dict_head

    call find_word

    test rax, rax
    jz .not_found

    mov rdi, rax
    add rdi, 8
    push rdi
    call print_string
    mov rdi, seperator
    call print_string
    pop rdi
    call string_length
    lea rdi, [rdi+rax+1]
    call print_string
    call print_newline

    jmp .exit
.not_found:
    mov rdi, error_not_found_msg
    call print_error
.exit:
    add rsp, BUFFER_SIZE
    xor rdi, rdi
    call exit