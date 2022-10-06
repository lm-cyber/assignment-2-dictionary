section .text
 
; Принимает код возврата и завершает текущий процесс
global exit
exit: 
    mov rax, 60
    syscall 

; Принимает указатель на нуль-терминированную строку, возвращает её длину
global string_length
string_length:
    xor rax, rax
    push rbx            ; Callee-saved
.lp:
    mov bl, [rdi+rax]
    test bl, bl
    jz .return
    inc rax
    jmp .lp
.return:
    pop rbx             ; Callee-saved
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
global print_string
print_string:
    push rdi            ; Caller-saved
    call string_length
    pop rdi
    mov rdx, rax
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    ret

global print_error
print_error:
    push rdi            ; Caller-saved
    call string_length
    pop rdi
    mov rdx, rax
    mov rax, 1
    mov rsi, rdi
    mov rdi, 2
    syscall
    ret

; Принимает код символа и выводит его в stdout
global print_char
print_char:
    dec rsp
    mov [rsp], dil
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    inc rsp
    ret

; Переводит строку (выводит символ с кодом 0xA)
global print_newline
print_newline:
    mov rdi, 10
    jmp print_char

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
global print_uint
print_uint:
    push rbx          ; Callee-saved
    dec rsp
    mov byte [rsp], 0 ; Null terminator
    mov rsi, 1
    mov rax, rdi
    mov rbx, 10       ; Base 10
.lp:
    xor rdx, rdx ; Empty remainder register
    div rbx
    add rdx, 48  ; Make ascii digit
    dec rsp    ; Reserve space in stack
    mov [rsp], dl ; Push digit into stack string
    inc rsi
    test rax, rax ; Check if there's anything left
    jnz .lp
    mov rdi, rsp ; Print string
    push rsi
    call print_string
    pop rsi
    add rsp, rsi
    pop rbx         ; Callee-saved
    ret

; Выводит знаковое 8-байтовое число в десятичном формате 
global print_int
print_int:
    cmp rdi, 0
    jge .print
    push rdi        ; Save number
    mov rdi, 45     ; Print minus sign
    call print_char
    pop rdi         ; Retrieve number
    neg rdi         ; Make number positive
.print:
    call print_uint
    ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
global string_equals
string_equals:
    xor rax, rax
    xor rcx, rcx        ; i
.loop:
    mov r10b, [rdi+rcx] ; r10b = a[i]
    mov r11b, [rsi+rcx] ; r11b = b[i]
    inc rcx
    cmp r10b, r11b
    jne .return
    test r10b, r10b
    jnz .loop
    mov rax, 1
.return:
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
global read_char
read_char:
    dec rsp         ; Reserve space in stack
    mov rax, 0
    mov rdi, 0
    mov rsi, rsp
    mov rdx, 1
    syscall         ; read(0, rsp, 1)
    test rax, rax
    jz .return
    mov al, [rsp]   ; Return byte in rax
.return:
    inc rsp         ; Free space in stack
    ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор
global read_word

read_word:
    xor rdx, rdx   ; Count bytes read
    dec rsi        ; Reserve space for null-terminator
.read_chars:
    cmp rdx, rsi        ; Check for space in buffer
    jge .fail           ; Failed if rdx >= rsi

    push rdx            ; Save byte count
    push rdi            ; Save buffer address
    push rsi            ; Save buffer size
    call read_char
    pop rsi             ; Retrieve buffer size
    pop rdi             ; Retrieve buffer address
    pop rdx             ; Retrieve byte count

    test rax, rax       ; If eof
    jz .terminate       ; -- terminate

    push rax            ; Save char
    push rdi            ; Save buffer address
    mov dil, al         ; Arg for .is_space
    call .is_space
    test rax, rax
    pop rdi             ; Retrieve buffer address
    pop rax             ; Retrieve char
    jz .process_char    ; If not space, process character
    test rdx, rdx
    jz .read_chars      ; Continue trimming spaces if pre-chars space
    jmp .terminate      ; terminate if post-chars space
.process_char:
    mov [rdi+rdx], rax
    inc rdx
    jmp .read_chars
.terminate:
    mov byte [rdi+rdx], 0
    mov rax, rdi
    ret
.fail:
    xor rax, rax
    ret
; Function that returns whether the passed byte is one of 3 space symbols or not
.is_space:
    cmp dil, 0x20
    je .true
    cmp dil, 0x9
    je .true
    cmp dil, 0xA
    je .true
.false:
    mov rax, 0
    ret
.true:
    mov rax, 0xFFFFFFFFFFFFFFFF
    ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
global parse_uint
parse_uint:
    xor rax, rax
    xor rsi, rsi
    push rbx
    mov rbx, 10  ; Constant to match sizes
.loop:
    ; Register to match sizes with rax
    xor r10, r10
    mov r10b, [rdi+rsi]
    ; Ensure character is numeric [0-9]
    cmp r10, 0x30
    jl .return
    cmp r10, 0x39
    jg .return
    mul rbx
    add rax, r10
    sub rax, 0x30
    inc rsi
    jmp .loop
.return:
    pop rbx
    mov rdx, rsi
    ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
global parse_int
parse_int:
    xor r11, r11        ; Temporary flag
    cmp byte [rdi], 0x2d     ; Process first minus symbol
    jne .process_number
    not r11             ; Negative number flag
    inc rdi
.process_number:
    call parse_uint
    test rdx, rdx       ; If parsing failed, return
    jz .return
    test r11, r11       ; If parsing did not fail, the number is positive, return
    jz .return
    neg rax
    inc rdx
.return:
    ret 

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
global string_copy
string_copy:
    xor rax, rax
.lp:
    inc rax
    cmp rax, rdx      ; Check for space in buffer
    jle .null_check
    xor rax, rax      ; Return 0
    ret
.null_check:
    mov bl, [rdi+rax-1] ; Get byte from original string
    mov [rsi+rax-1], bl ; Put byte to buffer
    test bl, bl ; Check if null
    jnz .lp
    dec rax
    ret