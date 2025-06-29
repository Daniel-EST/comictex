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
\RequirePackage{etoolbox}
\RequirePackage{pgffor}

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

% Storage for character names and descriptions
\newcommand{\character@names}{}
\newcommand{\character@descs}{}

% Define new character: \newcharacter[name=Alice,desc=Explorer]{protagonist}
\NewDocumentCommand{\newcharacter}{O{}m}{%
  \begingroup
    \def\character@name{}%
    \def\character@desc{}%
    % Parse the key-value options
    \setkeys{character}{#1}%
    % Save data into lists
    \xappto{\character@names}{\def#2name{\character@name}}%
    \xappto{\character@descs}{\def#2desc{\character@desc}}%
    % Store identifier
    \xappto{\character@list}{#2,}%
    % Define macro that expands to the character name
    \expandafter\newcommand\csname #2\endcsname{\character@name}%
  \endgroup
}

% Define keys for character options
\makeatletter
\define@key{character}{name}{\def\character@name{#1}}
\define@key{character}{desc}{\def\character@desc{#1}}
\makeatother

% Character list holder
\newcommand{\character@list}{}

% Command: \listcharacters
\newcommand{\listcharacters}{%
  \section*{Character List}%
  % Re-evaluate definitions
  \character@names
  \character@descs
  % Iterate over characters
  \foreach \char in \character@list {%
    \noindent\textbf{\csname \char name\endcsname}:~%
    \csname \char desc\endcsname\par
  }%
}

% Storage for location names and descriptions
\newcommand{\location@names}{}
\newcommand{\location@descs}{}
\newcommand{\location@list}{}

% Define new location: \newlocation[name=Labyrinth,desc=Underground maze]{maze}
\NewDocumentCommand{\newlocation}{O{}m}{%
  \begingroup
    \def\location@name{}%
    \def\location@desc{}%
    % Parse the key-value options
    \setkeys{location}{#1}%
    % Save data into lists
    \xappto{\location@names}{\def#2name{\location@name}}%
    \xappto{\location@descs}{\def#2desc{\location@desc}}%
    \xappto{\location@list}{#2,}%
    % Define macro that expands to the location name
    \expandafter\newcommand\csname #2\endcsname{\location@name}%
  \endgroup
}

% Define keys for location options
\makeatletter
\define@key{location}{name}{\def\location@name{#1}}
\define@key{location}{desc}{\def\location@desc{#1}}
\makeatother

% Command: \listlocations
\newcommand{\listlocations}{%
  \section*{Location List}%
  % Re-evaluate definitions
  \location@names
  \location@descs
  % Iterate over locations
  \foreach \loc in \location@list {%
    \noindent\textbf{\csname \loc name\endcsname}:~%
    \csname \loc desc\endcsname\par
  }%
}

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
