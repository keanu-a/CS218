;	Keanu Aloua
;	CS 218 - Section 1002
;	Last Modified October 30, 2021
;	Assignment #6: This program will involve using the buffered I/O algorithm to efficiently analyze a large text file.

section .data
;   System service constants
    SYSTEM_READ equ 0
    STANDARD_IN equ 0
    SYSTEM_WRITE equ 1
    STANDARD_OUT equ 1
    SUCCESS equ 0
    SYSTEM_EXIT equ 60

;   File I/O Constants
    SYSTEM_OPEN equ 2
    SYSTEM_CLOSE equ 3
    READ_ONLY equ 000000q
    fileDescriptor dq 0 ; Not a constant, but for File I/O

;   String Constants
    LINEFEED equ 10
    NULL equ 0

;   Variable Strings
    echoArgString db "-echo", NULL
    errorOneArgString db "To use this program include the name of the file you wish to analyze.", LINEFEED, NULL
    errorOneArgContString db "-echo may be added to print the file to the terminal.", LINEFEED, NULL
    errorThirdArgString db "Invalid argument.", LINEFEED, NULL
    errorMoreArgString db "Incorrect number of arguments.", LINEFEED, NULL
    errorFileOpenString db "Could not open ", 34, NULL ; 34 is ASCII for quotation mark ""
    errorFileOpenString2 db 34, 46, LINEFEED, NULL ; 46 is ASCII for a period .
    errorReadingFile db "There was an error reading from the file.", LINEFEED, NULL

    echoUsedHeader db "File Text:", LINEFEED, NULL
    oneSpaceString db LINEFEED, NULL
    twoSpaceString db LINEFEED, LINEFEED, NULL

    labelWordCountString db "Word Count: ", NULL
    labelAverageWordString db "Average Word Length: ", NULL

    successString db "Success.", NULL

;   Variable Names
    wordAmount dd 0
    averageWordLength dd 0
    wordAmountString db 0
    averageWordLengthString db 0
    echoUsed dq 0 ; Bool for if "-echo" was typed or not
    letterBefore dd 0 ; Bool for if the current character is NOT a space
    letterCount dd 0 

;   Buffed I/O Constant
    BUFFER_SIZE equ 100000

;   Buffered I/O Variables
    charactersBuffered dq 0
    charactersRead dq 0
    endOfFileReached dq 0 ; Bool for if characters read is less than the BUFFER_SIZE
    bufferChar db 0 ; Stores the character read from readBuffer

section .bss
    readBuffer resb 100000

section .text

;	Converts a signed 32 bit integer to a null terminated string representation
;	Argument 1: 32 bit integer
;	Argument 2: Address to a string (20 characters maximum)
%macro int32ToString 2

	mov rcx, 0 ; Sets the index
	mov rbx, -1 ; Sets the multiplier for when the integer is negative
	mov r10, 0 ; Sets the character count
    mov r8, 0 ; Clears divisor reg
	mov r8d, 10 ; Sets the divisor

	mov eax, %1
	
    ; The integer value is in eax
    %%positiveInteger
    mov rdx, 0 ; Clears the remainder
    div r8d ; Divides the integer by 10
    push rdx ; Pushes the remainder to the stack
    inc r10 ; Increases character count
    cmp eax, 0 ; If the quotient is 0, then the calculation is over
    jne %%positiveInteger

	%%createStringLoop:
		pop r8
		add r8b, 48 ; Converts integer to character
		mov byte[%2 + rcx], r8b
		inc rcx
		cmp rcx, r10 ; Compares the index to the character count
		jne %%createStringLoop

	mov byte[%2 + 20], NULL ; Adds the NULL character to the end of the string
	; Added 12 because 12 characters maximum

%endmacro

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

    push r13
    push r12

    ; Saving the value of rdi and rsi
    mov r12, rdi ; argc
    mov r13, rsi ; argv

    startCheck:
        cmp r12, 2 ; Checking if there is only one command line argument
        jge checkSecondArg
        mov rax, 0 ; Returns 0 when a single command line argument was used
        jmp endCheck

    checkSecondArg:
        ; Checking if the file in 2nd command line argument can be opened
        mov rax, SYSTEM_OPEN
        mov rdi, [r13 + 8] ; Uses second command line argument for file
        mov rsi, READ_ONLY 
        syscall 
        mov qword[fileDescriptor], rax ; Stores file descriptor

        cmp rax, 0 ; Checks if rax is negative, meaning there is an error

        ; Printing the string that file can not be opened
        jge fileIsOpened
        mov rdi, errorFileOpenString
        call printString
        mov rdi, [r13 + 8]
        call printString
        mov rdi, errorFileOpenString2
        call printString

        mov rax, -3 ; Returns -3 if the file can not be opened
        jmp endCheck

        fileIsOpened:
        cmp r12, 2 ; Checks if there are two command line arguments
        jg checkThirdArg ; If there are two, then it will check if there is a third
        jmp checkPassed

    checkThirdArg:
        mov rdi, qword[r13 + 16] ; Checks if the third command line argument is "-echo"
        mov rsi, echoArgString
        call compareStrings ; Checking for "-echo", NULL
        cmp rax, 0 ; Checks if the strings are equal
        je checkMoreArgs ; If they are equal then check if there are more than three command line arguments

        mov rax, -1 ; If not equal, then returns -1 when the third command line argument is not "-echo"
        jmp endCheck

    checkMoreArgs:
        mov qword[echoUsed], 1 ; Flag for when echo is used

        cmp r12, 4 ; Checks if there are more than three command line arguments
        jl checkPassed
        mov rax, -2
        jmp endCheck

    checkPassed:
        mov rax, 1 ; If all the checks have passed

    endCheck:
    pop r12
    pop r13

    ret ; Will either return a -3 if file can't be opened. Returns -2, -1, or 0 for errors. Will return a 1 if there are no errors.

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR FINDING WORD COUNT AND AVERAGE
;-------------------------------------------------------------------------------------------
global getWordCountAndAverage
getWordCountAndAverage:
;   rdi has wordAmount by reference
;   rsi has averageWordLength by reference

    push r15
    push r13
    push r12

    mov r12, rdi ; wordAmount
    mov r13, rsi ; averageWordLength

    loopGetCharacter:
        mov rdi, bufferChar
        mov r15, rdi ; To make sure the address for bufferChar doesn't change
        call getCharacter

        cmp rax, -1
        jg checkValue ; If -1, then error reading file
        jmp endFunction

        checkValue:
        cmp rax, 1 ; 1 if char was obtained
        jne noCharsToRead

        ; Check to see if bufferChar is a white space
        ; dword[letterBefore] starts at 0, meaning no character before the space
            checkSpace:
            cmp byte[r15], 0x20 ; 32 is ASCII for space
            ja checkForLetter
            cmp dword[letterBefore], 1 ; Checks if there is a letter before this space
            je increaseWordCount ; If there was, then increase word count
            jmp loopGetCharacter

            ; Check to see if bufferChar is between A-Z or a-z
            checkForLetter:
            cmp byte[r15], 0x41 ; Comparing char to A
            jae checkZ
            mov dword[letterBefore], 1 ; If the character is ! - @, its considered for word count
            jmp loopGetCharacter

            checkZ:
            cmp byte[r15], 0x5A ; Comparing char to Z
            jbe increaseLetterCount

            checkLowerA:
            cmp byte[r15], 0x61 ; Comparing char to a
            jae checkLowerZ
            mov dword[letterBefore], 1 ; If the character is [ - ', its considered for word count
            jmp loopGetCharacter

            checkLowerZ:
            cmp byte[r15], 0x7A ; Comparing char to z
            jbe increaseLetterCount
            mov dword[letterBefore], 1 ; If the character is { - [DEL], its considered for word count
            jmp loopGetCharacter

            increaseLetterCount:
            mov dword[letterBefore], 1 ; BOOL 1 to mark the previous character is a letter
            inc dword[letterCount] ; Increases counter for letters
            jmp loopGetCharacter

            increaseWordCount:
            mov dword[letterBefore], 0 ; BOOL 0 to mark the previous character is a space
            inc dword[r12]
            jmp loopGetCharacter

        noCharsToRead:
        cmp rax, 0 ; 0 If there are no more characters to read
        jne loopGetCharacter

    fileReadDone:

    mov rdx, 0
    mov r11, 0
    mov eax, dword[letterCount]
    mov r11d, dword[r12]
    div r11d ; wordCount / letterCount
    mov dword[r13], eax ; Average word length stored in address

    endFunction:

    pop r12
    pop r13
    pop r15

    ret

;-------------------------------------------------------------------------------------------
;   FUNCTION FOR GETTING EACH CHARACTER
;-------------------------------------------------------------------------------------------
global getCharacter
getCharacter:

    push r14
    push r13
    push r12

    checkCharactersRead:
    mov r12, qword[charactersRead]
    cmp r12, qword[charactersBuffered]
    jg continueCheck ; Checks if charactersRead < charactersBuffered
    mov r14b, byte[readBuffer + r12]
    mov byte[r15], r14b ; bufferChar = buffer[charactersRead]
    inc qword[charactersRead] ; charactersRead++
    mov rax, 1 ; Returns 1 if character retrieved is successful
    jmp endRead

    continueCheck:
        cmp qword[endOfFileReached], 1
        jne readFile
        mov rax, 0 ; Returns 0 if there are no more characters to read
        jmp endRead

        readFile:
        ; File Read System Service Call
        mov rax, SYSTEM_READ
        mov rdi, qword[fileDescriptor]
        mov rsi, readBuffer
        mov rdx, BUFFER_SIZE
        syscall 

        cmp rax, 0 ; Checks if rax is negative, meaning there is an error
        jl readError

        ; rax will have number of characters read
        mov r13, rax ; Preserves rax in case echo is used

        ; Check if echo is used, if it was used, then will print to console
        cmp qword[echoUsed], 1 ; Checks bool for echo
        jne continueRead

        ; Since echo was used, will write to console
        mov rax, SYSTEM_WRITE
        mov rdi, STANDARD_OUT
        mov rsi, readBuffer
        mov rdx, BUFFER_SIZE
        syscall
        ; End printing to the console

        continueRead:
            cmp rdx, r13 ; If r13 < BUFFER_SIZE (rax), then end of file has been reached
            jle needLoop
            mov qword[endOfFileReached], 1 ; Bool for if the end of file has been reached
            mov r8, qword[endOfFileReached]

        needLoop:
            mov qword[charactersBuffered], r13 ; Number of chars read
            mov qword[charactersRead], 0
            jmp checkCharactersRead

    readError:
    mov rax, -1

    endRead:
    pop r12
    pop r13
    pop r14

    ret

;-------------------------------------------------------------------------------------------
;   PROGRAM START
;-------------------------------------------------------------------------------------------
global main
main:
    ; rdi has argc
    ; rsi has argv

    call checkCommandLineArgs
    cmp rax, 1
    jl argumentErrorMessages ; If rax is less than 1, then there was an error

    cmp qword[echoUsed], 1 ; BOOL Checks if -echo was typed
    jne fileReady
    mov rdi, echoUsedHeader ; Outputs "File Text: ", LINEFEED, NULL
    call printString

    fileReady:
    mov rdi, wordAmount
    mov rsi, averageWordLength
    call getWordCountAndAverage
    cmp rax, -1 ; If there was an error reading the file, then program ends
    je errorRead

    mov r12d, dword[averageWordLengthString] ; Preserving this value

    ; *** Start Output Word Count and Average Word Length to Console ***
    startOutput:
    mov rdi, twoSpaceString             ; LINEFEED, LINEFEED
    call printString
    mov rdi, labelWordCountString       ; "Word Count: "
    call printString

    int32ToString dword[wordAmount], wordAmountString

    mov rdi, wordAmountString           ; Word Amount
    call printString
    mov rdi, oneSpaceString             ; LINEFEED, NULL
    call printString
    mov rdi, labelAverageWordString     ; "Average Word Length: "
    call printString

    mov dword[averageWordLengthString], r12d ; Moving the preserved value back into variable in case it has been changed
    int32ToString dword[averageWordLength], averageWordLengthString

    mov rdi, averageWordLengthString    ; Average Word Length Amount
    call printString
    mov rdi, oneSpaceString             ; LINEFEED, NULL
    call printString

    ; *** End Output to Console ***

    ; File close
    mov rax, SYSTEM_CLOSE
    mov rdi, qword[fileDescriptor]
    syscall

    jmp endProgram

    errorRead:
    mov rdi, errorReadingFile
    call printString
    jmp endProgram

    argumentErrorMessages:
        cmp rax, 0
        jne secondError
        mov rdi, errorOneArgString
        call printString
        mov rdi, errorOneArgContString
        call printString
        jmp endProgram

        secondError:
        cmp rax, -1
        jne thirdError
        mov rdi, errorThirdArgString
        call printString
        jmp endProgram

        thirdError:
        cmp rax, -2
        jne endProgram
        mov rdi, errorMoreArgString
        call printString
        jmp endProgram

endProgram:
    mov rax, SYSTEM_EXIT
    mov rdi, SUCCESS
    syscall