Extension { #name : 'RSAthensRenderer' }

{ #category : '*LibPoppler' }
RSAthensRenderer >> visitPdfPage: pdfShape [

	self
		visitShape: pdfShape
		withScaledMatrixDo: [ athensCanvas renderPopplerPdfPage: pdfShape ]
]
