.section .data

msg_1:  .ascii "Enter the first message: "
# Calculate the prompt length in bytes.
len_1 = . - msg_1

msg_2:  .ascii "Enter the second message: "
len_2 = . - msg_2

res:    .ascii "The Hamming distance is "
len_res = . - res

.section .bss

.lcomm str_1, 256
.lcomm str_2, 256
.lcomm res_h, 32

.section .text
.globl _start

_start:
    movq $1, %rax
    movq $1, %rdi
    leaq msg_1(%rip), %rsi
    movq $len_1, %rdx
    syscall

    movq $0, %rax
    movq $0, %rdi
    leaq str_1(%rip), %rsi
    movq $255, %rdx
    syscall

    # Keep the length at zero if read returns zero or an error.
    xorq %r12, %r12
    testq %rax, %rax
    jle second

    # Save the byte count and check the last byte for a newline.
    movq %rax, %r12
    leaq str_1(%rip), %rbx
    cmpb $10, -1(%rbx,%rax,1)
    jne second

    # Exclude the trailing newline from the length.
    decq %r12

second:
    movq $1, %rax
    movq $1, %rdi
    leaq msg_2(%rip), %rsi
    movq $len_2, %rdx
    syscall

    movq $0, %rax
    movq $0, %rdi
    leaq str_2(%rip), %rsi
    movq $255, %rdx
    syscall

    # Keep the length at zero if read returns zero or an error.
    xorq %r13, %r13
    testq %rax, %rax
    jle least

    # Save the byte count and check the last byte for a newline.
    movq %rax, %r13
    leaq str_2(%rip), %rbx
    cmpb $10, -1(%rbx,%rax,1)
    jne least

    decq %r13

least:
    # Store the shorter length in r12.
    cmpq %r13, %r12
    jle setup

    movq %r13, %r12

setup:
    leaq str_1(%rip), %r8
    leaq str_2(%rip), %r9

    # Clear the byte index and total bit difference count.
    xorq %r14, %r14
    xorq %rbp, %rbp

hamming:
    # Stop when the byte index reaches the shorter length.
    cmpq %r12, %r14
    jge print_result

    # Load one byte and clear the upper bits of r15.
    movzbq (%r8,%r14,1), %r15

    # XOR marks differing bits with 1.
    xorb (%r9,%r14,1), %r15b
    movq $8, %rcx

bit_loop:
    # Check whether the lowest bit is 1.
    testq $1, %r15
    jz bit_zero

    incq %rbp

bit_zero:
    # Shift to the next bit and repeat for all eight bits.
    shrq $1, %r15
    decq %rcx
    jnz bit_loop

    incq %r14
    jmp hamming

print_result:
    movq $1, %rax
    movq $1, %rdi
    leaq res(%rip), %rsi
    movq $len_res, %rdx
    syscall

    # Build the output backward, starting with a newline.
    leaq res_h+31(%rip), %rsi
    movb $10, (%rsi)
    movq %rbp, %rax
    movq $10, %rbx

    # Include the newline in the output length.
    movq $1, %r8

convert:
    # Divide RDX:RAX by 10; RAX holds the quotient, RDX the remainder.
    xorq %rdx, %rdx
    divq %rbx

    # Convert the remainder to an ASCII digit and prepend it.
    addb $48, %dl
    decq %rsi
    movb %dl, (%rsi)
    incq %r8

    # Continue until no digits remain.
    testq %rax, %rax
    jnz convert

    # Write the digits and trailing newline.
    movq %r8, %rdx
    movq $1, %rax
    movq $1, %rdi
    syscall

    movq $60, %rax
    xorq %rdi, %rdi
    syscall
    