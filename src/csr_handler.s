j config
j handler

config:
    li x3, 0xFFFFFFFF
    nop
    csrrw x0, mstatus, x3
    csrrw x0, mie, x3
    nop 
    la x2, handler
    slli x2, x2, 2
    nop
    csrrw x0, mtvec, x2
    j main
    nop

handler:
    csrrw x0, mie , x0
    nop
    add x7, x0, x12
    nop
    csrrw x0, mie, x3
    mret
    nop
    nop

main:
    li x10, 10
    li x11, 11
    add x12, x11, x10
    j loop
    nop

loop:
    add x12, x12, x10
    j loop
    nop
    nop
