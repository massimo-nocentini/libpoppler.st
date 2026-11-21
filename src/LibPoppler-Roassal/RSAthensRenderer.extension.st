Extension { #name : 'RSAthensRenderer' }

{ #category : '*LibPoppler-Roassal' }
RSAthensRenderer >> visitPdfPage: aShape [
	"As the stock visitLabel:: the shape matrix is already in the renderer's matrix (visitShapeIfNecessary:block:);
	move the origin to the shape's top-left corner, load the matrix (with the renderer's scale where the image has one)
	into the Athens path transform and let poppler draw there, 1 unit = 1 PDF point.
	A shape without a page (RSPdfPage new, as Roassal's generic shape tests make it) draws only its background."

	self visitShapeIfNecessary: aShape block: [
		| offset |
		offset := (aShape extent / -2) asFloatPoint.
		matrix translateBy: offset.
		self pathTransformLoadMatrix.
		aShape showsBackground ifTrue: [
			athensCanvas
				setPaint: Color white;
				drawShape: (0 @ 0 extent: aShape extent) ].
		aShape page ifNotNil: [ :page | athensCanvas drawPopplerPage: page ].
		athensCanvas pathTransform translateBy: offset negated.
		self showEncompassingRectangleIfNecessary: aShape.
		aShape isDirty: false ]
]
