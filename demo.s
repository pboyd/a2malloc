	ORG $2000

AllocateAndFill	MAC
		LDA ]1
		JSR Alloc
		BEQ ]3

		LDA ]1
		ASL
		TAY
		LDA ]2
]Loop		
		DEY
		STA (AllocPointer),Y
		BNE ]Loop
End		<<<

COUT	EQU $FDED
PrintLn	MAC
	LDX #$0

]Loop	    
	INX

	LDA ]1,X
	JSR COUT

	CPX ]1	
	BEQ End	
	JMP ]Loop

	LDA #$8D
	JSR COUT
	<<<

* Allocator Configuration
AllocPointer	EQU $40
AllocStart	EQU $42

Start	    
	    LDA #$8D		; Print a newline
	    JSR COUT

	    LDA #0		; Tell the allocator to use memory starting
	    STA AllocStart	; at $6000.
	    LDA #$60		    
	    STA AllocStart+1

	    AllocInit #$20

	    AllocateAndFill #$8;#$8;[OutOfMemory
	    AllocateAndFill #$7f;#$7f;[OutOfMemory
	    AllocateAndFill #$50;#$50;[OutOfMemory
	    ;AllocateAndFill #$80;#$80;[OutOfMemory
	    JMP End

[OutOfMemory
	    PrintLn NOTOK

End	    JMP $3D0	; Warm rentry vector

* Load the allocator subroutines.
	    PUT alloc

NOTOK	    STR "Not OK"
