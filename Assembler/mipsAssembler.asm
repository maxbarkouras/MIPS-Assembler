; mips assembler written in x64 asm by max barkouras

BITS 64

section .bss

    ;file read information buffers
    assemblyData resb 512
    assemblyInfo resb 144
    assemblySize resq 1
    assemblyDesc resq 1

    ;file write information buffers
    binaryDesc resq 1
    machineDesc resq 1

    ;single assembled line buffer
    assembledLine resb 32

section .data

    ;boolean for if line is rType instruction or not
    isLineRtype db 0

    newline db 0x0A

    ;int for tracking position of current register component
    registerPosition db 0

    ;define file names
    assemblyFile db "assembly.asm", 00h
    binaryFile db "binary.bin", 00h
    machineFile db "machine.bin", 00h

    ;defining not found message in case of failure
    noFind db "couldnt find", 00h

    ;define op codes
    rtypeName db "rtype", 00h
    lwName db "lw", 00h
    swName db "sw", 00h
    beqName db "beq", 00h
    bneName db "bne", 00h
    jName db "j", 00h
    addiName db "addi", 00h
    rtypeCode db "000000", 00h
    lwCode db "100011", 00h
    swCode db "101011", 00h
    beqCode db "000100", 00h
    bneCode db "000101", 00h
    jCode db "000010", 00h
    addiCode db "001000", 00h

    ;define "arrays" of opcodes
    opCodeNames dq rtypeName, lwName, swName, beqName, bneName, jName, addiName
    opCodeCodes dq rtypeCode, lwCode, swCode, beqCode, bneCode, jCode, addiCode
    opCodesLength equ 7

    ;define func codes
    addName db "add", 00h
    subName db "sub", 00h
    andName db "and", 00h
    orName db "or", 00h
    sltName db "slt", 00h
    addCode db "100000", 00h
    subCode db "100010", 00h
    andCode db "100100", 00h
    orCode db "100101", 00h
    sltCode db "101010", 00h

    ;define "arrays" of funcodes
    funcCodeNames dq addName, subName, andName, orName, sltName
    funcCodeCodes dq addCode, subCode, andCode, orCode, sltCode
    funcCodesLength equ 5

    ;define int codes
    zerName db 0x30, 00h
    oneName db 0x31, 00h
    twoName db 0x32, 00h
    threeName db 0x33, 00h
    fourName db 0x34, 00h
    fiveName db 0x35, 00h
    sixName db 0x36, 00h
    sevenName db 0x37, 00h
    eightName db 0x38, 00h
    nineName db 0x39, 00h
    zerCode db "0000000000000000", 00h
    oneCode db "0000000000000001", 00h
    twoCode db "0000000000000010", 00h
    threeCode db "0000000000000011", 00h
    fourCode db "0000000000000100", 00h
    fiveCode db "0000000000000101", 00h
    sixCode db "0000000000000110", 00h
    sevenCode db "0000000000000111", 00h
    eightCode db "0000000000001000", 00h
    nineCode db "0000000000001001", 00h

    ;define "arrays" of ints
    numNames dq zerName, oneName, twoName, threeName, fourName, fiveName, sixName, sevenName, eightName, nineName
    numCodes dq zerCode, oneCode, twoCode, threeCode, fourCode, fiveCode, sixCode, sevenCode, eightCode, nineCode
    numLength equ 10

    ;define registers
    zeroName db "$zero", 00h
    t0Name db "$t0", 00h
    t1Name db "$t1", 00h
    t2Name db "$t2", 00h
    t3Name db "$t3", 00h
    t4Name db "$t4", 00h
    t5Name db "$t5", 00h
    t6Name db "$t6", 00h
    t7Name db "$t7", 00h
    s0Name db "$s0", 00h
    s1Name db "$s1", 00h
    s2Name db "$s2", 00h
    s3Name db "$s3", 00h
    s4Name db "$s4", 00h
    s5Name db "$s5", 00h
    s6Name db "$s6", 00h
    s7Name db "$s7", 00h
    zeroCode db "00000", 00h
    t0Code db "01000", 00h
    t1Code db "01001", 00h
    t2Code db "01010", 00h
    t3Code db "01011", 00h
    t4Code db "01100", 00h
    t5Code db "01101", 00h
    t6Code db "01110", 00h
    t7Code db "01111", 00h
    s0Code db "10000", 00h
    s1Code db "10001", 00h
    s2Code db "10010", 00h
    s3Code db "10011", 00h
    s4Code db "10100", 00h
    s5Code db "10101", 00h
    s6Code db "10110", 00h
    s7Code db "10111", 00h

    ;define "arrays" of registers
    registerNames dq zeroName, t0Name, t1Name, t2Name, t3Name, t4Name, t5Name, t6Name, t7Name, s0Name, s1Name, s2Name, s3Name, s4Name, s5Name, s6Name, s7Name
    registerCodes dq zeroCode, t0Code, t1Code, t2Code, t3Code, t4Code, t5Code, t6Code, t7Code, s0Code, s1Code, s2Code, s3Code, s4Code, s5Code, s6Code, s7Code
    registersLength equ 17

section .text
global _start

_start:

;open assembly file
mov rax, 2
mov rdi, assemblyFile
xor rsi, rsi
xor rdx, rdx
syscall
mov [assemblyDesc], rax
mov r10, rax

;get file size for reading
mov rax, 5
mov rdi, [assemblyDesc]
mov rsi, assemblyInfo
syscall

;get file size through 48 byte offset in assemblyInfo
mov rax, [assemblyInfo + 48]
mov [assemblySize], rax

;read file and put in assemblyData buffer
mov rdi, r10
xor rax, rax
mov rsi, assemblyData
mov rdx, [assemblySize]
syscall

;open binary file for writing
mov rax, 2
mov rdi, binaryFile
mov rsi, 577
mov rdx, 0644
syscall
mov [binaryDesc], rax

;open machine code file for writing
mov rax, 2
mov rdi, machineFile
mov rsi, 577
mov rdx, 0644
syscall
mov [machineDesc], rax

;clear registers
xor rax, rax
xor rbx, rbx
xor rcx, rcx
xor rdx, rdx

;put file contents in rsi, file size in r15 for counter
mov rsi, assemblyData
mov r15, [assemblySize]
inc r15

;iterate through file bytes and jump when byte is a space or newline; ignore comments
fileProcess:
    dec r15
    mov al, [rsi]
    cmp al, 0x23
    je commentSkipPrep
    cmp al, 0x20
    je valueConvertPrep
    cmp al, 0x28
    je valueConvertPrep
    cmp al, 0x0a
    je valueConvertPrep
    jmp restartFileProcess

;move one byte in file contents, quit if file has been fully iterated through, continue if not
restartFileProcess:
    inc rsi
    cmp r15, 0
    jne fileProcess
    jmp exit

;copy file contents to r9 for volatility and to r10 for modification, check if previous byte was comma - jump if so, continue to convertion if not
valueConvertPrep:
    xor r11, r11
    mov r9, rsi
    mov r10, rsi
    dec r10
    mov al, [r10]
    cmp al, 0x2C
    je extraPrep
    cmp al, 0x29
    je extraPrep
    jmp valueConvert

;move one extra byte down to skip over comma, continue to convertion
extraPrep:
    dec r10
    jmp valueConvert

;iterates through rsi until newline, meaning comment is over, restarts file processesing from there
commentSkipPrep:
    inc rsi
    cmp r15, 0
    jne commentSkip
    jmp exit

commentSkip:
    dec r15
    mov al, [rsi]
    cmp al, 0x0a
    jne commentSkipPrep
    mov r9, rsi
    call writeLine
    mov rsi, r9
    inc rsi
    jmp fileProcess

;iterate through bytes from file, moving into r11 until current component ends, find opcode when so
valueConvert:
    mov r12b, [r10]
    cmp r12b, 0x2C
    je opFinder
    cmp r12b, 0x20
    je opFinder
    cmp r12b, 0x0a
    je opFinder
    cmp r12b, 0x00
    je opFinder
    cmp r12b, 0x28
    je opFinder
    shl r11, 8
    mov r11b, [r10]
    dec r10
    jmp valueConvert

;reset counter and continue
opFinder:
    xor rbx, rbx
    jmp checkFunc

;iterate through funcCode array, attempting to compare component to a known value; if not found, jump to opcode array
checkFunc:
    cmp rbx, funcCodesLength
    je checkOpPrep
    mov rax, [funcCodeNames + rbx * 8]
    mov eax, [rax]
    inc rbx
    cmp eax, r11d
    jne doubleCheckFunc
    dec rbx
    jmp assembleFuncLine

    ;check if null byte is inside eax, meaning component might be smaller
    doubleCheckFunc:
        xor ecx, ecx
        mov ecx, eax
        shr ecx, 16
        cmp cl, 0x00
        je smallFuncCheck
        jmp checkFunc
    
    ;check if lower 16 bytes match component
    smallFuncCheck:
        cmp ax, r11w
        jne checkFunc
        dec rbx
    
;construct assembledLine buffer, set isLineRtype to true
assembleFuncLine:
    mov byte [isLineRtype], 1
    xor rcx, rcx
    mov byte [registerPosition], 0

    ;place func code in positions 26-32
    placeFuncCode:
        lea rsi, [funcCodeCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 26 + rcx], al
        inc rcx
        cmp rcx, 6
        jne placeFuncCode
    
    ;place shamt in positions 20-25
    xor rcx, rcx
    placeShamt:
        mov byte [assembledLine + 21 + rcx], '0'
        inc rcx
        cmp rcx, 5
        jne placeShamt
    
    ;place shamt in positions 0-5
    xor rcx, rcx
    placeRtype:
        mov byte [assembledLine + rcx], '0'
        inc rcx
        cmp rcx, 6
        jne placeRtype

    jmp fileProcessPrep

;reset counter and continue
checkOpPrep:
    xor rbx, rbx
    jmp checkOp

;iterate through opCode array, attempting to compare component to a known value; if not found, jump to register array
checkOp:
    cmp rbx, opCodesLength
    je checkRegPrep
    mov rax, [opCodeNames + rbx * 8]
    mov eax, [rax]
    inc rbx
    cmp eax, r11d
    jne doubleCheckOp
    dec rbx
    jmp assembleOpLine
    
    ;check if null byte is inside eax, meaning component might be smaller
    doubleCheckOp:
        xor ecx, ecx
        mov ecx, eax
        shr ecx, 16
        cmp cl, 0x00
        je smallOpCheck
        jmp checkOp
    
    ;check if lower 16 bytes match component
    smallOpCheck:
        cmp ax, r11w
        jne checkOp
        dec rbx

;construct assembledLine buffer, set isLineRtype to true
assembleOpLine:
    mov byte [isLineRtype], 0
    xor rcx, rcx
    mov byte [registerPosition], 0
    
    ;place op code in positions 0-5
    placeOpCode:
        lea rsi, [opCodeCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + rcx], al
        inc rcx
        cmp rcx, 6
        jne placeOpCode

    jmp fileProcessPrep

;reset counter and continue
checkRegPrep:
    xor rbx, rbx
    jmp checkReg

;iterate through register array, attempting to compare component to a known value; if not found, print not found message and exit
checkReg:
    cmp rbx, registersLength
    je checkNumPrep
    mov rax, [registerNames + rbx * 8]
    mov eax, [rax]
    inc rbx
    cmp eax, r11d
    jne checkReg
    dec rbx

    ;get position for current register component and put in right spot 
    ;check if current line is rtype or not, which changes register positioning
    assembleRegLine:
        xor rcx, rcx
        mov r14b, byte [isLineRtype]
        cmp r14b, 1
        je loadRegRtype
        jmp loadRegNonRtype

    ;prep function for non rtype register loading
    loadRegNonRtype:
        mov r13b, byte [registerPosition]
        inc r13
        mov byte [registerPosition], r13b
        cmp r13, 1
        je positionOneLoad
        jmp positionTwoLoad

    ;load rd in positions 11-15
    positionOneLoad:
        lea rsi, [registerCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 11 + rcx], al
        inc rcx
        cmp rcx, 5
        jne positionOneLoad
        jmp fileProcessPrep
    
    ;load rs in positions 6-10
    positionTwoLoad:
        lea rsi, [registerCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 6 + rcx], al
        inc rcx
        cmp rcx, 5
        jne positionTwoLoad
        jmp fileProcessPrep
    
    ;prep function for rtype register loading
    loadRegRtype:
        mov r13b, byte [registerPosition]
        inc r13
        mov byte [registerPosition], r13b
        cmp r13, 1
        je positionOneLoadrType
        cmp r13, 2
        je positionTwoLoadrType
        jmp positionThreeLoadrType
    
    ;if rd, place reg code in positions 16-20
    positionOneLoadrType:
        lea rsi, [registerCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 16 + rcx], al
        inc rcx
        cmp rcx, 5
        jne positionOneLoadrType
        jmp fileProcessPrep

    ;if rs, place reg code in positions 6-10
    positionTwoLoadrType:
        lea rsi, [registerCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 6 + rcx], al
        inc rcx
        cmp rcx, 5
        jne positionTwoLoadrType
        jmp fileProcessPrep

    ;if rt, place reg code in positions 11-15
    positionThreeLoadrType:
        lea rsi, [registerCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 11 + rcx], al
        inc rcx
        cmp rcx, 5
        jne positionThreeLoadrType
        jmp fileProcessPrep

    jmp fileProcessPrep

;reset counter and continue
checkNumPrep:
    xor rbx, rbx
    jmp checkNum

;iterate through number array, attempting to compare component to a known value; if not found, print not found message and exit
checkNum:
    cmp rbx, numLength
    je cantFind
    mov rax, [numNames + rbx * 8]
    mov eax, [rax]
    inc rbx
    cmp al, r11b
    jne checkNum
    dec rbx
    jmp assembleNumLine

    ;clear counter and continue
    assembleNumLine:
        xor rcx, rcx
        jmp placeNumCode

    ;place num code in positions 16-32
    placeNumCode:
        lea rsi, [numCodes + rbx * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        mov byte [assembledLine + 16 + rcx], al
        inc rcx
        cmp rcx, 16
        jne placeNumCode

    jmp fileProcessPrep

;move file contents back into rsi, move one byte up, and start iteration for next component
fileProcessPrep:
    xor rax, rax
    mov rsi, r9
    inc rsi
    mov r9b, [r9]
    cmp r9b, 0x0a
    jne fileProcess
    mov r9, rsi
    call writeLine
    mov rsi, r9
    inc rsi
    jmp fileProcess

;print not found message and exit
cantFind:
    mov rax, 1
    mov rdi, 1
    mov rdx, 12
    mov rsi, noFind
    syscall
    jmp exit

;function for writing asssembled line to file
writeLine:

    ;write binary file
    writeBinary:
    mov rax, 1
    mov rsi, assembledLine
    mov rdi, [binaryDesc]
    mov rdx, 32
    syscall
    mov rax, 1
    mov rsi, newline
    mov rdi, [binaryDesc]
    mov rdx, 1
    syscall

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    mov rsi, assembledLine

    ;convert binary representation into machine code
    convertToMachine:
        movzx rdx, byte [rsi]
        test rdx, rdx
        jz writeMachine

        sub rdx, '0'
        shl rax, 1
        or rax, rdx

        inc rsi
        jmp convertToMachine

    ;write converted machine code into file and return
    writeMachine:
        mov [rsp-4], eax

        mov rax, 1
        mov rdi, [machineDesc]
        lea rsi, [rsp-4]
        mov rdx, 4
        syscall

ret

;close all files and cleanly exit
exit:
    mov rax, 3
    mov rdi, [assemblyDesc]    
    syscall

    mov rax, 3
    mov rdi, [binaryDesc]    
    syscall

    mov rax, 3
    mov rdi, [machineDesc]    
    syscall

    xor rdi, rdi
    inc rdi
    mov rax, 3Ch
    syscall
