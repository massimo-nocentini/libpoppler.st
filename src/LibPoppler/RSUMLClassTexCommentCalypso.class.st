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

{ #category : 'accessing - comment' }
RSUMLClassTexCommentCalypso class >> beamerTeXString [

	<tex: 'pdflatex' times: 2 pagesPerRow: 1>
	'
\documentclass{beamer}
%Information to be included in the title page:
\title{Sample title}
\author{Anonymous}
\institute{Overleaf}
\date{2021}

\begin{document}

\frame{\titlepage}

\begin{frame}
\frametitle{Sample frame title}
This is some text in the first frame. This is some text in the first frame. This is some text in the first frame.
\end{frame}

\end{document}
'
]

{ #category : 'accessing - comment' }
RSUMLClassTexCommentCalypso class >> shortDocumentTeXString [

	<tex: 'pdflatex' times: 2 pagesPerRow: 2>
	'
\documentclass[12pt, letterpaper]{article}
\title{My first LaTeX document}
\author{Hubert Farnsworth\thanks{Funded by the Overleaf team.}}
\date{August 2022}
\begin{document}
\maketitle
We have now added a title, author and date 
\newpage
to our first \LaTeX{} document!
\end{document}
	'
]

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
