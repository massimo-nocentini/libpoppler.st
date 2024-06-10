"
# RSPdf class

I am a class that allows the visualization of pdfs directly into Pharo.

Consider to add the following visiting message for slot descriptions:

```
visitRSPdf: pdf

	^ {
		  (self newSlotDescriptorSelector: #author).
		  (self newSlotDescriptorSelector: #title).
		  (self newSlotDescriptorSelector: #pages) }
```
"
Class {
	#name : 'PopplerPdf',
	#superclass : 'Object',
	#traits : 'TExternalAddressHolder',
	#classTraits : 'TExternalAddressHolder classTrait',
	#instVars : [
		'fileReference',
		'author',
		'title',
		'pages'
	],
	#category : 'LibPoppler-Roassal',
	#package : 'LibPoppler',
	#tag : 'Roassal'
}

{ #category : 'instance creation' }
PopplerPdf class >> compile: texCompilerName TeX: texString times: iterations [

	| tmpFileName fileReference last fullName cmd stream |
	fileReference := FileReference newTempFilePrefix: 'RSPdf-' suffix: ''.

	fullName := fileReference fullName.

	last := fullName lastIndexOf: $/.

	tmpFileName := fullName copyFrom: last + 1 to: fullName size.

	fileReference writeStreamDo: [ :aStream |
		aStream << texString withUnixLineEndings ].

	cmd := texCompilerName , ' -halt-on-error -output-directory='
	       , fileReference parent fullName , ' ' , fullName.

	stream := Smalltalk tools transcript.

	iterations timesRepeat: [
		self libc pipe: cmd writeStream: stream.

		stream flush ].

	^ (fileReference fullName , '.pdf') asFileReference asPdf
]

{ #category : 'instance creation' }
PopplerPdf class >> compileTeX: texString times: iterations [

	^ self compile: self texCompilerName TeX: texString times: iterations
]

{ #category : 'finalization' }
PopplerPdf class >> deallocateHandle: anExternalAddress [

	self
		ffiCall: #( void g_object_unref #( void #* anExternalAddress ) )
		module: GObjectLibrary
]

{ #category : 'instance creation' }
PopplerPdf class >> libc [

	^ LibC uniqueInstance
]

{ #category : 'instance creation' }
PopplerPdf class >> texCompilerName [

	^ 'xelatex'
]

{ #category : 'accessing' }
PopplerPdf >> author [

	^ author
]

{ #category : 'accessing' }
PopplerPdf >> fileReference [

	^ fileReference
]

{ #category : 'accessing' }
PopplerPdf >> fileReference: anObject [

	fileReference := anObject
]

{ #category : 'ffi methods' }
PopplerPdf >> g_bytes_new: p size: s [

	^ self
		  ffiCall:
		  #( void #* g_bytes_new #( const void #* p #, int s ) )
		  module: GLibLibrary
]

{ #category : 'primitives' }
PopplerPdf >> g_bytes_unref: anExternalAddress [

	^ self
		  ffiCall: #( void g_bytes_unref #( void #* anExternalAddress ) )
		  module: GLibLibrary
]

{ #category : 'initialization' }
PopplerPdf >> load [

	(self fileReference isNotNil and: [ self fileReference exists ])
		ifTrue: [
			| bytes gbytesHandle |
			bytes := self fileReference binaryReadStreamDo: #contents.
			gbytesHandle := self g_bytes_new: bytes size: bytes size.

			handle := self poppler_document_new_from_bytes: gbytesHandle.

			author := self poppler_document_get_author: self getHandle.
			title := self poppler_document_get_title: self getHandle.

			pages := RSGroup new.
			1 to: (self poppler_document_get_n_pages: self getHandle) do: [
				:pageNumber |
				pages add: (RSPdfPage new
						 pdf: self;
						 pageNumber: pageNumber;
						 load;
						 yourself) ].

			self g_bytes_unref: gbytesHandle ]
		ifFalse: [
			Smalltalk tools transcript open.
			Error signal: 'Cannot load the desired pdf.' ]
]

{ #category : 'accessing' }
PopplerPdf >> pages [

	^ pages
]

{ #category : 'ffi methods' }
PopplerPdf >> poppler_document_get_author: document [

	^ self
		  ffiCall:
		  #( char #* poppler_document_get_author #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
PopplerPdf >> poppler_document_get_n_pages: document [

	^ self
		  ffiCall:
		  #( int poppler_document_get_n_pages #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
PopplerPdf >> poppler_document_get_title: document [

	^ self
		  ffiCall:
		  #( char #* poppler_document_get_title #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
PopplerPdf >> poppler_document_new_from_bytes: bytes [

	^ self
		  poppler_document_new_from_bytes: bytes
		  password: ExternalAddress null
		  error: ExternalAddress null
]

{ #category : 'ffi methods' }
PopplerPdf >> poppler_document_new_from_bytes: bytes password: password error: e [

	^ self
		  ffiCall: #( void #* poppler_document_new_from_bytes
			     #( void #* bytes #, const char #* password #, void #* e ) )
		  module: PopplerLibrary
]

{ #category : 'accessing' }
PopplerPdf >> title [

	^ title
]
