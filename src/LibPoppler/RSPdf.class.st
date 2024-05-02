"
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
	#name : 'RSPdf',
	#superclass : 'Object',
	#instVars : [
		'fileReference'
	],
	#category : 'LibPoppler-Roassal',
	#package : 'LibPoppler',
	#tag : 'Roassal'
}

{ #category : 'instance creation' }
RSPdf class >> compile: texCompilerName TeX: texString times: iterations [

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

	^ self new
		  fileReference: (fileReference fullName , '.pdf') asFileReference;
		  yourself
]

{ #category : 'instance creation' }
RSPdf class >> compileTeX: texString times: iterations [

	^ self compile: self texCompilerName TeX: texString times: iterations
]

{ #category : 'instance creation' }
RSPdf class >> libc [

	^ LibC uniqueInstance
]

{ #category : 'instance creation' }
RSPdf class >> texCompilerName [

	^ 'xelatex'
]

{ #category : 'accessing' }
RSPdf >> author [

	| author |
	author := String empty.

	self withPopplerDocumentHandleDo: [ :docHandle |
		author := self poppler_document_get_author: docHandle ].

	^ author
]

{ #category : 'accessing' }
RSPdf >> fileReference [

	^ fileReference
]

{ #category : 'accessing' }
RSPdf >> fileReference: anObject [

	fileReference := anObject
]

{ #category : 'ffi methods' }
RSPdf >> g_bytes_new: p size: s [

	^ self
		  ffiCall:
		  #( void #* g_bytes_new #( const void #* p #, int s ) )
		  module: GLibLibrary
]

{ #category : 'ffi methods' }
RSPdf >> g_bytes_unref: p [

	^ self
		  ffiCall: #( void g_bytes_unref #( void #* p ) )
		  module: GLibLibrary
]

{ #category : 'ffi methods' }
RSPdf >> g_filename_to_uri: absoluteFileName [

	^ self
		  ffiCall:
			  #( char #* g_filename_to_uri #( const char #* absoluteFileName
			        #, NULL #, NULL ) )
		  module: GLibLibrary
]

{ #category : 'ffi methods' }
RSPdf >> g_free: p [

	^ self ffiCall: #( void g_free #( void #* p ) ) module: GLibLibrary
]

{ #category : 'ffi methods' }
RSPdf >> g_object_unref: handle [

	self
		ffiCall: #( void g_object_unref #( void #* handle ) )
		module: GObjectLibrary
]

{ #category : 'accessing' }
RSPdf >> pages [

	| group |
	group := RSGroup new.

	self withPopplerDocumentHandleDo: [ :docHandle |
		1 to: (self poppler_document_get_n_pages: docHandle) do: [
			:pageNumber |
			| pageShape |
			pageShape := RSPdfPage new
				             pdf: self;
				             pageNumber: pageNumber;
				             yourself.

			group add: pageShape ] ].

	^ group
]

{ #category : 'ffi methods' }
RSPdf >> poppler_document_get_author: document [

	^ self
		  ffiCall:
		  #( char #* poppler_document_get_author #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
RSPdf >> poppler_document_get_n_pages: document [

	^ self
		  ffiCall:
		  #( int poppler_document_get_n_pages #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
RSPdf >> poppler_document_get_title: document [

	^ self
		  ffiCall:
		  #( char #* poppler_document_get_title #( void #* document ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
RSPdf >> poppler_document_new_from_bytes: bytes [

	^ self
		  poppler_document_new_from_bytes: bytes
		  password: nil
		  error: ExternalAddress null
]

{ #category : 'ffi methods' }
RSPdf >> poppler_document_new_from_bytes: bytes password: password error: e [

	^ self
		  ffiCall: #( void #* poppler_document_new_from_bytes
			     #( void #* bytes #, const char #* password #, void #* e ) )
		  module: PopplerLibrary
]

{ #category : 'ffi methods' }
RSPdf >> poppler_document_new_from_file: uri [

	^ self
		  ffiCall: #( void #* poppler_document_new_from_file
			     #( const char #* uri #, NULL #, NULL ) )
		  module: PopplerLibrary
]

{ #category : 'accessing' }
RSPdf >> title [

	| title |
	title := String empty.

	self withPopplerDocumentHandleDo: [ :docHandle |
		title := self poppler_document_get_title: docHandle ].

	^ title
]

{ #category : 'accessing' }
RSPdf >> withPopplerDocumentHandleDo: block [

	| d bytes gbytes |
	bytes := self fileReference exists
		         ifTrue: [ self fileReference binaryReadStreamDo: #contents ]
		         ifFalse: [
			         Smalltalk tools transcript open.
			         ^ self ].

	gbytes := self g_bytes_new: bytes size: bytes size.

	d := self poppler_document_new_from_bytes: gbytes.

	[ block value: d ] ensure: [
		self
			g_object_unref: d;
			g_bytes_unref: gbytes ]
]
