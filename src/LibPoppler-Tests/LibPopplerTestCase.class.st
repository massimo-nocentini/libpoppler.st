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

{ #category : 'TeX chunks' }
LibPopplerTestCase >> tikZGraphTeXString [

	<tex: 'pdflatex' times: 2 pagesPerRow: 2>
	'
\documentclass{standalone}
\usepackage{pgfplots}
\usetikzlibrary{graphs}
%\usepgfplotslibrary{external}
%\tikzexternalize
\begin{document}
\usetikzlibrary {mindmap}
\begin{tikzpicture}
  \path[mindmap,concept color=black,text=white]
    node[concept] {Computer Science}
    [clockwise from=0]
    % note that `sibling angle'' can only be defined in
    % `level 1 concept/.append style={}''
    child[concept color=green!50!black] {
      node[concept] {practical}
      [clockwise from=90]
      child { node[concept] {algorithms} }
      child { node[concept] {data structures} }
      child { node[concept] {pro\-gramming languages} }
      child { node[concept] {software engineer\-ing} }
    }
    % note that the `concept color'' is passed to the `child''(!)
    child[concept color=blue] {
      node[concept] {applied}
      [clockwise from=-30]
      child { node[concept] {databases} }
      child { node[concept] {WWW} }
    }
    child[concept color=red] { node[concept] {technical} }
    child[concept color=orange] { node[concept] {theoretical} };
\end{tikzpicture}
\end{document}
'
]

{ #category : 'TeX chunks' }
LibPopplerTestCase >> tikZTeXString [

	<tex: 'pdflatex' times: 2 pagesPerRow: 2>
	'
\documentclass{standalone}
%\usepackage[margin=0.5in]{geometry}
\usepackage{pgfplots}
%\pgfplotsset{width=10cm,compat=1.9}
%\usepgfplotslibrary{external}
%\tikzexternalize
\begin{document}
\begin{tikzpicture}
\begin{axis}[
    title=Example using the mesh parameter,
    hide axis,
    colormap/cool,
]
\addplot3[
    mesh,
    samples=50,
    domain=-8:8,
]
{sin(deg(sqrt(x^2+y^2)))/sqrt(x^2+y^2)};
\addlegendentry{\(\frac{sin(r)}{r}\)}
\end{axis}
\end{tikzpicture}
\end{document}
'
]
