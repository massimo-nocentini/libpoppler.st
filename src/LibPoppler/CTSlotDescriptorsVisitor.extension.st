Extension { #name : 'CTSlotDescriptorsVisitor' }

{ #category : '*LibPoppler' }
CTSlotDescriptorsVisitor >> visitRSPdf: pdf [

	^ {
		  (self newSlotDescriptorSelector: #author).
		  (self newSlotDescriptorSelector: #title).
		  (self newSlotDescriptorSelector: #pages) }
]
