Class {
	#name : 'PopplerTeXDisplayStyleChunk',
	#superclass : 'PopplerTeXChunk',
	#category : 'LibPoppler',
	#package : 'LibPoppler'
}

{ #category : 'as yet unclassified' }
PopplerTeXDisplayStyleChunk >> standaloneLatexFooter [

	^ ' \)' , super standaloneLatexFooter
]

{ #category : 'as yet unclassified' }
PopplerTeXDisplayStyleChunk >> standaloneLatexPreamble [

	^ super standaloneLatexPreamble , '\(\displaystyle '
]
