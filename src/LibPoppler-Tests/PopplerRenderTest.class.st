"
Rendering `PopplerPage`s on Athens canvases and into Forms: ink, placement under an Athens transform, printing, the JPEG (DCT) decoder and the base-14 font substitution. Also checks the fixtures' own building blocks (the JPEG, RC4).
"
Class {
	#name : 'PopplerRenderTest',
	#superclass : 'PopplerTestCase',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'tests' }
PopplerRenderTest >> testAsFormHasInk [

	| form |
	form := (self threePageDocument pageAt: 1) asFormScale: 1.
	self assert: form extent equals: 596 @ 842.
	self assert: (self darkPixelsOf: form) > 100
]

{ #category : 'tests' }
PopplerRenderTest >> testAsFormScale [

	| page small large |
	page := self threePageDocument pageAt: 3.
	small := page asFormScale: 1.
	large := page asFormScale: 2.
	self assert: small extent equals: 300 @ 200.
	self assert: large extent equals: 600 @ 400.
	self assert: (self darkPixelsOf: large) > ((self darkPixelsOf: small) * 3)
]

{ #category : 'tests' }
PopplerRenderTest >> testBase14PageInks [
	"Non-embedded Helvetica: poppler substitutes a font through fontconfig."

	| page |
	page := (PopplerDocument fromBytes: PopplerFixtures base14Pdf) pageAt: 1.
	self assert: (self darkPixelsOf: (page asFormScale: 1)) > 20
]

{ #category : 'tests' }
PopplerRenderTest >> testFixtureJpegDecodesToItsColour [
	"The fixture itself, decoded by the image's JPEG reader (not by poppler)."

	| form colour |
	form := ImageReadWriter formFromStream: PopplerFixtures redJpeg readStream.
	self assert: form extent equals: 32 @ 32.
	#( 0 15 31 ) do: [ :x |
		#( 0 16 31 ) do: [ :y |
			colour := form colorAt: x @ y.
			self assert: (colour red * 255) rounded > 180.
			self assert: (colour green * 255) rounded < 20.
			self assert: (colour blue * 255) rounded < 20 ] ]
]

{ #category : 'tests' }
PopplerRenderTest >> testJpegPageCentre [
	"poppler decodes the embedded JPEG (DCTDecode) with the bundled libjpeg-turbo."

	| form pixel |
	form := ((PopplerDocument fromBytes: PopplerFixtures jpegPdf) pageAt: 1) asFormScale: 1.
	self assert: form extent equals: 64 @ 64.
	pixel := form pixelValueAt: 32 @ 32.
	self assert: ((pixel bitShift: -16) bitAnd: 255) > 150.
	self assert: ((pixel bitShift: -8) bitAnd: 255) < 60.
	self assert: (pixel bitAnd: 255) < 60.
	"outside the image the page stays white"
	self assert: ((form pixelValueAt: 4 @ 4) bitAnd: 16rFFFFFF) equals: 16rFFFFFF
]

{ #category : 'tests' }
PopplerRenderTest >> testRc4KnownAnswer [

	self
		assert: (PopplerFixtures rc4: 'Key' asByteArray data: 'Plaintext' asByteArray)
		equals: #[ 16rBB 16rF3 16r16 16rE8 16rD9 16r40 16rAF 16r0A 16rD3 ].
	self
		assert: (PopplerFixtures rc4: 'Secret' asByteArray data: 'Attack at dawn' asByteArray)
		equals: #[ 16r45 16rA0 16r1F 16r64 16r5F 16rC3 16r5B 16r38 16r35 16r52 16r54 16r4B 16r9B 16rF5 ]
]

{ #category : 'tests' }
PopplerRenderTest >> testRenderForPrintingInks [

	| form |
	form := self
		        formOf: (self threePageDocument pageAt: 3)
		        extent: 300 @ 200
		        translatedBy: 0 @ 0
		        printing: true.
	self assert: (self darkPixelsOf: form) > 50
]

{ #category : 'tests' }
PopplerRenderTest >> testRenderKeepsTheAthensState [
	"After a page, Athens draws with its own transform and paint as before."

	| page surface form |
	page := self threePageDocument pageAt: 3.
	surface := AthensCairoSurface extent: 60 @ 60.
	surface drawDuring: [ :canvas |
		canvas pathTransform loadIdentity.
		canvas setPaint: Color white.
		canvas drawShape: (0 @ 0 extent: 60 @ 60).
		canvas pathTransform translateBy: 10 @ 10.
		canvas pathTransform scaleBy: 0.1.
		page renderOn: canvas.
		canvas setPaint: Color blue.
		canvas drawShape: (300 @ 300 extent: 100 @ 100) ].
	form := surface asForm.
	"the blue square is at (10 + 30) @ (10 + 30), 10 units wide"
	self assert: ((form pixelValueAt: 45 @ 45) bitAnd: 16rFFFFFF) equals: 16r0000FF.
	self assert: ((form pixelValueAt: 55 @ 55) bitAnd: 16rFFFFFF) equals: 16rFFFFFF
]

{ #category : 'tests' }
PopplerRenderTest >> testRenderTranslatedMovesTheInk [

	| page plain moved plainBounds movedBounds |
	page := self threePageDocument pageAt: 3.
	plain := self formOf: page extent: 400 @ 300 translatedBy: 0 @ 0 printing: false.
	moved := self formOf: page extent: 400 @ 300 translatedBy: 50 @ 50 printing: false.
	plainBounds := self inkBoundsOf: plain.
	movedBounds := self inkBoundsOf: moved.
	self assert: plainBounds notNil.
	self assert: ((movedBounds origin - plainBounds origin) - (50 @ 50)) abs < (2 @ 2).
	self assert: ((movedBounds corner - plainBounds corner) - (50 @ 50)) abs < (2 @ 2)
]
