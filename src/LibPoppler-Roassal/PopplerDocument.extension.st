Extension { #name : 'PopplerDocument' }

{ #category : '*LibPoppler-Roassal' }
PopplerDocument >> asRoassalShapes [
	"An RSGroup with one RSPdfPage per page, in page order (each with its PopplerPage as model)."

	^ RSGroup withAll: (self pages collect: [ :each | each asRoassalShape ])
]
