"
I am a poppler error (GError domain `poppler-quark`), signalled when a document cannot be opened or reopened, or when poppler answers NULL where an object was expected.

`code` is one of my class-side constants (poppler's `PopplerError` enum): `invalid` 0, `encrypted` 1, `openFile` 2, `badCatalog` 3, `damaged` 4, `signing` 5; test it with `isEncrypted`, `isDamaged`, `isInvalid`, `isOpenFile`.

- A wrong or missing password gives `isEncrypted`;
- bytes that are not a PDF `isDamaged` (or another code, never a crash);
- a file-opened document whose file vanished or changed before a reopen `isOpenFile`.
"
Class {
	#name : 'PopplerError',
	#superclass : 'GLibError',
	#category : 'LibPoppler-Errors',
	#package : 'LibPoppler',
	#tag : 'Errors'
}

{ #category : 'constants' }
PopplerError class >> badCatalog [

	^ 3
]

{ #category : 'constants' }
PopplerError class >> damaged [

	^ 4
]

{ #category : 'constants' }
PopplerError class >> domainName [

	^ 'poppler-quark'
]

{ #category : 'constants' }
PopplerError class >> encrypted [

	^ 1
]

{ #category : 'constants' }
PopplerError class >> invalid [

	^ 0
]

{ #category : 'constants' }
PopplerError class >> openFile [

	^ 2
]

{ #category : 'signalling' }
PopplerError class >> signalCode: anInteger message: aString [
	"Signal an error made on the Smalltalk side (no GError), in poppler's domain."

	^ self new
		  domain: self domainName;
		  code: anInteger;
		  signal: aString
]

{ #category : 'constants' }
PopplerError class >> signing [

	^ 5
]

{ #category : 'testing' }
PopplerError >> isDamaged [

	^ self isPopplerCode: self class damaged
]

{ #category : 'testing' }
PopplerError >> isEncrypted [

	^ self isPopplerCode: self class encrypted
]

{ #category : 'testing' }
PopplerError >> isInvalid [

	^ self isPopplerCode: self class invalid
]

{ #category : 'testing' }
PopplerError >> isOpenFile [

	^ self isPopplerCode: self class openFile
]

{ #category : 'private' }
PopplerError >> isPopplerCode: anInteger [

	^ domain = self class domainName and: [ code = anInteger ]
]
