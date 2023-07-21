Class {
	#name : #GObjectLibrary,
	#superclass : #FFILibrary,
	#category : #'LibPoppler-Library'
}

{ #category : #'accessing - platform' }
GObjectLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: 'libgobject-2.0.so'
]

{ #category : #'accessing - platform' }
GObjectLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary: #( 'libgobject-2.0-0.dll' )
]