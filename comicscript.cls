\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{comicscript}[2020/10/09 Comic Script]

% Options ---------------------------------------------------------------------
% Is the script paged or not? This affects the numbering of panel labels
\newif\ifcomicscript@unpaged
\comicscript@unpagedfalse
\DeclareOption{paged}{\comicscript@unpagedfalse}
\DeclareOption{unpaged}{\comicscript@unpagedtrue}

% Include a titlepage? This puts the output of \maketitle on its own page
\newif\ifcomicscript@titlepage
\comicscript@titlepagefalse
\DeclareOption{titlepage}{\comicscript@titlepagetrue}
\DeclareOption{notitlepage}{\comicscript@titlepagefalse}

% Options passed to the article class
\DeclareOption{twocolumn}{\OptionNotUsed}
\DeclareOption{twoside}{\OptionNotUsed}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

\ProcessOptions*\relax
\LoadClass{article}

% Packages --------------------------------------------------------------------
\RequirePackage[margin=1in]{geometry}
\RequirePackage{xparse}
\RequirePackage[pagestyles]{titlesec}
\RequirePackage{tabularx}
\RequirePackage{fmtcount}
\RequirePackage{xcolor}
\RequirePackage{tikz}
\RequirePackage{expl3}
\RequirePackage{etoolbox} % for conditional checks

% Commands and settings -------------------------------------------------------
% Handle mutually exclusive options
\ifcomicscript@unpaged
  \renewcommand{\thesubsection}{\arabic{subsection}}
\fi

\AtBeginDocument{
  \ifx\@title\empty
    \ifx\@series\empty
      \ClassError{comicscript}{Either \noexpand\title or \noexpand\series must be given}\@ehc
    \fi
  \fi
}

% Variables for \maketitle and headers
\def\@author{\ClassError{comicscript}{No \noexpand\author given}\@ehc}
\gdef\@title{}
\gdef\@series{}
\gdef\@issue{}
\DeclareRobustCommand\series[2]{
  \gdef\@series{#1}
  \gdef\@issue{#2}
}
\renewcommand{\maketitle}{
  \ifcomicscript@titlepage
    \hspace{0pt}\vfill
    \@maketitle
    \vfill\hspace{0pt}
    \clearpage
  \else
    \@maketitle
  \fi
}
\renewcommand{\@maketitle}{
  \begin{center}
    \ifx\@series\empty
      {\Huge\bfseries\@title}
    \else
      \ifx\@title\empty
        {\Huge\bfseries\@series~\#\@issue}
      \else
        {\Huge\bfseries\@series~\#\@issue~---~\@title}
      \fi
    \fi
    \medskip\par{\large Written by \@author}\bigskip
  \end{center}
  \thispagestyle{empty}
}

% Use \emph for bold italics, as it is common in comic lettering
\renewcommand{\emph}[1]{\textit{\textbf{#1}}}

\newpagestyle{main}{
  \sethead{}{}{
    \color{black!30}\MakeUppercase{%
      \small\slshape%
      \ifx\@series\empty\else{\@series~\#\@issue~\textbullet~}\fi%
      \ifx\@title\empty\else{\@title~\textbullet~}\fi%
      \@author
    }
  }
  \setfoot{}{}{}
}
\pagestyle{main}

% Sectioning commands and styling
\ifcomicscript@unpaged\else\newcommand{\page}{\section{Page \Numberstring{section}}}\fi
\NewDocumentCommand{\panel}{o}{\subsection{Panel \arabic{subsection}\IfNoValueTF{#1}{}{ (#1)}}}

\titleformat{\section}[hang]{\normalfont\Large\bfseries}{}{0pt}{}
\titleformat{\subsection}[runin]{\normalfont\bfseries}{}{0pt}{}[:]

% Lettering instruction commands
\newcolumntype{R}[1]{>{\raggedleft\arraybackslash}p{#1}}
\newenvironment{lettering}
  {\medskip\par\noindent\tabularx{\textwidth}{ R{0.05\textwidth} p{0.25\textwidth} X }}
  {\endtabularx}
\newcounter{letteringitem}[section]
\NewDocumentCommand{\letteringitem}{ m o m }{
  \stepcounter{letteringitem}
  \arabic{letteringitem}. & \MakeUppercase{#1}\IfNoValueTF{#2}{}{ (\MakeUppercase{#2})}: & #3 \\
}
\NewDocumentCommand{\dialogue}{ m o m }{\letteringitem{#1}[#2]{#3}}
\NewDocumentCommand{\narration}{ o m }{\letteringitem{NARRATION}[#1]{#2}}
\NewDocumentCommand{\sfx}{ m }{\letteringitem{SFX}{#1}}

\ExplSyntaxOn
% ============================
% === Characters ============
% ============================

\seq_new:N \g_comic_characters_seq
\prop_new:N \g_comic_character_data_prop

\keys_define:nn { comic/character }
{
  name .tl_set:N = \l_comic_character_name_tl,
  desc .tl_set:N = \l_comic_character_desc_tl,
}

\NewDocumentCommand{\newcharacter}{O{}m}
{
  \keys_set:nn { comic/character } { #1 }
  \seq_gput_right:Nn \g_comic_characters_seq { #2 }
  \prop_gput:Nnx \g_comic_character_data_prop { #2/name } { \l_comic_character_name_tl }
  \prop_gput:Nnx \g_comic_character_data_prop { #2/desc } { \l_comic_character_desc_tl }
  \cs_new:cpn {#2} { \MakeUppercase{\prop_item:Nn \g_comic_character_data_prop { #2/name }} }
}

\NewDocumentCommand{\listcharacters}{}{
  \par\bigskip
  \section*{Character~List}\par\medskip
  \seq_map_inline:Nn \g_comic_characters_seq
  {
    \noindent
    \textbf{\MakeUppercase{\prop_item:Nn \g_comic_character_data_prop { ##1/name }}}:~
    \prop_item:Nn \g_comic_character_data_prop { ##1/desc } \par
  }
}

% ============================
% === Locations =============
% ============================

\seq_new:N \g_comic_locations_seq
\prop_new:N \g_comic_location_data_prop

\keys_define:nn { comic/location }
{
  name .tl_set:N = \l_comic_location_name_tl,
  desc .tl_set:N = \l_comic_location_desc_tl,
}

\NewDocumentCommand{\newlocation}{O{}m}
{
  \keys_set:nn { comic/location } { #1 }
  \seq_gput_right:Nn \g_comic_locations_seq { #2 }
  \prop_gput:Nnx \g_comic_location_data_prop { #2/name } { \l_comic_location_name_tl }
  \prop_gput:Nnx \g_comic_location_data_prop { #2/desc } { \l_comic_location_desc_tl }
  \cs_new:cpn {#2} { \MakeUppercase{\prop_item:Nn \g_comic_location_data_prop { #2/name }} }
}

\NewDocumentCommand{\listlocations}{}{
  \par\bigskip
  \section*{Location~List}\par\medskip
  \seq_map_inline:Nn \g_comic_locations_seq
  {
    \noindent
    \textbf{\MakeUppercase{\prop_item:Nn \g_comic_location_data_prop { ##1/name }}}:~
    \prop_item:Nn \g_comic_location_data_prop { ##1/desc } \par
  }
}
\ExplSyntaxOff

% Cell size and spacing (in inches)
\newcommand{\cellwidth}{3}
\newcommand{\cellheight}{2.5}
\newcommand{\cellxspacing}{0.25}
\newcommand{\cellyspacing}{0.25}
\newcommand{\startx}{0}
\newcommand{\starty}{8}

% Macro: \boxpanel{line}{column}{width}{height}{content}
\newcommand{\boxpanel}[5]{
    % Total size includes internal spacing
    \pgfmathsetmacro{\boxheight}{#4 * \cellheight + (#4 - 1) * \cellyspacing}
    \pgfmathsetmacro{\boxwidth}{#3 * \cellwidth + (#3 - 1) * \cellxspacing}

    % Position: x0 + offset + half width
    \pgfmathsetmacro{\ycenter}{\starty - #1 * (\cellheight + \cellyspacing) - 0.5 * \boxheight}
    \pgfmathsetmacro{\xcenter}{\startx + #2 * (\cellwidth + \cellxspacing) + 0.5 * \boxwidth}

    \node[draw, thick, rectangle, align=left] at (\xcenter in, \ycenter in)
    {\begin{minipage}[t][\boxheight in][t]{\boxwidth in}
    #5
    \end{minipage}};
}

\newenvironment{layout}{
    \begin{tikzpicture}
}
{
    \end{tikzpicture}
    \newpage
}

\newcommand{\sceneheader}[3]{
    \noindent
    \begin{tikzpicture}
        \node[draw=gray!70, fill=gray!70, align=left, inner sep=5pt] at (0, 0)
        {\begin{minipage}{\textwidth}\MakeUppercase{\textbf{#1 #2 \boldmath{$-$} #3}}\end{minipage}};
    \end{tikzpicture}
}
