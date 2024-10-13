;mips disassembler written in x64 asm by max barkouras

BITS 64

section .bss

    ;file read information buffers
    binaryDesc resq 1
    binaryData resb 512
    binaryInfo resq 1
    binarySize resq 1
    numLines resq 1

    machineDesc resq 1
    machineData resb 512
    machineInfo resq 1
    machineSize resq 1
    binaryLine resb 32

    ;file read information buffers
    disassemblyDesc resq 1

    ;single assembled line buffer
    disassembledLine resb 32
    disassembledOpCode resb 6
    disassembledFuncCode resb 6
    disassembledRegister resb 5
    disassembledNum resb 8

section .data

    ;boolean for if line is rType instruction or not
    isLineRtype db 0

    ;boolean for if there are newlines in binary file
    newlineCheck db 0

    ;define newline byte for ease of use
    newline db 0x0A

    ;define counter for current line in binary file
    currentLine db 0

    ;define file names
    disassembledFile db "disassembled.asm", 00h
    binaryFile db "binary.bin", 00h
    machineFile db "machine.bin", 00h

    ;defining not found message in case of failure
    noFind db "couldnt find", 00h

    ;defining no arguments warning
    commandArgs db "please provide a command line argument - 'b' for binary file or 'm' for machine code file", 0ah, 00h

    wrongArgs db "invalid command line argument - use 'b' for binary file or 'm' for machine code file", 0ah, 00h

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
    zerCode db "0000000", 00h
    oneCode db "00000001", 00h
    twoCode db "00000010", 00h
    threeCode db "00000011", 00h
    fourCode db "00000100", 00h
    fiveCode db "00000101", 00h
    sixCode db "00000110", 00h
    sevenCode db "00000111", 00h
    eightCode db "00001000", 00h
    nineCode db "00001001", 00h

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

call machineOrBin

;open binary file
mov rax, 2
mov rdi, binaryFile
xor rsi, rsi
xor rdx, rdx
syscall
mov [binaryDesc], rax

;get file size for reading
mov rax, 5
mov rdi, [binaryDesc]
mov rsi, binaryInfo
syscall

;get file size through 48 byte offset in assemblyInfo
mov rax, [binaryInfo + 48]
mov [binarySize], rax

;divide file size by 32 to get the number of lines, store in numLines
xor rdx, rdx
mov rcx, 32
mov rax, [binarySize]
div rcx
mov [numLines], rax

;get file contents and put in binaryData
mov rax, 0
mov rdx, [binarySize]
mov rsi, binaryData
mov rdi, [binaryDesc]
syscall

;open disasssembled file for writing
mov rax, 2
mov rdi, disassembledFile
mov rsi, 577
mov rdx, 0644
syscall
mov [disassemblyDesc], rax

;check if binary file is formatted with newlines or not, jump depending
xor rax, rax
mov al, byte [binaryData+32]
cmp byte [binaryData+32], 0x0a
jne withLine
jmp withNewline

;if no new lines, get op codes, func codes, and registers
xor rbx, rbx
withLine:
    mov byte [newlineCheck], 0
    movzx r9, byte [currentLine]
    imul r9, 32

    ;get opCode in buffer disassembled OpCode
    xor r10, r10
    call getOpCode

    xor rdx, rdx
    cmp byte [isLineRtype], 0
    je findOpInstruct
    jmp findFuncInstruct

;if new lines, get op codes, func codes, and registers
mov rbx, 0
withNewline:
    mov byte [newlineCheck], 1
    movzx r9, byte [currentLine]
    imul r9, 33

    xor r10, r10
    call getOpCode

    xor rdx, rdx
    cmp byte [isLineRtype], 0
    je findOpInstruct
    jmp findFuncInstruct

;move the first six bytes of the assembly to a buffer for referance
getOpCode:
    mov al, byte [binaryData+r9+r10]
    mov [disassembledOpCode+r10], al
    inc r10
    cmp r10, 6
    jne getOpCode

    xor r10, r10
    cmp byte [disassembledOpCode], 0x30
    je testFunc
    ret

    ;find matching instruction location from opcode
    findOpInstruct:
        cmp rdx, opCodesLength
        je cantFind
        mov rax, [opCodeCodes + rdx * 8]
        inc rdx
        mov rax, [rax]
        shl rax, 10h
        shr rax, 10h
        
        mov r10, [disassembledOpCode]
        shl r10, 10h
        shr r10, 10h
        xor rcx, rcx
        cmp r10, rax
        je findStartOp
        jmp findOpInstruct

    ;prepare for find method
    findStartOp:
        mov r10, rdx
        xor rax, rax
        xor r11, r11
        dec r10

        lea rsi, [opCodeNames + r10 * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        jmp findOpCode

    ;put plaintext instruction in disassembled line buffer
    findOpCode:
        cmp al, 0x00
        je finishBuffer

        lea rsi, [opCodeNames + r10 * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]

        mov byte [disassembledLine + rcx], al
        inc rcx
        jmp findOpCode

;check if opcode is rtype or not
testFunc:
    mov al, byte [disassembledOpCode+r10]
    cmp al, 0x30
    jne return
    inc r10
    cmp r10, 6
    jne testFunc
    xor r10, r10
    je getFuncCode

;return opcode if rtype was a false alarm
return:
    ret

;move the last six bytes of the assembly to a buffer for referance
getFuncCode:
    mov al, byte [binaryData+26+r10+r9]
    mov [disassembledFuncCode+r10], al
    inc r10
    cmp r10, 6
    jne getFuncCode
    mov byte [isLineRtype], 1
    ret

    ;compare last 6 bytes to values stored in memory
    findFuncInstruct:
        cmp rdx, funcCodesLength
        je cantFind
        mov rax, [funcCodeCodes + rdx * 8]
        inc rdx
        mov rax, [rax]
        shl rax, 10h
        shr rax, 10h
        
        mov r10, [disassembledFuncCode]
        shl r10, 10h
        shr r10, 10h
        xor rcx, rcx
        cmp r10, rax
        je findFuncPrep
        jmp findFuncInstruct

    ;prepare for find method
    findFuncPrep:
        mov r10, rdx
        xor rax, rax
        xor r11, r11
        dec r10

        lea rsi, [funcCodeNames + r10 * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]
        jmp findFuncCode

    ;put plaintext instruction in disassembled line buffer
    findFuncCode:
        cmp al, 0x00
        je finishBuffer

        lea rsi, [funcCodeNames + r10 * 8]
        mov al, [rsi]
        mov rsi, [rsi]
        mov al, [rsi + rcx]

        mov byte [disassembledLine + rcx], al
        inc rcx
        jmp findFuncCode

;when null byte is found, add space following instruction to finish buffer
finishBuffer:
    dec rcx
    mov byte [disassembledLine+rcx], 0x20
    inc rcx
    mov r14, rcx

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx

    cmp byte [isLineRtype], 0
    je getRegistersNonRtype
    jmp getRegistersRtype

;get registers for instructions and place in correct positions, jump elsewhere if lw or sw for formatting
getRegistersNonRtype:
    mov rax, [swCode]
    mov rbx, [lwCode]
    mov rcx, [disassembledOpCode]
    shl rax, 10h
    shr rax, 10h
    shl rbx, 10h
    shr rbx, 10h
    shl rcx, 10h
    shr rcx, 10h
    cmp rax, rcx
    je wordRegisters
    cmp rbx, rcx
    je wordRegisters

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    jmp reg1noRtype
    
    ;move the first register (in position 2) into buffer for easy referance
    reg1noRtype:
        mov al, byte [binaryData + 11 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg1noRtype
        inc rcx
        jmp reg1noRtype

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg1noRtype:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg1noRtypeFound
            inc rdx
            jmp inputReg1noRtype

        ;add register to dissassembled line
        reg1noRtypeFound:
            cmp al, 0x00
            je writeRegister1noRtype
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r14 + rcx], al
            inc rcx
            cmp rcx, 7
            jne reg1noRtypeFound
            je writeRegister1noRtype

        ;add formatting after register (comma and space), then clear registers and move to register 2
        writeRegister1noRtype:
            dec rcx
            mov byte [disassembledLine+r14+rcx], 0x2C
            inc rcx
            mov byte [disassembledLine+r14+rcx], 0x20

            inc rcx
            mov r15, rcx
            add r15, r14
            xor rax, rax
            xor rbx, rbx
            xor rcx, rcx
            xor rdx, rdx

            jmp reg2noRtype

    ;move the second register (in position 1) into buffer for easy referance
    reg2noRtype:
        mov al, byte [binaryData + 6 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg2noRtype
        inc rcx
        jmp reg2noRtype

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg2noRtype:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg2noRtypeFound
            inc rdx
            jmp inputReg2noRtype

        ;prepare for adding the register to the disassembled line
        reg2noRtypeFoundEntry:
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

        ;add register to dissassembled line
        reg2noRtypeFound:
            cmp al, 0x00
            je writeRegister2noRtype
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r15 + rcx], al
            inc rcx
            cmp rcx, 7
            jne reg2noRtypeFound
            je writeRegister2noRtype

        ;add formatting after register (comma and space), then clear registers and move to number
        writeRegister2noRtype:
            dec rcx
            mov byte [disassembledLine+r15+rcx], 0x2C
            inc rcx
            mov byte [disassembledLine+r15+rcx], 0x20
            inc rcx

            add r15, rcx
            xor rax, rax
            xor rbx, rbx
            xor rcx, rcx
            xor rdx, rdx
            jmp num

    ;move the number (in position 3) into buffer for easy referance
    num:
        mov al, byte [binaryData + 24 + r9 + rcx]
        mov byte [disassembledNum + rcx], al
        cmp rcx, 7
        je inputNum
        inc rcx
        jmp num

        ;compare number buffer to entries in array to find location of plaintext number
        inputNum:
            cmp rdx, numLength
            je cantFind
            mov rax, [numCodes + rdx * 8]
            mov rax, [rax]
            mov r10, [disassembledNum]

            xor rcx, rcx
            cmp r10, rax
            je numFound
            inc rdx
            jmp inputNum

        ;place plaintext number in disassembled line buffer
        numFound:
            cmp al, 0x00
            je writeNum
            lea rsi, [numNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r15 + rcx], al
            inc rcx
            cmp rcx, 7
            jne numFound
            je writeNum

        ;add formatting after number (newline), then clear registers and call write file
        writeNum:
            dec rcx
            mov byte [disassembledLine+r15+rcx], 0x0a
            inc rcx
            add r15, rcx
            call writeAssembly
            jmp looperFunc

;clear registers for getting registers of lw/sw command
wordRegisters:
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx

    ;move the first register (in position 2) into buffer for easy referance
    reg1word:
        mov al, byte [binaryData + 11 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg1word
        inc rcx
        jmp reg1word

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg1word:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg1wordFound
            inc rdx
            jmp inputReg1word

        ;add register to dissassembled line
        reg1wordFound:
            cmp al, 0x00
            je writeRegister1word
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r14 + rcx], al
            inc rcx
            cmp rcx, 7
            jne reg1wordFound
            je writeRegister1word

        ;add formatting after register (comma and space), then clear registers and move to register 2
        writeRegister1word:
            dec rcx
            mov byte [disassembledLine+r14+rcx], 0x2C
            inc rcx
            mov byte [disassembledLine+r14+rcx], 0x20

            inc rcx
            mov r15, rcx
            mov r13, r15
            add r15, r14
            xor rax, rax
            xor rbx, rbx
            xor rcx, rcx
            xor rdx, rdx

            jmp reg2word

    ;move the second register (in position 1) into buffer for easy referance
    reg2word:
        mov al, byte [binaryData + 6 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg2word
        inc rcx
        jmp reg2word

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg2word:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg2wordFound
            inc rdx
            jmp inputReg2word

        ;prepare for adding the register to the disassembled line
        reg2wordFoundEntry:
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

        ;add register to dissassembled line
        reg2wordFound:
            cmp al, 0x00
            je writeRegister2word
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r15 + 2 + rcx], al
            inc rcx
            cmp rcx, 7
            jne reg2wordFound
            je writeRegister2word

        ;add formatting after register (parenthesis), then clear registers and move to number
        writeRegister2word:
            dec rcx
            mov byte [disassembledLine+r15+1], 0x28
            inc rcx
            mov byte [disassembledLine+r15+rcx+1], 0x29
            inc rcx

            add r15, rcx
            xor rax, rax
            xor rbx, rbx
            xor rcx, rcx
            xor rdx, rdx
            jmp numWord

    ;move the number (in position 3) into buffer for easy referance
    numWord:
        mov al, byte [binaryData + 24 + r9 + rcx]
        mov byte [disassembledNum + rcx], al
        cmp rcx, 7
        je inputNumWord
        inc rcx
        jmp numWord

        ;iterate through number array to find matching plaintext value
        inputNumWord:
            cmp rdx, numLength
            je cantFind
            mov rax, [numCodes + rdx * 8]
            mov rax, [rax]
            mov r10, [disassembledNum]

            xor rcx, rcx
            cmp r10, rax
            je numFoundWord
            inc rdx
            jmp inputNumWord

        ;write plaintext number to disassembled line
        numFoundWord:
            lea rsi, [numNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]
            cmp al, 0x00
            je writeNumWord

            mov byte [disassembledLine + r13+3], al
            inc rcx
            cmp rcx, 7
            jne numFoundWord
            je writeNumWord

        ;add formatting after number (newline), then clear registers and call write file
        writeNumWord:
            mov byte [disassembledLine+r15+1], 0x0a
            inc rcx
            add r15, rcx
            call writeAssembly
            jmp looperFunc

;if current line is a rtype instruction, get and write three registers
getRegistersRtype:

    ;move the first register (in position 3) into buffer for easy referance
    reg1:
        mov al, byte [binaryData + 16 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg1
        inc rcx
        jmp reg1

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg1:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg1Found
            inc rdx
            jmp inputReg1

        ;add register to dissassembled line
        reg1Found:
            cmp al, 0x00
            je writeRegister1
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r14 + rcx], al
            inc rcx
            cmp rcx, 7
            jne reg1Found
            je writeRegister1

        ;add formatting after register (comma and space), then clear registers and move to register 2
        writeRegister1:
            dec rcx
            mov byte [disassembledLine+r14+rcx], 0x2C
            inc rcx
            mov byte [disassembledLine+r14+rcx], 0x20

            inc rcx
            mov r15, rcx
            add r15, r14
            xor rax, rax
            xor rbx, rbx
            xor rcx, rcx
            xor rdx, rdx

            jmp reg2

    ;move the second register (in position 1) into buffer for easy referance
    reg2:
        mov al, byte [binaryData + 6 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg2
        inc rcx
        jmp reg2

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg2:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg2Found
            inc rdx
            jmp inputReg2

        ;prepare for adding the register to the disassembled line
        reg2FoundEntry:
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

        ;add register to dissassembled line
        reg2Found:
            cmp al, 0x00
            je writeRegister2
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r15 + rcx], al
            inc rcx
            cmp rcx, 7
            jne reg2Found
            je writeRegister2

        ;add formatting after register (comma and space), then clear registers and move to register 3
        writeRegister2:
            dec rcx
            mov byte [disassembledLine+r15+rcx], 0x2C
            inc rcx
            mov byte [disassembledLine+r15+rcx], 0x20
            inc rcx

            add r15, rcx
            xor rax, rax
            xor rbx, rbx
            xor rcx, rcx
            xor rdx, rdx
            jmp reg3

    ;move the second register (in position 2) into buffer for easy referance
    reg3:
        mov al, byte [binaryData + 11 + r9 + rcx]
        mov byte [disassembledRegister + rcx], al
        cmp rcx, 4
        je inputReg3
        inc rcx
        jmp reg3

        ;compare register buffer to entries in array to find location of plaintext register
        inputReg3:
            cmp rdx, registersLength
            je cantFind
            mov rax, [registerCodes + rdx * 8]
            mov rax, [rax]
            shl rax, 10h
            shr rax, 10h
            
            mov r10, [disassembledRegister]
            shl r10, 18h
            shr r10, 18h
            xor rcx, rcx

            cmp r10, rax
            je reg3Found
            inc rdx
            jmp inputReg3

        ;prepare for adding the register to the disassembled line
        reg3FoundEntry:
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

        ;add register to dissassembled line
        reg3Found:
            cmp al, 0x00
            je writeRegister3
            lea rsi, [registerNames + rdx * 8]
            mov al, [rsi]
            mov rsi, [rsi]
            mov al, [rsi + rcx]

            mov byte [disassembledLine + r15 + rcx], al
            inc rcx
            cmp rcx, 7
            je writeRegister3
            jmp reg3Found

        ;add formatting after register (newline), then clear registers and call write file
        writeRegister3:
            dec rcx
            mov byte [disassembledLine+r15+rcx], 0x0a
            inc rcx
            add r15, rcx
            call writeAssembly
            jmp looperFunc

;if cant find, check if file is fully iterated, if not print message, then exit either way
cantFind:
    mov r10, [binarySize]
    cmp r9, r10
    je exit

    inc r10
    cmp r9, r10
    je exit

    cmp byte [binaryData+r9], 0x0a
    je exit

    mov rax, 1
    mov rdi, 0
    mov rdx, 12
    mov rsi, noFind
    syscall
    
    jmp exit

;close all files and exit
exit:
    mov rax, 3
    mov rdi, [binaryDesc]    
    syscall

    mov rax, 3
    mov rdi, [disassemblyDesc]    
    syscall

    mov rax, 3
    mov rdi, [machineDesc]    
    syscall

    mov rax, 60
    syscall

;write to asm file r15 bytes from disassembled line
writeAssembly:
    mov rax, 1
    mov rsi, disassembledLine
    mov rdi, [disassemblyDesc]
    mov rdx, r15
    syscall

    ret

;prepare to disassemble next instruction, clear registers, reset booleans
looperFunc:
    mov byte [isLineRtype], 0
    mov al, byte [currentLine]
    inc al
    mov byte [currentLine], al

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    cmp byte [newlineCheck], 0
    je withLine
    jmp withNewline

;check if user wants to disassemble machine code or binary file
machineOrBin:
    cmp byte[rsp+8], 1
    je passArg

    mov rax, [rsp + 24]
    mov al, byte[rax]
    cmp al, 0x6d
    je setMachine
    cmp al, 0x62
    jne invalidArg
    xor rax, rax
    ret

;convert machine code file to binary representation, then continue with start of program
setMachine:

    ;open binary file for writing
    mov rax, 2
    mov rdi, binaryFile
    mov rsi, 577
    mov rdx, 0644
    syscall
    mov [binaryDesc], rax

    ;open machine code file
    mov rax, 2
    mov rdi, machineFile
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [machineDesc], rax

    ;get machine code size for reading/iterating
    mov rax, 5
    mov rdi, [machineDesc]
    mov rsi, machineInfo
    syscall

    ;get machine code size through 48 byte offset in machineInfo
    mov rax, [machineInfo + 48]
    mov [machineSize], rax

    ;get file contents and put in binaryData
    mov rax, 0
    mov rdx, [machineSize]
    mov rsi, machineData
    mov rdi, [machineDesc]
    syscall

    ;iterate one byte at a time, bitshift 8 times per byte to get most signifacant bit and check value
    xor r15, r15
    mov r9, 3
    mov rcx, 7
    mov rdx, 0
    getLeastSigBit:
        mov r10b, byte [machineData + r12 + r9]
        shr r10b, cl
        and r10b, 0x01
        cmp r10b, 1
        je one
        jmp zero

        ;if bit is 1 write 0x31 and jump to reset for next bit
        one:
            mov byte [binaryLine + rdx], 0x31
            jmp reset

        ;if bit is 0, write 0x30 and jump to reset for next bit
        zero:
            mov byte [binaryLine + rdx], 0x30
            jmp reset

        ;decrease bit counter and increase location to write byte in binary line, if already bitshifted 8 times, jump to done to move to next byte
        reset:
            cmp rcx, 0
            je nextByte
            dec rcx
            inc rdx
            jmp getLeastSigBit

    ;reset bit counter, write binary file, check if all bytes are converted (exit if so), and jump to next byte
    nextByte:
        mov rax, 1
        mov rdx, 8
        lea rsi, binaryLine
        mov rdi, [binaryDesc]
        syscall

        mov rcx, [machineSize]
        dec rcx
        cmp r15, rcx
        je finishedConvertion

        inc r15
        mov rcx, 7
        mov rdx, 0
        cmp r9, 0
        je resetFourInc

        dec r9
        jmp getLeastSigBit

    ;because it is little edian, reset reverse counter every four bytes
    resetFourInc:
        mov r9, 3
        add r12, 4
        jmp getLeastSigBit

    ret

;clear registers and return to start
finishedConvertion:
    xor rcx, rcx
    xor rdx, rdx
    xor r9, r9
    xor r11, r11
    xor r12, r12
    xor r15, r15
    ret

;if no command line args are passed, print statement and exit
passArg:
    mov rax, 1
    mov rdi, 1
    mov rdx, 91
    mov rsi, commandArgs
    syscall

    jmp exit

;if invalid command line args are passed, print statement and exit
invalidArg:
    mov rax, 1
    mov rdi, 1
    mov rdx, 86
    mov rsi, wrongArgs
    syscall

    jmp exit
