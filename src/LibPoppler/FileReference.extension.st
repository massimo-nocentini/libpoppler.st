Extension { #name : 'FileReference' }

{ #category : '*LibPoppler' }
FileReference >> asPdf [

	^ PopplerPdf new
		  fileReference: self;
		  yourself
]
