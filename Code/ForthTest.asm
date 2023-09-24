; Jump Table
Ascii2HexNibble = $FE00				; [A -> A][A -> A]
Ascii2HexByte	= $FE03				; [(HL) -> A][(HL) -> A]
Ascii2HexWord	= $FE06				; [(HL) -> BC][(HL) -> BC]
ClearScreen		= $FE09				; [][]
GetHexParameter	= $FE0C				; [(HL) -> BC,A,(HL)][(HL) -> BC,A,(HL)]
PrintChar		= $FE0F				; [A ->][A ->]
PrintString		= $FE12				; [HL ->][HL ->]
PrintCRLF		= $FE15				; [][]
PrintNibble		= $FE18				; [A ->][A ->]
PrintByte		= $FE1B				; [A ->][A ->]
PrintWord		= $FE1E				; [HL ->][HL ->]
RangeValidation	= $FE21				; Start&EndAddress -> C, Start&EndAddress, Start&EndAddressAlt)
ReadChar		= $FE24				; [-> A][-> A]
ReadCharNoWait	= $FE27
ReadString		= $FE2A				; [HL ->][HL ->]
ReadByte		= $FE2D				; [-> A][-> A]
ReadWord		= $FE30				; [-> HL][-> HL]
SkipSpaces		= $FE33				; [HL -> HL][HL -> HL]
UpperCase		= $FE36				; [A -> A][A -> A]
Registers		= $FE39				; [][]
Dec2Hex			= $FE3C				; [(HL) -> BC]	

; Return Stack (assuming stack starts at memory address 0x8000)
ReturnStack		equ		$8000
RetStkPtr		equ		ReturnStack		; Forth Return Stack Pointer

; Data stack (assuming stack starts at memory address 0x7F00)
DataStack		equ		$7F00			; Data Stack
DatStkPtr		equ		DataStack		; Data Stack Pointer
	
ParsedWord:		equ		$7800			; Memory location to store parsed word
InputWord: 		equ 	ParsedWord		; Assuming a word has already been parsed
FoundWordAddr	equ		$7900			; Adjust this address as neeed




Fr80Forth:
	; Initialize the data stack and return stack
	ld		HL,DataStack
	ld		(DatStkPtr),HL
	ld		HL,ReturnStack
	ld		(RetStkPtr),HL

ForthMainLoop:
	call	GetWord				; Get the next word from input
	call	FindWord			; Find the word in the dictionary
	call	ExecuteWordFound	; Execute the word
	jr		ForthMainLoop


; Function to get the next word from input
; ----------------------------------------

GetWord:
	LD		HL,ParsedWord		; Destination memory location for the parsed word
	LD		DE,0				; Clear DE register to accumulate characters
GetWordLoop:
	call	ReadChar			; Read a character from serial from console
	cp		SPACE				; Check if the character is a space delimiter
	jp		z,GetWordEnd		; If it's a space, end GetWord

	; Store the character in memory
	ld		(HL),A
	inc		HL					; Move to the next memory location
	inc		DE					; Increment the character count

	; Check for end of input or word length limit
	; Adjust the word length limit as needed
	CP		CR					; Check for end of input
	jp		z,GetWordEnd		; If it's a carriage return, end GetWord
	ld		A,DE				;`
	cp		31					; Limit word length (adjust as needed)
	jp		z,GetWordEnd
	jr		GetWordLoop			; Read the next character

GetWordEnd:
	ld		(HL),0				; Null-terminate the parsed word
	ret

	
; Input word to find
; ------------------

FindWord:
	ld		HL,ForthDictionary	; Start of the dictionary

FindWordLoop:
	ld		DE,(HL)				; Load the address of the word name
	inc		HL					; Move to the next entry
	ld		BC,(HL)				; Load the length of the word
	inc		HL					; Move to the next entry 
	
	; Compare the input word with the dictionary word
	ld		A,(InputWord)
	ld		IY,ForthDictionary+4; Offset of the name in an entry
	call	StringCompare		; Compare the strings (see below)
	cp		0					; If the word is found ...
	jr		z,WordFound			; ... load its execution address
	
	; Check for the end of the dictionary
	ld		A,C
	OR B
	cp		#EOT
	jp		z,WordNotFound

	add		HL,BC				; Move to the next dictionary entry
	jr		FindWordLoop


; Address where the execution address of the found word will be stored
; --------------------------------------------------------------------
; Execution address is in DE

WordFound:
	ld		(FoundWordAddr),DE	; Store the execution address in memory for execution
	call	ExecuteWordFound	; Execute the found word
	ret


; Function to execute the found word
; ----------------------------------

ExecuteFoundWord:
    ; Load the execution address of the found word
	ld		DE,(FoundWordExecAddr)

    ; Perform the word's execution based on the address in DE
    ; Implement the behavior of the found word here
    ; You'll need to set up a proper execution mechanism based on your Forth interpreter's design

	call	DE
	
	ret


WordNotFound:
	; The word is not found in the dictionary
	; Handle the error or return accordingly
	push	HL
	ld		HL,WordNotFoundMsg
	call	PrintString
	pop		HL
	ret


; Function to compare two null-terminated strings
; DE: Pointer to the first string
; IY: Pointer to the second string
; Returns: Z flag set if the strings match
StringCompare:
	ld		A,(DE)
	ld		B,(IY)
	cp		A,B				; Compare characters from both strings
	ret		nz				; Return if characters do not match
	cp		A,0				; Check if we've reached the end of both strings
	jp		Z, StringCompareEnd
	inc		DE
	inc		IY
	jr		StringCompare
StringCompareEnd:
	ret		z					; Strings match, return with Z flag set


; Function to execute a word
EXECUTE:
	; Execute the word based on the execution address
	RET

; Function to print the data stack (for debugging)
PRINT_STACK:
	; Your code to print the data stack goes here
	RET

; Core Forth words

DUP:
	; Duplicate the top item on the stack
	; Your code goes here
	RET

SWAP:
	; Swap the top two items on the stack
	; Your code goes here
	RET

OVER:
	; Copy the second item on the stack to the top
	; Your code goes here
	RET

DROP:
	; Remove the top item from the stack
	; Your code goes here
	RET





INTERPRET:
	LD A, (HL)		  ; Load the next Forth token
	CP 0xFF			 ; Check if it's the end of the program
	JP Z, DONE		  ; If it is, exit
	CALL EXECUTE		; Execute the Forth word
	INC HL			  ; Move to the next token
	JR INTERPRET		; Continue interpreting

; Forth Word Execution
EXECUTE:
	PUSH AF			 ; Save the current flags
	LD A, (HL)		  ; Load the next Forth word
	CP DUP			  ; Check for DUP word (for example)
	JR Z, DO_DUP		; If it's DUP, execute DUP word
	; Implement other Forth word execution logic here
	; Add more word comparisons and execution routines
	POP AF			  ; Restore the flags
	RET

DO_DUP:
	CALL FW_DUP			; Execute DUP word
	RET


; Forth Words
; -----------

FW_DUP:
	LD HL, (SP)		 ; Load the top item from the stack
	PUSH HL			 ; Duplicate it on the stack
	RET

FW_DROP:
	POP DE			  ; Remove the top item from the stack
	RET

FW_SWAP:
	LD HL, (SP)		 ; Load the top item from the stack
	LD (SP), DE		 ; Replace it with the second item
	LD DE, HL		   ; Put the top item in DE
	PUSH DE			 ; Push it back onto the stack
	RET

FW_OVER:
	LD HL, (SP)		 ; Load the top item from the stack
	LD DE, (SP + 2)	 ; Load the second item from the stack
	PUSH HL			 ; Push the top item back onto the stack
	PUSH DE			 ; Push the second item back onto the stack
	RET

; 16-bit PUSH
FW_PUSH:
	LD HL, (SP)	  ; Load current stack pointer
	ADD HL, 2		; Move stack pointer 2 bytes up (for next item)
	LD (SP), HL	  ; Update stack pointer
	LD (HL), DE	  ; Store the 16-bit value on the stack
	RET

; 16-bit POP
FW_POP:
	LD HL, (SP)	  ; Load current stack pointer
	LD DE, (HL)	  ; Load the 16-bit value from the stack
	ADD HL, 2		; Move stack pointer 2 bytes down
	LD (SP), HL	  ; Update stack pointer
	RET

; Math Operations
FW_ADD:
	POP DE
	POP HL
	ADD HL, DE
	PUSH HL
	RET

FW_SUB:
	POP DE
	POP HL
	SUB HL, DE
	PUSH HL
	RET

FW_MULTIPLY:
	POP DE
	POP HL
	LD BC, HL
	LD HL, DE
	CALL FW_MULT
	PUSH HL
	RET

FW_MULT:
	PUSH DE
	PUSH HL
	XOR A
	LD C, A
	ADD HL, BC
	JR NC, FW_NOOVERFLOW
	INC C
FW_NOOVERFLOW:
	POP HL
	POP DE
	RET

FW_DIV:
	POP DE
	POP HL
	XOR A
	LD C, A
	DIV HL, DE
	PUSH HL
	RET

FW_MOD:
	POP DE
	POP HL
	XOR A
	LD C, A
	DIV HL, DE
	LD L, A
	PUSH HL
	RET

; Comparison
FW_EQUAL:
	POP DE
	POP HL
	XOR A
	CP HL, DE
	LD HL, 0x0000
	JR NZ, FW_NOT_EQUAL
	LD HL, 0xFFFF
FW_NOT_EQUAL:
	PUSH HL
	RET

FW_LESS_THAN:
	POP DE
	POP HL
	XOR A
	CP HL, DE
	LD HL, 0x0000
	JR C, FW_LESS
	LD HL, 0xFFFF
FW_LESS:
	PUSH HL
	RET

FW_GREATER_THAN:
	POP DE
	POP HL
	XOR A
	CP HL, DE
	LD HL, 0x0000
	JR NC, FW_GREATER
	LD HL, 0xFFFF
FW_GREATER:
	PUSH HL
	RET

; I/O
FW_EMIT:
	pop		DE
	ld		A,E
	call	PrintChar				; System's print character (io.asm)
	push	DE
	ret

; List Forth Words
FW_WORDS:
	ld		HL,Forth_Dictionary	; Load the address of the word list into HL
FW_WORDS_LOOP:
	call	PrintString			; Print the word at the address in HL
	ld		A, ","				; Print a carriage return to separate words
	call	PrintChar
	inc		HL					; Move to the next word in the list
	inc		HL
	ld		A,(HL)				; Load the next byte
	cp		$FF					; Check if it's null (end of the list)
	jr		z,FW_WORDS_DONE		; If it's null, we're done
	ld		A," "				; Print a space to separate words
	call	PrintChar
	jr		FW_WORDS_LOOP		; Repeat the loop
FW_WORDS_DONE:
	ret
	
FW_DONE:
	ret

; Dictionary Entry Structure
; --------------------------
; Each dictionary entry consists of a name (a string of characters)
; and a pointer to the corresponding word's subroutine.

; Example Dictionary Entries
; DB "WORD1", 0 ; Null-terminated name of the word
; DW WORD1_SUBROUTINE ; Pointer to the subroutine

ForthDictionary:
	DB	FW_ADD,		3, "ADD", 0
	DB	FW_DIV,		3, "DIV", 0
	DB	FW_DONE,	4, "DONE", 0
	DB	DROP,		4, "DROP", 0
	DB	FW_DUP,		3, "DUP", 0
	DB	FW_EMIT,	4, "EMIT", 0
	DB	FW_EQUAL,	2, "EQ", 0
	DB	FW_GREATER_THAN,2, "GT", 0
	DB	FW_LESS_THAN,	2, "LT", 0
	DB	FW_MOD,		3, "MOD", 0
	DB	FW_MULT,	4, "MULT", 0
	DB	FW_OVER,	4, "OVER", 0
	DB	FW_POP,		3, "POP", 0
	DB	FW_PUSH,	4, "PUSH", 0
	DB	FW_SUB,		3, "SUB", 0
	DB	FW_SWAP,	4, "SWAP", 0
	DB	DW_WORDS,	5, "WORDS", 0
	DB EOT

WordNotFoundMsg:
	DB	"Word not found!",0