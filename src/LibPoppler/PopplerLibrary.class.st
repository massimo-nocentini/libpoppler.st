Class {
	#name : 'PopplerLibrary',
	#superclass : 'FFILibrary',
	#category : 'LibPoppler-Library',
	#package : 'LibPoppler',
	#tag : 'Library'
}

{ #category : 'accessing - platform' }
PopplerLibrary >> macLibraryName [

	^ FFIMacLibraryFinder findLibrary: 'libpoppler-glib.dylib'
]

{ #category : 'accessing - platform' }
PopplerLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: 'libpoppler-glib.so'
]

{ #category : 'accessing - platform' }
PopplerLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary:
		  #( 'libpoppler-glib-8.dll' )
]
