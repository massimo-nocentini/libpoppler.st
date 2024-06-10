Trait {
	#name : 'TPopplerStandaloneTeXBuilder',
	#category : 'LibPoppler',
	#package : 'LibPoppler'
}

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> standaloneLatexFooter [

	^ ' \)
\end{document}'
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> standaloneLatexPreamble [
	"https://tex.stackexchange.com/questions/353943/how-to-paste-a-mathematica-formula-to-the-latex-unicode-included"

	^ '\documentclass[12pt]{standalone}
\usepackage{mathtools}
\usepackage{concrete}
\usepackage{euler}
\usepackage{amssymb}
\usepackage[T1]{fontenc}
\usepackage{fontspec}
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
\(\displaystyle '
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> withStandaloneLaTeXStreamDo: block [

	^ String streamContents: [ :aStream |
		  aStream << self standaloneLatexPreamble.
		  block value: aStream.
		  aStream << self standaloneLatexFooter ]
]
