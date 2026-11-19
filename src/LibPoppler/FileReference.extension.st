Extension { #name : 'FileReference' }

{ #category : '*LibPoppler' }
FileReference >> asPdf [
	"The PDF document in this file (a PopplerDocument; its pages are PopplerPages)."

	^ PopplerDocument fromFile: self
]
