Extension { #name : 'FileReference' }

{ #category : '*LibPoppler' }
FileReference >> asPdf [

	^ PopplerPdf new
		  fileReference: self;
		  load;
		  yourself
]
