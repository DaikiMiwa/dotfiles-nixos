{ pkgs, lib, ... }:

let
  paperMainTemplate = pkgs.writeText "paper-main.tex" ''
    % !TEX program = lualatex
    \documentclass[a4paper,11pt]{ltjsarticle}

    \usepackage{amsmath,amssymb,amsthm}
    \usepackage{booktabs}
    \usepackage{graphicx}
    \usepackage[hidelinks]{hyperref}
    \usepackage[nameinlink,noabbrev]{cleveref}
    \usepackage[backend=biber,style=numeric,sorting=none]{biblatex}
    \addbibresource{references.bib}

    \title{Title}
    \author{Author}
    \date{\today}

    \theoremstyle{definition}
    \newtheorem{definition}{Definition}
    \newtheorem{theorem}{Theorem}
    \newtheorem{lemma}{Lemma}

    \begin{document}
    \maketitle

    \begin{abstract}
    \end{abstract}

    \section{Introduction}
    \label{sec:introduction}

    \section{Related Work}
    \label{sec:related-work}

    \section{Method}
    \label{sec:method}

    \section{Experiments}
    \label{sec:experiments}

    \section{Conclusion}
    \label{sec:conclusion}

    \printbibliography

    \end{document}
  '';

  paperReferencesTemplate = pkgs.writeText "paper-references.bib" ''
    @article{example2026,
      author  = {Author, Alice and Writer, Bob},
      title   = {Example Paper},
      journal = {Journal Name},
      year    = {2026},
    }
  '';

  paperLatexmkrcTemplate = pkgs.writeText "paper-latexmkrc" ''
    $pdf_mode = 4;
    $lualatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
    $biber = 'biber %O %B';
    $out_dir = 'build';
  '';

  paperGitignoreTemplate = pkgs.writeText "paper-gitignore" ''
    /build/
    *.aux
    *.bbl
    *.bcf
    *.blg
    *.fdb_latexmk
    *.fls
    *.log
    *.out
    *.run.xml
    *.synctex.gz
  '';

  texlive = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-medium
      latexmk
      latexindent
      chktex
      biber
      biblatex
      collection-bibtexextra
      collection-fontsrecommended
      collection-langcjk
      collection-langjapanese
      collection-latexextra
      collection-luatex
      collection-pictures
      collection-publishers
      latexdiff
      ;
  };

  latexmk-lualatex = pkgs.writeShellApplication {
    name = "latexmk-lualatex";
    runtimeInputs = [
      texlive
    ];
    text = ''
      exec latexmk -lualatex "$@"
    '';
  };

  latexmk-pdflatex = pkgs.writeShellApplication {
    name = "latexmk-pdflatex";
    runtimeInputs = [
      texlive
    ];
    text = ''
      exec latexmk -pdf "$@"
    '';
  };

  latexmk-platex = pkgs.writeShellApplication {
    name = "latexmk-platex";
    runtimeInputs = [
      texlive
    ];
    text = ''
      exec latexmk \
        -pdfdvi \
        -latex='platex -synctex=1 -interaction=nonstopmode -file-line-error %O %S' \
        -bibtex='pbibtex %O %B' \
        -dvipdf='dvipdfmx %O -o %D %S' \
        "$@"
    '';
  };

  latexmk-uplatex = pkgs.writeShellApplication {
    name = "latexmk-uplatex";
    runtimeInputs = [
      texlive
    ];
    text = ''
      exec latexmk \
        -pdfdvi \
        -latex='uplatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S' \
        -bibtex='upbibtex %O %B' \
        -dvipdf='dvipdfmx %O -o %D %S' \
        "$@"
    '';
  };

  paper-new = pkgs.writeShellApplication {
    name = "paper-new";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: paper-new <directory>" >&2
        exit 2
      fi

      paper_dir="$1"
      mkdir -p "$paper_dir"/{figures,tables,notes}

      main_tex="$paper_dir/main.tex"
      references_bib="$paper_dir/references.bib"
      latexmkrc="$paper_dir/.latexmkrc"
      gitignore="$paper_dir/.gitignore"

      if [ ! -e "$main_tex" ]; then
        install -m 0644 ${paperMainTemplate} "$main_tex"
      fi

      if [ ! -e "$references_bib" ]; then
        install -m 0644 ${paperReferencesTemplate} "$references_bib"
      fi

      if [ ! -e "$latexmkrc" ]; then
        install -m 0644 ${paperLatexmkrcTemplate} "$latexmkrc"
      fi

      if [ ! -e "$gitignore" ]; then
        install -m 0644 ${paperGitignoreTemplate} "$gitignore"
      fi
    '';
  };
in
{
  home.packages = [
    texlive
    latexmk-lualatex
    latexmk-pdflatex
    latexmk-platex
    latexmk-uplatex
    paper-new
    pkgs.bibtool
    pkgs.pandoc
    pkgs.poppler-utils
    pkgs.python3Packages.pygments
    pkgs.tex-fmt
    pkgs.texlab
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.zathura
  ];
}
