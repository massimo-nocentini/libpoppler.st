Extension { #name : 'FileReference' }

{ #category : '*LibPoppler' }
FileReference >> asPdf [

	^ RSPdf new
		  fileReference: self;
		  yourself
]
