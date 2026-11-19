"ci-load.st - load libpoppler.st with Metacello from a checkout, check it and run its tests

	LIBPOPPLER_DIR=<checkout> LIBPANGOCAIRO_DIR=<libpangocairo.st checkout> pharo --headless X.image --no-default-preferences st ci/ci-load.st

(ci/run.sh sets everything up: a fresh copy of the image, the environment, a timeout.)

LIBPOPPLER_DIR                  this checkout: BaselineOfLibPoppler is loaded from tonel://<it>/src (no network)
LIBPANGOCAIRO_DIR               a checkout of libpangocairo.st: its GLib group is loaded from tonel://<it>/src and
                                LibPangoCairo is locked there first, so the baseline's github:// reference to it is
                                honoured from that checkout (no network)
CI_GROUPS                       the groups to load, separated by spaces, instead of the automatic choice:
                                Core Tests, plus Roassal RoassalTests Examples when the image has RSCanvas
PHARO_CAIRO_STACK_EXPECT_LIBS   yes: a missing library fails the tests instead of skipping them, and no test may
                                skip itself but the platform-gated ones named in allowedSkips

After the load: no new Undeclared, no method of the loaded packages (LibGLib*, LibPoppler*) using an undeclared
variable or sending a selector that nothing implements, and the choke-point lint (every callout of a GLibHandle
subclass is a prim... method with no self in its signature; every other method sending a prim... selector reads no
handle but through validHandle). Then every TestCase of the loaded LibPoppler test packages runs, one test at a time.
One line per load problem, lint finding, failure, error and skip, then the summary

	LibPoppler <pharo-version> loaded <groups> tests <run> passed <p> skipped <s> failed <f> errors <e> poppler <version> ok

ending in FAILED instead of ok when anything went wrong. The image is never saved: the exit status is 0 for ok,
1 otherwise."

| environment out lineEnd line fail checkoutAt repository pangoRepository groups undeclaredBefore registration
  packages methods problems lint flatten glibHandle allowedSkips counts expectLibs poppler version summary ok |
environment := OSEnvironment current.
out := Stdio stdout.
lineEnd := OSPlatform current lineEnding.
line := [ :string | out nextPutAll: string; nextPutAll: lineEnd; flush ].
fail := [ :message |
	line value: 'LibPoppler FAILED: ' , message.
	Smalltalk exitFailure ].
version := SystemVersion current major printString , '.' , SystemVersion current minor printString.
expectLibs := (environment at: 'PHARO_CAIRO_STACK_EXPECT_LIBS' ifAbsent: [ '' ]) = 'yes'.
"skips that do not depend on the libraries: the fontconfig no-op test runs off macOS only (spec 4.7)"
allowedSkips := #( 'PopplerDocumentTest>>testFontconfigIsANoOpOffMacOS' ).

[
"1. the checkouts"
checkoutAt := [ :variable :baseline :what |
	| directory |
	directory := (environment at: variable ifAbsent: [ '' ]) ifEmpty: [
		fail value: variable , ' is not set (the checkout of ' , what , ')' ].
	directory := directory asFileReference / 'src'.
	(directory / baseline) isDirectory ifFalse: [ fail value: 'no ' , (directory / baseline) fullName ].
	directory ].
repository := checkoutAt value: 'LIBPOPPLER_DIR' value: 'BaselineOfLibPoppler' value: 'libpoppler.st'.
pangoRepository := checkoutAt value: 'LIBPANGOCAIRO_DIR' value: 'BaselineOfLibPangoCairo' value: 'libpangocairo.st'.

"2. the groups"
groups := (environment at: 'CI_GROUPS' ifAbsent: [ '' ]) substrings: ' '.
groups := groups isEmpty
	ifTrue: [
		| automatic |
		automatic := OrderedCollection withAll: #( 'Core' 'Tests' ).
		(Smalltalk globals includesKey: #RSCanvas) ifTrue: [ automatic addAll: #( 'Roassal' 'RoassalTests' 'Examples' ) ].
		automatic asArray ]
	ifFalse: [ groups asArray ].
line value: 'LibPoppler: Pharo ' , SystemVersion current printString , ', loading ' , groups printString , ' from '
	, repository fullName , ', LibPangoCairo locked to ' , pangoRepository fullName.

"3. the GLib group of the libpangocairo.st checkout, its lock, the load (Metacello's warnings are printed and resumed;
 a lock is always honoured).  A lock alone does not do: Metacello skips a locked project that is not loaded yet."
undeclaredBefore := Undeclared keys asSet.
[ [ Metacello new
		baseline: 'LibPangoCairo';
		repository: 'tonel://' , pangoRepository fullName;
		load: #( 'GLib' ).
	Metacello new
		baseline: 'LibPangoCairo';
		repository: 'tonel://' , pangoRepository fullName;
		lock.
	Metacello new
		baseline: 'LibPoppler';
		repository: 'tonel://' , repository fullName;
		onLock: [ :lock | lock honor ];
		load: groups ]
	on: Warning
	do: [ :warning |
		line value: 'WARNING ' , (warning messageText asString copyReplaceAll: String cr with: ' ').
		warning resume ] ]
	on: Error
	do: [ :error | fail value: 'loading ' , groups printString , ': ' , error description ].

"the GLib layer must come from the locked checkout"
registration := MetacelloProjectRegistration
	registrationForClassNamed: 'BaselineOfLibPangoCairo'
	ifAbsent: [ fail value: 'LibPangoCairo is not registered after the load' ].
(registration repositoryDescriptions anySatisfy: [ :each | each = ('tonel://' , pangoRepository fullName) ])
	ifFalse: [ fail value: 'LibPangoCairo registered with ' , registration repositoryDescriptions printString ].
line value: 'LibPoppler: LibPangoCairo ' , (registration locked ifTrue: [ 'locked' ] ifFalse: [ 'NOT locked' ]) , ' at '
	, registration repositoryDescriptions printString.
registration locked ifFalse: [ fail value: 'the lock of LibPangoCairo was lost' ].

packages := ((PackageOrganizer default packageNames select: [ :each |
	(each beginsWith: 'LibGLib') or: [ each beginsWith: 'LibPoppler' ] ]) collect: [ :each | each asString ])
	asSortedCollection asArray.
(packages includes: 'LibPoppler') ifFalse: [ fail value: 'no package LibPoppler after the load' ].
(packages includes: 'LibGLib-Cairo') ifFalse: [ fail value: 'no package LibGLib-Cairo after the load' ].
line value: 'LibPoppler: packages ' , packages printString.

"4. Undeclared and unimplemented selectors"
problems := 0.
(Undeclared keys asSet reject: [ :each | undeclaredBefore includes: each ]) do: [ :each |
	problems := problems + 1.
	line value: 'UNDECLARED ' , each printString ].
methods := packages flatCollect: [ :each | (PackageOrganizer default packageNamed: each) methods ].
methods do: [ :method |
	| missing |
	(method literals select: [ :literal |
		literal isVariableBinding and: [ literal class name includesSubstring: 'Undeclared' ] ]) do: [ :literal |
			problems := problems + 1.
			line value: 'UNDECLARED ' , method printString , ' -> ' , literal key printString ].
	missing := method messages reject: [ :selector | (SystemNavigation default allImplementorsOf: selector) notEmpty ].
	missing ifNotEmpty: [
		problems := problems + missing size.
		line value: 'UNIMPLEMENTED ' , method printString , ' -> ' , missing asArray printString ] ].

"5. the choke-point lint (spec 4.1) on both sides of every GLibHandle subclass"
lint := 0.
flatten := nil.
flatten := [ :array |
	array inject: OrderedCollection new into: [ :all :each |
		each isArray ifTrue: [ all addAll: (flatten value: each) ] ifFalse: [ all add: each ].
		all ] ].
glibHandle := Smalltalk globals at: #GLibHandle ifAbsent: [ nil ].
glibHandle ifNil: [ fail value: 'no GLibHandle after the load' ].
glibHandle withAllSubclasses do: [ :class |
	{ class. class class } do: [ :behavior |
		behavior methods do: [ :method |
			| finding |
			finding := nil.
			(#( #ffiCall: #ffiCall:module: #ffiCall:library: ) anySatisfy: [ :selector | method sendsSelector: selector ])
				ifTrue: [
					(method selector beginsWith: 'prim') ifFalse: [ finding := 'callout not named prim...' ].
					((method literals select: [ :literal | literal isArray ]) anySatisfy: [ :array |
						(flatten value: array) includes: #self ]) ifTrue: [ finding := 'callout names self in its signature' ] ]
				ifFalse: [
					((method selector beginsWith: 'prim') not and: [
						method messages anySatisfy: [ :selector | selector beginsWith: 'prim' ] ]) ifTrue: [
							| nodes |
							nodes := method ast allChildren.
							(method messages includesAny: #( #handle #getHandle )) ifTrue: [
								finding := 'prim sender reads #handle/#getHandle' ].
							(nodes anySatisfy: [ :node | node isVariable and: [ node name asString = 'handle' ] ]) ifTrue: [
								finding := 'prim sender reads the handle variable' ].
							((nodes select: [ :node | node isMessage and: [ node selector beginsWith: 'prim' ] ])
								anySatisfy: [ :node |
									node arguments anySatisfy: [ :argument |
										argument isVariable and: [ argument name asString = 'self' ] ] ]) ifTrue: [
									finding := 'prim sender passes self' ] ] ].
			finding ifNotNil: [
				lint := lint + 1.
				line value: 'LINT ' , finding , ': ' , method printString ] ] ] ].

"6. the tests of the loaded LibPoppler test packages"
counts := Dictionary new.
#( #run #passed #skipped #failed #errors ) do: [ :each | counts at: each put: 0 ].
(packages select: [ :each | (each beginsWith: 'LibPoppler') and: [ each endsWith: '-Tests' ] ]) do: [ :each |
	| classes |
	classes := ((PackageOrganizer default packageNamed: each) definedClasses select: [ :class |
		(class inheritsFrom: TestCase) and: [ class isAbstract not ] ]) asSortedCollection: [ :a :b | a name <= b name ].
	classes do: [ :class |
		class testSelectors asSortedCollection do: [ :selector |
			| name outcome |
			name := class name asString , '>>' , selector asString.
			outcome := [ (class selector: selector) runCase. #passed -> '' ]
				on: TestSkipped , TestFailure , Error
				do: [ :error |
					| kind |
					kind := (error isKindOf: TestSkipped)
						ifTrue: [ #skipped ]
						ifFalse: [ (error isKindOf: TestFailure) ifTrue: [ #failed ] ifFalse: [ #errors ] ].
					error return: kind -> (String streamContents: [ :stream |
						stream nextPutAll: error class name; space; nextPutAll: error messageText asString.
						kind = #errors ifTrue: [
							| context depth |
							context := error signalerContext.
							depth := 0.
							[ context notNil and: [ depth < 6 ] ] whileTrue: [
								stream nextPutAll: ' | '; print: context.
								context := context sender.
								depth := depth + 1 ] ] ]) ].
			counts at: #run put: (counts at: #run) + 1.
			counts at: outcome key put: (counts at: outcome key) + 1.
			outcome key = #passed ifFalse: [
				| tag |
				tag := outcome key = #skipped
					ifTrue: [
						(expectLibs and: [ (allowedSkips includes: name) not ])
							ifTrue: [
								problems := problems + 1.
								'SKIP (not allowed with PHARO_CAIRO_STACK_EXPECT_LIBS=yes) ' ]
							ifFalse: [ 'SKIP ' ] ]
					ifFalse: [ outcome key = #failed ifTrue: [ 'FAIL ' ] ifFalse: [ 'ERROR ' ] ].
				line value: tag , name , ' -- ' , (outcome value copyReplaceAll: String cr with: ' ') ] ] ] ].

"7. the summary"
poppler := (Smalltalk globals at: #PopplerLibrary ifAbsent: [ nil ])
	ifNil: [ 'none' ]
	ifNotNil: [ :library | [ library versionString ] on: Error do: [ :error | error return: 'none' ] ].
ok := problems = 0 and: [ lint = 0 and: [ (counts at: #failed) = 0 and: [ (counts at: #errors) = 0 ] ] ].
summary := String streamContents: [ :stream |
	stream nextPutAll: 'LibPoppler '; nextPutAll: version; nextPutAll: ' loaded '.
	groups do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPut: $, ].
	#( #run #passed #skipped #failed #errors ) with: #( 'tests' 'passed' 'skipped' 'failed' 'errors' ) do: [ :key :label |
		stream space; nextPutAll: label; space; print: (counts at: key) ].
	stream nextPutAll: ' poppler '; nextPutAll: poppler; nextPutAll: (ok ifTrue: [ ' ok' ] ifFalse: [ ' FAILED' ]) ].
problems + lint > 0 ifTrue: [
	line value: 'LibPoppler: ' , problems printString , ' load problems or disallowed skips, ' , lint printString
		, ' lint findings' ].
line value: summary.
ok ]
	on: Error
	do: [ :error |
		line value: 'LibPoppler FAILED: ' , error class name , ' ' , error messageText asString.
		ok := false ].
ok == true
	ifTrue: [ Smalltalk exitSuccess ]
	ifFalse: [ Smalltalk exitFailure ]
