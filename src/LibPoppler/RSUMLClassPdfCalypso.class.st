"
# Why

I am a variant that uses a Microdown visitor to produce a _Roassal rendering_ of the given class comment.
"
Class {
	#name : 'RSUMLClassPdfCalypso',
	#superclass : 'RSUMLClassCalypso',
	#category : 'LibPoppler-Roassal',
	#package : 'LibPoppler',
	#tag : 'Roassal'
}

{ #category : 'testing' }
RSUMLClassPdfCalypso class >> shouldBeActivatedInContext: aBrowserContext [

	^ (super shouldBeActivatedInContext: aBrowserContext) and: [
		  (aBrowserContext selectedMethods select: [ :method |
			   (method pragmas select: [ :pragma |
				    pragma selector beginsWith: #pdf ]) isNotEmpty ]) isNotEmpty ]
]

{ #category : 'building' }
RSUMLClassPdfCalypso >> buildUmlCanvas [

	| method pages pragma repo fileReference |
	method := self context selectedMethods
		          ifEmpty: [ ^ RSCanvas new ]
		          ifNotEmpty: [ :methods | methods first ].

	pragma := (method pragmaAt: #pdf:pagesPerRow:) ifNil: [
		          ^ RSCanvas new ].

	repo := IceRepository
		        atPackage: self class package
		        ifAbsent: [ ^ RSCanvas new ].

	fileReference := (pragma argumentNamed: #pdf)
		                 inject: repo repositoryDirectory
		                 into: #/.

	pages := fileReference asPdf pages
		         collect: [ :page |
			         (page notedWithPad: Float goldenRatio)
				         draggable;
				         yourself ]
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
RSUMLClassPdfCalypso >> defaultTitle [

	^ 'Pdf'
]
