;	Keanu Aloua
;	CS 218 - Section 1002
;	Last Modified October 17, 2021
;	Assignment #6: This program will involve writing functions to perform a variety of tasks.
;                  These tasks relate to floating points, the command line, and integrating with C/C++ code.

section .data
;   System service constants
    SYSTEM_WRITE equ 1
    STANDARD_OUT equ 1
    SYSTEM_READ equ 0
    STANDARD_IN equ 0
    SUCCESS equ 0
    SYSTEM_EXIT equ 60

;   Variable Constants
    LINEFEED equ 10
    NULL equ 0

;   Variable Strings
    errorSingleArgString db "Please include the following: -W weight -D diameter", LINEFEED, NULL
    errorNumArgString db "Expected 4 arguments: -W weight -D diamter", LINEFEED, NULL
    errorIncorrectWString db "Expected a -W argument.", LINEFEED, NULL
    errorIncorrectDString db "Expected a -D argument.", LINEFEED, NULL
    errorInvalidString db "Invalid Number entered.", LINEFEED, NULL
    secondArgString db "-W", NULL
    fourthArgString db "-D", NULL
    validString db "VALID WOOO", LINEFEED, NULL

;   Double constant variables
    PI dq 3.14159
    HELIUM_LIFT dq 0.06689
    VALID_FLOAT_CHECK dq 0.0 ; Variable for checking to see valid float command line arguments

section .bss
;   Double variables
    balloonWeight dq 1
    balloonDiameter dq 1
    balloonsRequired dq 1

section .text
    extern atof, ceil, printBalloonsRequired

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR FINDING THE STRING LENGTH
;-------------------------------------------------------------------------------------------
global findStringLength
findStringLength:
    ; rdi will have string address

    mov r11, 0 ; Setting a counter/index
    mov rax, 0 ; Clearing out register

    stringCountLoop:
        cmp byte[rdi + r11], NULL ; Compares character to NULL
        je foundLength ; If the character is NULL, then the length has been found
        inc r11         
        jmp stringCountLoop

    foundLength:
        mov rax, r11 ; Moves the counter value to the return value

    ret

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR PRINTING A NULL TERMINATED STRING
;-------------------------------------------------------------------------------------------
global printString
printString:
    ; rdi will have the string address

    push rbx ; Reserves register
    mov rbx, rdi

    call findStringLength ; rax will have the string length
    mov r11, rax ; Moves the string length to rbx

    ; Print system call
    mov rax, SYSTEM_WRITE
	mov rdi, STANDARD_OUT
	mov rsi, rbx ; Will print the string
	mov rdx, r11 ; Will print the value ot the string length
	syscall

    pop rbx
    ret

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR COMPARING NULL TERMINATED STRINGS
;-------------------------------------------------------------------------------------------
global compareStrings
compareStrings:
    ; rdi will have the first string address
    ; rsi will have the second string address

    mov rax, 0 ; Clearing the register

    compareLoop:
        mov al, byte[rdi] ; Moves first char of the first string to al
        cmp al, byte[rsi] ; Compares the first char of the second string -> the first char of the first string
        jne stringsNotEqual ; Jumps if they are not equal

        inc rdi ; Goes to the next char
        inc rsi ; Goes to the next char
        
        cmp byte[rdi], NULL ; Checks if the first string is equal to NULL
        je checkNextString

        jmp compareLoop
 
    checkNextString:
        cmp byte[rsi], NULL ; Checks if the second string is equal to NULL
        je stringsEqual

    stringsNotEqual:
        mov rax, -1 ; Returns -1 if not equal
        jmp compareLoopDone

    stringsEqual:
        mov rax, 0 ; Returns 0 if the strings are equal

    compareLoopDone:

    ret

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR CHECKING AND CONVERTING COMMAND LINE ARGUMENTS
;-------------------------------------------------------------------------------------------
global checkCommandLineArgs
checkCommandLineArgs:
;   rdi will have the argc
;   rsi will have argv

    ; Saving the values of rdi and rsi
    mov r12, rdi ; argc
    mov r13, rsi ; argv

    startCheck:
        cmp r12, 1 ; Checking if there is only one command line argument
        jne moreThanOneArg
        mov rax, 0 ; Returns 0 when a single command line argument was used
        jmp endCheck

    moreThanOneArg:
        cmp r12, 5 ; Checking if there are 5 command line arguments
        je checkSecondArg
        mov rax, -1 ; Returns -1 when the number of arguments is not exactly 5
        jmp endCheck

    checkSecondArg:
        mov rdi, qword[r13 + 8]
        mov rsi, secondArgString
        call compareStrings ; Checking for "-W", NULL
        cmp rax, 0 ; Checks if the strings are equal

        je checkFourthArg ; If they are equal, check the fourth argument
        mov rax, -2 ; If not equal, then returns -2 when the second command line argument is not "-W"
        jmp endCheck

    checkFourthArg:
        mov rdi, qword[r13 + 24]
        mov rsi, fourthArgString
        call compareStrings ; Checking for "-D", NULL
        cmp rax, 0 ; Checks if the strings are equal

        je checkFloatArgs ; If they are equal then check the float values
        mov rax, -4 ; If not equal, then returns -4 when the fourth command line argument is not "-D"
        jmp endCheck

    checkFloatArgs:
        ; Checking the first float value/ 3rd Argument
        mov rdi, qword[r13 + 16]
        call atof
        ucomisd xmm0, qword[VALID_FLOAT_CHECK]
        jbe notValidFloatArgs ; If the first float value is 0.0 or less, then it is invalid

        movsd qword[balloonWeight], xmm0 ; If valid, stores weight value into double variable

        ; Checking the second float value/ 5th argument
        mov rdi, qword[r13 + 32]
        call atof
        ucomisd xmm0, qword[VALID_FLOAT_CHECK]
        jbe notValidFloatArgs ; If the second double value is less than 0.0, then the value is invalid
        
        movsd qword[balloonDiameter], xmm0 ; If valid, stores diameter value into double variable

        ; If both double values are greater than 0.0, they are both valid
        jmp checkPassed

        notValidFloatArgs:
            mov rax, -3 ; Returns -3 when the double value returned from atof is 0.0 or less
            jmp endCheck

    checkPassed:
        mov rax, 1 ; If all the checks have passed

    endCheck:
    ret ; Will either return a -4, -3, -2, -1, or 0 for errors. Will return a 1 if there are no errors.

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR BALLOON CALCULATIONS
;-------------------------------------------------------------------------------------------
global balloonCalculations
balloonCalculations:
;   xmm0 will have the balloon weight
;   xmm1 will have the balloon diameter

    mov r12, 2
    mov r13, 3
    mov r14, 4
    cvtsi2sd xmm2, r12 ; 2
    cvtsi2sd xmm3, r13 ; 3
    cvtsi2sd xmm4, r14 ; 4
    movsd xmm5, qword[PI]
    movsd xmm6, qword[HELIUM_LIFT]

    balloonVolumeCalculations:
        divsd xmm4, xmm3 ; 4 / 3
        mulsd xmm4, xmm5 ; (4 / 3) * Pi should be around 4.188786

        divsd xmm1, xmm2 ; Diameter / 2
        movsd xmm2, xmm1 ; Moves (Diameter / 2) to 2nd register
        mulsd xmm1, xmm2 ; (Diameter / 2) ^2
        mulsd xmm1, xmm2  ; (Diameter / 2) ^3

        mulsd xmm1, xmm4 ; [(4 / 3) * Pi] * [(Diameter / 2) ^3]
        ; xmm1 will have the volume

    balloonsRequiredCalc:
        mulsd xmm1, xmm6 ; Volume * Helium Lift
        divsd xmm0, xmm1 ; Weight / (Volume * Helium Lift)

    ; xmm0 will have [Weight / (Volume * Helium Lift)]
    call ceil

    ret ; Returns the balloons required

;-------------------------------------------------------------------------------------------
;   PROGRAM START
;-------------------------------------------------------------------------------------------
global main
main:
    ; rdi has argc
    ; rsi has argv
    
    call checkCommandLineArgs

    cmp rax, 1
    jne errorMessages ; If the return value is not 1, then there is an error

    movsd xmm0, qword[balloonWeight]
    movsd xmm1, qword[balloonDiameter]
    call balloonCalculations

    movsd qword[balloonsRequired], xmm0 ; Moves the returned value into address

    ; Adjusting the stack to be a multiple of 16
    mov rax, rsp
    mov rdx, 0
    mov rcx, 16
    div rcx
    sub rsp, rdx

    movsd xmm0, qword[balloonWeight]
    movsd xmm1, qword[balloonDiameter]
    movsd xmm2, qword[balloonsRequired]
    call printBalloonsRequired

    jmp endProgram

errorMessages:
    ; First check to see if there is only one command line argument
    cmp rax, 0
    jne secondErrorMessage
    mov rdi, errorSingleArgString
    call printString
    jmp endProgram

    ; Second check to see if there are not exactly 5 arguments
    secondErrorMessage:
    cmp rax, -1
    jne thirdErrorMessage
    mov rdi, errorNumArgString
    call printString
    jmp endProgram

    ; Third check to see if the command line argument 2 is not "-W"
    thirdErrorMessage:
    cmp rax, -2
    jne fourthErrorMesssage
    mov rdi, errorIncorrectWString
    call printString
    jmp endProgram

    ; Fourth check to see if the command line argument 4 is not "-D"
    fourthErrorMesssage:
    cmp rax, -4
    jne fifthErrorMessage
    mov rdi, errorIncorrectDString
    call printString
    jmp endProgram

    ; Fifth check to see if the double values are 0.0 or less
    fifthErrorMessage:
    cmp rax, -3
    jne endProgram
    mov rdi, errorInvalidString
    call printString


endProgram:
    mov rax, SYSTEM_EXIT
    mov rdi, SUCCESS
    syscall