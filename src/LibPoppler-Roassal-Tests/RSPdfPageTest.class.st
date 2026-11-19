"
RSPdfPage: extent, page shapes of a document, ink on a canvas exported as a Form, placement under the Roassal camera (position 100@50, zoom 2: the drawn page lies on the shape's encompassing rectangle mapped through the camera), and a shape whose page and document come from a previous image session.

The PDFs are PopplerFixtures' (LibPoppler-Tests).
"
Class {
	#name : 'RSPdfPageTest',
	#superclass : 'PopplerTestCase',
	#category : 'LibPoppler-Roassal-Tests',
	#package : 'LibPoppler-Roassal-Tests'
}

{ #category : 'helpers' }
RSPdfPageTest >> boundsOf: aForm where: aBlock [
	"The smallest rectangle holding every pixel whose 24-bit RGB value satisfies aBlock; nil when none."

	| left top right bottom |
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			(aBlock value: ((aForm pixelValueAt: x @ y) bitAnd: 16rFFFFFF)) ifTrue: [
				left := left ifNil: [ x ] ifNotNil: [ left min: x ].
				right := right ifNil: [ x ] ifNotNil: [ right max: x ].
				top := top ifNil: [ y ].
				bottom := y ] ] ].
	left ifNil: [ ^ nil ].
	^ left @ top corner: right + 1 @ (bottom + 1)
]

{ #category : 'helpers' }
RSPdfPageTest >> canvasWith: aShape color: aColor [
	"A 1200x800 canvas holding aShape at 100@50, camera zoom 2."

	| canvas |
	canvas := RSCanvas new.
	canvas color: aColor.
	canvas extent: 1200 @ 800.
	canvas add: aShape.
	aShape position: 100 @ 50.
	canvas camera scale: 2.
	^ canvas
]

{ #category : 'helpers' }
RSPdfPageTest >> mappedRectangleOf: aShape in: aCanvas [
	"aShape's encompassing rectangle in pixels of aCanvas (through its camera)."

	| rectangle |
	rectangle := aShape encompassingRectangle.
	^ (aCanvas camera fromSpaceToPixel: rectangle origin) corner: (aCanvas camera fromSpaceToPixel: rectangle corner)
]

{ #category : 'tests' }
RSPdfPageTest >> testAsRoassalShapes [

	| document shapes |
	document := self threePageDocument.
	shapes := document asRoassalShapes.
	self assert: (shapes isKindOf: RSGroup).
	self assert: shapes size equals: 3.
	shapes withIndexDo: [ :shape :index |
		self assert: (shape isKindOf: RSPdfPage).
		self assert: shape page identicalTo: (document pageAt: index).
		self assert: shape model identicalTo: (document pageAt: index).
		self assert: shape showsBackground ].
	self assert: (document pageAt: 3) asRoassalShape page identicalTo: (document pageAt: 3)
]

{ #category : 'tests' }
RSPdfPageTest >> testExtentIsThePageSize [

	| document |
	document := self threePageDocument.
	1 to: 3 do: [ :index |
		| page shape |
		page := document pageAt: index.
		shape := RSPdfPage page: page.
		self assert: (shape extent x - page width) abs < 0.01.
		self assert: (shape extent y - page height) abs < 0.01 ].
	self assert: ((RSPdfPage page: (document pageAt: 1)) extent - (595.28 @ 841.89)) abs < (0.01 @ 0.01)
]

{ #category : 'tests' }
RSPdfPageTest >> testGridOfPagesHasInk [

	| canvas shapes form |
	shapes := self threePageDocument asRoassalShapes.
	canvas := RSCanvas new.
	canvas extent: 800 @ 600.
	canvas addAll: shapes.
	RSGridLayout new
		gapSize: 20;
		on: shapes.
	canvas zoomToFit.
	form := canvas asForm.
	self assert: form extent equals: 800 @ 600.
	self assert: (self darkPixelsOf: form) > 100.
	"the three pages do not overlap"
	shapes do: [ :each |
		(shapes copyWithout: each) do: [ :other |
			self deny: (each encompassingRectangle intersects: other encompassingRectangle) ] ]
]

{ #category : 'tests' }
RSPdfPageTest >> testInkLiesInsideTheShape [
	"No background, on a white canvas: the page's ink lies inside the shape's rectangle as the camera maps it."

	| shape canvas form ink expected |
	shape := RSPdfPage page: (self threePageDocument pageAt: 3).
	shape showsBackground: false.
	canvas := self canvasWith: shape color: Color white.
	form := canvas asForm.
	expected := self mappedRectangleOf: shape in: canvas.
	ink := self boundsOf: form where: [ :rgb | rgb ~= 16rFFFFFF ].
	self assert: ink notNil.
	self assert: (self darkPixelsOf: form) > 100.
	self assert: ink left >= (expected left - 2).
	self assert: ink top >= (expected top - 2).
	self assert: ink right <= (expected right + 2).
	self assert: ink bottom <= (expected bottom + 2).
	"the text 'Hello Poppler 3' starts 20 pt from the left edge and its baseline is 60 pt from the top: x2 on screen"
	self assert: (ink left - (expected left + 40)) abs < 6.
	self assert: ink bottom < (expected top + 140)
]

{ #category : 'tests' }
RSPdfPageTest >> testPageIsPlacedOnTheShape [
	"Position 100@50, camera zoom 2, on a black canvas: the white page covers exactly the shape's mapped rectangle."

	| shape canvas form white expected |
	shape := RSPdfPage page: (self threePageDocument pageAt: 3).
	canvas := self canvasWith: shape color: Color black.
	form := canvas asForm.
	expected := self mappedRectangleOf: shape in: canvas.
	self assert: expected extent equals: 600 @ 400.
	white := self boundsOf: form where: [ :rgb |
		         (rgb bitShift: -16) > 200 and: [ ((rgb bitShift: -8) bitAnd: 255) > 200 and: [ (rgb bitAnd: 255) > 200 ] ] ].
	self assert: white notNil.
	self assert: (white origin - expected origin) abs < (2 @ 2).
	self assert: (white corner - expected corner) abs < (2 @ 2).
	self assert: (self darkPixelsOf: (form copy: expected rounded)) > 100
]

{ #category : 'tests' }
RSPdfPageTest >> testRenderPopplerPdfPage [
	"The selector kept from the previous LibPoppler draws the shape's page (no background)."

	| shape surface form |
	shape := RSPdfPage page: (self threePageDocument pageAt: 3).
	surface := AthensCairoSurface extent: 300 @ 200.
	surface drawDuring: [ :canvas |
		canvas pathTransform loadIdentity.
		canvas setPaint: Color white.
		canvas drawShape: (0 @ 0 extent: 300 @ 200).
		canvas renderPopplerPdfPage: shape ].
	form := surface asForm.
	self assert: (self darkPixelsOf: form) > 50
]

{ #category : 'tests' }
RSPdfPageTest >> testShapeSurvivesARestart [
	"A canvas holding a page shape redraws after a (forged) restart: page and document reopen. The old references
	are forgotten (never unref'd), so the test drops each of them exactly once, after a reference of its own."

	| document page shape canvas oldDocument oldPage |
	document := self threePageDocument.
	page := document pageAt: 3.
	shape := page asRoassalShape.
	canvas := self canvasWith: shape color: Color white.
	self assert: (self darkPixelsOf: canvas asForm) > 100.
	oldDocument := document validHandle copy.
	oldPage := page validHandle copy.
	GObjectLibrary ref: oldDocument.
	GObjectLibrary ref: oldPage.
	self forge: document.
	self forge: page.
	self deny: page isValid.
	"a canvas exported once does not redraw clean shapes: the same shape in a fresh canvas"
	shape remove.
	canvas := self canvasWith: shape color: Color white.
	self assert: (self darkPixelsOf: canvas asForm) > 100.
	self assert: page isValid.
	self assert: document isValid.
	self assert: shape page identicalTo: page.
	self deny: page validHandle asInteger equals: oldPage asInteger.
	"the abandoned wrappers' references, plus ours"
	self assert: (self refCountOf: oldPage) equals: 2.
	self assert: (self refCountOf: oldDocument) equals: 3.
	GObjectLibrary unref: oldPage.
	GObjectLibrary unref: oldDocument.
	GObjectLibrary unref: oldPage.
	self assert: (self refCountOf: oldDocument) equals: 1.
	GObjectLibrary unref: oldDocument
]

{ #category : 'tests' }
RSPdfPageTest >> testShowsBackground [
	"On a black canvas, a page without its background leaves more dark pixels than one with it."

	| document plain bare shape |
	document := self threePageDocument.
	plain := (self canvasWith: (document pageAt: 3) asRoassalShape color: Color black) asForm.
	shape := (document pageAt: 3) asRoassalShape.
	shape showsBackground: false.
	self deny: shape showsBackground.
	bare := (self canvasWith: shape color: Color black) asForm.
	self assert: (self darkPixelsOf: bare) > ((self darkPixelsOf: plain) + 10000)
]
