; Ancillary monitor routines in this include file:
; ------------------------------------------------
;	- CommandPrompt					; {}
;	- GetHexParameter				; [(HL) -> BC,A,(HL)]
;	- Parse							; (HL)
;	- SkipSpaces					; [HL -> HL]


;   ____                                                       _   ____                                       _   
;  / ___|   ___    _ __ ___    _ __ ___     __ _   _ __     __| | |  _ \   _ __    ___    _ __ ___    _ __   | |_ 
; | |      / _ \  | '_ ` _ \  | '_ ` _ \   / _` | | '_ \   / _` | | |_) | | '__|  / _ \  | '_ ` _ \  | '_ \  | __|
; | |___  | (_) | | | | | | | | | | | | | | (_| | | | | | | (_| | |  __/  | |    | (_) | | | | | | | | |_) | | |_ 
;  \____|  \___/  |_| |_| |_| |_| |_| |_|  \__,_| |_| |_|  \__,_| |_|     |_|     \___/  |_| |_| |_| | .__/   \__|
;                                                                                                    |_|          

; *********************************************************************************************************************
; Prints the prompt to console
; *********************************************************************************************************************

CommandPrompt:
	push	AF
	push	HL
	ld		A,(CurrentBank)			; Get Current Bank number
	call	PrintByte				; Print it
	ld		A,":"					; 
	call	PrintChar				; Print colon symbol
	ld		HL,(CurrentAddress)
	call	PrintWord				; Print current address poointer
	ld		A,">"					; 
	call	PrintChar				; Print prompt symbol
	ld		A," "					; 
	call	PrintChar				; Print a space
	pop		HL
	pop		AF
	ret


;  ____                  _____                                ____            _           _                 
; |  _ \    ___    ___  | ____|  _ __   _ __    ___    _ __  |  _ \    ___   (_)  _ __   | |_    ___   _ __ 
; | | | |  / _ \  / __| |  _|   | '__| | '__|  / _ \  | '__| | |_) |  / _ \  | | | '_ \  | __|  / _ \ | '__|
; | |_| | |  __/ | (__  | |___  | |    | |    | (_) | | |    |  __/  | (_) | | | | | | | | |_  |  __/ | |   
; |____/   \___|  \___| |_____| |_|    |_|     \___/  |_|    |_|      \___/  |_| |_| |_|  \__|  \___| |_|   
;
;
; *********************************************************************************************************************
; Decrement error pointer by one
; *********************************************************************************************************************

DecErrorPointer:
	push	AF
	ld		A,(CmdErrorPointer)
	dec		A
	ld		(CmdErrorPointer),A
	pop		AF
	ret


;   ____          _     _   _                 ____                                              _                 
;  / ___|   ___  | |_  | | | |   ___  __  __ |  _ \    __ _   _ __    __ _   _ __ ___     ___  | |_    ___   _ __ 
; | |  _   / _ \ | __| | |_| |  / _ \ \ \/ / | |_) |  / _` | | '__|  / _` | | '_ ` _ \   / _ \ | __|  / _ \ | '__|
; | |_| | |  __/ | |_  |  _  | |  __/  >  <  |  __/  | (_| | | |    | (_| | | | | | | | |  __/ | |_  |  __/ | |   
;  \____|  \___|  \__| |_| |_|  \___| /_/\_\ |_|      \__,_| |_|     \__,_| |_| |_| |_|  \___|  \__|  \___| |_|   
;
;
; *********************************************************************************************************************
; Read a hexadecimal parameter from the CommandBuffer
;	- Input:	HL = Buffer pointer of command buffer, points to parameter
;	- Output:	BC = contains the converted Hex number (if it's a byte B is 0, C is the converted byte) 
;				A = 0 is no parameter, 1 is a byte, 2 is a word
;				HL = New position of pointer
;				Carry set if valid; Carry clear if error
; *********************************************************************************************************************

GetHexParameter:
	call	SkipSpaces				; Skip any spaces if any
	push	HL						; Save it, restoring it after character count
	ld		C,$00					; Character count set to zero
	
GetParamCount:
	ld		A,(HL)					; Read a character form the CommandBuffer
	cp		0						; Is it the end of the CommandBuffer?
	jr		z,GetParamFetch			; Yes, then stop counting
	cp		DELIMITER				; If it's the delimiter for the next parameter
	jr		z,GetParamFetch			; Yes, then stop counting
	cp		"?"
	jr		z,GetParamHelp
	inc		HL						; Increment buffer pointer to next character in parameter
	inc		C						; Add one, to the count of characters
	jr		GetParamCount			; Loop if delimiter has not been reached

GetParamFetch:
	ld		A,C						; Load counted characters into accumulator
	pop		HL						; Restore pointer back to it's original position
	ld		BC,$0000				; Clear the results register to store a nibble, byte or nibble+byte

GetParamFetch0;
	cp		0						; Was a parameter specified?
	jr		nz,GetParamFetch1		; No then check for 1 
	ld		A,0						; Returns 0 to indicate no parameters
	jr		GetParameterEnd			; End routine
	
GetParamFetch1:
	cp		1						; Was it only one digit?
	jr		nz,GetParamFetch2		; No then check for 2
	ld		A,(HL)
	inc		HL
	call	Ascii2HexNibble			; Convert an ASCII char in HL to a 4-bit hex value
	jr		nc,GetParamHexError		; If there was an error in the digit, print it and exit
	ld		C,A						; Save value in LSB of C
	ld		A,1						; Return 1 to indicate it's a 1-byte result
	jr		GetParameterEnd			; End routine

GetParamFetch2:
	cp		2						; Was it two digits?
	jr		nz,GetParamFetch3		; No then check for 3
	call	Ascii2HexByte			; Convert a hex digit to a hex value
	jr		nc,GetParamHexError		; If there was an error in the digit, print it and exit
	ld		C,A						; Save value in C
	ld		A,1						; Return 1 to indicate it's a 1-byte result
	jr		GetParameterEnd			; End routine

GetParamFetch3:
	cp		3						; Was three digits?
	jr		nz,GetParamFetch4		; No then check for 4
	ld		A,(HL)
	inc		HL
	call	Ascii2HexNibble			; Convert the first ASCII char in HL to a hex value
	jr		nc,GetParamHexError		; If there was an error in the digit, print it and exit
	ld		B,A						; Save result in D
	call	Ascii2HexByte			; Convert a hex digit to a hex value
	jr		nc,GetParamHexError		; If there was an error in the digit, print it and exit
	ld		C,A						; Store resulting byte in C (LSB)
	ld		A,2						; Return 2 to indicate it's a 2-byte result
	jr		GetParameterEnd			; End routine

GetParamFetch4:
	cp		4						; Was four digits?
	jr		nz,GetParamNumberError	; Print error message
	call	Ascii2HexWord			; Convert a 4-character hex digit pointed by HL to a hex value
	jr		nc,GetParamHexError		; If there was an error in the digit, print it and exit
	ld		A,2						; Return 2 to indicate it's a 2-byte result

GetParameterEnd:
	scf								; Set carry to indicate all is ok
	ret

GetParamHelp:
	pop		AF						; Dummy pop from stack as there was a push before
	ld		A,HELP
	scf
	ret

GetParamNumberError:
	ld		B,4						;
GetErrorPointerLoop:
	call	IncErrorPointer			;
	djnz	GetErrorPointerLoop		;
	call	PrintErrorPointer
	call	TooManyDigits			; Print invalid number of digits message	
	jr		GetParamErrorEnd		; End Error handling

GetParamHexError:
	call	PrintErrorPointer
	call	InvalidHexDigit			;Print invalid hex character message

GetParamErrorEnd:
	or		A						; Clear carry
	ret


;  ___                  _____                                ____            _           _                 
; |_ _|  _ __     ___  | ____|  _ __   _ __    ___    _ __  |  _ \    ___   (_)  _ __   | |_    ___   _ __ 
;  | |  | '_ \   / __| |  _|   | '__| | '__|  / _ \  | '__| | |_) |  / _ \  | | | '_ \  | __|  / _ \ | '__|
;  | |  | | | | | (__  | |___  | |    | |    | (_) | | |    |  __/  | (_) | | | | | | | | |_  |  __/ | |   
; |___| |_| |_|  \___| |_____| |_|    |_|     \___/  |_|    |_|      \___/  |_| |_| |_|  \__|  \___| |_|   
;
;
; *********************************************************************************************************************
; Increment error pointer by one
; *********************************************************************************************************************

IncErrorPointer:
	push	AF
	ld		A,(CmdErrorPointer)
	inc		A
	ld		(CmdErrorPointer),A
	pop		AF
	ret


;  ____                                     
; |  _ \    __ _   _ __   ___    ___   _ __ 
; | |_) |  / _` | | '__| / __|  / _ \ | '__|
; |  __/  | (_| | | |    \__ \ |  __/ | |   
; |_|      \__,_| |_|    |___/  \___| |_|   
;
;
; *********************************************************************************************************************
; Parse the string and compare the commands list and the command prompt, then execute if found
;	- Output:	BufferPointer points to parameter, if any
; *********************************************************************************************************************
;	- A = Command buffer character
;	- B	= Command list character
;	- DE = Command list pointer
;	- HL = Command buffer pointer

Parser:
	push	AF
	push	BC
	push	DE
	ld		(ParseSaveHL),HL		; Saves HL register, because it's not possible to push it due to routine call

	call	ResetErrorPointer		; Reset error pointer to start position
	ld		DE,CommandList			; Commands list pointer
	ld		HL,CommandBuffer		; Command buffer pointer
	call	SkipSpaces				; Removes any leading spaces in command buffer
	ld		(BufferPointer),HL		; Save the position of the first character for later
	ld		A,(HL)					; Read first character or delimiter of the command in command buffer
	cp		0						; Is it the end of the string already?
	jr		z,ParseEnd				; If so, then exit parser routine

ParseNextChar:
	ld		A,(HL)					; Read a character from the command buffer
	call	UpperCase				; Change the case to uppercase, as the command list is in uppercase
	ld		B,A						; Put the uppercase character read from string in B
	ld		A,(DE)					; Load a command list character in accumulator
	cp		EOT						; Has the end of the command list been reached?
	jr		z,ParseInvalid			; Teache the End Of Table, no matching commands has been found
	cp		JUMP					; Is it a command delimiter? (Which is actualy a jp opcode)
	jr		z,ParseValidate			; Yes, then execute command
	cp		B						; Is the letter from the list matching the buffer?
	jr		nz,ParseNextCmd			; If not the same, go to next command in the list
	call	IncErrorPointer			; Increment command line error pointer
	inc		DE						; Increment command list pointer to the next character
	inc		HL						; Increment command buffer pointer to tne next character
	jr		ParseNextChar			; Get the next character from command list

ParseNextCmd:
	inc		DE						; Increment command list pointer to eventually go to next command
	ld		A,(DE)					; Load from command list
	cp		JUMP					; Is it the End Of Command delimiter?
	jr		nz,ParseNextCmd			; No, then repeat until found
	inc		DE						; It is then bypass jump address
	inc		DE						; Point to the first character of following command
	inc		DE						;
	ld		HL,(BufferPointer)		; Restore location of first valid command buffer character
	call	ResetErrorPointer		; Reset error pointer to start position
	jr		ParseNextChar			; Loop back to read next character in list

ParseValidate:
	ld		A,(HL)					; Check for extra unwanted characters by enforcing space delimiter
	cp		0						; Check if it's the end of the buffer
	jr		z,ParseExecute			; It's the end of the buffer, execute command
	cp		DELIMITER				; Is the space delimiter present in the command buffer?
	jr		nz,ParseInvalid			; No, then it's not valid

ParseExecute:
	ld		(BufferPointer),HL		; Save current command buffer pointer for jump command parameters, if applicable
	ex		DE,HL					; Exchange DE with HL registers to be able to use HL for jumping
;	jp		(HL)					; Execute command at address in DE (now HL)

	pop		DE
	pop		BC
	pop		AF
	push	HL						; Save call address
	ld		HL,(ParseSaveHL)		; Restore HL
	ret								; Perform indirect call (HL)
	jp		Main					; Go to main
	
ParseInvalid:
	ld		HL,ParseInvalidErr
	call	PrintString

ParseEnd:
	ld		HL,(ParseSaveHL)
	pop		DE
	pop		BC
	pop		AF
	
	ret


;  ____           _           _     _____                                ____            _           _                 
; |  _ \   _ __  (_)  _ __   | |_  | ____|  _ __   _ __    ___    _ __  |  _ \    ___   (_)  _ __   | |_    ___   _ __ 
; | |_) | | '__| | | | '_ \  | __| |  _|   | '__| | '__|  / _ \  | '__| | |_) |  / _ \  | | | '_ \  | __|  / _ \ | '__|
; |  __/  | |    | | | | | | | |_  | |___  | |    | |    | (_) | | |    |  __/  | (_) | | | | | | | | |_  |  __/ | |   
; |_|     |_|    |_| |_| |_|  \__| |_____| |_|    |_|     \___/  |_|    |_|      \___/  |_| |_| |_|  \__|  \___| |_|   
;
;
; *********************************************************************************************************************
; Print error pointer character under the command line, pointing to the culprit
; *********************************************************************************************************************

PrintErrorPointer:
	push	AF
	push	BC
	
	ld		A,(CmdErrorPointer)		; Load error pointer as counter
	ld		B,A
PrintErrorLoop:
	ld		A," "
	call	PrintChar				; Print a space character
	djnz	PrintErrorLoop			; Decrement B, and repeat printing space, until 0
	ld		A,ERRORPTR
	call	PrintChar				; Print the error pointer character
	call	PrintCRLF				; Change line
	
	pop		BC
	pop		AF
	ret


;  ____                                  __     __          _   _       _           _     _                 
; |  _ \    __ _   _ __     __ _    ___  \ \   / /   __ _  | | (_)   __| |   __ _  | |_  (_)   ___    _ __  
; | |_) |  / _` | | '_ \   / _` |  / _ \  \ \ / /   / _` | | | | |  / _` |  / _` | | __| | |  / _ \  | '_ \ 
; |  _ <  | (_| | | | | | | (_| | |  __/   \ V /   | (_| | | | | | | (_| | | (_| | | |_  | | | (_) | | | | |
; |_| \_\  \__,_| |_| |_|  \__, |  \___|    \_/     \__,_| |_| |_|  \__,_|  \__,_|  \__| |_|  \___/  |_| |_|
;                          |___/                                                                            

; *********************************************************************************************************************
; Validates a range of addresses that can be written to with commands such as Fill and Zero. The range returns
; one or two ranges (before BIOS and after BIOS). It excludes BIOS, Interrupt vectors, jump table, and stack.
; - Input:	StartAddress, EndAddress
; - Output:	Updated StartAddress and EndAddress for low range, and StartAddressAlt and EndAddressAlt for high range
;			C = Flags: bit0 = Low bank, bit1 = High bank
; *********************************************************************************************************************

RangeValidation:
	push	AF
	push	DE
	push	HL
	
	ld		C,0						; Clear the region flag
	ld		HL,0
	ld		(StartAddressAlt),HL	; Reset alternate start address (that represents low memory)
	ld		(EndAddressAlt),HL		; Reset alternate end address (that represents high memory)
	
; CHECK ORDER OF START AND END ADDRESSES, AND IF RANGE IS ZERO
; ------------------------------------------------------------
ValCheckInverted:
	ld		HL,(StartAddress)		; Load start address
	ld		DE,(EndAddress)			; Load end address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jp		z,ValRangeTooSmallError	; If the range is 0, then print invalid error and exit
	jp		nc,ValInvertedError		; If start address is higher than the end address, then print error and exit

; CHECK IF THE START AND END ADDRESSES ARE IN THE VECTOR AREAS AND AJUST THEM ACCORDINGLY
; ----------------------------------------------------------------------------------------
ValCheckLowLimit:					; VALIDATE START ADDRESS IF IT'S IN INTERRUPT VECTOR TABLE
	ld		HL,(StartAddress)		; Load start address
	ld		DE,InterruptVectorEnd+1	; Load interrupt vector address to compare too
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jr		nc, ValCheckLowLimit2	; If it's not in the interrupt vector table, continue to next validation 
	ld		HL,InterruptVectorEnd			; Load 
	ld		(StartAddress),HL

ValCheckLowLimit2:					; VALIDATE END ADDRESS IF IT'S IN INTERRUPT VECTOR TABLE
	ld		HL,(EndAddress)			; Load end address
	ld		DE,InterruptVectorEnd+1	; Load interrupt vector address to compare too
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jp		c, RangeValidationError	; If it's in the interrupt vector table, print error and exit

ValCheckHighLimit:					; VALIDATE END ADDRESS IF IT'S IN THE END VECTOR TABLES AND STACK
	ld		HL,(EndAddress)			; Load start address
	ld		DE,VectorTable			; Load end vector table address to compare too (includes stack)
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jr		c, ValCheckHighLimit2	; If it's not in the vector tables, continue to next validation
	ld		HL,VectorTable-1		; Load Start of vector table area
	ld		(EndAddress),HL
	
ValCheckHighLimit2:					; VALIDATE START ADDRESS IF IT'S IN THE END VECTOR TABLES AND STACK
	ld		HL,(StartAddress)		; Load start address
	ld		DE,VectorTable			; Load end vector table address to compare too (includes stack)
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jp		nc,RangeValidationError	; If it's in the interrupt vector table, then change upper limit 

; CHECK IF THE RANGE IS COMPLETELY IN BIOS ZONE
; ---------------------------------------------
ValCheckBiosLow:
	ld		HL,(StartAddress)		; Load start address
	ld		DE,StartOfCode			; Load start of code to compare too
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jr		c,ValCheckHigh			; If start address is lower than the start of code, then check if in high RRAM

ValCheckBiosHi:
	ld		HL,(EndAddress)			; Load end address
	ld		DE,EndOfCode			; Load end of code address to compare too
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jr		nc,ValCheckHigh			; If end address is higher than the end of code, then check if in high RAM
	jp		ValBiosRangeError		; Else print invalid range and exit

; CHECK IF RANGE IS IN HIGH MEMORY
; --------------------------------
ValCheckHigh:
	; Is it in high memory?
	ld		HL,(StartAddress)		; Load start address
	ld		DE,StartOfCode			; Load start of code address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	; No, then check for low memory
	jr		c,ValCheckLow

	; Is it in high memory, but is it within the BIOS region?
	ld		HL,(StartAddress)		; Load start address
	ld		DE,EndOfCode			; Load end of code address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	; Yes, then change StartAddress to upper limit of BIOS
	jr		c,ValCheckHighBios
	; No, then only copy start and end addresses to the Alt locations
	ld		HL,(StartAddress)		;
	ld		(StartAddressAlt),HL	; Set start address at the end of code, in case it overlapped
	ld		HL,(EndAddress)			;
	ld		(EndAddressAlt),HL		; Set end address in the high alternate position
	set		1,C						; Flag high address
	jr		ValCheckLow

ValCheckHighBios:
	ld		HL,EndOfCode		;
	ld		(StartAddressAlt),HL	; Set start address at the end of code, in case it overlapped
	ld		HL,(EndAddress)			;
	ld		(EndAddressAlt),HL		; Set end address in the high alternate position
	set		1,C						; Flag high address
	
; CHECK IF RANGE IS IN LOW MEMORY
; -------------------------------
ValCheckLow:
	; Is it in low memory only?
	ld		HL,(EndAddress)			; Load start address
	ld		DE,EndOfCode			; Load start of code address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	; No, then it overlaps BIOS
	jr		nc,ValBiosOverlap

	; Is it in low memory, but is it within the BIOS region?
	ld		HL,(EndAddress)			; Load start address
	ld		DE,StartOfCode			; Load end of code address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	; Yes, then change EndAddress to lower limit of BIOS
	jr		nc,ValCheckLowBios
	; No, then only flag low memory
	set		0,C						; Flag low address
	jr		ValBiosOverlap

ValCheckLowBios:
	ld		HL,StartOfCode			;
	dec		HL
	ld		(EndAddress),HL			; Set start address at the end of code, in case it overlapped
	set		0,C						; Flag low address

; CHECK IF RANGE OVERLAPS BIOS AREA
; ---------------------------------
ValBiosOverlap:
	ld		A,C
	cp		0
	jr		nz,ValCheckIfZeroDataLow
	; Move EndAddress to the Alternate one
	ld		HL,(EndAddress)
	ld		(EndAddressAlt),HL
	; Change low memory EndAddress to beginning of BIOS -1
	ld		HL,StartOfCode		
	dec		HL
	ld		(EndAddress),HL
	; Change high memory StartAddressAlt to end of BIOS
	ld		HL,EndOfCode
	ld		(StartAddressAlt),HL
	set		0,C						; Flag low address
	set		1,C						; Flag high address

; CHECK IF RANGE(S) ARE ZERO, WITH REASSIGNMENT, IT'S POSSIBLE
; ------------------------------------------------------------
ValCheckIfZeroDataLow:
	bit		0,C
	jr		z,ValCheckIfZeroDataHigh
	ld		HL,(StartAddress)		; Load start address
	ld		DE,(EndAddress)			; Load end address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jr		z,ValRangeTooSmallError	; If the range is 0, then print error and exit

ValCheckIfZeroDataHigh:
	bit		1,C
	jr		z,ValPrintRange
	ld		HL,(StartAddressAlt)	; Load alternate start address
	ld		DE,(EndAddressAlt)		; Load alternate end address
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	jr		z,ValRangeTooSmallError	; If the range is 0, then print error and exit

	; PRINTS ADDRESS RANGE
ValPrintRange:
	call	Range

ValPrintRange1:
	bit		0,C
	jr		z,ValPrintRange2
	ld		A," "
	call	PrintChar
	ld		HL,(StartAddress)
	call	PrintWord
	ld		A,"-"
	call	PrintChar
	ld		HL,(EndAddress)
	call	PrintWord
	
ValPrintRange2:
	bit		1,C
	jr		z,ValPrintRangeEnd
	ld		A," "
	call	PrintChar
	ld		HL,(StartAddressAlt)
	call	PrintWord
	ld		A,"-"
	call	PrintChar
	ld		HL,(EndAddressAlt)
	call	PrintWord	

ValPrintRangeEnd:
	call	PrintCRLF
	scf								; Set carry
	jr		RangeValidationEnd

ValBiosRangeError:
	call	BiosRange
	or		A
	jr		RangeValidationEnd

ValRangeTooSmallError:
	call	RangeTooSmall
	or		A
	jr		RangeValidationEnd

ValInvertedError:
	call	RangeInverted
	or		A
	jr		RangeValidationEnd
	
RangeValidationError:
	call	InvalidVectorRange
	or		A						; Clear Carry

RangeValidationEnd:
	pop		HL
	pop		DE
	pop		AF

	ret


;  ____                        _     _____                                ____            _           _                 
; |  _ \    ___   ___    ___  | |_  | ____|  _ __   _ __    ___    _ __  |  _ \    ___   (_)  _ __   | |_    ___   _ __ 
; | |_) |  / _ \ / __|  / _ \ | __| |  _|   | '__| | '__|  / _ \  | '__| | |_) |  / _ \  | | | '_ \  | __|  / _ \ | '__|
; |  _ <  |  __/ \__ \ |  __/ | |_  | |___  | |    | |    | (_) | | |    |  __/  | (_) | | | | | | | | |_  |  __/ | |   
; |_| \_\  \___| |___/  \___|  \__| |_____| |_|    |_|     \___/  |_|    |_|      \___/  |_| |_| |_|  \__|  \___| |_|   
;
;
; *********************************************************************************************************************
; Increment error pointer by one
; *********************************************************************************************************************

ResetErrorPointer:
	push	AF
	ld		A,ErrorPtrOffset
	ld		(CmdErrorPointer),A
	pop		AF
	ret


;  ____    _      _           ____                                      
; / ___|  | | __ (_)  _ __   / ___|   _ __     __ _    ___    ___   ___ 
; \___ \  | |/ / | | | '_ \  \___ \  | '_ \   / _` |  / __|  / _ \ / __|
;  ___) | |   <  | | | |_) |  ___) | | |_) | | (_| | | (__  |  __/ \__ \
; |____/  |_|\_\ |_| | .__/  |____/  | .__/   \__,_|  \___|  \___| |___/
;                    |_|             |_|                                
;
; *********************************************************************************************************************
; Removes leading spaces for parsing commands
;	- Input:	HL pointing to command string
;	- Output:	HL points to the next delimiterless position
; *********************************************************************************************************************

SkipSpaces:
	push	AF
SkipSpacesLoop:
	ld		A,(HL)					; Read the contents of HL, where the 
	cp		" "						; Is it a space?
	jr		nz,SkipSpacesEnd		; It's not a space, so end routine
	inc		HL						; It's a space, so move to next character
	call	IncErrorPointer			; Increment command line error pointer
	jr		SkipSpacesLoop			; Check for other spaces, just in case
SkipSpacesEnd:
	pop		AF
	ret

