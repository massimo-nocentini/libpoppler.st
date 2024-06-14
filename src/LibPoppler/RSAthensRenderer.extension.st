Extension { #name : 'RSAthensRenderer' }

{ #category : '*LibPoppler' }
RSAthensRenderer >> visitPdfPage: pdfShape [

	| lbtranslation |
	lbtranslation := pdfShape extent halvedAsFloat negated.

	matrix translateBy: lbtranslation.

	athensCanvas pathTransform loadAffineTransform: matrix.
	athensCanvas setPathMatrix.

	athensCanvas renderPopplerPdfPage: pdfShape
]
