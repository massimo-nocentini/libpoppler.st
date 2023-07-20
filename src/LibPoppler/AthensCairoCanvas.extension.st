Extension { #name : #AthensCairoCanvas }

{ #category : #'*LibPoppler' }
AthensCairoCanvas >> renderPopplerPageHandle: p ofPdfShape: s [

	s poppler_page_render: p cairo: handle
]
