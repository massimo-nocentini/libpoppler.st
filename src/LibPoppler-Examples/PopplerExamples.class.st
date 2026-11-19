"
Examples of LibPoppler with Roassal (class side, `<example>`). They show a small three-page PDF written here in Smalltalk (`samplePdf`: base-14 Helvetica text and coloured boxes, page labels 'i' 'ii' 'iii'); the builders take any document:

	PopplerExamples gridCanvasOn: 'paper.pdf' asFileReference asPdf.
	PopplerExamples textCanvasOn: (PopplerDocument fromFile: 'paper.pdf').
"
Class {
	#name : 'PopplerExamples',
	#superclass : 'Object',
	#category : 'LibPoppler-Examples',
	#package : 'LibPoppler-Examples'
}

{ #category : 'examples' }
PopplerExamples class >> exampleGrid [
	"The pages of a document as Roassal shapes in a grid; drag and zoom with the mouse, a popup tells the page label."

	<example>
	^ (self gridCanvasOn: self sampleDocument) open
]

{ #category : 'examples' }
PopplerExamples class >> exampleText [
	"Each page next to the text poppler extracts from it."

	<example>
	^ (self textCanvasOn: self sampleDocument) open
]

{ #category : 'building' }
PopplerExamples class >> gridCanvasOn: aPopplerDocument [
	"An RSCanvas with every page of aPopplerDocument (an RSPdfPage each) in a grid."

	| canvas shapes |
	canvas := RSCanvas new.
	canvas color: (Color gray: 0.85).
	shapes := aPopplerDocument asRoassalShapes.
	shapes do: [ :each | each @ (RSPopup text: [ :page | 'page ' , page label ]) ].
	canvas addAll: shapes.
	RSGridLayout new
		gapSize: 20;
		on: shapes.
	canvas @ RSCanvasController.
	^ canvas
]

{ #category : 'private' }
PopplerExamples class >> pdfWithObjects: anArray [
	"A PDF 1.4 file whose objects 1..n have the bodies in anArray (Strings), with a correct xref table; object 1 is the catalog."

	| out offsets xref lf |
	lf := String with: Character lf.
	out := WriteStream on: (ByteArray new: 2048).
	out nextPutAll: ('%PDF-1.4' , lf) asByteArray.
	offsets := anArray withIndexCollect: [ :body :n |
		           | offset |
		           offset := out position.
		           out nextPutAll: (n printString , ' 0 obj' , lf , body , lf , 'endobj' , lf) asByteArray.
		           offset ].
	xref := out position.
	out nextPutAll: ('xref' , lf , '0 ' , (anArray size + 1) printString , lf , '0000000000 65535 f ' , lf) asByteArray.
	offsets do: [ :each | out nextPutAll: ((each printPaddedWith: $0 to: 10) , ' 00000 n ' , lf) asByteArray ].
	out nextPutAll: ('trailer' , lf , '<< /Size ' , (anArray size + 1) printString , ' /Root 1 0 R >>' , lf , 'startxref'
		 , lf , xref printString , lf , '%%EOF' , lf) asByteArray.
	^ out contents
]

{ #category : 'sample' }
PopplerExamples class >> sampleDocument [

	^ PopplerDocument fromBytes: self samplePdf
]

{ #category : 'sample' }
PopplerExamples class >> samplePdf [
	"Three pages (300x200, 300x200, 200x300 points) with a title, a line of text and coloured boxes each, in base-14
	Helvetica (not embedded: poppler substitutes a system font through fontconfig); roman page labels."

	| pages objects lf |
	lf := String with: Character lf.
	pages := {
		         { 300. 200. 'Poppler in Roassal'. 'Page one: three boxes.'. '0.80 0.10 0.10 rg 20 20 70 70 re f 0.10 0.60 0.20 rg 110 20 70 70 re f 0.10 0.30 0.80 rg 200 20 70 70 re f' }.
		         { 300. 200. 'Second page'. 'Text and a frame.'. '0 0 0 RG 4 w 20 20 260 80 re S' }.
		         { 200. 300. 'Third page'. 'A tall one.'. '0.95 0.65 0.10 rg 40 40 120 120 re f' } }.
	objects := OrderedCollection new.
	objects add: '<< /Type /Catalog /Pages 2 0 R /PageLabels << /Nums [0 << /S /r >>] >> >>'.
	objects add: '<< /Type /Pages /Kids [4 0 R 6 0 R 8 0 R] /Count 3 >>'.
	objects add: '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'.
	pages do: [ :each |
		| content |
		content := 'BT /F1 18 Tf 20 ' , (each second - 40) printString , ' Td (' , each third , ') Tj ET' , lf , 'BT /F1 11 Tf 20 '
		           , (each second - 64) printString , ' Td (' , each fourth , ') Tj ET' , lf , each fifth.
		objects add: '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ' , each first printString , ' ' , each second printString
			, '] /Resources << /Font << /F1 3 0 R >> >> /Contents ' , (objects size + 2) printString , ' 0 R >>'.
		objects add: '<< /Length ' , content size printString , ' >>' , lf , 'stream' , lf , content , lf , 'endstream' ].
	^ self pdfWithObjects: objects asArray
]

{ #category : 'building' }
PopplerExamples class >> textCanvasOn: aPopplerDocument [
	"An RSCanvas with one row per page: the page (an RSPdfPage) and, on its right, the lines of its text."

	| canvas rows |
	canvas := RSCanvas new.
	rows := aPopplerDocument pages collect: [ :page |
		        | shapes lines |
		        lines := (page text lines reject: [ :each | each isEmpty ]) collect: [ :each |
			                 RSLabel new
				                 text: each;
				                 color: Color black;
				                 yourself ].
		        lines := RSGroup withAll: lines.
		        RSVerticalLineLayout on: lines.
		        shapes := RSGroup new.
		        shapes add: page asRoassalShape.
		        shapes add: (RSComposite new
				         shapes: lines;
				         yourself).
		        RSHorizontalLineLayout new
			        gapSize: 20;
			        alignMiddle;
			        on: shapes.
		        RSComposite new
			        shapes: shapes;
			        color: (Color gray alpha: 0.15);
			        padding: 10;
			        yourself ].
	canvas addAll: rows.
	RSVerticalLineLayout new
		gapSize: 20;
		on: rows.
	canvas @ RSCanvasController.
	^ canvas
]
