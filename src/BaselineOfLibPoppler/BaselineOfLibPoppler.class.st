Class {
	#name : #BaselineOfLibPoppler,
	#superclass : #BaselineOf,
	#category : #BaselineOfLibPoppler
}

{ #category : #baselines }
BaselineOfLibPoppler >> baseline: spec [

	<baseline>
	spec for: #common do: [ spec package: 'LibPoppler' ]
]
