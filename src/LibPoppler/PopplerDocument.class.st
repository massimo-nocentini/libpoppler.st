"
I am a PDF document opened by poppler-glib (a PopplerDocument GObject), always from bytes: `fromFile:` reads the whole file in Smalltalk and nothing ever reaches GIO.

	doc := PopplerDocument fromFile: 'paper.pdf'.        ""or: 'paper.pdf' asFileReference asPdf""
	doc := PopplerDocument fromBytes: aByteArray password: 'secret'.
	doc pageCount.  doc title.  doc author.
	(doc pageAt: 1) text.  (doc pageLabeled: 'ii') index.
	doc pagesDo: [ :page | ... ].

Pages are PopplerPages, made lazily by `pageAt:` (1-based; SubscriptOutOfBounds outside 1..pageCount) and cached, so `pageAt:` and `pageLabeled:` answer the same object for the same page. `title` and `author` answer nil when the PDF has none.

Errors: a document that cannot be opened signals PopplerError (`isEncrypted` for a missing or wrong password, `isDamaged`/`isInvalid` for bytes that are not a PDF), never a crash.

Memory: the GObject is unref'd when I am collected, or at once by `release`. Pages hold a reference on their document in C, so the order in which they are collected does not matter.

Image restarts: unlike Pango objects, I survive a restart. In a new session the first use reopens me: from the same file when I was opened from one (I keep the FileReference, its size and modification time, never its bytes; PopplerError `isOpenFile` when it vanished or changed), else from the bytes I keep. The old pointer is forgotten, never unref'd. My pages reopen the same way through me.
Passwords are kept for the current session only, in a class-side weak dictionary that `shutDown:` empties (I am registered with the SessionManager), so a password is never written into a snapshot. After a restart an encrypted document signals PopplerError `isEncrypted` until it is given its password again with `password:`.
"
Class {
	#name : 'PopplerDocument',
	#superclass : 'GLibObject',
	#traits : 'TPopplerLibrary',
	#classTraits : 'TPopplerLibrary classTrait',
	#instVars : [
		'file',
		'fileStamp',
		'bytes',
		'pages'
	],
	#classInstVars : [
		'passwords'
	],
	#category : 'LibPoppler-Document',
	#package : 'LibPoppler',
	#tag : 'Document'
}

{ #category : 'instance creation' }
PopplerDocument class >> fromBytes: aByteArray [

	^ self fromBytes: aByteArray password: nil
]

{ #category : 'instance creation' }
PopplerDocument class >> fromBytes: aByteArray password: aStringOrNil [
	"Open the PDF in aByteArray (copied: I keep the copy to reopen after a restart)."

	| kept document |
	kept := aByteArray asByteArray copy.
	document := self fromOwnedHandle: (self openBytes: kept password: aStringOrNil).
	document setBytes: kept.
	self password: aStringOrNil for: document.
	^ document
]

{ #category : 'instance creation' }
PopplerDocument class >> fromFile: aFileReferenceOrString [

	^ self fromFile: aFileReferenceOrString password: nil
]

{ #category : 'instance creation' }
PopplerDocument class >> fromFile: aFileReferenceOrString password: aStringOrNil [
	"Open the PDF file (read whole in Smalltalk; I keep the reference, not the bytes, to reopen after a restart)."

	| reference stamp document |
	reference := aFileReferenceOrString asFileReference.
	stamp := self stampOf: reference.
	document := self fromOwnedHandle: (self openBytes: (self read: reference) password: aStringOrNil).
	document setFile: reference stamp: stamp.
	self password: aStringOrNil for: document.
	^ document
]

{ #category : 'testing' }
PopplerDocument class >> handleFreeSelectors [

	^ super handleFreeSelectors , #( #password: )
]

{ #category : 'class initialization' }
PopplerDocument class >> initialize [
	"shutDown: forgets the passwords before every snapshot."

	(SessionManager default hasRegistered: self name) ifFalse: [
		SessionManager default registerUserClassNamed: self name ]
]

{ #category : 'private' }
PopplerDocument class >> openBytes: aByteArray password: aStringOrNil [
	"Answer the owned address of a new PopplerDocument for aByteArray, or signal PopplerError."

	| address |
	GLibInstanceCheck ensureLibrary: PopplerLibrary.
	PopplerFontconfig ensureConfigured.
	address := GLibBytes on: aByteArray do: [ :gbytes |
		           PopplerError signalAfter: [ :errorSlot |
			           self
				           primNewFromBytes: gbytes validHandle
				           password: (aStringOrNil
						            ifNil: [ ExternalAddress null ]
						            ifNotNil: [ GLibLibrary utf8Z: aStringOrNil ])
				           error: errorSlot ] ].
	(address isNil or: [ address isNull ]) ifTrue: [
		PopplerError signalCode: PopplerError invalid message: 'poppler_document_new_from_bytes answered NULL' ].
	^ address
]

{ #category : 'private - passwords' }
PopplerDocument class >> password: aStringOrNil for: aDocument [

	aStringOrNil ifNil: [
		passwords ifNotNil: [ passwords removeKey: aDocument ifAbsent: [  ] ].
		^ self ].
	passwords ifNil: [ passwords := WeakIdentityKeyDictionary new ].
	passwords at: aDocument put: aStringOrNil
]

{ #category : 'private - passwords' }
PopplerDocument class >> passwordFor: aDocument [

	passwords ifNil: [ ^ nil ].
	^ passwords at: aDocument ifAbsent: [ nil ]
]

{ #category : 'private - ffi' }
PopplerDocument class >> primNewFromBytes: aGBytes password: aPassword error: anErrorSlot [

	^ self ffiCall: #( void * poppler_document_new_from_bytes #( void * aGBytes , void * aPassword , void * anErrorSlot ) )
]

{ #category : 'private' }
PopplerDocument class >> read: aFileReference [

	^ [ aFileReference binaryReadStreamDo: [ :stream | stream upToEnd ] ]
		  on: FileSystemError
		  do: [ :e |
			  PopplerError
				  signalCode: PopplerError openFile
				  message: 'cannot read ' , aFileReference fullName , ': ' , e messageText asString ]
]

{ #category : 'system startup' }
PopplerDocument class >> shutDown: quitting [
	"Passwords never reach a snapshot: after a restart an encrypted document needs password: again."

	passwords := nil
]

{ #category : 'private' }
PopplerDocument class >> stampOf: aFileReference [
	"Size and modification time of the file (a reopen refuses a file that changed)."

	aFileReference isFile ifFalse: [
		PopplerError signalCode: PopplerError openFile message: 'no such file: ' , aFileReference fullName ].
	^ Array with: aFileReference size with: aFileReference modificationTime
]

{ #category : 'accessing' }
PopplerDocument >> author [
	"The document's author (from its Info dictionary or XMP), nil when absent."

	^ GLibLibrary stringFromOwned: (self primGetAuthor: self validHandle)
]

{ #category : 'copying' }
PopplerDocument >> copy [
	"A copy takes its own reference, and the password of this session."

	| theCopy |
	theCopy := super copy.
	self class password: (self class passwordFor: self) for: theCopy.
	^ theCopy
]

{ #category : 'validity' }
PopplerDocument >> ensureValid [
	"Released in this session: GLibStaleObject. From a previous session: reopen (see the class comment)."

	self isValid ifTrue: [ ^ self ].
	session == Smalltalk session ifTrue: [ ^ GLibStaleObject signalFor: self ].
	self reopen
]

{ #category : 'accessing' }
PopplerDocument >> pageAt: anInteger [
	"The page of index anInteger (1-based), made once and cached."

	| count page |
	count := self pageCount.
	(anInteger isInteger and: [ anInteger between: 1 and: count ]) ifFalse: [
		^ SubscriptOutOfBounds signalFor: anInteger lowerBound: 1 upperBound: count in: self ].
	(pages isNil or: [ pages size ~= count ]) ifTrue: [ pages := Array new: count ].
	page := pages at: anInteger.
	(page isNil or: [ page isReleased ]) ifTrue: [
		page := PopplerPage document: self index: anInteger address: (self pageAddressAt: anInteger).
		pages at: anInteger put: page ].
	^ page
]

{ #category : 'accessing' }
PopplerDocument >> pageCount [

	^ self primGetNPages: self validHandle
]

{ #category : 'accessing' }
PopplerDocument >> pageLabeled: aString [
	"The page whose label (e.g. 'iv', 'A-1') is aString, the same object as pageAt: answers; nil when none."

	| address index |
	address := self primGetPageByLabel: self validHandle label: (GLibLibrary utf8Z: aString).
	(address isNil or: [ address isNull ]) ifTrue: [ ^ nil ].
	index := [ PopplerPage primGetIndex: address ] ensure: [ GObjectLibrary unref: address ].
	^ self pageAt: index + 1
]

{ #category : 'accessing' }
PopplerDocument >> pages [

	^ (1 to: self pageCount) collect: [ :each | self pageAt: each ]
]

{ #category : 'enumerating' }
PopplerDocument >> pagesDo: aBlock [

	1 to: self pageCount do: [ :each | aBlock value: (self pageAt: each) ]
]

{ #category : 'accessing' }
PopplerDocument >> password: aString [
	"Supply the password again (after a restart, before the reopen of an encrypted document). Kept for this session only."

	self class password: aString for: self
]

{ #category : 'copying' }
PopplerDocument >> postCopy [

	super postCopy.
	pages := nil
]

{ #category : 'private' }
PopplerDocument >> pageAddressAt: anInteger [
	"An owned address of page anInteger (1-based, in range)."

	| address |
	address := self primGetPage: self validHandle index: anInteger - 1.
	(address isNil or: [ address isNull ]) ifTrue: [
		PopplerError
			signalCode: PopplerError invalid
			message: 'poppler_document_get_page answered NULL for page ' , anInteger printString ].
	^ address
]

{ #category : 'private - ffi' }
PopplerDocument >> primGetAuthor: aDocument [

	^ self ffiCall: #( void * poppler_document_get_author #( void * aDocument ) )
]

{ #category : 'private - ffi' }
PopplerDocument >> primGetNPages: aDocument [

	^ self ffiCall: #( int poppler_document_get_n_pages #( void * aDocument ) )
]

{ #category : 'private - ffi' }
PopplerDocument >> primGetPage: aDocument index: anInteger [

	^ self ffiCall: #( void * poppler_document_get_page #( void * aDocument , int anInteger ) )
]

{ #category : 'private - ffi' }
PopplerDocument >> primGetPageByLabel: aDocument label: aByteArray [

	^ self ffiCall: #( void * poppler_document_get_page_by_label #( void * aDocument , void * aByteArray ) )
]

{ #category : 'private - ffi' }
PopplerDocument >> primGetTitle: aDocument [

	^ self ffiCall: #( void * poppler_document_get_title #( void * aDocument ) )
]

{ #category : 'private - reopen' }
PopplerDocument >> reopen [
	"A previous session's pointer is meaningless: forget it (its cell is cleared, so nothing unrefs it) and open again."

	| contents |
	cell ifNotNil: [ cell clear ].
	handle := ExternalAddress null.
	(file isNil and: [ bytes isNil ]) ifTrue: [ ^ GLibStaleObject signalFor: self ].
	contents := file
		            ifNil: [ bytes ]
		            ifNotNil: [
			            (self class stampOf: file) = fileStamp ifFalse: [
				            PopplerError
					            signalCode: PopplerError openFile
					            message: file fullName , ' changed since it was opened' ].
			            self class read: file ].
	self reopenWithOwnedHandle: (self class openBytes: contents password: (self class passwordFor: self))
]

{ #category : 'private' }
PopplerDocument >> setBytes: aByteArray [

	bytes := aByteArray
]

{ #category : 'private' }
PopplerDocument >> setFile: aFileReference stamp: anArray [

	file := aFileReference.
	fileStamp := anArray
]

{ #category : 'accessing' }
PopplerDocument >> title [
	"The document's title (from its Info dictionary or XMP), nil when absent."

	^ GLibLibrary stringFromOwned: (self primGetTitle: self validHandle)
]
