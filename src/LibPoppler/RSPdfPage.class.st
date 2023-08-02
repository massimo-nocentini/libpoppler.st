Class {
	#name : #RSPdfPage,
	#superclass : #RSBoundingShape,
	#instVars : [
		'pdf',
		'pageNumber'
	],
	#category : #'LibPoppler-Roassal'
}

{ #category : #visiting }
RSPdfPage >> accept: visitor [

	visitor visitPdfPage: self
]

{ #category : #accessing }
RSPdfPage >> computeEncompassingRectangle [

	| width height |
	width := ByteArray new: 8.
	height := ByteArray new: 8.

	self withPopplerPageHandleDo: [ :popplerPageHandler |
		self
			poppler_page_get_size: popplerPageHandler
			width: width
			height: height ].

	^ Rectangle
		  center: 0 @ 0
		  extent: (width doubleAt: 1) @ (height doubleAt: 1)
]

{ #category : #dispatched }
RSPdfPage >> drawOnAthensCairoCanvas: athensCairoCanvas [

	self withPopplerPageHandleDo: [ :pageHandle |
		athensCairoCanvas
			renderPopplerPageHandle: pageHandle
			ofPdfPage: self ]
]

{ #category : #initialization }
RSPdfPage >> initialize [

	super initialize.

	self pageNumber: 1
]

{ #category : #accessing }
RSPdfPage >> pageNumber: anObject [

	pageNumber := anObject
]

{ #category : #accessing }
RSPdfPage >> pdf: anObject [

	pdf := anObject
]

{ #category : #'ffi methods' }
RSPdfPage >> poppler_document: document get_page: p [

	^ self
		  ffiCall:
		  #( void #* poppler_document_get_page #( void #* document #, int
		        p ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdfPage >> poppler_page_get_size: p width: width height: height [

	^ self
		  ffiCall:
			  #( void poppler_page_get_size #( void #* p #, double #* width
			        #, double #* height ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdfPage >> poppler_page_render: p cairo: cr [

	^ self
		  ffiCall:
		  #( void poppler_page_render #( void #* p #, void #* cr ) )
		  module: PopplerLibrary
]

{ #category : #accessing }
RSPdfPage >> withPopplerPageHandleDo: block [

	pdf withPopplerDocumentHandleDo: [ :d |
		| pageHandle |
		pageHandle := self poppler_document: d get_page: pageNumber - 1.

		[ block value: pageHandle ] ensure: [
			pdf g_object_unref: pageHandle ] ]
]
