Class {
	#name : 'GLibLibrary',
	#superclass : 'FFILibrary',
	#category : 'LibPoppler-Library',
	#package : 'LibPoppler',
	#tag : 'Library'
}

{ #category : 'accessing - platform' }
GLibLibrary >> macLibraryName [

	^ FFIMacLibraryFinder findLibrary: 'libglib-2.0.dylib'
]

{ #category : 'accessing platform' }
GLibLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: 'libglib-2.0.so'
]

{ #category : 'accessing platform' }
GLibLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary: #( 'libglib-2.0-0.dll' )
]
