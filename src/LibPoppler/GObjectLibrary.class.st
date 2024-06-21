Class {
	#name : 'GObjectLibrary',
	#superclass : 'FFILibrary',
	#category : 'LibPoppler-Library',
	#package : 'LibPoppler',
	#tag : 'Library'
}

{ #category : 'accessing - platform' }
GObjectLibrary >> macLibraryName [

	^ FFIMacLibraryFinder findLibrary: 'libgobject-2.0.dylib'
]

{ #category : 'accessing - platform' }
GObjectLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: 'libgobject-2.0.so'
]

{ #category : 'accessing - platform' }
GObjectLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary: #( 'libgobject-2.0-0.dll' )
]
