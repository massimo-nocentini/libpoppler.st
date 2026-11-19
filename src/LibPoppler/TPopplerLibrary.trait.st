"
I bind my users' callouts (`ffiCall:` without `module:`) to PopplerLibrary, on both sides.
"
Trait {
	#name : 'TPopplerLibrary',
	#category : 'LibPoppler-Library',
	#package : 'LibPoppler',
	#tag : 'Library'
}

{ #category : 'library path' }
TPopplerLibrary classSide >> ffiLibraryName [

	^ PopplerLibrary
]

{ #category : 'library path' }
TPopplerLibrary >> ffiLibraryName [

	^ self class ffiLibraryName
]
