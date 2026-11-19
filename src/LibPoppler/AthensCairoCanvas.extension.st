Extension { #name : 'AthensCairoCanvas' }

{ #category : '*LibPoppler' }
AthensCairoCanvas >> drawPopplerPage: aPopplerPage [
	"Render aPopplerPage with its top-left corner at the origin of the current Athens user space, 1 unit = 1 PDF point.
	No background is painted. The cairo state Athens (and the CairoPlugin) rely on is restored afterwards."

	GLibInstanceCheck ensureSameCairoAs: PopplerLibrary.
	self cairoSavedDo: [ aPopplerPage primRender: aPopplerPage validHandle on: self handle ]
]

{ #category : '*LibPoppler' }
AthensCairoCanvas >> drawPopplerPageForPrinting: aPopplerPage [
	"As drawPopplerPage:, with poppler's printing flags (annotations as printed, no forms highlighting)."

	GLibInstanceCheck ensureSameCairoAs: PopplerLibrary.
	self cairoSavedDo: [ aPopplerPage primRenderForPrinting: aPopplerPage validHandle on: self handle ]
]
