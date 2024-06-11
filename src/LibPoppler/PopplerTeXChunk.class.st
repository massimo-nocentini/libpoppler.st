Class {
	#name : 'PopplerTeXChunk',
	#superclass : 'Object',
	#traits : 'TPopplerStandaloneTeXBuilder',
	#classTraits : 'TPopplerStandaloneTeXBuilder classTrait',
	#instVars : [
		'chunk'
	],
	#category : 'LibPoppler',
	#package : 'LibPoppler'
}

{ #category : 'as yet unclassified' }
PopplerTeXChunk >> asRSPangoShapeUsingFont: aFont [

	| shape texContent |
	texContent := self withStandaloneLaTeXStreamDo: [ :aStream |
		              aStream << self chunk ].

	shape := (PopplerPdf compileTeX: texContent times: 1) pages
		         ifEmpty: [ RSComposite new ]
		         ifNotEmpty: [ :pages | pages first ].

	^ shape
		  model: self;
		  asCompositeShape
]

{ #category : 'as yet unclassified' }
PopplerTeXChunk >> chunk [

	^ chunk
]

{ #category : 'as yet unclassified' }
PopplerTeXChunk >> chunk: anObject [

	chunk := anObject
]
