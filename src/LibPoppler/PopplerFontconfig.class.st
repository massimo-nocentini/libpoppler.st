"
On macOS the cairo stack bundles a fontconfig built for poppler only, with no system configuration file: poppler needs one to substitute the base-14 fonts (non-embedded Helvetica, Times ...). `ensureConfigured`, sent before the first document of every session, loads the bundle's `Contents/Resources/fontconfig/fonts.conf` into poppler's fontconfig (FcConfigCreate, FcConfigParseAndLoad, FcConfigSetCurrent, then FcConfigDestroy of our reference).

Both files are located from PopplerLibrary's resolved path (`Contents/MacOS/Plugins/libpoppler-glib.8.dylib`): the fontconfig library is `libfontconfig.1.dylib` next to it (the file poppler's `@rpath` resolves to, so dyld answers the image already loaded) and the configuration `../../Resources/fontconfig/fonts.conf` from there. The four callouts use `ffiCall:module:` with that absolute path.

A no-op on Linux and Windows (the system's or the bundle's configuration is found by fontconfig itself), when `FONTCONFIG_FILE` is set, or when the configuration file does not exist (a poppler not from the bundle).
"
Class {
	#name : 'PopplerFontconfig',
	#superclass : 'Object',
	#classInstVars : [
		'session',
		'libraryPath'
	],
	#category : 'LibPoppler-Library',
	#package : 'LibPoppler',
	#tag : 'Library'
}

{ #category : 'private' }
PopplerFontconfig class >> configure: aConfigurationFile library: aLibraryPath [
	"Make aConfigurationFile the current configuration of the fontconfig at aLibraryPath. Answer whether it was applied."

	| config ok |
	aConfigurationFile isFile ifFalse: [ ^ false ].
	libraryPath := aLibraryPath.
	config := self primConfigCreate.
	(config isNil or: [ config isNull ]) ifTrue: [ ^ false ].
	ok := false.
	[
	ok := (self primConfig: config parseAndLoad: (GLibLibrary utf8Z: aConfigurationFile fullName) complain: 1) ~= 0.
	ok ifTrue: [ ok := (self primConfigSetCurrent: config) ~= 0 ] ] ensure: [ self primConfigDestroy: config ].
	^ ok
]

{ #category : 'accessing' }
PopplerFontconfig class >> configurationFileNextTo: aLibraryPath [
	"<bundle>/Contents/MacOS/Plugins/<lib> -> <bundle>/Contents/Resources/fontconfig/fonts.conf"

	^ aLibraryPath asFileReference parent parent parent / 'Resources' / 'fontconfig' / 'fonts.conf'
]

{ #category : 'configuring' }
PopplerFontconfig class >> ensureConfigured [
	"Once per session, before the first document (macOS only)."

	| popplerPath |
	OSPlatform current isMacOS ifFalse: [ ^ self ].
	session == Smalltalk session ifTrue: [ ^ self ].
	session := Smalltalk session.
	(OSEnvironment current at: 'FONTCONFIG_FILE' ifAbsent: [ '' ]) isEmpty ifFalse: [ ^ self ].
	popplerPath := PopplerLibrary uniqueInstance libraryName.
	self
		configure: (self configurationFileNextTo: popplerPath)
		library: (self fontconfigLibraryNextTo: popplerPath)
]

{ #category : 'accessing' }
PopplerFontconfig class >> fontconfigLibraryNextTo: aLibraryPath [

	^ (aLibraryPath asFileReference parent / 'libfontconfig.1.dylib') fullName
]

{ #category : 'private - ffi' }
PopplerFontconfig class >> primConfig: aConfig parseAndLoad: aByteArray complain: anInteger [

	^ self
		  ffiCall: #( int FcConfigParseAndLoad #( void * aConfig , void * aByteArray , int anInteger ) )
		  module: libraryPath
]

{ #category : 'private - ffi' }
PopplerFontconfig class >> primConfigCreate [

	^ self ffiCall: #( void * FcConfigCreate #( ) ) module: libraryPath
]

{ #category : 'private - ffi' }
PopplerFontconfig class >> primConfigDestroy: aConfig [

	^ self ffiCall: #( void FcConfigDestroy #( void * aConfig ) ) module: libraryPath
]

{ #category : 'private - ffi' }
PopplerFontconfig class >> primConfigSetCurrent: aConfig [

	^ self ffiCall: #( int FcConfigSetCurrent #( void * aConfig ) ) module: libraryPath
]
