	ORG $2000

Fill	MAC
	LDY ]2
	LDA ]3
]Loop	STA (]1),Y
	DEY
	BNE ]Loop
	<<<

AllocateAndFill	MAC
		LDA ]1
		JSR Alloc
		BEQ End

		LDA ]2
		LDY ]1+1
]Loop		DEY
		STA (AllocPointer),Y
		BNE ]Loop
End		<<<

* Allocator Configuration
AllocPointer	EQU $40
AllocStart	EQU $42
AllocCount	EQU #$20

Start	    LDA #0		    ; Tell the allocator to use memory starting
	    STA AllocStart	    ; at $6000.
	    LDA #$60		    
	    STA AllocStart+1

	    JSR AllocInit

	    JSR $FC58		    ; Clear the screen.

	    ;AllocateAndFill #$f;#$f
	    ;AllocateAndFill #$e;#$e
	    ;AllocateAndFill #$d;#$d
	    ;AllocateAndFill #$c;#$c
	    ;AllocateAndFill #$b;#$b
	    ;AllocateAndFill #$a;#$a

	    AllocateAndFill #$fe;#$fe
	    ;AllocateAndFill #$fe;#$fe
	    ;AllocateAndFill #$50;#$50

	    ;LDA #$f
	    ;JSR Alloc
	    ;LDY #0
	    ;LDA #$AA
	    ;STA (AllocPointer),Y

	    ;Fill AllocPointer;#$f;#$aa

End	    RTS

* Load the allocator subroutines.
	    PUT alloc
