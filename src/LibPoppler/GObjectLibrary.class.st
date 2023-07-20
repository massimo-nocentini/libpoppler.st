Class {
	#name : #GObjectLibrary,
	#superclass : #FFILibrary,
	#category : #'LibPoppler-Library'
}

{ #category : #'accessing - platform' }
GObjectLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary: #( 'libgobject-2.0-0.dll' )
]
