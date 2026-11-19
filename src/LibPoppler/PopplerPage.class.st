"
I am one page of a PopplerDocument (a PopplerPage GObject), made by `PopplerDocument>>pageAt:` (and cached there).

	page size.          ""a Point of Floats in PDF points (1/72 in)""
	page label.         ""the page label ('iv', 'A-1'); the page number ('3') when the PDF defines no labels""
	page text.          ""the page's text, UTF-8 decoded""
	page asFormScale: 2.
	anAthensCairoCanvas drawPopplerPage: page.     ""= page renderOn: anAthensCairoCanvas""

Rendering draws the page with its top-left corner at the origin of the canvas's current Athens user space, 1 unit = 1 PDF point, without painting a background; `asFormScale:` paints a white page into a new surface first.

I hold a reference on my document in C. After an image restart I am refetched from my document (which reopens itself) by my index; `release` drops my reference at once (the document then answers a new page object from `pageAt:`).
"
Class {
	#name : 'PopplerPage',
	#superclass : 'GLibObject',
	#traits : 'TPopplerLibrary',
	#classTraits : 'TPopplerLibrary classTrait',
	#instVars : [
		'document',
		'index'
	],
	#category : 'LibPoppler-Document',
	#package : 'LibPoppler',
	#tag : 'Document'
}

{ #category : 'private' }
PopplerPage class >> document: aPopplerDocument index: anInteger address: anExternalAddress [

	^ (self fromOwnedHandle: anExternalAddress) setDocument: aPopplerDocument index: anInteger
]

{ #category : 'testing' }
PopplerPage class >> handleFreeSelectors [

	^ super handleFreeSelectors , #( #document #index )
]

{ #category : 'private - ffi' }
PopplerPage class >> primGetIndex: aPage [

	^ self ffiCall: #( int poppler_page_get_index #( void * aPage ) )
]

{ #category : 'converting' }
PopplerPage >> asFormScale: aNumber [
	"A Form of the page on a white background, aNumber pixels per PDF point."

	| extent surface |
	extent := ((self size * aNumber) ceiling) max: 1 @ 1.
	surface := AthensCairoSurface extent: extent.
	surface drawDuring: [ :canvas |
		canvas pathTransform loadIdentity.
		canvas setPaint: Color white.
		canvas drawShape: (0 @ 0 extent: extent).
		canvas pathTransform scaleBy: aNumber.
		self renderOn: canvas ].
	^ surface asForm
]

{ #category : 'accessing' }
PopplerPage >> document [

	^ document
]

{ #category : 'validity' }
PopplerPage >> ensureValid [
	"Released in this session: GLibStaleObject. From a previous session: refetched from the document by index."

	self isValid ifTrue: [ ^ self ].
	session == Smalltalk session ifTrue: [ ^ GLibStaleObject signalFor: self ].
	cell ifNotNil: [ cell clear ].
	handle := ExternalAddress null.
	self reopenWithOwnedHandle: (document pageAddressAt: index)
]

{ #category : 'accessing' }
PopplerPage >> height [

	^ self size y
]

{ #category : 'accessing' }
PopplerPage >> index [
	"1-based."

	^ index
]

{ #category : 'private' }
PopplerPage >> isReleased [
	"Released in this session (the document then makes a new page object)."

	^ session == Smalltalk session and: [ self isValid not ]
]

{ #category : 'accessing' }
PopplerPage >> label [
	"The page label; poppler answers the page number ('3') when the document defines no labels."

	^ GLibLibrary stringFromOwned: (self primGetLabel: self validHandle)
]

{ #category : 'private - ffi' }
PopplerPage >> primGetLabel: aPage [

	^ self ffiCall: #( void * poppler_page_get_label #( void * aPage ) )
]

{ #category : 'private - ffi' }
PopplerPage >> primGetSize: aPage width: aWidthBuffer height: aHeightBuffer [

	^ self ffiCall: #( void poppler_page_get_size #( void * aPage , void * aWidthBuffer , void * aHeightBuffer ) )
]

{ #category : 'private - ffi' }
PopplerPage >> primGetText: aPage [

	^ self ffiCall: #( void * poppler_page_get_text #( void * aPage ) )
]

{ #category : 'private - ffi' }
PopplerPage >> primRender: aPage on: aCairo [

	^ self ffiCall: #( void poppler_page_render #( void * aPage , void * aCairo ) )
]

{ #category : 'private - ffi' }
PopplerPage >> primRenderForPrinting: aPage on: aCairo [

	^ self ffiCall: #( void poppler_page_render_for_printing #( void * aPage , void * aCairo ) )
]

{ #category : 'printing' }
PopplerPage >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: ' page ';
		print: index
]

{ #category : 'rendering' }
PopplerPage >> renderForPrintingOn: anAthensCairoCanvas [

	anAthensCairoCanvas drawPopplerPageForPrinting: self
]

{ #category : 'rendering' }
PopplerPage >> renderOn: anAthensCairoCanvas [

	anAthensCairoCanvas drawPopplerPage: self
]

{ #category : 'private' }
PopplerPage >> setDocument: aPopplerDocument index: anInteger [

	document := aPopplerDocument.
	index := anInteger
]

{ #category : 'accessing' }
PopplerPage >> size [
	"Width @ height in PDF points (Floats)."

	| width height |
	width := ByteArray new: 8.
	height := ByteArray new: 8.
	self primGetSize: self validHandle width: width height: height.
	^ (width doubleAt: 1) @ (height doubleAt: 1)
]

{ #category : 'accessing' }
PopplerPage >> text [
	"The page's text (UTF-8 from poppler, decoded leniently)."

	^ GLibLibrary stringFromOwned: (self primGetText: self validHandle)
]

{ #category : 'accessing' }
PopplerPage >> width [

	^ self size x
]
