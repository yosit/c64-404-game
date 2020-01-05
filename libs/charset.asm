* = $4000 "Charset"
.import binary "./../data/everything-charset.bin"

* = * "Map"
Map:
.import binary "./../data/everything-map.bin"

* = $7000 "sprites"
	#import  "../data/sprites.asm"