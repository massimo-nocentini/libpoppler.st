Extension { #name : 'AthensCairoCanvas' }

{ #category : '*LibPoppler' }
AthensCairoCanvas >> renderPopplerPageHandle: p ofPdfPage: s [

	s poppler_page_render: p cairo: handle
]
