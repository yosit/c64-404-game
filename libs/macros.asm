//loads a byte from arg address and multiplies it by 9 (asl x3 = *8, + arg = *9).
//Used to index 3x3 tiles (9 chars each) in the charset. Output: Register A.
.macro multiplyby9(arg) {
		clc
		lda arg
		asl
		asl
		asl
		adc arg
}

.macro StoreState() {
		pha //A
		txa 
		pha //X
		tya 
		pha //Y
}

.macro RestoreState() {
		pla 
		tay
		pla 
		tax 
		pla 
}


.macro waitForRasterLine( line ) {
		lda #line
		cmp VIC.RASTER_Y
		bne *-3	
}
