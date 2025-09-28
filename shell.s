.global _start

.section .data
prompt:     .asciz "shell> "
newline:    .asciz "\n"
hello_msg:  .asciz "Hello World!\n"
help_msg:   .asciz "Available commands:\nhello\nhelp\nexit\nclear\nhex <number>\navg <n1> <n2> ...\n"
cmd_hello:  .asciz "hello"
cmd_help:   .asciz "help"
cmd_exit:   .asciz "exit"
cmd_clear:  .asciz "clear"
cmd_hex:    .asciz "hex"
cmd_avg:    .asciz "avg"
clear_msg:  .asciz "\033[2J\033[H"
hex_prefix: .asciz "0x"
avg_prefix: .asciz "Average: "

.section .bss
buffer: .skip 128

.section .text

_start:
    bl main

main:
    ldr r0, =prompt
    bl print_string
    b read_loop

read_loop:
    ldr r0, =buffer
    mov r1, #128
    bl read_input
    ldr r0, =buffer
    bl strip_newline

    ldr r0, =buffer
    ldr r1, =cmd_hello
    bl string_equal
    cmp r0, #1
    beq do_hello

    ldr r0, =buffer
    ldr r1, =cmd_help
    bl string_equal
    cmp r0, #1
    beq do_help

    ldr r0, =buffer
    ldr r1, =cmd_exit
    bl string_equal
    cmp r0, #1
    beq do_exit

    ldr r0, =buffer
    ldr r1, =cmd_clear
    bl string_equal
    cmp r0, #1
    beq do_clear

    ldr r0, =buffer
    ldr r1, =cmd_hex
    bl starts_with
    cmp r0, #1
    beq do_hex

    ldr r0, =buffer
    ldr r1, =cmd_avg
    bl starts_with
    cmp r0, #1
    beq do_avg

    ldr r0, =prompt
    bl print_string
    b read_loop

do_hello:
    ldr r0, =hello_msg
    bl print_string
    ldr r0, =prompt
    bl print_string
    b read_loop

do_help:
    ldr r0, =help_msg
    bl print_string
    ldr r0, =prompt
    bl print_string
    b read_loop

do_exit:
    mov r7, #1
    mov r0, #0
    swi 0

do_clear:
    ldr r0, =clear_msg
    bl print_string
    ldr r0, =prompt
    bl print_string
    b read_loop

do_hex:
    ldr r0, =buffer
    bl skip_first_word
    bl str_to_int
    mov r1, r0
    bl print_hex
    ldr r0, =newline
    bl print_string
    ldr r0, =prompt
    bl print_string
    b read_loop

do_avg:
    ldr r0, =buffer
    bl skip_first_word
    mov r1, r0
    mov r2, #0         @ sum
    mov r3, #0         @ count
avg_next:
    mov r0, r1
    bl str_to_int
    mov r4, r0
    cmp r4, #0
    beq avg_done
    add r2, r2, r4
    add r3, r3, #1
    mov r0, r1
    bl skip_first_word
    mov r1, r0
    b avg_next
avg_done:
    cmp r3, #0
    beq avg_skip
    mov r0, r2
    mov r1, r3
    bl udiv
    ldr r1, =avg_prefix
    bl print_string
    mov r1, r0
    bl print_dec
    ldr r0, =newline
    bl print_string
avg_skip:
    ldr r0, =prompt
    bl print_string
    b read_loop

print_string:
    push {lr}
    mov r1, r0
    bl strlen
    mov r2, r0
    mov r0, #1
    mov r7, #4
    swi 0
    pop {lr}
    bx lr

strlen:
    push {r1, r2, lr}
    mov r4, r0
    mov r1, r0
strlen_loop:
    ldrb r2, [r1]
    cmp r2, #0
    beq strlen_done
    add r1, r1, #1
    b strlen_loop
strlen_done:
    sub r0, r1, r4
    pop {r1, r2, lr}
    bx lr

read_input:
    push {lr}
    mov r2, r1
    mov r1, r0
    mov r0, #0
    mov r7, #3
    swi 0
    pop {lr}
    bx lr

strip_newline:
    push {r1, r2, lr}
    mov r1, r0
strip_loop:
    ldrb r2, [r1]
    cmp r2, #0
    beq strip_done
    cmp r2, #10
    bne strip_next
    mov r2, #0
    strb r2, [r1]
    b strip_done
strip_next:
    add r1, r1, #1
    b strip_loop
strip_done:
    pop {r1, r2, lr}
    bx lr

string_equal:
    push {r2, r3, lr}
string_equal_loop:
    ldrb r2, [r0], #1
    ldrb r3, [r1], #1
    cmp r2, r3
    bne string_equal_no
    cmp r2, #0
    bne string_equal_loop
    mov r0, #1
    pop {r2, r3, lr}
    bx lr
string_equal_no:
    mov r0, #0
    pop {r2, r3, lr}
    bx lr

starts_with:
    push {r2, r3, lr}
starts_loop:
    ldrb r2, [r0], #1
    ldrb r3, [r1], #1
    cmp r3, #0
    beq starts_match
    cmp r2, r3
    bne starts_no
    b starts_loop
starts_match:
    mov r0, #1
    pop {r2, r3, lr}
    bx lr
starts_no:
    mov r0, #0
    pop {r2, r3, lr}
    bx lr

skip_first_word:
    push {r1, r2, lr}
    mov r1, r0
skip_loop:
    ldrb r2, [r1]
    cmp r2, #' '
    beq skip_found
    cmp r2, #0
    beq skip_end
    add r1, r1, #1
    b skip_loop
skip_found:
    add r1, r1, #1
skip_spaces:
    ldrb r2, [r1]
    cmp r2, #' '
    beq skip_spaces_continue
    b skip_end
skip_spaces_continue:
    add r1, r1, #1
    b skip_spaces
skip_end:
    mov r0, r1
    pop {r1, r2, lr}
    bx lr

str_to_int:
    mov r1, #0
parse_loop:
    ldrb r2, [r0], #1
    cmp r2, #0
    beq parse_done
    cmp r2, #'0'
    blt parse_done
    cmp r2, #'9'
    bgt parse_done
    sub r2, r2, #'0'
    mov r3, #10
    mul r3, r1, r3
    add r1, r3, r2
    b parse_loop
parse_done:
    mov r0, r1
    bx lr

print_hex:
    push {r1-r7, lr}
    ldr r0, =hex_prefix
    bl print_string
    mov r2, r1
    mov r3, #28
hex_loop:
    mov r1, r2
    lsr r1, r1, r3
    and r1, r1, #0xF
    cmp r1, #10
    blt hex_digit
    add r1, r1, #'A' - 10
    b hex_emit
hex_digit:
    add r1, r1, #'0'
hex_emit:
    mov r0, r1
    bl print_char
    sub r3, r3, #4
    cmp r3, #-4
    bgt hex_loop
    pop {r1-r7, lr}
    bx lr

print_char:
    push {r1, r2, lr}
    mov r1, sp
    sub sp, sp, #1
    strb r0, [sp]
    mov r0, #1
    mov r1, sp
    mov r2, #1
    mov r7, #4
    swi 0
    add sp, sp, #1
    pop {r1, r2, lr}
    bx lr

print_dec:
    push {r1-r5, lr}
    mov r2, #10
    sub sp, sp, #12
    mov r3, sp
    mov r4, #0
print_dec_loop:
    mov r1, #10
    bl udiv
    add r0, r0, #'0'
    strb r0, [r3, r4]
    add r4, r4, #1
    mov r0, r5
    cmp r0, #0
    bne print_dec_loop
print_dec_out:
    subs r4, r4, #1
    bmi print_dec_done
    ldrb r0, [r3, r4]
    bl print_char
    b print_dec_out
print_dec_done:
    add sp, sp, #12
    pop {r1-r5, lr}
    bx lr

udiv:
    push {r2, r3, lr}
    mov r2, #0
    mov r3, r0
udiv_loop:
    cmp r3, r1
    blt udiv_done
    sub r3, r3, r1
    add r2, r2, #1
    b udiv_loop
udiv_done:
    mov r0, r2
    pop {r2, r3, lr}
    bx lr

.section .note.GNU-stack,"",%progbits

