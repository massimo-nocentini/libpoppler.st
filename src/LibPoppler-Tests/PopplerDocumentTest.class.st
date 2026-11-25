"
`PopplerDocument`: opening from bytes and files, metadata, pages and labels, errors, passwords, reopening after a (forged) restart, finalization, `release`, copies, and the stale-object choke point.
"
Class {
	#name : 'PopplerDocumentTest',
	#superclass : 'PopplerTestCase',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'helpers' }
PopplerDocumentTest >> assertReopens: aGLibHandle on: aSelector [
	"aGLibHandle, forged into a previous session, reopens transparently when sent aSelector; the abandoned
	reference is neither dropped nor finalized, so the test drops it, exactly once."

	| old |
	old := aGLibHandle validHandle copy.
	self forge: aGLibHandle.
	self stalePerform: aSelector on: aGLibHandle.
	self assert: aGLibHandle isValid description: aSelector , ' did not reopen'.
	self deny: aGLibHandle validHandle asInteger equals: old asInteger.
	GObjectLibrary unref: old
]

{ #category : 'helpers' }
PopplerDocumentTest >> stalePerform: aSelector on: anObject [

	(#( #renderOn: #renderForPrintingOn: ) includes: aSelector) ifTrue: [
		^ (AthensCairoSurface extent: 8 @ 8) drawDuring: [ :canvas | anObject perform: aSelector with: canvas ] ].
	aSelector numArgs = 0 ifTrue: [ ^ anObject perform: aSelector ].
	^ anObject perform: aSelector with: ((Dictionary newFrom: {
				   (#pageAt: -> 1).
				   (#pageLabeled: -> 'ii').
				   (#pagesDo: -> [ :page | page ]).
				   (#asFormScale: -> 0.1) }) at: aSelector)
]

{ #category : 'helpers' }
PopplerDocumentTest >> temporaryFileDuring: aBlock [

	| file |
	file := FileLocator temp asFileReference / ('poppler-test-' , UUID new asString , '.pdf').
	^ [ aBlock value: file ] ensure: [ file ensureDelete ]
]

{ #category : 'tests - pages' }
PopplerDocumentTest >> testCopyOfAPageTakesAReference [

	| document page address count copy |
	document := self threePageDocument.
	page := document pageAt: 1.
	address := page validHandle copy.
	count := self refCountOf: address.
	copy := page copy.
	self assert: (self refCountOf: address) equals: count + 1.
	self deny: copy == page.
	self assert: copy index equals: 1.
	self assert: copy document identicalTo: document.
	self assert: (copy text includesSubstring: 'Hello Poppler 1').
	copy release.
	self assert: (self refCountOf: address) equals: count.
	self assert: page isValid
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testCopyOfADocumentKeepsThePassword [

	| document copy |
	document := PopplerDocument
		            fromBytes: (PopplerFixtures encryptedPdfUser: 'pharo' owner: 'owner')
		            password: 'pharo'.
	copy := document copy.
	self deny: copy == document.
	self assert: copy validHandle asInteger equals: document validHandle asInteger.
	self assert: (PopplerDocument passwordFor: copy) equals: 'pharo'.
	self assert: ((copy pageAt: 1) text includesSubstring: 'Secret').
	self deny: (copy pageAt: 1) == (document pageAt: 1)
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testEmptyAndGarbageBytesSignal [

	self should: [ PopplerDocument fromBytes: #[  ] ] raise: PopplerError.
	self should: [ PopplerDocument fromBytes: (ByteArray new: 1000 withAll: 65) ] raise: PopplerError.
	self
		should: [ PopplerDocument fromBytes: '%PDF-1.4 this is not a PDF' asByteArray ]
		raise: PopplerError
		withExceptionDo: [ :e | self assert: e domain equals: 'poppler-quark' ]
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testEncrypted [

	| bytes document |
	bytes := PopplerFixtures encryptedPdfUser: 'pharo' owner: 'owner'.
	self
		should: [ PopplerDocument fromBytes: bytes ]
		raise: PopplerError
		withExceptionDo: [ :e |
			self assert: e isEncrypted.
			self assert: e code equals: PopplerError encrypted ].
	self
		should: [ PopplerDocument fromBytes: bytes password: 'wrong' ]
		raise: PopplerError
		withExceptionDo: [ :e | self assert: e isEncrypted ].
	document := PopplerDocument fromBytes: bytes password: 'pharo'.
	self assert: document pageCount equals: 1.
	self assert: ((document pageAt: 1) text includesSubstring: 'Secret').
	document := PopplerDocument fromBytes: bytes password: 'owner'.
	self assert: ((document pageAt: 1) text includesSubstring: 'Secret')
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testEncryptedReopenNeedsThePasswordAfterShutDown [

	| document old |
	document := PopplerDocument
		            fromBytes: (PopplerFixtures encryptedPdfUser: 'pharo' owner: 'owner')
		            password: 'pharo'.
	old := document validHandle copy.
	self forge: document.
	self assert: document pageCount equals: 1.
	GObjectLibrary unref: old.
	"as before a snapshot: the passwords are forgotten"
	PopplerDocument shutDown: false.
	self assert: (PopplerDocument passwordFor: document) isNil.
	old := document validHandle copy.
	self forge: document.
	self should: [ document pageCount ] raise: PopplerError withExceptionDo: [ :e | self assert: e isEncrypted ].
	GObjectLibrary unref: old.
	self should: [ document title ] raise: PopplerError.
	document password: 'pharo'.
	self assert: document pageCount equals: 1.
	self assert: document isValid.
	self assert: ((document pageAt: 1) text includesSubstring: 'Secret')
]

{ #category : 'tests - memory' }
PopplerDocumentTest >> testFinalizationOfADocumentAndItsPage [

	| document page documentAddress pageAddress |
	document := self threePageDocument.
	page := document pageAt: 1.
	documentAddress := document validHandle copy.
	pageAddress := page validHandle copy.
	GObjectLibrary ref: documentAddress.
	GObjectLibrary ref: pageAddress.
	self assert: (self refCountOf: documentAddress) equals: 3.
	self assert: (self refCountOf: pageAddress) equals: 2.
	document := nil.
	page := nil.
	[
	self assert: (self waitUntilRefCountOf: pageAddress is: 1).
	"ours and the page's"
	self assert: (self waitUntilRefCountOf: documentAddress is: 2) ] ensure: [ GObjectLibrary unref: pageAddress ].
	self assert: (self refCountOf: documentAddress) equals: 1.
	GObjectLibrary unref: documentAddress
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testFontconfigIsANoOpOffMacOS [

	OSPlatform current isMacOS ifTrue: [ ^ self skip: 'macOS configures the bundled fontconfig' ].
	PopplerFontconfig ensureConfigured.
	self assert: (PopplerFontconfig instVarNamed: 'libraryPath') isNil
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testFromBytes [

	| bytes document |
	bytes := PopplerFixtures threePagePdf.
	document := PopplerDocument fromBytes: bytes.
	self assert: document pageCount equals: 3.
	self assert: document isOwned.
	"the document keeps its own copy"
	bytes atAllPut: 0.
	self assert: document pageCount equals: 3
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testFromFile [

	self temporaryFileDuring: [ :file |
		file binaryWriteStreamDo: [ :stream | stream nextPutAll: PopplerFixtures threePagePdf ].
		self assert: (PopplerDocument fromFile: file) pageCount equals: 3.
		self assert: (PopplerDocument fromFile: file fullName) pageCount equals: 3.
		self assert: file asPdf pageCount equals: 3.
		self assert: (file asPdf pageAt: 2) label equals: 'ii' ]
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testInstanceCheckPasses [

	GLibInstanceCheck reset.
	GLibInstanceCheck ensureLibrary: PopplerLibrary.
	GLibInstanceCheck ensureSameCairoAs: PopplerLibrary
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testLibraryResolves [

	| vmDirectory |
	self assert: PopplerLibrary isAvailable.
	vmDirectory := Smalltalk vm directory asFileReference.
	(vmDirectory children anySatisfy: [ :each | each basename beginsWith: 'libpoppler-glib' ]) ifTrue: [
		self
			assert: PopplerLibrary uniqueInstance libraryName asFileReference parent fullName
			equals: vmDirectory fullName ]
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testMissingFileSignals [

	self
		should: [ PopplerDocument fromFile: FileLocator temp asFileReference / ('no-such-' , UUID new asString , '.pdf') ]
		raise: PopplerError
		withExceptionDo: [ :e | self assert: e isOpenFile ]
]

{ #category : 'tests - pages' }
PopplerDocumentTest >> testPageAtIsCachedAndChecked [

	| document visited |
	document := self threePageDocument.
	self assert: (document pageAt: 1) identicalTo: (document pageAt: 1).
	self assert: (document pageAt: 3) index equals: 3.
	self assert: document pages size equals: 3.
	self assert: document pages first identicalTo: (document pageAt: 1).
	visited := OrderedCollection new.
	document pagesDo: [ :each | visited add: each index ].
	self assert: visited asArray equals: #( 1 2 3 ).
	self should: [ document pageAt: 0 ] raise: SubscriptOutOfBounds.
	self should: [ document pageAt: 4 ] raise: SubscriptOutOfBounds.
	self should: [ document pageAt: 'x' ] raise: SubscriptOutOfBounds
]

{ #category : 'tests - pages' }
PopplerDocumentTest >> testPageLabeled [

	| document address count |
	document := self threePageDocument.
	self assert: (document pageLabeled: 'ii') identicalTo: (document pageAt: 2).
	self assert: (document pageLabeled: 'i') identicalTo: (document pageAt: 1).
	self assert: (document pageLabeled: 'A-1') index equals: 3.
	self assert: (document pageLabeled: 'no such label') isNil.
	"the temporary page of the lookup is released at once"
	address := document validHandle copy.
	count := self refCountOf: address.
	document pageLabeled: 'A-1'.
	document pageLabeled: 'missing'.
	self assert: (self refCountOf: address) equals: count
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testPasswordsAreForgottenAtShutDown [

	| document |
	self assert: (SessionManager default hasRegistered: #PopplerDocument).
	document := PopplerDocument
		            fromBytes: (PopplerFixtures encryptedPdfUser: 'pharo' owner: 'owner')
		            password: 'pharo'.
	self assert: (PopplerDocument passwordFor: document) equals: 'pharo'.
	PopplerDocument shutDown: false.
	self assert: (PopplerDocument passwordFor: document) isNil.
	"the open document is still usable in this session"
	self assert: ((document pageAt: 1) text includesSubstring: 'Secret').
	document password: 'pharo'.
	self assert: (PopplerDocument passwordFor: document) equals: 'pharo'.
	document password: nil.
	self assert: (PopplerDocument passwordFor: document) isNil
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testStartUpKeepsTheExternalAddresses [
	"The assertion on the method comes first: the inherited one would null the addresses of the whole image"

	| address |
	self assert: (PopplerDocument class lookupSelector: #startUp:) methodClass equals: PopplerDocument class.
	address := ExternalAddress fromAddress: 16r1234.
	PopplerDocument startUp: true.
	self deny: address isNull
]

{ #category : 'tests - memory' }
PopplerDocumentTest >> testRelease [

	| document page documentAddress pageAddress |
	document := self threePageDocument.
	page := document pageAt: 1.
	documentAddress := document validHandle copy.
	pageAddress := page validHandle copy.
	GObjectLibrary ref: documentAddress.
	GObjectLibrary ref: pageAddress.
	page release.
	self assert: (self refCountOf: pageAddress) equals: 1.
	page release.
	self assert: (self refCountOf: pageAddress) equals: 1.
	self should: [ page text ] raise: GLibStaleObject.
	"the document makes a new page object for a released one"
	self deny: (document pageAt: 1) == page.
	self assert: ((document pageAt: 1) text includesSubstring: 'Hello Poppler 1').
	"wrapper, old page, new page, ours"
	self assert: (self refCountOf: documentAddress) equals: 4.
	document release.
	self assert: (self refCountOf: documentAddress) equals: 3.
	self should: [ document pageCount ] raise: GLibStaleObject.
	"the finalizers of released wrappers do nothing"
	page := nil.
	document := nil.
	self settle.
	self assert: (self refCountOf: pageAddress) equals: 1.
	GObjectLibrary unref: pageAddress.
	self assert: (self waitUntilRefCountOf: documentAddress is: 1).
	GObjectLibrary unref: documentAddress
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testReleasedObjectsSignalStale [

	| document page |
	document := self threePageDocument.
	page := document pageAt: 1.
	page release.
	PopplerPage staleCheckSelectors do: [ :each |
		self should: [ self stalePerform: each on: page ] raise: GLibStaleObject ].
	document release.
	PopplerDocument staleCheckSelectors do: [ :each |
		self should: [ self stalePerform: each on: document ] raise: GLibStaleObject ]
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testReopenFromBytes [
	"After a (forged) restart the document and its page reopen; the old references are forgotten: not unref'd,
	not finalized. The test drops each of them exactly once."

	| document page oldDocument oldPage |
	document := self threePageDocument.
	page := document pageAt: 1.
	oldDocument := document validHandle copy.
	oldPage := page validHandle copy.
	GObjectLibrary ref: oldDocument.
	GObjectLibrary ref: oldPage.
	self forge: document.
	self forge: page.
	self deny: document isValid.
	self deny: page isValid.
	self assert: document pageCount equals: 3.
	self assert: document isValid.
	self assert: (document pageAt: 1) identicalTo: page.
	self assert: (page text includesSubstring: 'Hello Poppler 1').
	self assert: page isValid.
	self deny: document validHandle asInteger equals: oldDocument asInteger.
	self deny: page validHandle asInteger equals: oldPage asInteger.
	"wrapper (abandoned), page (abandoned), ours"
	self assert: (self refCountOf: oldDocument) equals: 3.
	self assert: (self refCountOf: oldPage) equals: 2.
	document := nil.
	page := nil.
	self settle.
	self assert: (self refCountOf: oldDocument) equals: 3.
	self assert: (self refCountOf: oldPage) equals: 2.
	GObjectLibrary unref: oldPage.
	GObjectLibrary unref: oldDocument.
	self assert: (self refCountOf: oldPage) equals: 1.
	self assert: (self refCountOf: oldDocument) equals: 2.
	GObjectLibrary unref: oldPage.
	self assert: (self refCountOf: oldDocument) equals: 1.
	GObjectLibrary unref: oldDocument
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testReopenFromFile [

	self temporaryFileDuring: [ :file |
		| document old |
		file binaryWriteStreamDo: [ :stream | stream nextPutAll: PopplerFixtures threePagePdf ].
		document := PopplerDocument fromFile: file.
		old := document validHandle copy.
		self forge: document.
		self assert: (document pageAt: 2) label equals: 'ii'.
		GObjectLibrary unref: old.
		"the file changed: no reopen"
		old := document validHandle copy.
		file ensureDelete.
		file binaryWriteStreamDo: [ :stream | stream nextPutAll: PopplerFixtures base14Pdf ].
		self forge: document.
		self should: [ document pageCount ] raise: PopplerError withExceptionDo: [ :e | self assert: e isOpenFile ].
		GObjectLibrary unref: old.
		"the file vanished"
		file ensureDelete.
		self should: [ document pageCount ] raise: PopplerError withExceptionDo: [ :e | self assert: e isOpenFile ] ]
]

{ #category : 'tests - sessions' }
PopplerDocumentTest >> testStaleSelectorsReopen [
	"The choke point: every public selector reaching C reopens a document or page of a previous session."

	| document page |
	self assert: (PopplerDocument staleCheckSelectors includesAll:
			 #( #author #title #pageCount #pageAt: #pageLabeled: #pages #pagesDo: #refCount )).
	self deny: (PopplerDocument staleCheckSelectors includes: #password:).
	self assert: (PopplerPage staleCheckSelectors includesAll:
			 #( #size #width #height #label #text #renderOn: #renderForPrintingOn: #asFormScale: #refCount )).
	self deny: (PopplerPage staleCheckSelectors includes: #index).
	document := self threePageDocument.
	page := document pageAt: 1.
	PopplerDocument staleCheckSelectors do: [ :each | self assertReopens: document on: each ].
	PopplerPage staleCheckSelectors do: [ :each | self assertReopens: page on: each ]
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testTitleAndAuthor [

	| document |
	document := self threePageDocument.
	self assert: document title equals: 'Pharo ✓ Poppler'.
	self assert: document author equals: 'Pharo'.
	self assert: (PopplerDocument fromBytes: PopplerFixtures base14Pdf) title isNil
]

{ #category : 'tests - opening' }
PopplerDocumentTest >> testVersion [

	| version expected |
	version := PopplerLibrary versionString.
	self assert: (version matchesRegex: '\d+\.\d+\.\d+').
	expected := OSEnvironment current at: 'POPPLER_EXPECT_VERSION' ifAbsent: [ '' ].
	expected ifNotEmpty: [ self assert: version equals: expected ]
]
