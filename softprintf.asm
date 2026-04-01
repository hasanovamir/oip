;context switch
;mov который кидает в массив и икрементит позицию

global SoftPrintfTrampoline

default rel

section .data

;==============================================

    number_buffer      db 32 dup(0)
    tmp_char           db 0
    ret_address        dq 0
    print_buffer       db 256 dup(0)

    undef_str db 'undefined symbol', 10
    ten_float dq 10.0
    ten_pow6  dq 1000000.0

;==============================================

    specifier_jmp_table:

        times '%' - 0      dq undef_sym
                           dq percent_specifier
        times 'b' - '%' -1 dq undef_sym
                           dq b_specifier
                           dq c_specifier
                           dq d_specifier
                           dq undef_sym  ;%e
                           dq f_specifier
        times 'o'-'g'      dq undef_sym
                           dq o_specifier
                           dq pointer_specifier
        times 's'-'q'      dq undef_sym
                           dq s_specifier
        times 'x'-'t'      dq undef_sym
                           dq x_specifier
        times 128 -'y'     dq undef_sym


;==============================================

section .text

;————————————————————————————————————————————————————————————————————————————————
;use syscall function to print a string

;enter  : 1 arg = buffer pointer
;       : 2 arg = string length

;return : -

;destroy: rax, rdx, rsi, rdi
;————————————————————————————————————————————————————————————————————————————————

%macro PRINT_STR 2

;rbx = buffer pointer
    mov rbx, %1
;rdi = print buffer ptr
    mov rdi, print_buffer
;add cur pos to start of array
    add rdi, r14

;rcx = str_len
    mov rcx, %2

    .pb_compare:

;if buffer is full we should output it
        cmp r14, 255
        jne .add_to_buffer

    .output:
;save rcx, because syscall destroy it
        push rcx
;print buffer content
;destroy: rax, rdx, rsi, rdi
        OUTPUT_BUFFER r14
;return rcx
        pop rcx
;clean buffer, make it zero size
        xor r14, r14
;pos in printf buffer = 0
        mov rdi, print_buffer
;goto next compare if we have more symbols
        cmp rcx, 0
        jg .pb_compare
;else go to end macro
        jmp .end

    .add_to_buffer:

;al = cur_symbol
        mov al, byte [rbx]
        mov [rdi], al

;increase pos in src buffer
    inc rbx
;increase pos in printf buffer
    inc rdi
;increase printf buffer size
    inc r14
;decrease num of iterations
;use dec + cmp, because, if last symbol
;is '\n', we goto .output there after 
;output we jmp to compare, so we will don`t
;change the rcx
    dec rcx

;if last sym == '\n' we goto output buffer
    cmp al, 10
    je .output

;goto next compare
        cmp rcx, 0
        jg .pb_compare

    .end:

%endmacro

;————————————————————————————————————————————————————————————————————————————————
;use syscall function to print a printf_buffer

;enter  : 1 arg = buffer size

;return : -

;destroy: rax, rdx, rsi, rdi
;————————————————————————————————————————————————————————————————————————————————

%macro OUTPUT_BUFFER 1

    ;buffer
    mov rsi, print_buffer
;str_len
    mov rdx, %1
;rax = write 
    mov rax, 1
;file descriptor
    mov rdi, 1

    syscall

%endmacro
;————————————————————————————————————————————————————————————————————————————————

%macro STR_LEN 1

;rax = str_ptr
    mov rax, %1
;rdx = 0 == str len
    xor rdx, rdx

;go to compare 
    jmp .len_cmp

    .len_count_iter:

;str_len++
    inc rdx
;str_ptr++
    inc rax

    .len_cmp:

        cmp byte [rax], 0
        jne .len_count_iter

%endmacro

;————————————————————————————————————————————————————————————————————————————————
;Expand the number by swapping elements that are symmetrical
;relative the center

;enter  : rdx = number len
;       : number_buffer = buffer there contain out number

;return : reversed number in number_buffer

;destroy: rax, rbx, rcx, rsi
;————————————————————————————————————————————————————————————————————————————————

%macro REVERSE_NUMBER 0

;rsi = number len
    mov rsi, rdx
;rsi = number_len / 2
    shr rsi, 1
;rcx = iteration counter, and pos of 1 elem
    xor rcx, rcx
;rbp = pos of 2 element
    mov rbp, rdx
    dec rbp

    .swap_iteration:

;al = value of first element
        mov al, byte [number_buffer + rcx]
;bl = value of second element
        mov bl, byte [number_buffer + rbp]

;put value of 1 element into 2 pos
        mov [number_buffer + rbp], al
;put value of 2 element into 1 pos
        mov [number_buffer + rcx], bl

;i++, increase pos of 1 element
        inc rcx
;decrease pos of 2 element
        dec rbp

        cmp rcx, rsi
        jb .swap_iteration

%endmacro

;————————————————————————————————————————————————————————————————————————————————
;convert a number to the specified number system.
;only for degrees of two.

;enter  : rax = number to convert
;       : rcx = powers of two

;return : rdx = number_len
;       : reversed number in number_buffer

;destroy: rax, rbx, rcx, rdx, rsi
;————————————————————————————————————————————————————————————————————————————————

%macro CONVERT_POWER_OF_TWO 0

;rsi = max value in current degree
;like f in hex-format
    mov rsi, 1
    shl rsi, rcx
    dec rsi

;pos in number_buffer
    xor rdx, rdx
;clear older 4 bytes from rax
;when you write smt in eax, rax / eax will be cleaned
    mov eax, eax

;==============================================

;cmp rax with 0, to know if it 0, because basic
;algorithm will print 0 symbols, if it 0
;we put 0 into number_buffer, and put 1 in number_len
    cmp rax, 0
    jne .two_convert_loop

;put 0 in 1 element of number_buffer to
;print it
    mov byte [number_buffer], '0'
;number of symbols to print
    mov rdx, 1

    jmp .end_convert

;==============================================

	.two_convert_loop:

;check if we translated all significant characters
    cmp rax, 0
    je .end_convert

;put rax value into rbx, to cmp last symbols
    mov rbx, rax
;clean older part of rbx
    and rbx, rsi 

;translate to hex
    cmp bl, 10
;if it just a number we will just add '0' to translate it to ASCII
    jb .is_digit

;if it hex we need to add 7, because '9' have number 57d,
;meanwhile 'A' have number 65, so if register value above or equal
;than 10 we need to add 65 - 57 - 1 (-1 because we cmp with 10)
    add bl, 'A' - '9' - 1

    .is_digit:

;just translate a number in bl to ASCII number
        add bl, '0'

;put cur hex-number in array
        mov [number_buffer+rdx], bl

;number_len++
    inc rdx

;shift rax to powers of two, to skip previous hex digit
    shr rax, cl

    cmp rax, 0
	jne .two_convert_loop

    .end_convert:

%endmacro

;————————————————————————————————————————————————————————————————————————————————

SoftPrintfTrampoline:

;==============================================

;rdi = format str ptr;
;rsi = agr_1
;rdx = arg_2
;rcx = arg_3
;r8 = arg_4
;r9 = arg_5
;other arguments are contain in stack

;r11 = virtual stack for floats
;r13 = printf`s str
;r14 = print buffer size
;r15 = num of float numbers
;r12 = cur_arg = virtual stack pointer
;that needs to access to stack, without 
;destroying rsp

;==============================================

;save return address
    pop rax
    mov [ret_address], rax

;==============================================

;push arguments
    push r9
    push r8
    push rcx
    push rdx
    push rsi

;==============================================

    sub rsp, 8 * 8

; there is no command push for xmm registers,
; so we have to move them right to stack
; movsd = move scalar double, which
    movsd [rsp + 8 * 0], xmm0
    movsd [rsp + 8 * 1], xmm1
    movsd [rsp + 8 * 2], xmm2
    movsd [rsp + 8 * 3], xmm3
    movsd [rsp + 8 * 4], xmm4
    movsd [rsp + 8 * 5], xmm5
    movsd [rsp + 8 * 6], xmm6
    movsd [rsp + 8 * 7], xmm7

;save r12-r15, rbp, rbx, because it destroy-free register
    push r12
    push r13
    push r14
    push r15
    push rbp
    push rbx

;==============================================

;fmt = format str pointer
    mov r13, rdi
;clean pos in printf buffer
    xor r14, r14

    xor r15, r15

;make virtual stack with only params
    mov r12, rsp
;add 48 bytes, because we pushed 4 registers r12-r15
    add r12, 6 * 8 + 8 * 8

;jmp to main function
    jmp SoftPrintf

end_soft_printf:

;output buffer if it isn`t clear
    cmp r14, 0
    je clear_print_buffer
    
    OUTPUT_BUFFER r14

;nothing in print buffer
    clear_print_buffer:

;==============================================

;return xmm values
    movsd xmm0, [rsp + 8 * 0]
    movsd xmm1, [rsp + 8 * 1]
    movsd xmm2, [rsp + 8 * 2]
    movsd xmm3, [rsp + 8 * 3]
    movsd xmm4, [rsp + 8 * 4]
    movsd xmm5, [rsp + 8 * 5]
    movsd xmm6, [rsp + 8 * 6]
    movsd xmm7, [rsp + 8 * 7]

    add rsp, 8 * 8

;==============================================

;return destroy-free register

    pop rbx
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12

;==============================================

;return params to register, to return all register
;and stack to start condition, because it will be
;processed by caller function

    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

;==============================================

;return from SoftPrintf
    mov rax, [ret_address]
    push rax
    ret

;--------------------------------------------------------------------------------

SoftPrintf:

compare:

;checking for the end of the line 
    cmp byte [r13], 0
    je end_soft_printf

;check if cur sym is specifier
    cmp byte [r13], '%'
    je specifier

;if the format is incomplete and it is not specifier,
;then it is just a character for output
    jmp print_letter

;--------------------------------------------------------------------------------

undef_sym:

;==============================================

;call PRINT_STR with "undef sym", and go end

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi
    PRINT_STR undef_str, 17

;==============================================

;go to error end
    jmp end_soft_printf

;————————————————————————————————————————————————————————————————————————————————
;Print symbol from format

;enter  : r13 = pos in format

;return : incremented r13 

;destroy: rax, rdx, rsi
;————————————————————————————————————————————————————————————————————————————————

print_letter:

;==============================================

;take cur sym from format
    mov al, [r13]
;put cur sym into variable, because print interrupt takes
;str pointer, so we need our str in memory
    mov byte [tmp_char], al

;==============================================

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi

    PRINT_STR tmp_char, 1

;==============================================

;increment pos in format, skip cur sym
    inc r13
;go to compare next symbols
    jmp compare    ;MAKE COMPARE MARK

;--------------------------------------------------------------------------------

specifier:

;skip '%'
    inc r13
;rax = specifier
    movzx rax, byte [r13]
;rax *= 8, because it will use like pointer
    shl rax, 3

    lea rdx, [rel specifier_jmp_table]
    add rdx, rax
    jmp [rdx]

;————————————————————————————————————————————————————————————————————————————————
;processing %c, take sym from stack and put in into terminal

;enter  : r13 = pos in format
;       : r12 = cur_arg

;return : incremented r13

;destroy: rax, rdx, rsi
;————————————————————————————————————————————————————————————————————————————————
c_specifier:

;take char to print
    mov rax, [r12]
    add r12, 8
;put cur sym into variable, because print 
;str pointer, so we need our str in memory
    mov [tmp_char], al

;==============================================

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi

    PRINT_STR tmp_char, 1

;==============================================

;skip 'c'
    inc r13
    jmp compare

;————————————————————————————————————————————————————————————————————————————————
;processing %s, take str offset from stack
;and count len then we print this str

;enter  : str offset in stack

;return : incremented bp

;destroy: rax, rdx, rcx
;————————————————————————————————————————————————————————————————————————————————

s_specifier:

;==============================================

;rbx = str_ptr
    mov rbx, [r12]
    add r12, 8

;count str len, destroy rax,
;rdx = str len
    STR_LEN rbx

;==============================================

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi

    PRINT_STR rbx, rdx

;==============================================
    
;skip 's'
    inc r13
    jmp compare

;————————————————————————————————————————————————————————————————————————————————
;we take number from stack and print in in hex-format

;enter  : str offset in stack

;return : incremented r13

;destroy: rax, rbx, rcx, rdx, rbp
;————————————————————————————————————————————————————————————————————————————————

x_specifier:

;rcx = powers of two = 4 = hex
    mov rcx, 4

;convert, reverse, print
;destroy: rax, rbx, rdx, rbp
    jmp powers_of_two

;————————————————————————————————————————————————————————————————————————————————
;we take number from stack and print in in octahedron-format

;enter  : str offset in stack

;return : incremented r13

;destroy: rax, rbx, rcx, rdx, rbp
;————————————————————————————————————————————————————————————————————————————————

o_specifier:

;rcx = powers of two = 1 = binary
    mov rcx, 3

;convert, reverse, print
;destroy: rax, rbx, rdx, rbp
    jmp powers_of_two

;————————————————————————————————————————————————————————————————————————————————
;we take number from stack and print in in 10th-format

;enter  : str offset in stack

;return : incremented r13

;destroy: rax, rbx, rcx, rdx, rbp
;————————————————————————————————————————————————————————————————————————————————

d_specifier:

;translate to octahedron number 

;==============================================

;rax = number, that we will print
    mov rax, [r12]
    add r12, 8

    call ProcessInteger

    inc r13
    jmp compare

;————————————————————————————————————————————————————————————————————————————————
;we take number from stack and print in bin-format

;enter  : str offset in stack

;return : incremented r13

;destroy: rax, rbx, rcx, rdx, rbp, rsi
;————————————————————————————————————————————————————————————————————————————————

b_specifier:

;rcx = powers of two = 1 = binary
    mov rcx, 1

;convert, reverse, print
;destroy: rax, rbx, rdx, rbp, rsi
    jmp powers_of_two

;————————————————————————————————————————————————————————————————————————————————
;we take number from stack and print in bin-format

;enter  : str offset in stack

;return : incremented r13
;destroy: rax, rbx, rcx, rdx, rbp, rsi
;————————————————————————————————————————————————————————————————————————————————

powers_of_two:

;rax = number, that we will print
    mov rax, [r12]
    add r12, 8

;==============================================

;convert a number to the specified number system.
;only for degrees of two.
;enter  : rax = number to convert
;       : rcx = powers of two
;return : rdx = number_len
;       : reversed number in number_buffer
;destroy: rax, rbx, rcx, rdx, rsi

    CONVERT_POWER_OF_TWO

;==============================================

;Expand the number by swapping elements that are symmetrical
;relative the center
;enter  : rdx = number len
;       : number_buffer = buffer there contain out number
;return : reversed number in number_buffer
;destroy: rax, rbx, rcx, rsi

    REVERSE_NUMBER

;==============================================

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi

    PRINT_STR number_buffer, rdx

;==============================================

    inc r13
    jmp compare

;————————————————————————————————————————————————————————————————————————————————
;Print '%' from format

;enter  : r13 = pos in format

;return : incremented r13 

;destroy: rax, rdx, rsi
;————————————————————————————————————————————————————————————————————————————————

percent_specifier:

;Print symbol == '%' from format
;enter  : r13 = pos in format
;return : incremented r13 
;destroy: rax, rdx, rsi
    jmp print_letter

;————————————————————————————————————————————————————————————————————————————————

pointer_specifier:

;rax = number, that we will print
    mov rax, [r12]
    add r12, 8

    mov rcx, 4

;==============================================

;convert a number to the specified number system.
;only for degrees of two.
;enter  : rax = number to convert
;       : rcx = powers of two
;return : rdx = number_len
;       : reversed number in number_buffer
;destroy: rax, rbx, rcx, rdx, rsi

;==============================================

;p_spec is the same with powers_of two,
;but there we don`t clear the older part form rax

;rsi = max value in current degree
;like f in hex-format
    mov rsi, 0xf

;pos in number_buffer
    xor rdx, rdx

;==============================================

;cmp rax with 0, to know if it 0, because basic
;algorithm will print 0 symbols, if it 0
;we put 0 into number_buffer, and put 1 in number_len
    cmp rax, 0
    jne p_spec_convert_loop

;put 0 in 1 element of number_buffer to
;print it
    mov byte [number_buffer], '0'
;number of symbols to print
    mov rdx, 1

    jmp p_spec_end_convert

;==============================================

	p_spec_convert_loop:

;check if we translated all significant characters
    cmp rax, 0
    je p_spec_end_convert

;put rax value into rbx, to cmp last symbols
    mov rbx, rax
;clean older part of rbx
    and rbx, rsi 

;translate to hex
    cmp bl, 10
;if it just a number we will just add '0' to translate it to ASCII
    jb p_spec_is_digit

;if it hex we need to add 7, because '9' have number 57d,
;meanwhile 'A' have number 65, so if register value above or equal
;than 10 we need to add 65 - 57 - 1 (-1 because we cmp with 10)
    add bl, 'A' - '9' - 1

    p_spec_is_digit:

;just translate a number in bl to ASCII number
        add bl, '0'

;put cur hex-number in array
        mov [number_buffer+rdx], bl

;number_len++
    inc rdx

;shift rax to powers of two, to skip previous hex digit
    shr rax, cl

    cmp rax, 0
	jne p_spec_convert_loop

    p_spec_end_convert:

;==============================================

;Expand the number by swapping elements that are symmetrical
;relative the center
;enter  : rdx = number len
;       : number_buffer = buffer there contain out number
;return : reversed number in number_buffer
;destroy: rax, rbx, rcx, rsi

    REVERSE_NUMBER

;==============================================

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi

    PRINT_STR number_buffer, rdx

;==============================================

    inc r13
    jmp compare

;————————————————————————————————————————————————————————————————————————————————

f_specifier:

    jmp print_float

    cmp r15, 8
    jb take_from_start_stack

;==============================================

    movsd xmm0, [r12]
    add r12, 8
    jmp print_float

;==============================================

    take_from_start_stack:

;xmm0 = cur float
        movsd xmm0, [rsp + 8 * r15]
        inc r15
        jmp print_float

;————————————————————————————————————————————————————————————————————————————————

print_float:

;process the integer part
;==============================================

;put integer part from xmm0 to rax
    cvttsd2si rax, xmm0
;save rax, because ProcessInteger destroy it
    push rax

;parse integer and print it
;enter  : rax = immediate
;return : -
;destroy: rax, rbx, rcx, rdx, rsi, rdi
    call ProcessInteger

;==============================================

    mov byte [tmp_char], '.'
    PRINT_STR tmp_char, 1

;==============================================

;return rax
    pop rax
;frac = xmm0 - (double) ((int) xmm0)
;xmm1 = (float)int_part
    cvtsi2sd xmm1, rax

    movapd  xmm2, xmm0
;xmm0 = frac in range [0;1)
    subsd   xmm2, xmm1

;==============================================

    mulsd   xmm2, [ten_pow6]
    cvttsd2si rax, xmm2
    call ProcessInteger

end_frac:
;skip 'f'
    inc r13
    jmp compare

;————————————————————————————————————————————————————————————————————————————————
;parse integer and print it

;enter  : rax = immediate

;return : -

;destroy: rax, rbx, rcx, rdx, rsi, rdi
;————————————————————————————————————————————————————————————————————————————————

ProcessInteger:

;compare digit with 0
;and if it negative digit we print '-',
;then take abs (digit) and pars it
;==============================================

    cmp rax, 0
    jge int_positive_digit

    neg rax
;save rax, because PRINT_STR destroys it
    push rax

;PRINT_STR, takes str_ptr, str_len
;destroy rax, rdx, rsi
    mov [tmp_char], '-'
    PRINT_STR tmp_char, 1

    pop rax

;==============================================

    int_positive_digit:

;rcx = num digits
    xor rcx, rcx

    int_div_iter:

        xor rdx, rdx
;rax / 10
        mov rbx, 0xA
;rdx = surplus after div
        div rbx
;save result in buffer
        mov [number_buffer + rcx], dl
;translate number to str
        add [number_buffer + rcx], '0'
;pos in buffer++
        inc rcx

    cmp rax, 0
    ja int_div_iter

;put number len into rdx, because macros take it in rdx
    mov rdx, rcx

;==============================================

;Expand the number by swapping elements that are symmetrical
;relative the center
;enter  : rdx = number len
;       : number_buffer = buffer there contain out number
;return : reversed number in number_buffer
;destroy: rax, rbx, rcx, rsi

    REVERSE_NUMBER

;==============================================

;use syscall function to print a string
;enter  : 1 arg = buffer pointer
;       : 2 arg = string length
;return : -
;destroy: rax, rdx, rsi, rdi 

    PRINT_STR number_buffer, rdx

;==============================================

    ret

;————————————————————————————————————————————————————————————————————————————————