"
The common part of the LibPoppler tests: skipped when libpoppler-glib is not found (failed instead when `PHARO_CAIRO_STACK_EXPECT_LIBS=yes`), the instance check before anything else, and helpers for reference counts (read on raw addresses we hold a reference to), forged sessions, finalization and ink.
"
Class {
	#name : 'PopplerTestCase',
	#superclass : 'TestCase',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'testing' }
PopplerTestCase class >> isAbstract [

	^ self == PopplerTestCase
]

{ #category : 'helpers' }
PopplerTestCase >> darkPixelsOf: aForm [
	"Pixels whose red, green and blue are all below 128."

	| count |
	count := 0.
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			| v |
			v := aForm pixelValueAt: x @ y.
			((v bitShift: -16) bitAnd: 255) < 128 & (((v bitShift: -8) bitAnd: 255) < 128) & ((v bitAnd: 255) < 128)
				ifTrue: [ count := count + 1 ] ] ].
	^ count
]

{ #category : 'helpers' }
PopplerTestCase >> forge: aGLibHandle [
	"Make aGLibHandle look like an object of a previous image session."

	aGLibHandle instVarNamed: 'session' put: Object new
]

{ #category : 'helpers' }
PopplerTestCase >> formOf: aPopplerPage extent: anExtent translatedBy: aPoint printing: aBoolean [
	"A white surface of anExtent with the page drawn at aPoint (Athens translation)."

	| surface |
	surface := AthensCairoSurface extent: anExtent.
	surface drawDuring: [ :canvas |
		canvas pathTransform loadIdentity.
		canvas setPaint: Color white.
		canvas drawShape: (0 @ 0 extent: anExtent).
		canvas pathTransform translateBy: aPoint.
		aBoolean
			ifTrue: [ aPopplerPage renderForPrintingOn: canvas ]
			ifFalse: [ aPopplerPage renderOn: canvas ] ].
	^ surface asForm
]

{ #category : 'helpers' }
PopplerTestCase >> inkBoundsOf: aForm [
	"The smallest rectangle holding every pixel that is not white; nil when none."

	| left top right bottom |
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			((aForm pixelValueAt: x @ y) bitAnd: 16rFFFFFF) = 16rFFFFFF ifFalse: [
				left := left ifNil: [ x ] ifNotNil: [ left min: x ].
				right := right ifNil: [ x ] ifNotNil: [ right max: x ].
				top := top ifNil: [ y ].
				bottom := y ] ] ].
	left ifNil: [ ^ nil ].
	^ left @ top corner: right @ bottom
]

{ #category : 'helpers' }
PopplerTestCase >> refCountOf: anExternalAddress [
	"GObject.ref_count (only on an address we hold a reference to)."

	^ anExternalAddress unsignedLongAt: 9
]

{ #category : 'running' }
PopplerTestCase >> setUp [

	super setUp.
	PopplerLibrary isAvailable ifFalse: [
		GLibLibrary expectsLibraries
			ifTrue: [ self fail: 'libpoppler-glib not found' ]
			ifFalse: [ self skip: 'libpoppler-glib not found' ] ].
	"a wrong GLib instance ends in GLibInstanceMismatch here, not in a crash later"
	GLibInstanceCheck ensureLibrary: PopplerLibrary
]

{ #category : 'helpers' }
PopplerTestCase >> settle [
	"Give the finalization process (a FinalizationRegistry on P12-P15) every chance to run."

	1 to: 20 do: [ :i |
		Smalltalk garbageCollect.
		(Delay forMilliseconds: 10) wait ]
]

{ #category : 'helpers' }
PopplerTestCase >> threePageDocument [

	^ PopplerDocument fromBytes: PopplerFixtures threePagePdf
]

{ #category : 'helpers' }
PopplerTestCase >> waitUntilRefCountOf: anExternalAddress is: anInteger [

	1 to: 50 do: [ :i |
		Smalltalk garbageCollect.
		(Delay forMilliseconds: 10) wait.
		(self refCountOf: anExternalAddress) = anInteger ifTrue: [ ^ true ] ].
	^ false
]
