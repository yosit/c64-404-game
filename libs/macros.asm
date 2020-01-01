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