Class {
	#name : #RSPdf,
	#superclass : #RSBoundingShape,
	#instVars : [
		'fileReference',
		'pageNumber'
	],
	#category : #'LibPoppler-Roassal'
}

{ #category : #visiting }
RSPdf >> accept: visitor [

	visitor visitPdf: self
]

{ #category : #accessing }
RSPdf >> computeEncompassingRectangle [

	| width height |
	width := ByteArray new: 8.
	height := ByteArray new: 8.

	self withPopplerPageHandlerDo: [ :popplerPageHandler |
		self
			poppler_page_get_size: popplerPageHandler
			width: width
			height: height ].

	^ Rectangle
		  center: 0 @ 0
		  extent: (width doubleAt: 1) @ (height doubleAt: 1)
]

{ #category : #accessing }
RSPdf >> fileReference [

	^ fileReference
]

{ #category : #accessing }
RSPdf >> fileReference: anObject [

	fileReference := anObject
]

{ #category : #accessing }
RSPdf >> pageNumber [

	^ pageNumber
]

{ #category : #accessing }
RSPdf >> pageNumber: anObject [

	pageNumber := anObject
]

{ #category : #accessing }
RSPdf >> withPopplerPageHandlerDo: block [

	| p d uri |
	uri := self g_filename_to_uri: self fileReference fullName.

	d := self poppler_document_new_from_file: uri.

	p := self poppler_document: d get_page: self pageNumber - 1.

	[ block value: p ] ensure: [
		self
			g_object_unref: p;
			g_object_unref: d ]
]
