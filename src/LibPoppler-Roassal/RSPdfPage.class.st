"
I am a Roassal shape showing one page of a PDF: a PopplerPage drawn by poppler on the canvas's cairo context.

	shape := RSPdfPage page: ('paper.pdf' asFileReference asPdf pageAt: 1).
	shapes := 'paper.pdf' asFileReference asPdf asRoassalShapes.     ""an RSGroup, one shape per page""
	(document pageAt: 2) asRoassalShape.

My extent is the page size in PDF points (1 unit = 1 pt), taken when the page is set. Like every bounding shape I am centred on my position; the page is drawn with its top-left corner at the top-left of my encompassing rectangle. `showsBackground:` (default true) paints a white page under the PDF content, which itself paints no background.

I store only my PopplerPage (and plain values). The page reopens itself after an image restart (through its document, which re-reads its file or its kept bytes), so a canvas holding me redraws in a new session.
"
Class {
	#name : 'RSPdfPage',
	#superclass : 'RSBoundingShape',
	#instVars : [
		'page',
		'showsBackground'
	],
	#category : 'LibPoppler-Roassal',
	#package : 'LibPoppler-Roassal'
}

{ #category : 'instance creation' }
RSPdfPage class >> page: aPopplerPage [

	^ self new
		  page: aPopplerPage;
		  yourself
]

{ #category : 'visiting' }
RSPdfPage >> accept: aVisitor [

	aVisitor visitPdfPage: self
]

{ #category : 'initialization' }
RSPdfPage >> initialize [

	super initialize.
	showsBackground := true
]

{ #category : 'accessing' }
RSPdfPage >> page [
	"The PopplerPage I show."

	^ page
]

{ #category : 'accessing' }
RSPdfPage >> page: aPopplerPage [
	"Show aPopplerPage; my extent becomes its size in PDF points."

	page := aPopplerPage.
	self extent: aPopplerPage size
]

{ #category : 'accessing' }
RSPdfPage >> showsBackground [

	^ showsBackground
]

{ #category : 'accessing' }
RSPdfPage >> showsBackground: aBoolean [
	"When true (the default) a white page is painted under the PDF content."

	showsBackground := aBoolean
]
