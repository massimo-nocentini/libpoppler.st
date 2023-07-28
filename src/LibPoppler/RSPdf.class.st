Class {
	#name : #RSPdf,
	#superclass : #RSBoundingShape,
	#instVars : [
		'fileReference',
		'pageNumber'
	],
	#category : #'LibPoppler-Roassal'
}

{ #category : #creating }
RSPdf class >> allPagesOfFileReference: fileReference [

	| p d uri shape |
	shape := self new.

	uri := shape g_filename_to_uri: fileReference fullName.

	d := shape poppler_document_new_from_file: uri.

	p := [ shape poppler_document_get_n_pages: d ] ensure: [
		     shape g_object_unref: d ].

	^ self
		  pagesOfFileReference: fileReference
		  from: 1
		  to: (p ifNil: [ 0 ])
]

{ #category : #'instance creation' }
RSPdf class >> compileTeX: texString times: iterations [

	| tmpFileName fileReference last fullName cmd |
	fileReference := FileReference newTempFilePrefix: 'RSPdf-' suffix: ''.

	fullName := fileReference fullName.

	last := fullName lastIndexOf: $/.

	tmpFileName := fullName copyFrom: last + 1 to: fullName size.

	fileReference writeStreamDo: [ :aStream |
		aStream << texString withUnixLineEndings ].

	cmd := 'xelatex -output-directory=' , fileReference parent fullName
	       , ' ' , fullName.

	iterations timesRepeat: [ LibC runCommand: cmd ].

	^ self new
		  fileReference: (fileReference fullName , '.pdf') asFileReference;
		  yourself
]

{ #category : #creating }
RSPdf class >> pagesOfFileReference: fileReference from: from to: to [

	| pages |
	pages := RSGroup new.

	from to: to do: [ :i |
		| pdf |
		pdf := self new
			       fileReference: fileReference;
			       pageNumber: i;
			       yourself.

		pages add: pdf ].

	^ pages
]

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

{ #category : #dispatched }
RSPdf >> drawOnAthensCairoCanvas: athensCairoCanvas [

	self withPopplerPageHandlerDo: [ :p |
		athensCairoCanvas renderPopplerPageHandle: p ofPdfShape: self ]
]

{ #category : #accessing }
RSPdf >> fileReference [

	^ fileReference
]

{ #category : #accessing }
RSPdf >> fileReference: anObject [

	fileReference := anObject
]

{ #category : #'ffi methods' }
RSPdf >> g_bytes_new: p size: s [

	^ self
		  ffiCall:
		  #( void #* g_bytes_new #( const void #* p #, int s ) )
		  module: GLibLibrary
]

{ #category : #'ffi methods' }
RSPdf >> g_bytes_unref: p [

	^ self
		  ffiCall: #( void g_bytes_unref #( void #* p ) )
		  module: GLibLibrary
]

{ #category : #'ffi methods' }
RSPdf >> g_filename_to_uri: absoluteFileName [

	^ self
		  ffiCall:
			  #( char #* g_filename_to_uri #( const char #* absoluteFileName
			        #, NULL #, NULL ) )
		  module: GLibLibrary
]

{ #category : #'ffi methods' }
RSPdf >> g_free: p [

	^ self ffiCall: #( void g_free #( void #* p ) ) module: GLibLibrary
]

{ #category : #'ffi methods' }
RSPdf >> g_object_unref: handle [

	self
		ffiCall: #( void g_object_unref #( void #* handle ) )
		module: GObjectLibrary
]

{ #category : #initialization }
RSPdf >> initialize [

	super initialize.

	self pageNumber: 1
]

{ #category : #accessing }
RSPdf >> pageNumber [

	^ pageNumber
]

{ #category : #accessing }
RSPdf >> pageNumber: anObject [

	pageNumber := anObject
]

{ #category : #'ffi methods' }
RSPdf >> poppler_document: document get_page: p [

	^ self
		  ffiCall:
		  #( void #* poppler_document_get_page #( void #* document #, int
		        p ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdf >> poppler_document_get_n_pages: document [

	^ self
		  ffiCall:
		  #( int poppler_document_get_n_pages #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdf >> poppler_document_new_from_bytes: bytes [

	^ self
		  ffiCall: #( void #* poppler_document_new_from_bytes
			     #( void #* bytes #, NULL #, NULL ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdf >> poppler_document_new_from_file: uri [

	^ self
		  ffiCall: #( void #* poppler_document_new_from_file
			     #( const char #* uri #, NULL #, NULL ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdf >> poppler_page_get_size: p width: width height: height [

	^ self
		  ffiCall:
			  #( void poppler_page_get_size #( void #* p #, double #* width
			        #, double #* height ) )
		  module: PopplerLibrary
]

{ #category : #'ffi methods' }
RSPdf >> poppler_page_render: p cairo: cr [

	^ self
		  ffiCall:
		  #( void poppler_page_render #( void #* p #, void #* cr ) )
		  module: PopplerLibrary
]

{ #category : #accessing }
RSPdf >> withPopplerPageHandlerDo: block [

	| p d bytes gbytes |
	"uri := self g_filename_to_uri: self fileReference fullName.

	d := self poppler_document_new_from_file: uri."
	bytes := self fileReference binaryReadStreamDo: #contents.

	gbytes := self g_bytes_new: bytes size: bytes size.

	d := self poppler_document_new_from_bytes: gbytes.

	p := self poppler_document: d get_page: self pageNumber - 1.

	[ block value: p ] ensure: [
		self
			g_object_unref: p;
			g_object_unref: d;
			g_bytes_unref: gbytes ]
]
