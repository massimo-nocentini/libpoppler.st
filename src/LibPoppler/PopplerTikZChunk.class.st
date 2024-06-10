Class {
	#name : 'PopplerTikZChunk',
	#superclass : 'Object',
	#traits : 'TPopplerStandaloneTeXBuilder',
	#classTraits : 'TPopplerStandaloneTeXBuilder classTrait',
	#instVars : [
		'chunk'
	],
	#category : 'LibPoppler',
	#package : 'LibPoppler'
}

{ #category : 'accessing' }
PopplerTikZChunk >> asRSPangoShapeUsingFont: aFont [

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

{ #category : 'accessing' }
PopplerTikZChunk >> chunk [

	^ chunk
]

{ #category : 'accessing' }
PopplerTikZChunk >> chunk: anObject [

	chunk := anObject
]

{ #category : 'enumerating' }
PopplerTikZChunk >> standaloneLatexFooter [

	^ '
\end{document}'
]

{ #category : 'enumerating' }
PopplerTikZChunk >> standaloneLatexPreamble [
	"https://tex.stackexchange.com/questions/353943/how-to-paste-a-mathematica-formula-to-the-latex-unicode-included"

	^ '\documentclass[12pt]{standalone}
\usepackage{mathtools}
\usepackage{concrete}
\usepackage{euler}
\usepackage{amssymb}
\usepackage[T1]{fontenc}
\usepackage{fontspec}
\usepackage{tikz}
\usepackage{pgfplots}
\newfontfamily{\mathematicamono}{MathematicaMono}
\ExplSyntaxOn
\NewDocumentCommand{\mmono}{m}
 {
  \text{\mathematicamono#1}
 }
\NewDocumentCommand{\unicode}{m}
 {
  \mmono { \symbol { \int_from_hex:n { #1 } } }
 }
\ExplSyntaxOff
\begin{document}
'
]
