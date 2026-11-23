"
I am libpoppler-glib, resolved by uFFI's finders (image directory, VM directory or bundle, then system paths) under its soname / install name / MSYS2 DLL name: the cairo stack VM bundles poppler 26.11.

Class side: `isAvailable` (the library resolves and exports `poppler_get_version`) and `versionString` (poppler's runtime version, e.g. `'26.11.0'`).

The GLib side of the bindings (strings, GBytes, GError, GObject references, finalization) is LibPangoCairo's `GLib` group (`LibGLib`, `LibGLib-Cairo`).
"
Class {
	#name : 'PopplerLibrary',
	#superclass : 'FFILibrary',
	#category : 'LibPoppler-Library',
	#package : 'LibPoppler',
	#tag : 'Library'
}

{ #category : 'testing' }
PopplerLibrary class >> isAvailable [

	^ GLibLibrary isLibrary: self providing: 'poppler_get_version'
]

{ #category : 'private - ffi' }
PopplerLibrary class >> primGetVersion [

	^ self ffiCall: #( void * poppler_get_version #( ) ) module: PopplerLibrary
]

{ #category : 'accessing' }
PopplerLibrary class >> versionString [
	"poppler's version at run time (a static string in the library)."

	^ GLibLibrary stringFromUnowned: self primGetVersion
]

{ #category : 'accessing platform' }
PopplerLibrary >> macLibraryName [

	^ FFIMacLibraryFinder findAnyLibrary: #( 'libpoppler-glib.8.dylib' 'libpoppler-glib.dylib' )
]

{ #category : 'accessing platform' }
PopplerLibrary >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findAnyLibrary: #( 'libpoppler-glib.so.8' 'libpoppler-glib.so' )
]

{ #category : 'accessing platform' }
PopplerLibrary >> win32LibraryName [

	^ FFIWindowsLibraryFinder findAnyLibrary: #( 'libpoppler-glib-8.dll' )
]
