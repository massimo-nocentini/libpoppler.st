Class {
	#name : #GLibLibrary,
	#superclass : #FFILibrary,
	#category : #'LibPoppler-Library'
}

{ #category : #'accessing platform' }
GLibLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: 'libglib-2.0.so'
]

{ #category : #'accessing platform' }
GLibLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary: #( 'libglib-2.0-0.dll' )
]
