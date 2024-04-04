"
# Why

I am a variant that uses a Microdown visitor to produce a _Roassal rendering_ of the given class comment.
"
Class {
	#name : 'RSUMLClassTexCommentCalypso',
	#superclass : 'RSUMLClassCalypso',
	#category : 'LibPoppler-Roassal',
	#package : 'LibPoppler',
	#tag : 'Roassal'
}

{ #category : 'testing' }
RSUMLClassTexCommentCalypso class >> shouldBeActivatedInContext: aBrowserContext [

	^ (super shouldBeActivatedInContext: aBrowserContext) and: [
		  (aBrowserContext selectedMethods select: [ :method |
			   (method pragmas select: [ :pragma |
				    pragma selector beginsWith: #tex ]) isNotEmpty ]) isNotEmpty ]
]

{ #category : 'building' }
RSUMLClassTexCommentCalypso >> buildUmlCanvas [

	| pdf method tex pages pragma |
	method := self context selectedMethods
		          ifEmpty: [ ^ RSCanvas new ]
		          ifNotEmpty: [ :methods | methods first ].

	pragma := (method pragmaAt: #tex:times:pagesPerRow:) ifNil: [
		          ^ RSCanvas new ].

	tex := (Character cr join:
		        (method sourceNode body statements collect: [ :each |
			         each value ])) ifEmpty: [ ^ RSCanvas new ].

	pdf := RSPdf
		       compile: (pragma argumentNamed: #tex)
		       TeX: tex
		       times: (pragma argumentNamed: #times).

	pages := pdf pages
		         collect: [ :page | page notedWithPad: Float goldenRatio ]
		         as: RSGroup.

	RSGridLayout new
		lineItemsCount: (pragma argumentNamed: #pagesPerRow:);
		on: pages.

	^ RSCanvas new
		  useRTree;
		  @ RSCanvasController;
		  addAll: pages;
		  yourself
]

{ #category : 'initialization' }
RSUMLClassTexCommentCalypso >> defaultTitle [

	^ 'TeX'
]
