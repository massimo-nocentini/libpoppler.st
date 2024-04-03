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
		  aBrowserContext lastSelectedClass texComment isNotEmpty ]
]

{ #category : 'accessing - comment' }
RSUMLClassTexCommentCalypso class >> texComment [

	^ '
\documentclass[12pt, letterpaper]{article}
\title{My first LaTeX document}
\author{Hubert Farnsworth\thanks{Funded by the Overleaf team.}}
\date{August 2022}
\begin{document}
\maketitle
We have now added a title, author and date to our first \LaTeX{} document!
\end{document}
	'
]

{ #category : 'building' }
RSUMLClassTexCommentCalypso >> buildUmlCanvas [

	| walker shape pages |
	walker := CTDfsWalker new.

	pages := (RSPdf compileTeX: self class texComment times: 2) pages.

	shape := pages asShapeSlotsDfsTree: walker.

	^ RSCanvas new
		  useRTree;
		  @ RSCanvasController;
		  " add: shape;"addAll:
			  (pages collect: [ :each | each notedWithPad: Float goldenRatio ]);
		  yourself
]

{ #category : 'initialization' }
RSUMLClassTexCommentCalypso >> defaultTitle [

	^ 'TeX Comment'
]
