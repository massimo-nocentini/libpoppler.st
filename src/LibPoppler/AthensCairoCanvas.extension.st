Extension { #name : 'AthensCairoCanvas' }

{ #category : '*LibPoppler' }
AthensCairoCanvas >> renderPopplerPageHandle: p ofPdfPage: s [

	s poppler_page_render: p cairo: handle
]

{ #category : '*LibPoppler' }
AthensCairoCanvas >> renderPopplerPdfPage: popplerPdfPage [

	popplerPdfPage poppler_page_render: handle
]
