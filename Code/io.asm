; Routines in this include file:
; ------------------------------
;	- PrintChar		[A ->]
;	- PrintString	[HL ->]
;	- PrintCRLF
;	- PrintNibble	[A ->]
;	- PrintByte		[A ->]
;	- PrintWord		[HL ->]
;	- ReadChar		[-> A]
;	- ReadString	[HL ->]
;	- ReadByte		[-> A]
;	- ReadWord		[-> HL]
;	- SIO_Init


;  ____           _           _     ____                
; |  _ \   _ __  (_)  _ __   | |_  |  _ \    ___    ___ 
; | |_) | | '__| | | | '_ \  | __| | | | |  / _ \  / __|
; |  __/  | |    | | | | | | | |_  | |_| | |  __/ | (__ 
; |_|     |_|    |_| |_| |_|  \__| |____/   \___|  \___|
;
;
; *********************************************************************************************************************
; Prints a hex number to Decimal on the console
;	- Input:	HL = 16-bit hex number
;	- Ouput:	HL = Untouched 16-bit hex number
; *********************************************************************************************************************

PrintDec:
	push	HL
	call	Hex2Dec
	call	PrintString
	pop		HL
	ret


;  ____           _           _     ____            _          
; |  _ \   _ __  (_)  _ __   | |_  | __ )   _   _  | |_    ___ 
; | |_) | | '__| | | | '_ \  | __| |  _ \  | | | | | __|  / _ \
; |  __/  | |    | | | | | | | |_  | |_) | | |_| | | |_  |  __/
; |_|     |_|    |_| |_| |_|  \__| |____/   \__, |  \__|  \___|
;                                           |___/              
;
; *********************************************************************************************************************
; Prints a byte to the console
;	- Input:	A (Byte to print)
; *********************************************************************************************************************

PrintByte:
	push	AF
	push	AF
	srl		A					; Push the uppermost nibble to the lower half
	srl		A
	srl		A
	srl		A
	call	PrintNibble			; Print the first nibble of the byte
	pop		AF
	call	PrintNibble			; Print the second nibble of the byte
	pop		AF
	ret


;  ____           _           _      ____   _                    
; |  _ \   _ __  (_)  _ __   | |_   / ___| | |__     __ _   _ __ 
; | |_) | | '__| | | | '_ \  | __| | |     | '_ \   / _` | | '__|
; |  __/  | |    | | | | | | | |_  | |___  | | | | | (_| | | |   
; |_|     |_|    |_| |_| |_|  \__|  \____| |_| |_|  \__,_| |_|   
;

; *********************************************************************************************************************
; Print a character to the console
;	- Input: A (Character to transmit)
; *********************************************************************************************************************

PrintChar:
	push	AF
PrintCharTxWait:
	in		A,(SIO_PortA_Ctrl)		; Read RR0 and place it in accumulator
	and		%00000100				; Isolate bit 2: TX Buffer Empty
	jr		z,PrintCharTxWait		; If it's busy, then wait
	pop		AF
	out		(SIO_PortA_Data),A		; Transmit the character in accumulator
	ret


;  ____           _           _      ____   ____    _       _____ 
; |  _ \   _ __  (_)  _ __   | |_   / ___| |  _ \  | |     |  ___|
; | |_) | | '__| | | | '_ \  | __| | |     | |_) | | |     | |_   
; |  __/  | |    | | | | | | | |_  | |___  |  _ <  | |___  |  _|  
; |_|     |_|    |_| |_| |_|  \__|  \____| |_| \_\ |_____| |_|    


; *********************************************************************************************************************
; Print a carriage-return and line-feed to serial port A
; *********************************************************************************************************************

PrintCRLF:
	push	AF
	ld		A,CR
	call	PrintChar				; Print carriage-return
	ld		A,LF
	call	PrintChar				; Print line-feed
	pop		AF
	ret


;  ____           _           _     _       _                
; |  _ \   _ __  (_)  _ __   | |_  | |     (_)  _ __     ___ 
; | |_) | | '__| | | | '_ \  | __| | |     | | | '_ \   / _ \
; |  __/  | |    | | | | | | | |_  | |___  | | | | | | |  __/
; |_|     |_|    |_| |_| |_|  \__| |_____| |_| |_| |_|  \___|


; *********************************************************************************************************************
; Prints a line (the size of HorizTextRes)
; *********************************************************************************************************************

PrintLine:
	push	AF
	push	BC
	ld		A,HorizTextRes			; Load the screen width constant
	ld		B,A						; Place it register B
	ld		A,"-"					; Load the dash character
PrintLineLoop:
	call	PrintChar				; Print the dash
	djnz	PrintLineLoop			; Decrement B, and loop until B is 0
	call	PrintCRLF				; Change line
	pop		BC
	pop		AF
	ret


;  ____           _           _     _   _   _   _       _       _        
; |  _ \   _ __  (_)  _ __   | |_  | \ | | (_) | |__   | |__   | |   ___ 
; | |_) | | '__| | | | '_ \  | __| |  \| | | | | '_ \  | '_ \  | |  / _ \
; |  __/  | |    | | | | | | | |_  | |\  | | | | |_) | | |_) | | | |  __/
; |_|     |_|    |_| |_| |_|  \__| |_| \_| |_| |_.__/  |_.__/  |_|  \___|


; *********************************************************************************************************************
; Prints a nibble to the console
;	- Input:	A (LSB to print)
; *********************************************************************************************************************

PrintNibble:
	push	AF
	and		$0F						; Filter out MSB
	add     "0"						; Add ASCII character 0
	cp      "9"+1					; Is the value numeric values?
	jr		c,PrintNibbleEnd		; Yes, then exit with 0 through 9
	add     "A"-"9"-1				; No, then exit with A through F
PrintNibbleEnd:
	call	PrintChar				; Print the nibble
	pop		AF
	ret
	
	
;  ____           _           _     ____    _            _                 
; |  _ \   _ __  (_)  _ __   | |_  / ___|  | |_   _ __  (_)  _ __     __ _ 
; | |_) | | '__| | | | '_ \  | __| \___ \  | __| | '__| | | | '_ \   / _` |
; |  __/  | |    | | | | | | | |_   ___) | | |_  | |    | | | | | | | (_| |
; |_|     |_|    |_| |_| |_|  \__| |____/   \__| |_|    |_| |_| |_|  \__, |
;                                                                    |___/ 
;
; *********************************************************************************************************************
; Prints a string to serial port A, until the null character is reached
;	- Input:	HL = Address pointer of string to transmit
;	- Output:	HL = Address pointer to the next character, past NULL (Practical for printing lines in between text)
; *********************************************************************************************************************

PrintString:
	push	AF
PrintStringLoop:
	ld		A,(HL)					; Load character to print in accumulator
	inc		HL						; Increment HL to next character to print
	cp		0					; Is it the end of the string?
	jr		z,PrintStringEnd		; Yes, then exit routine
	call	PrintChar				; Print the character
	jr		PrintStringLoop			; Repeat the loop until null character is reached
PrintStringEnd:
	pop		AF
	ret


;  ____           _           _    __        __                     _ 
; |  _ \   _ __  (_)  _ __   | |_  \ \      / /   ___    _ __    __| |
; | |_) | | '__| | | | '_ \  | __|  \ \ /\ / /   / _ \  | '__|  / _` |
; |  __/  | |    | | | | | | | |_    \ V  V /   | (_) | | |    | (_| |
; |_|     |_|    |_| |_| |_|  \__|    \_/\_/     \___/  |_|     \__,_|


; *********************************************************************************************************************
; Prints a 16-bit word (double-byte) to the console
;	- Input: HL (Word to print)
; *********************************************************************************************************************

PrintWord:
	push	AF
	ld		A,H						; Get the first byte in accumulator
	call	PrintByte				; Print first byte
	ld		A,L						; Get the second byte in accumulator
	call	PrintByte				; Print second byte
	pop		AF
	ret


;  ____                       _    ____   _                    
; |  _ \    ___    __ _    __| |  / ___| | |__     __ _   _ __ 
; | |_) |  / _ \  / _` |  / _` | | |     | '_ \   / _` | | '__|
; |  _ <  |  __/ | (_| | | (_| | | |___  | | | | | (_| | | |   
; |_| \_\  \___|  \__,_|  \__,_|  \____| |_| |_|  \__,_| |_|   


; *********************************************************************************************************************
; Read a character from the console (waiting)
;	- Output:	Character received in A
; *********************************************************************************************************************

ReadChar:
	in		A,(SIO_PortA_Ctrl)		; Read RR0 and place it in the accumulator
	and		%00000001				; Isolate bit 1: RX Character Available
	jr		z,ReadChar				; If there's no character in buffer, loop until one is present
	in		A,(SIO_PortA_Data)		; Read the character and place it in the accumulator
	ret


;  ____                       _    ____   _                      _   _          __        __          _   _   
; |  _ \    ___    __ _    __| |  / ___| | |__     __ _   _ __  | \ | |   ___   \ \      / /   __ _  (_) | |_ 
; | |_) |  / _ \  / _` |  / _` | | |     | '_ \   / _` | | '__| |  \| |  / _ \   \ \ /\ / /   / _` | | | | __|
; |  _ <  |  __/ | (_| | | (_| | | |___  | | | | | (_| | | |    | |\  | | (_) |   \ V  V /   | (_| | | | | |_ 
; |_| \_\  \___|  \__,_|  \__,_|  \____| |_| |_|  \__,_| |_|    |_| \_|  \___/     \_/\_/     \__,_| |_|  \__|
;
;
; *********************************************************************************************************************
; Read a character from the console if present (non-waiting)
;	- Output:	Character in A if received.
;				A = 0 if no character received.
;				Z = not ready, NZ = has character
; *********************************************************************************************************************

ReadCharNoWait:
	in		A,(SIO_PortA_Ctrl)		; Read RR0 and place it in the accumulator
	and		%00000001				; Isolate bit 1: RX Character Available
	ld		A,$00					; Put nothing in A
	ret		z						; Return if not ready
	in		A,(SIO_PortA_Data)		; Read the character and place it in the accumulator
	or		A						; Resets the carry flag (and zero)
	ret


;  ____                       _   ____            _          
; |  _ \    ___    __ _    __| | | __ )   _   _  | |_    ___ 
; | |_) |  / _ \  / _` |  / _` | |  _ \  | | | | | __|  / _ \
; |  _ <  |  __/ | (_| | | (_| | | |_) | | |_| | | |_  |  __/
; |_| \_\  \___|  \__,_|  \__,_| |____/   \__, |  \__|  \___|
;                                         |___/              
;
; *********************************************************************************************************************
; Read a byte (2 ASCII Hex characters) from the console (waiting)
;	- Output: Byte received in A
; *********************************************************************************************************************

ReadByte:
	push	HL
	ld		HL,DigitString			; Point to staging area to convert ASCII Characters to a byte
	call	ReadChar				; Read first character
	ld		(HL),A					; Store it
	inc		HL						; Point to the next cell
	call	ReadChar				; Read second character
	ld		(HL),A					; Store it
	dec		HL						; Point back to the beginning
	call	Ascii2HexByte
	pop		HL
	ret


;  ____                       _   ____    _            _                 
; |  _ \    ___    __ _    __| | / ___|  | |_   _ __  (_)  _ __     __ _ 
; | |_) |  / _ \  / _` |  / _` | \___ \  | __| | '__| | | | '_ \   / _` |
; |  _ <  |  __/ | (_| | | (_| |  ___) | | |_  | |    | | | | | | | (_| |
; |_| \_\  \___|  \__,_|  \__,_| |____/   \__| |_|    |_| |_| |_|  \__, |
;                                                                  |___/ 

; *********************************************************************************************************************
; Read a string from console
;	- Input:	HL = Points to the memory area to store string
;				B = Bytes to count
;	- Output:	HL = Points to the start of string
; *********************************************************************************************************************

ReadString:
	push	AF
	push	BC
	push	DE
	push	HL						; Store the start position

	ld		C,0						; Character counter initialized to zero
	push	HL						; Save HL's start position...
	pop		DE						; in DE for later use
;	ld		HL,CommandBuffer		; Load CommandBuffer location in HL

; READ A CHARACTER AND VALIDATE
ReadStringChar:	
	call	ReadChar				; Read a character from console
	cp		BKSP					; Is it the backspace?
	jr		z,ReadStringBS			; If it is, then erase last character
	cp		ESC						; Is it the escape key?
	jr		z,ReadStringESC			; If it is, then ignore whatever has been entered
	cp		CR						; Is it the carriage return?
	jr		z,ReadStringCR			; If it is, then end the routine
	cp		$80						; Is it a character above or equal to the ASCII value $80?
	jr		nc,ReadStringChar		; Loop to get a valid ASCII character
	cp		$20						; Is it any other non-printable character?
	jr		c,ReadStringChar		; Loop to get a valid ASCII character

; STORE THE CHARACTER IN THE BUFFER
ReadStringSave:
	call	PrintChar				; Echo typed character on screen
;	call	UpperCase				; *** (Optional) *****************************
	ld		(HL),A					; Store character in memory
	inc		HL						; Increment buffer to next spot
	inc		C						; Increment bytes counter
	ld		A,B						; Load total bytes to read in accumulator
	cp		C						; Has the total number of characters been read?
	jr		c,ReadStringBS			; If it was one too many characters, backspace
	jr		ReadStringChar			; Else, loop to get the next character

ReadStringBS:
	ld		A,C						; Load characther counter in accumulator
	cp		0						; Are there any characters to erase?
	jp		z,ReadStringChar		; No, then go read another character
	dec		C						; Else, decrement character counter by one
	dec		HL						; And decrement buffer to previous spot
	ld		A,BKSP					; Erace character on screen...
	call	PrintChar				; Go back one previous character
	ld		A," "					;
	call	PrintChar				; Overwrite the character with a space
	ld		A,BKSP					;
	call	PrintChar				; Then go back one character again
	jr		ReadStringChar			; Get the next character
	
ReadStringESC:
	ex		DE,HL					; Restore start position of HL
;	ld		HL,CommandBuffer		; Point CommandBuffer to start

ReadStringCR:
	ld		(HL),0					; Write NULL character in buffer to indicate end of string
	call	PrintCRLF				; Change line
	
	pop		HL						; Points to the start of the string
	pop		DE
	pop		BC
	pop		AF
	ret


;  ____                       _  __        __                     _ 
; |  _ \    ___    __ _    __| | \ \      / /   ___    _ __    __| |
; | |_) |  / _ \  / _` |  / _` |  \ \ /\ / /   / _ \  | '__|  / _` |
; |  _ <  |  __/ | (_| | | (_| |   \ V  V /   | (_) | | |    | (_| |
; |_| \_\  \___|  \__,_|  \__,_|    \_/\_/     \___/  |_|     \__,_|


; *********************************************************************************************************************
; Read a word (4 ASCII Hex characters) from the console (waiting)
;	- Output: Word received in HL
; *********************************************************************************************************************

ReadWord:
	push	AF
	call	ReadByte			; Read first byte (first and second ASCII character)
	ld		H,A					; Store the MSB
	call	ReadByte			; Read second byte (third and fourth ASCII character)
	ld		L,A					; Store the LSB
	call	Ascii2HexWord		; Convert the ASCII characters to a word, result in BC
	pop		AF
	ret

	
;  ____    ___    ___            ___           _   _   
; / ___|  |_ _|  / _ \          |_ _|  _ __   (_) | |_ 
; \___ \   | |  | | | |          | |  | '_ \  | | | __|
;  ___) |  | |  | |_| |          | |  | | | | | | | |_ 
; |____/  |___|  \___/   _____  |___| |_| |_| |_|  \__|
;                       |_____|                        

; *********************************************************************************************************************
; Initializes SIO port A
;   - Destroys: AF, HL, BC (There's usually no need to save registers in the init stage)
; *********************************************************************************************************************

SIO_Init:
	ld		A,%00011000				; Perform channel reset
	out		(SIO_PortA_Ctrl),A		; Requires four extra clock cycles for the SIO reset time
	nop
	ld		A,%00000100				; WR0: select register 4
	out		(SIO_PortA_Ctrl),A
	ld		A,%01000100				; WR4: 1/16 (115200 @ 1.8432MHZ), 8-bit sync, 1 stop bit, no parity
	out		(SIO_PortA_Ctrl),A
	ld		A,%00000011				; WR0: select register 3
	out		(SIO_PortA_Ctrl),A
	ld		A,%11000001				; WR3: 8-bits/char, RX enabled
	out		(SIO_PortA_Ctrl),A
	ld		A,%00000101				; WR0: select register 5
	out		(SIO_PortA_Ctrl),A
	ld		A,%01101000				; WR5: DTR=0, 8-bits/char, TX enabled
	out		(SIO_PortA_Ctrl),A
	ret
