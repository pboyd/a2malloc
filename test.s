*
* This program allocates and frees some memory, then checks the effect. If it
* works, there will be 20 pages starting at $6000 that begin with:
*
*    01 00 7f 7f
*

	ORG $2000

	USE lib.macs.s

* Allocator Configuration
AllocPointer	EQU $40
AllocStart	EQU $42

* Location to store the pointer with the record of what's been allocated.
Blocks		EQU $80
BlocksLen	EQU $82

Start
	    LDA #0		; Tell the allocator to use memory starting
	    STA AllocStart	; at $6000.
	    LDA #$60
	    STA AllocStart+1

	    AllocInit #$20

	    LDA #0
	    STA BlocksLen

	    ; This is too big and will always fail.
	    ;LDA #$80
	    ;JSR TestAlloc

	    * Get 20 bytes to store the list of allocated memory.
	    LDA #20
	    JSR	Alloc
	    CopyWord AllocPointer;Blocks

	    * Block 0
	    LDA #$8
	    JSR TestAlloc

	    * Block 1
	    LDA #$7F
	    JSR TestAlloc

	    * Block 2
	    LDA #$50
	    JSR TestAlloc

	    * Block 3
	    LDA #$7F
	    JSR TestAlloc

	    * Block 4
	    LDA #$1
	    JSR TestAlloc

	    * Block 5
	    LDA #$10
	    JSR TestAlloc

	    * Block 6
	    LDA #$20
	    JSR TestAlloc

	    LDA #2
	    JSR TestFree

	    LDA #4
	    JSR TestFree

	    LDA #6
	    JSR TestFree

	    LDA #5
	    JSR TestFree

	    LDA #3
	    JSR TestFree

	    LDA #1
	    JSR TestFree

	    LDA #0
	    JSR TestFree

	    CopyWord Blocks;AllocPointer
	    LDA #20
	    JSR Free

	    * Now walk through the pages we used an make sure they are correct.

	    JSR $FC58		    ; Clear the screen

	    CopyWord AllocStart;AllocPointer
	    LDX #20
]CheckLoop
	    LDY #0		    ; check that byte 0 is 1
	    LDA (AllocPointer),Y
	    CMP #1
	    BNE [CheckFailed

	    INY			    ; check that byte 1 is 1
	    LDA (AllocPointer),Y
	    BNE [CheckFailed

	    INY			    ; check that byte 2 is 7f
	    LDA (AllocPointer),Y
	    CMP #$7f
	    BNE [CheckFailed

	    INY			    ; check that byte 3 is 7f
	    LDA (AllocPointer),Y
	    CMP #$7f
	    BNE [CheckFailed

	    DEX			    ; Decrement our index
	    BEQ [CheckPassed	    ; Is it 0?

	    INC AllocPointer+1	    ; Advance the MSB of the pointer.
	    JMP ]CheckLoop

[CheckFailed
	    ; Print Not OK
	    PrintLn NotOK
	    JMP End

[CheckPassed
	    ; Print OK
	    PrintLn OK

End
	    JMP $3D0	; Use the "warm rentry vector" because we printed
			; something.

OK	    STR "OK"
NotOK	    STR "Not OK"

* TestAlloc calls Alloc, then fills the returned pointer with the size, and
* records the allocated memory in Blocks.
*
* The caller should set the allocator to the number of words to be allocated.
TestAlloc
		PHA
		JSR Alloc
		BEQ [Fail

		PLA
		PHA
		ASL		; Fill bytes, not words.
		TAY

		LDA BlocksLen	; Fill with the number of the allocation
]Loop
		DEY
		STA (AllocPointer),Y
		BNE ]Loop

		LDA BlocksLen	; Get the index, which is length * 4.
		ASL
		ASL
		TAY

		LDA AllocPointer
		STA (Blocks),Y

		INY
		LDA AllocPointer+1
		STA (Blocks),Y

		INY
		PLA
		STA (Blocks),Y

		INC BlocksLen

		JMP EndTestAlloc

[Fail		PLA
		BRK
EndTestAlloc	RTS

* TestFree frees memory that's referenced in Blocks.
* The caller should put the Blocks index in the accumulator.
TestFree
	    ASL	    ; Multiply the index by 4 to get the address.
	    ASL
	    TAY

	    * Copy the pointer from blocks to AllocPointer
	    LDA (Blocks),Y
	    STA AllocPointer
	    INY
	    LDA (Blocks),Y
	    STA AllocPointer+1

	    * Get the size from Blocks too
	    INY
	    LDA (Blocks),Y

	    JSR Free

	    RTS

* Load the allocator subroutines.
	    PUT alloc
