Class {
	#name : 'LibPopplerTestCase',
	#superclass : 'TestCase',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'examples' }
LibPopplerTestCase >> examplePBE_objectModel [

	<script: 'self new examplePBE_objectModel'>
	<pdf: #( 'pbe-object-model.pdf' ) pagesPerRow: 2>
	self testPBE_objectModel pages inspect
]

{ #category : 'examples' }
LibPopplerTestCase >> testPBE_objectModel [

	| pdf |
	pdf := ((IceRepository repositoryNamed: 'libpoppler.st')
		        repositoryDirectory / 'pbe-object-model.pdf')
		       asFileReference asPdf.

	self assert: pdf pages size equals: 272 - 259 + 1.

	^ pdf
]
