Extension { #name : #RSAthensRenderer }

{ #category : #'*LibPoppler' }
RSAthensRenderer >> visitPdfPage: pdfShape [

	| lbtranslation |
	lbtranslation := (pdfShape extent / 2.0) asFloatPoint negated.

	matrix translateBy: lbtranslation.

	athensCanvas pathTransform loadAffineTransform: matrix.
	athensCanvas setPathMatrix.

	pdfShape drawOnAthensCairoCanvas: athensCanvas
]
