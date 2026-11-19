Extension { #name : 'AthensCairoCanvas' }

{ #category : '*LibPoppler-Roassal' }
AthensCairoCanvas >> renderPopplerPdfPage: anRSPdfPage [
	"Draw the page of anRSPdfPage (without its background) at the origin of the current Athens user space.
	Kept from the previous LibPoppler; the same as drawPopplerPage: of the shape's page."

	self drawPopplerPage: anRSPdfPage page
]
