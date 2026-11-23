"
`PopplerPage`: sizes, labels, indexes and text of the fixtures.
"
Class {
	#name : 'PopplerPageTest',
	#superclass : 'PopplerTestCase',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'tests' }
PopplerPageTest >> testBase14Text [

	| page |
	page := (PopplerDocument fromBytes: PopplerFixtures base14Pdf) pageAt: 1.
	self assert: (page text includesSubstring: 'Base14 Pharo').
	self assert: page size equals: 200.0 @ 50.0
]

{ #category : 'tests' }
PopplerPageTest >> testIndexesAndDocument [

	| document |
	document := self threePageDocument.
	1 to: 3 do: [ :each |
		self assert: (document pageAt: each) index equals: each.
		self assert: (document pageAt: each) document identicalTo: document ]
]

{ #category : 'tests' }
PopplerPageTest >> testLabels [

	| document |
	document := self threePageDocument.
	self assert: (document pages collect: [ :each | each label ]) equals: #( 'i' 'ii' 'A-1' ).
	"no page labels in the document: poppler answers the page number"
	self assert: ((PopplerDocument fromBytes: PopplerFixtures jpegPdf) pageAt: 1) label equals: '1'
]

{ #category : 'tests' }
PopplerPageTest >> testSizes [

	| document expected |
	document := self threePageDocument.
	expected := { (595.28 @ 841.89). (612 @ 792). (300 @ 200) }.
	expected withIndexDo: [ :size :n |
		| page |
		page := document pageAt: n.
		self assert: page size x isFloat.
		self assert: (page size x - size x) abs < 0.01.
		self assert: (page size y - size y) abs < 0.01.
		self assert: (page width - size x) abs < 0.01.
		self assert: (page height - size y) abs < 0.01 ]
]

{ #category : 'tests' }
PopplerPageTest >> testText [

	| document first |
	document := self threePageDocument.
	first := (document pageAt: 1) text.
	self assert: (first includesSubstring: 'Hello Poppler 1').
	self assert: (first includesSubstring: 'Grüße €').
	self assert: ((document pageAt: 2) text includesSubstring: 'Hello Poppler 2').
	self assert: ((document pageAt: 3) text includesSubstring: 'Hello Poppler 3').
	self deny: ((document pageAt: 3) text includesSubstring: 'Grüße')
]
