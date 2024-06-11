Class {
	#name : 'PopplerTikZChunk',
	#superclass : 'PopplerTeXChunk',
	#category : 'LibPoppler',
	#package : 'LibPoppler'
}

{ #category : 'enumerating' }
PopplerTikZChunk >> texPackagesExtra [

	^ { '{tikz}'. '{pgfplots}' }
]
