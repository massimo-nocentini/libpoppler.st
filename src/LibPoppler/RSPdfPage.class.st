Class {
	#name : 'RSPdfPage',
	#superclass : 'RSBoundingShape',
	#traits : 'TExternalAddressHolder',
	#classTraits : 'TExternalAddressHolder classTrait',
	#instVars : [
		'pdf',
		'pageNumber'
	],
	#category : 'LibPoppler-Roassal',
	#package : 'LibPoppler',
	#tag : 'Roassal'
}

{ #category : 'finalization' }
RSPdfPage class >> deallocateHandle: anExternalAddress [

	self
		ffiCall: #( void g_object_unref #( void #* anExternalAddress ) )
		module: GObjectLibrary
]

{ #category : 'visiting' }
RSPdfPage >> accept: visitor [

	visitor visitPdfPage: self
]

{ #category : 'initialization' }
RSPdfPage >> initialize [

	super initialize.

	self pageNumber: 1
]

{ #category : 'accessing' }
RSPdfPage >> load [

	| width height |
	handle := self
		          poppler_document: pdf getHandle
		          get_page: pageNumber - 1.

	width := ByteArray new: 8.
	height := ByteArray new: 8.

	self
		poppler_page_get_size: self getHandle
		width: width
		height: height.

	baseRectangle := Rectangle extentCenteredAtCartesianOrigin:
		                 (width doubleAt: 1) @ (height doubleAt: 1).

	self addToTheResourceManager
]

{ #category : 'accessing' }
RSPdfPage >> pageNumber: anObject [

	pageNumber := anObject
]

{ #category : 'accessing' }
RSPdfPage >> pdf: anObject [

	pdf := anObject
]

{ #category : 'ffi methods' }
RSPdfPage >> poppler_document: document get_page: p [

	^ self
		  ffiCall:
		  #( void #* poppler_document_get_page #( void #* document #, int
		        p ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
RSPdfPage >> poppler_page_get_size: p width: w height: h [

	^ self
		  ffiCall:
			  #( void poppler_page_get_size #( void #* p #, double #* w #, double
			        #* h ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
RSPdfPage >> poppler_page_render: cr [

	^ self poppler_page_render: self getHandle cairo: cr
]

{ #category : 'ffi methods' }
RSPdfPage >> poppler_page_render: p cairo: cr [

	^ self
		  ffiCall:
		  #( void poppler_page_render #( void #* p #, void #* cr ) )
		  module: PopplerLibrary
]
