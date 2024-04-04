Class {
	#name : 'LibPopplerTestCase',
	#superclass : 'TestCase',
	#category : 'LibPoppler-Tests',
	#package : 'LibPoppler-Tests'
}

{ #category : 'TeX chunks' }
LibPopplerTestCase >> beamerTeXString [

	<tex: 'pdflatex' times: 2 pagesPerRow: 1>
	'
\documentclass{beamer}
%Information to be included in the title page:
\title{Sample title}
\author{Anonymous}
\institute{Overleaf}
\date{2021}

\begin{document}

\frame{\titlepage}

\begin{frame}
\frametitle{Sample frame title}
This is some text in the first frame. This is some text in the first frame. This is some text in the first frame.
\end{frame}

\end{document}
'
]

{ #category : 'examples' }
LibPopplerTestCase >> examplePBE_objectModel [

	<script: 'self new examplePBE_objectModel'>
	<pdf: #( 'pbe-object-model.pdf' ) pagesPerRow: 2>
	self testPBE_objectModel pages inspect
]

{ #category : 'TeX chunks' }
LibPopplerTestCase >> shortDocumentTeXString [

	<tex: 'pdflatex' times: 2 pagesPerRow: 2>
	'
\documentclass[12pt, letterpaper]{article}
\title{My first LaTeX document}
\author{Hubert Farnsworth\thanks{Funded by the Overleaf team.}}
\date{August 2022}
\begin{document}
\maketitle
We have now added a title, author and date 
\newpage
to our first \LaTeX{} document!
\end{document}
	'
]

{ #category : 'tests' }
LibPopplerTestCase >> testPBE_objectModel [

	| pdf |
	pdf := ((self class iceRepositoryIfAbsent: [ Error signal ])
		        repositoryDirectory / 'pbe-object-model.pdf')
		       asFileReference asPdf.

	self assert: pdf pages size equals: 272 - 258.

	^ pdf
]
