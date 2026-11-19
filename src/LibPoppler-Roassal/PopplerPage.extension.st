Extension { #name : 'PopplerPage' }

{ #category : '*LibPoppler-Roassal' }
PopplerPage >> asRoassalShape [
	"An RSPdfPage showing me, with me as its model."

	^ (RSPdfPage page: self)
		  model: self;
		  yourself
]
