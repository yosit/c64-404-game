//loads a byte from arg address and multiply it by 3.
//output Register A
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
