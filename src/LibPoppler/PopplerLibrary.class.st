Class {
	#name : #PopplerLibrary,
	#superclass : #FFILibrary,
	#category : #'LibPoppler-Library'
}

{ #category : #'accessing platform' }
PopplerLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: 'libpoppler-glib.so'
]
