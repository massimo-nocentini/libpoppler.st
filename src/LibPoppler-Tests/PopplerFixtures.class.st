"
I make the PDFs of the tests at test time (no binary fixture in the repository), on my class side:

- `threePagePdf`: written by cairo's PDF surface (cairo FFI with `module: CairoLibrary`, to a temp file read back and deleted): page sizes 595.28x841.89, 612x792 and 300x200, page labels `'i'` `'ii'` `'A-1'`, title `'Pharo ✓ Poppler'`, author `'Pharo'`, toy text `'Hello Poppler <n>'` on each page and `'Grüße €'` on page 1 (sans-serif 24);
- `jpegPdf`: one 64x64 page painting, at `16@16`, a 32x32 image surface that carries `redJpeg` as its `CAIRO_MIME_TYPE_JPEG` data, so the PDF embeds the JPEG (DCTDecode) and poppler decodes it with libjpeg-turbo. The mime data lives in `ExternalAddress allocate:` memory freed only after the image surface is destroyed;
- `encryptedPdfUser: 'pharo' owner: 'owner'`: a one-page PDF written here, encrypted with the Standard security handler V2 R3, 128-bit RC4, P = -4 (PDF 1.7, 7.6.3, Algorithms 1, 2, 3 and 5; MD5 from the image, RC4 in `rc4:data:`), with a trailer `/ID`; its page shows `'Secret'` in non-embedded Helvetica;
- `base14Pdf`: a hand-written one-page PDF (about 450 bytes, correct xref) with the text `'Base14 Pharo'` in non-embedded `/Type1` Helvetica: poppler must substitute the font through fontconfig.

`redJpeg` is a fixed 32x32 baseline JPEG of solid `#C00000` (646 bytes), made once with the libjpeg-turbo 3.2.1 of the cairo stack prototype and checked to decode to exactly that colour.
"
Class {
	#name : 'PopplerFixtures',
	#superclass : 'Object',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'fixtures' }
PopplerFixtures class >> base14Pdf [

	| text |
	text := 'BT /F1 18 Tf 10 20 Td (Base14 Pharo) Tj ET'.
	^ self
		  pdfWithObjects: {
				  '<< /Type /Catalog /Pages 2 0 R >>'.
				  '<< /Type /Pages /Kids [3 0 R] /Count 1 >>'.
				  '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 50] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>'.
				  (self streamObject: text asByteArray).
				  '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>' }
		  trailer: ''
]

{ #category : 'fixtures' }
PopplerFixtures class >> encryptedPdfUser: aUserPassword owner: anOwnerPassword [

	| id owner key user content |
	id := MD5 hashMessage: 'LibPoppler-Tests encrypted fixture' asByteArray.
	owner := self ownerEntryUser: aUserPassword owner: anOwnerPassword.
	key := self fileKeyUser: aUserPassword ownerEntry: owner permissions: -4 id: id.
	user := self userEntryKey: key id: id.
	content := self
		           rc4: (self objectKey: key number: 4 generation: 0)
		           data: 'BT /F1 24 Tf 20 40 Td (Secret) Tj ET' asByteArray.
	^ self
		  pdfWithObjects: {
				  '<< /Type /Catalog /Pages 2 0 R >>'.
				  '<< /Type /Pages /Kids [3 0 R] /Count 1 >>'.
				  '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 100] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>'.
				  (self streamObject: content).
				  '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'.
				  ('<< /Filter /Standard /V 2 /R 3 /Length 128 /P -4 /O <' , owner hex , '> /U <' , user hex , '> >>') }
		  trailer: '/Encrypt 6 0 R /ID [<' , id hex , '> <' , id hex , '>]'
]

{ #category : 'private - encryption' }
PopplerFixtures class >> fileKeyUser: aPassword ownerEntry: anOwnerEntry permissions: anInteger id: anId [
	"Algorithm 2 (R3, 128 bits): the file encryption key."

	| hash p |
	p := anInteger bitAnd: 16rFFFFFFFF.
	hash := MD5 hashMessage: (self pad: aPassword) , anOwnerEntry
		        , (ByteArray
				         with: (p bitAnd: 255)
				         with: ((p bitShift: -8) bitAnd: 255)
				         with: ((p bitShift: -16) bitAnd: 255)
				         with: ((p bitShift: -24) bitAnd: 255)) , anId.
	50 timesRepeat: [ hash := MD5 hashMessage: (hash first: 16) ].
	^ hash first: 16
]

{ #category : 'fixtures' }
PopplerFixtures class >> jpegPdf [

	| jpeg data |
	jpeg := self redJpeg.
	data := ExternalAddress allocate: jpeg size.
	^ [
	  data replaceFrom: 1 to: jpeg size with: jpeg startingAt: 1.
	  self pdfBytesDo: [ :path |
		  | surface image cr |
		  surface := self primPdfSurfaceCreate: path width: 64.0 height: 64.0.
		  image := self primImageSurfaceCreate: 1 width: 32 height: 32.
		  [
		  (self
			   primSurfaceSetMimeData: image
			   type: (GLibLibrary utf8Z: 'image/jpeg')
			   data: data
			   length: jpeg size
			   destroy: ExternalAddress null
			   closure: ExternalAddress null) = 0 ifFalse: [ self error: 'cairo_surface_set_mime_data failed' ].
		  cr := self primCreate: surface.
		  [
		  self primSetSource: cr surface: image x: 16.0 y: 16.0.
		  self primPaint: cr.
		  self primShowPage: cr ] ensure: [ self primDestroy: cr ] ] ensure: [
			  self primSurfaceFinish: surface.
			  self primSurfaceDestroy: surface.
			  "the PDF surface released the image: destroying it now detaches the mime data"
			  self primSurfaceDestroy: image ] ] ] ensure: [ data free ]
]

{ #category : 'private - encryption' }
PopplerFixtures class >> objectKey: aKey number: anObjectNumber generation: aGeneration [
	"Algorithm 1: the RC4 key of one object."

	| hash |
	hash := MD5 hashMessage: aKey , (ByteArray
		         with: (anObjectNumber bitAnd: 255)
		         with: ((anObjectNumber bitShift: -8) bitAnd: 255)
		         with: ((anObjectNumber bitShift: -16) bitAnd: 255)
		         with: (aGeneration bitAnd: 255)
		         with: ((aGeneration bitShift: -8) bitAnd: 255)).
	^ hash first: (aKey size + 5 min: 16)
]

{ #category : 'private - encryption' }
PopplerFixtures class >> ownerEntryUser: aUserPassword owner: anOwnerPassword [
	"Algorithm 3 (R3, 128 bits): the /O entry."

	| hash key result |
	hash := MD5 hashMessage: (self pad: (anOwnerPassword ifEmpty: [ aUserPassword ])).
	50 timesRepeat: [ hash := MD5 hashMessage: (hash first: 16) ].
	key := hash first: 16.
	result := self rc4: key data: (self pad: aUserPassword).
	1 to: 19 do: [ :i | result := self rc4: (key collect: [ :each | each bitXor: i ]) data: result ].
	^ result
]

{ #category : 'private - encryption' }
PopplerFixtures class >> pad: aPassword [
	"The password's bytes, truncated or completed to 32 bytes with the standard padding."

	| bytes |
	bytes := aPassword asByteArray.
	bytes size > 32 ifTrue: [ bytes := bytes first: 32 ].
	^ bytes , (self padding first: 32 - bytes size)
]

{ #category : 'private - encryption' }
PopplerFixtures class >> padding [

	^ #[ 16r28 16rBF 16r4E 16r5E 16r4E 16r75 16r8A 16r41 16r64 16r00 16r4E 16r56 16rFF 16rFA 16r01 16r08
	     16r2E 16r2E 16r00 16rB6 16rD0 16r68 16r3E 16r80 16r2F 16r0C 16rA9 16rFE 16r64 16r53 16r69 16r7A ]
]

{ #category : 'private' }
PopplerFixtures class >> pdfBytesDo: aBlock [
	"Evaluate aBlock with the NUL-terminated UTF-8 path of a fresh temp file, answer the file's bytes and delete it."

	| file |
	file := FileLocator temp asFileReference / ('poppler-fixture-' , UUID new asString , '.pdf').
	^ [
	  aBlock value: (GLibLibrary utf8Z: file fullName).
	  file binaryReadStreamDo: [ :stream | stream upToEnd ] ] ensure: [ file ensureDelete ]
]

{ #category : 'private' }
PopplerFixtures class >> pdfWithObjects: anArray trailer: aString [
	"A PDF 1.4 file whose objects 1..n have the bodies in anArray (Strings or ByteArrays), with a correct xref table;
	aString is added to the trailer dictionary after /Size and /Root."

	| out offsets xref lf |
	lf := String with: Character lf.
	out := WriteStream on: (ByteArray new: 1024).
	out nextPutAll: ('%PDF-1.4' , lf) asByteArray.
	out nextPutAll: #[ 16r25 16rE2 16rE3 16rCF 16rD3 10 ].
	offsets := anArray withIndexCollect: [ :body :n |
		           | offset |
		           offset := out position.
		           out nextPutAll: (n printString , ' 0 obj' , lf) asByteArray.
		           out nextPutAll: body asByteArray.
		           out nextPutAll: (lf , 'endobj' , lf) asByteArray.
		           offset ].
	xref := out position.
	out nextPutAll: ('xref' , lf , '0 ' , (anArray size + 1) printString , lf , '0000000000 65535 f ' , lf) asByteArray.
	offsets do: [ :each |
		out nextPutAll: ((each printPaddedWith: $0 to: 10) , ' 00000 n ' , lf) asByteArray ].
	out nextPutAll: ('trailer' , lf , '<< /Size ' , (anArray size + 1) printString , ' /Root 1 0 R ' , aString , ' >>' , lf
		 , 'startxref' , lf , xref printString , lf , '%%EOF' , lf) asByteArray.
	^ out contents
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primCreate: aSurface [

	^ self ffiCall: #( void * cairo_create #( void * aSurface ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primDestroy: aCairo [

	^ self ffiCall: #( void cairo_destroy #( void * aCairo ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primImageSurfaceCreate: aFormat width: aWidth height: aHeight [

	^ self
		  ffiCall: #( void * cairo_image_surface_create #( int aFormat , int aWidth , int aHeight ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primMoveTo: aCairo x: x y: y [

	^ self ffiCall: #( void cairo_move_to #( void * aCairo , double x , double y ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primPaint: aCairo [

	^ self ffiCall: #( void cairo_paint #( void * aCairo ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primPdfSurface: aSurface setMetadata: aKey value: aByteArray [

	^ self
		  ffiCall: #( void cairo_pdf_surface_set_metadata #( void * aSurface , int aKey , void * aByteArray ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primPdfSurface: aSurface setPageLabel: aByteArray [

	^ self
		  ffiCall: #( void cairo_pdf_surface_set_page_label #( void * aSurface , void * aByteArray ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primPdfSurface: aSurface width: aWidth height: aHeight [

	^ self
		  ffiCall: #( void cairo_pdf_surface_set_size #( void * aSurface , double aWidth , double aHeight ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primPdfSurfaceCreate: aPath width: aWidth height: aHeight [

	^ self
		  ffiCall: #( void * cairo_pdf_surface_create #( void * aPath , double aWidth , double aHeight ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSelectFontFace: aCairo family: aByteArray slant: aSlant weight: aWeight [

	^ self
		  ffiCall: #( void cairo_select_font_face #( void * aCairo , void * aByteArray , int aSlant , int aWeight ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSetFontSize: aCairo size: aSize [

	^ self ffiCall: #( void cairo_set_font_size #( void * aCairo , double aSize ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSetSource: aCairo surface: aSurface x: x y: y [

	^ self
		  ffiCall: #( void cairo_set_source_surface #( void * aCairo , void * aSurface , double x , double y ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSetSourceRgba: aCairo red: r green: g blue: b alpha: a [

	^ self
		  ffiCall: #( void cairo_set_source_rgba #( void * aCairo , double r , double g , double b , double a ) )
		  module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primShowPage: aCairo [

	^ self ffiCall: #( void cairo_show_page #( void * aCairo ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primShowText: aCairo text: aByteArray [

	^ self ffiCall: #( void cairo_show_text #( void * aCairo , void * aByteArray ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSurfaceDestroy: aSurface [

	^ self ffiCall: #( void cairo_surface_destroy #( void * aSurface ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSurfaceFinish: aSurface [

	^ self ffiCall: #( void cairo_surface_finish #( void * aSurface ) ) module: CairoLibrary
]

{ #category : 'private - cairo' }
PopplerFixtures class >> primSurfaceSetMimeData: aSurface type: aType data: aData length: aLength destroy: aDestroy closure: aClosure [
	"The length is a C unsigned long: size_t here, which is right on LP64 and harmless for small values on LLP64 (Win64)."

	^ self
		  ffiCall: #( int cairo_surface_set_mime_data #( void * aSurface , void * aType , void * aData , size_t aLength , void * aDestroy , void * aClosure ) )
		  module: CairoLibrary
]

{ #category : 'private - encryption' }
PopplerFixtures class >> rc4: aKey data: aByteArray [
	"RC4 (encryption and decryption are the same)."

	| s i j out |
	s := ByteArray new: 256.
	0 to: 255 do: [ :k | s at: k + 1 put: k ].
	j := 0.
	0 to: 255 do: [ :k |
		j := j + (s at: k + 1) + (aKey at: k \\ aKey size + 1) \\ 256.
		s swap: k + 1 with: j + 1 ].
	i := 0.
	j := 0.
	out := ByteArray new: aByteArray size.
	1 to: aByteArray size do: [ :n |
		i := i + 1 \\ 256.
		j := j + (s at: i + 1) \\ 256.
		s swap: i + 1 with: j + 1.
		out at: n put: ((aByteArray at: n) bitXor: (s at: (s at: i + 1) + (s at: j + 1) \\ 256 + 1)) ].
	^ out
]

{ #category : 'fixtures' }
PopplerFixtures class >> redJpeg [

	^ self redJpegBase64 base64Decoded
]

{ #category : 'fixtures' }
PopplerFixtures class >> redJpegBase64 [
	"A 32x32 baseline JPEG of solid #C00000 (libjpeg-turbo 3.2.1, quality 90, 4:2:0)."

	^ '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMU'
	  , 'FRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQU'
	  , 'FBQUFBQUFBT/wAARCAAgACADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUF'
	  , 'BAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVW'
	  , 'V1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi'
	  , '4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC'
	  , 'AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVm'
	  , 'Z2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq'
	  , '8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD5Cooor8qP9AAooooAKKKKACiiigD/2Q=='
]

{ #category : 'private' }
PopplerFixtures class >> streamObject: aByteArray [

	| lf |
	lf := String with: Character lf.
	^ ('<< /Length ' , aByteArray size printString , ' >>' , lf , 'stream' , lf) asByteArray , aByteArray
	  , (lf , 'endstream') asByteArray
]

{ #category : 'fixtures' }
PopplerFixtures class >> threePagePdf [

	^ self pdfBytesDo: [ :path |
		  | surface cr |
		  surface := self primPdfSurfaceCreate: path width: 595.28 height: 841.89.
		  [
		  self primPdfSurface: surface setMetadata: 0 value: (GLibLibrary utf8Z: 'Pharo ✓ Poppler').
		  self primPdfSurface: surface setMetadata: 1 value: (GLibLibrary utf8Z: 'Pharo').
		  cr := self primCreate: surface.
		  [
		  #( #( 595.28 841.89 'i' ) #( 612 792 'ii' ) #( 300 200 'A-1' ) ) withIndexDo: [ :page :n |
			  n > 1 ifTrue: [ self primPdfSurface: surface width: page first asFloat height: page second asFloat ].
			  self primPdfSurface: surface setPageLabel: (GLibLibrary utf8Z: page third).
			  self primSetSourceRgba: cr red: 0.0 green: 0.0 blue: 0.0 alpha: 1.0.
			  self primSelectFontFace: cr family: (GLibLibrary utf8Z: 'sans-serif') slant: 0 weight: 0.
			  self primSetFontSize: cr size: 24.0.
			  self primMoveTo: cr x: 20.0 y: 60.0.
			  self primShowText: cr text: (GLibLibrary utf8Z: 'Hello Poppler ' , n printString).
			  n = 1 ifTrue: [
				  self primMoveTo: cr x: 20.0 y: 120.0.
				  self primShowText: cr text: (GLibLibrary utf8Z: 'Grüße €') ].
			  self primShowPage: cr ] ] ensure: [ self primDestroy: cr ] ] ensure: [
			  self primSurfaceFinish: surface.
			  self primSurfaceDestroy: surface ] ]
]

{ #category : 'private - encryption' }
PopplerFixtures class >> userEntryKey: aKey id: anId [
	"Algorithm 5 (R3): the /U entry (16 significant bytes, then 16 bytes of padding)."

	| result |
	result := self rc4: aKey data: (MD5 hashMessage: self padding , anId).
	1 to: 19 do: [ :i | result := self rc4: (aKey collect: [ :each | each bitXor: i ]) data: result ].
	^ result , (ByteArray new: 16)
]
