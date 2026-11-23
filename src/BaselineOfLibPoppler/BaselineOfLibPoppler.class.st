"
I load libpoppler.st: uFFI bindings to poppler-glib for Pharo 12 to 15, on the libraries of the cairo stack VM (or the system's).

The shared GLib/GObject layer comes from libpangocairo.st, of which only the `GLib` group (`LibGLib`, `LibGLib-Cairo`) is loaded.

Groups:

- `Core`: `LibPoppler` (`PopplerDocument`, `PopplerPage`, drawing on an Athens canvas, `FileReference>>asPdf`);
- `Roassal`: `Core` and `LibPoppler-Roassal` (`RSPdfPage`, `PopplerDocument>>asRoassalShapes`);
- `Examples`: `LibPoppler-Examples` (`PopplerExamples`);
- `Tests`, `RoassalTests`: the tests of each layer (the Roassal tests reuse the fixtures of `LibPoppler-Tests`);
- `default`: all of them.

Athens and Roassal are in the stock images.
"
Class {
	#name : 'BaselineOfLibPoppler',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfLibPoppler',
	#package : 'BaselineOfLibPoppler'
}

{ #category : 'baselines' }
BaselineOfLibPoppler >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec baseline: 'LibPangoCairo' with: [
			spec
				repository: 'github://massimo-nocentini/libpangocairo.st:master/src';
				loads: #( 'GLib' ) ].
		spec
			package: 'LibPoppler' with: [ spec requires: #( 'LibPangoCairo' ) ];
			package: 'LibPoppler-Tests' with: [ spec requires: #( 'LibPoppler' ) ];
			package: 'LibPoppler-Roassal' with: [ spec requires: #( 'LibPoppler' ) ];
			package: 'LibPoppler-Roassal-Tests' with: [ spec requires: #( 'LibPoppler-Roassal' 'LibPoppler-Tests' ) ];
			package: 'LibPoppler-Examples' with: [ spec requires: #( 'LibPoppler-Roassal' ) ].
		spec
			group: 'Core' with: #( 'LibPoppler' );
			group: 'Tests' with: #( 'LibPoppler-Tests' );
			group: 'Roassal' with: #( 'Core' 'LibPoppler-Roassal' );
			group: 'RoassalTests' with: #( 'LibPoppler-Roassal-Tests' );
			group: 'Examples' with: #( 'LibPoppler-Examples' );
			group: 'default' with: #( 'Core' 'Tests' 'Roassal' 'RoassalTests' 'Examples' ) ]
]
