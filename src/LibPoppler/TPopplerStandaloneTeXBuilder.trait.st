Trait {
	#name : 'TPopplerStandaloneTeXBuilder',
	#instVars : [
		'commaSeparatedDocClassOptionsString'
	],
	#category : 'LibPoppler',
	#package : 'LibPoppler'
}

{ #category : 'accessing' }
TPopplerStandaloneTeXBuilder >> commaSeparatedDocClassOptionsString [

	^ commaSeparatedDocClassOptionsString
]

{ #category : 'accessing' }
TPopplerStandaloneTeXBuilder >> commaSeparatedDocClassOptionsString: anObject [

	commaSeparatedDocClassOptionsString := anObject
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> standaloneLatexFooter [

	^ '
\end{document}'
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> standaloneLatexPreamble [
	"https://tex.stackexchange.com/questions/353943/how-to-paste-a-mathematica-formula-to-the-latex-unicode-included"

	^ String streamContents: [ :stream |
		  stream
			  << '\documentclass[';
			  << self commaSeparatedDocClassOptionsString;
			  << ']{standalone}';
			  cr.

		  self texPackages do: [ :packageName |
			  stream
				  << '\usepackage';
				  << packageName;
				  cr ].

		  stream << '\newfontfamily{\mathematicamono}{MathematicaMono}
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
' ]
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> texPackages [

	^ { '{mathtools}'. '{concrete}'. '{euler}'. '{amssymb}'. '[T1]{fontenc}'.
	  '{fontspec}' } , self texPackagesExtra
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> texPackagesExtra [

	^ {  }
]

{ #category : 'enumerating' }
TPopplerStandaloneTeXBuilder >> withStandaloneLaTeXStreamDo: block [

	^ String streamContents: [ :aStream |
		  aStream << self standaloneLatexPreamble.
		  block value: aStream.
		  aStream << self standaloneLatexFooter ]
]
