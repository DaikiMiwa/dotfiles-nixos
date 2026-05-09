{ pkgs, lib, ... }:

let
  paperLuaArticleTemplate = pkgs.writeText "paper-lualatex-article.tex" ''
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

  paperLuaConferenceTemplate = pkgs.writeText "paper-lualatex-conference.tex" ''
    % !TEX program = lualatex
    \documentclass[a4paper,10pt,twocolumn]{ltjsarticle}

    \usepackage{amsmath,amssymb,amsthm}
    \usepackage{booktabs}
    \usepackage{graphicx}
    \usepackage[hidelinks]{hyperref}
    \usepackage[nameinlink,noabbrev]{cleveref}
    \usepackage[backend=biber,style=numeric,sorting=none]{biblatex}
    \addbibresource{references.bib}

    \title{Title}
    \author{Author}
    \date{}

    \begin{document}
    \maketitle

    \begin{abstract}
    \end{abstract}

    \section{Introduction}
    \label{sec:introduction}

    \section{Method}
    \label{sec:method}

    \section{Evaluation}
    \label{sec:evaluation}

    \section{Conclusion}
    \label{sec:conclusion}

    \printbibliography

    \end{document}
  '';

  paperMinimalTemplate = pkgs.writeText "paper-minimal.tex" ''
    % !TEX program = lualatex
    \documentclass[a4paper,11pt]{ltjsarticle}

    \usepackage{amsmath,amssymb}
    \usepackage{graphicx}
    \usepackage[hidelinks]{hyperref}

    \title{Title}
    \author{Author}
    \date{\today}

    \begin{document}
    \maketitle

    \section{Introduction}

    \end{document}
  '';

  paperPdfArticleTemplate = pkgs.writeText "paper-pdflatex-article.tex" ''
    % !TEX program = pdflatex
    \documentclass[a4paper,11pt]{article}

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

    \begin{document}
    \maketitle

    \begin{abstract}
    \end{abstract}

    \section{Introduction}
    \label{sec:introduction}

    \section{Method}
    \label{sec:method}

    \section{Conclusion}
    \label{sec:conclusion}

    \printbibliography

    \end{document}
  '';

  paperPtexArticleTemplate = pkgs.writeText "paper-platex-article.tex" ''
    % !TEX program = platex
    \documentclass[a4paper,11pt]{jsarticle}

    \usepackage{amsmath,amssymb,amsthm}
    \usepackage{booktabs}
    \usepackage[dvipdfmx]{graphicx}
    \usepackage[dvipdfmx,hidelinks]{hyperref}
    \usepackage{pxjahyper}

    \title{Title}
    \author{Author}
    \date{\today}

    \begin{document}
    \maketitle

    \begin{abstract}
    \end{abstract}

    \section{はじめに}
    \label{sec:introduction}

    \section{提案手法}
    \label{sec:method}

    \section{評価}
    \label{sec:evaluation}

    \section{おわりに}
    \label{sec:conclusion}

    \bibliographystyle{jplain}
    \bibliography{references}

    \end{document}
  '';

  paperUptexArticleTemplate = pkgs.writeText "paper-uplatex-article.tex" ''
    % !TEX program = uplatex
    \documentclass[uplatex,a4paper,11pt]{jsarticle}

    \usepackage{amsmath,amssymb,amsthm}
    \usepackage{booktabs}
    \usepackage[dvipdfmx]{graphicx}
    \usepackage[dvipdfmx,hidelinks]{hyperref}
    \usepackage{pxjahyper}

    \title{Title}
    \author{Author}
    \date{\today}

    \begin{document}
    \maketitle

    \begin{abstract}
    \end{abstract}

    \section{はじめに}
    \label{sec:introduction}

    \section{提案手法}
    \label{sec:method}

    \section{評価}
    \label{sec:evaluation}

    \section{おわりに}
    \label{sec:conclusion}

    \bibliographystyle{jplain}
    \bibliography{references}

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

  paperLuaLatexmkrcTemplate = pkgs.writeText "paper-lualatex-latexmkrc" ''
    $pdf_mode = 4;
    $lualatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
    $biber = 'biber %O %B';
    $out_dir = 'build';
    $clean_ext = 'acn acr alg aux bbl bcf blg brf fdb_latexmk fls glg glo gls idx ilg ind ist lof log lot nav nlo nls out run.xml snm synctex.gz toc vrb xdv';
  '';

  paperPdfLatexmkrcTemplate = pkgs.writeText "paper-pdflatex-latexmkrc" ''
    $pdf_mode = 1;
    $pdflatex = 'pdflatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
    $biber = 'biber %O %B';
    $out_dir = 'build';
    $clean_ext = 'acn acr alg aux bbl bcf blg brf fdb_latexmk fls glg glo gls idx ilg ind ist lof log lot nav nlo nls out run.xml snm synctex.gz toc vrb';
  '';

  paperPlatexLatexmkrcTemplate = pkgs.writeText "paper-platex-latexmkrc" ''
    $pdf_mode = 3;
    $latex = 'platex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
    $bibtex = 'pbibtex %O %B';
    $dvipdf = 'dvipdfmx %O -o %D %S';
    $makeindex = 'mendex %O -o %D %S';
    $out_dir = 'build';
    $clean_ext = 'acn acr alg aux bbl bcf blg brf dvi fdb_latexmk fls glg glo gls idx ilg ind ist lof log lot nav nlo nls out run.xml snm synctex.gz toc vrb';
  '';

  paperUplatexLatexmkrcTemplate = pkgs.writeText "paper-uplatex-latexmkrc" ''
    $pdf_mode = 3;
    $latex = 'uplatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
    $bibtex = 'upbibtex %O %B';
    $dvipdf = 'dvipdfmx %O -o %D %S';
    $makeindex = 'upmendex %O -o %D %S';
    $out_dir = 'build';
    $clean_ext = 'acn acr alg aux bbl bcf blg brf dvi fdb_latexmk fls glg glo gls idx ilg ind ist lof log lot nav nlo nls out run.xml snm synctex.gz toc vrb';
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
      pdfcrop
      texcount
      upmendex
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
      usage() {
        cat >&2 <<'EOF'
      Usage: paper-new [options] <directory>

      Options:
        --engine <lualatex|pdflatex|platex|uplatex>
        --lualatex | --pdflatex | --platex | --uplatex
        --template <article|conference|minimal>
        --article | --conference | --minimal
      EOF
      }

      engine="lualatex"
      template="article"

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --engine)
            if [ "$#" -lt 2 ]; then
              usage
              exit 2
            fi
            engine="$2"
            shift 2
            ;;
          --template)
            if [ "$#" -lt 2 ]; then
              usage
              exit 2
            fi
            template="$2"
            shift 2
            ;;
          --lualatex|--pdflatex|--platex|--uplatex)
            engine="''${1#--}"
            shift
            ;;
          --article|--conference|--minimal)
            template="''${1#--}"
            shift
            ;;
          --help|-h)
            usage
            exit 0
            ;;
          --*)
            echo "paper-new: unknown option: $1" >&2
            usage
            exit 2
            ;;
          *)
            if [ -n "''${paper_dir:-}" ]; then
              echo "paper-new: only one directory can be specified" >&2
              usage
              exit 2
            fi
            paper_dir="$1"
            shift
            ;;
        esac
      done

      if [ -z "''${paper_dir:-}" ]; then
        usage
        exit 2
      fi

      case "$template:$engine" in
        article:lualatex)
          main_template=${paperLuaArticleTemplate}
          latexmkrc_template=${paperLuaLatexmkrcTemplate}
          ;;
        conference:lualatex)
          main_template=${paperLuaConferenceTemplate}
          latexmkrc_template=${paperLuaLatexmkrcTemplate}
          ;;
        minimal:lualatex)
          main_template=${paperMinimalTemplate}
          latexmkrc_template=${paperLuaLatexmkrcTemplate}
          ;;
        article:pdflatex|conference:pdflatex)
          main_template=${paperPdfArticleTemplate}
          latexmkrc_template=${paperPdfLatexmkrcTemplate}
          ;;
        minimal:pdflatex)
          main_template=${paperPdfArticleTemplate}
          latexmkrc_template=${paperPdfLatexmkrcTemplate}
          ;;
        article:platex|conference:platex|minimal:platex)
          main_template=${paperPtexArticleTemplate}
          latexmkrc_template=${paperPlatexLatexmkrcTemplate}
          ;;
        article:uplatex|conference:uplatex|minimal:uplatex)
          main_template=${paperUptexArticleTemplate}
          latexmkrc_template=${paperUplatexLatexmkrcTemplate}
          ;;
        *)
          echo "paper-new: unsupported template/engine combination: $template/$engine" >&2
          exit 2
          ;;
      esac

      mkdir -p "$paper_dir"/{figures,tables,notes}

      main_tex="$paper_dir/main.tex"
      references_bib="$paper_dir/references.bib"
      latexmkrc="$paper_dir/.latexmkrc"
      gitignore="$paper_dir/.gitignore"

      if [ ! -e "$main_tex" ]; then
        install -m 0644 "$main_template" "$main_tex"
      fi

      if [ ! -e "$references_bib" ]; then
        install -m 0644 ${paperReferencesTemplate} "$references_bib"
      fi

      if [ ! -e "$latexmkrc" ]; then
        install -m 0644 "$latexmkrc_template" "$latexmkrc"
      fi

      if [ ! -e "$gitignore" ]; then
        install -m 0644 ${paperGitignoreTemplate} "$gitignore"
      fi

      printf "Created %s (%s, %s)\n" "$paper_dir" "$template" "$engine"
    '';
  };

  paper-check = pkgs.writeShellApplication {
    name = "paper-check";
    runtimeInputs = [
      texlive
      pkgs.bibtool
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.poppler-utils
    ];
    text = ''
      main="''${1:-main.tex}"
      if [ ! -f "$main" ]; then
        echo "paper-check: main TeX file not found: $main" >&2
        exit 2
      fi

      echo "== latexmk =="
      latexmk "$main"

      echo
      echo "== chktex =="
      find . -path './build' -prune -o -name '*.tex' -print0 \
        | xargs -0 -r chktex -q -n22 -n30 -n36 || true

      echo
      echo "== bibtool =="
      find . -path './build' -prune -o -name '*.bib' -print0 \
        | while IFS= read -r -d "" bib; do
            tmp="$(mktemp)"
            if bibtool -q -i "$bib" -o "$tmp"; then
              printf "ok %s\n" "$bib"
            else
              printf "failed %s\n" "$bib" >&2
              rm -f "$tmp"
              exit 1
            fi
            rm -f "$tmp"
          done

      echo
      echo "== unresolved references =="
      if find build -name '*.log' -print -quit 2>/dev/null | grep -q .; then
        grep -RInE 'Reference .* undefined|Citation .* undefined|There were undefined references|Rerun to get' build/*.log || true
      else
        echo "no build log found"
      fi

      echo
      echo "== TODO comments =="
      grep -RInE '%[[:space:]]*(TODO|FIXME|REVIEW|NOTE):' --include='*.tex' . || true

      echo
      echo "== texcount =="
      texcount -inc -total "$main" | tail -n 20 || true

      pdf="build/$(basename "$main" .tex).pdf"
      if [ ! -f "$pdf" ]; then
        pdf="$(basename "$main" .tex).pdf"
      fi

      echo
      echo "== PDF =="
      if [ -f "$pdf" ]; then
        pdfinfo "$pdf" | sed -n '1,20p'
      else
        echo "pdf not found"
      fi
    '';
  };

  paper-diff = pkgs.writeShellApplication {
    name = "paper-diff";
    runtimeInputs = [
      texlive
      pkgs.coreutils
    ];
    text = ''
      if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
        echo "Usage: paper-diff <old.tex> <new.tex> [out.tex]" >&2
        exit 2
      fi

      old="$1"
      new="$2"
      out="''${3:-diff.tex}"

      latexdiff "$old" "$new" > "$out"
      printf "Wrote %s\n" "$out"
    '';
  };

  paper-bib-sort = pkgs.writeShellApplication {
    name = "paper-bib-sort";
    runtimeInputs = [
      pkgs.bibtool
      pkgs.coreutils
    ];
    text = ''
      bib="''${1:-references.bib}"
      if [ ! -f "$bib" ]; then
        echo "paper-bib-sort: file not found: $bib" >&2
        exit 2
      fi

      tmp="$(mktemp)"
      bibtool -s -i "$bib" -o "$tmp"
      install -m 0644 "$tmp" "$bib"
      rm -f "$tmp"
      printf "Sorted %s\n" "$bib"
    '';
  };

  paper-bib-check = pkgs.writeShellApplication {
    name = "paper-bib-check";
    runtimeInputs = [
      pkgs.gawk
    ];
    text = ''
      bib="''${1:-references.bib}"
      if [ ! -f "$bib" ]; then
        echo "paper-bib-check: file not found: $bib" >&2
        exit 2
      fi

      awk '
        BEGIN { ignorecase = 1; status = 0 }
        /^[[:space:]]*@[[:alnum:]_-]+[[:space:]]*[{(]/ {
          key = $0
          sub(/^[^{(]*[{(][[:space:]]*/, "", key)
          sub(/[[:space:]]*,.*/, "", key)
          current = key
          title[current] = 0
          year[current] = 0
          if (seen[key]++) {
            printf "duplicate key: %s\n", key
            status = 1
          }
        }
        current != "" && /^[[:space:]]*title[[:space:]]*=/ { title[current] = 1 }
        current != "" && /^[[:space:]]*year[[:space:]]*=/ { year[current] = 1 }
        END {
          for (key in seen) {
            if (!title[key]) {
              printf "missing title: %s\n", key
              status = 1
            }
            if (!year[key]) {
              printf "missing year: %s\n", key
              status = 1
            }
          }
          exit status
        }
      ' "$bib"
    '';
  };

  paper-fig = pkgs.writeShellApplication {
    name = "paper-fig";
    runtimeInputs = [
      texlive
      pkgs.coreutils
      pkgs.imagemagick
      pkgs.librsvg
      pkgs.gnused
    ];
    text = ''
      if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: paper-fig <input.{svg,pdf,png,jpg}> [output.pdf]" >&2
        exit 2
      fi

      input="$1"
      output="''${2:-figures/$(basename "$input" | sed -E 's/\.[^.]+$/.pdf/')}"
      mkdir -p "$(dirname "$output")"

      case "''${input##*.}" in
        svg)
          rsvg-convert -f pdf -o "$output" "$input"
          ;;
        pdf)
          pdfcrop "$input" "$output"
          ;;
        png|jpg|jpeg)
          magick "$input" "$output"
          ;;
        *)
          echo "paper-fig: unsupported input: $input" >&2
          exit 2
          ;;
      esac

      printf "Wrote %s\n" "$output"
    '';
  };

  paper-count = pkgs.writeShellApplication {
    name = "paper-count";
    runtimeInputs = [
      texlive
      pkgs.coreutils
      pkgs.poppler-utils
    ];
    text = ''
      main="''${1:-main.tex}"
      if [ ! -f "$main" ]; then
        echo "paper-count: main TeX file not found: $main" >&2
        exit 2
      fi

      texcount -inc -total "$main"

      pdf="build/$(basename "$main" .tex).pdf"
      if [ ! -f "$pdf" ]; then
        pdf="$(basename "$main" .tex).pdf"
      fi
      if [ -f "$pdf" ]; then
        pdfinfo "$pdf" | sed -n '/^Pages:/p'
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
    paper-check
    paper-diff
    paper-bib-sort
    paper-bib-check
    paper-fig
    paper-count
    pkgs.bibtool
    pkgs.librsvg
    pkgs.ltex-ls-plus
    pkgs.imagemagick
    pkgs.pandoc
    pkgs.poppler-utils
    pkgs.python3Packages.pygments
    pkgs.tex-fmt
    pkgs.texlab
    pkgs.vale
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.zathura
  ];

  home.file.".latexindent.yaml".text = ''
    defaultIndent: "  "
    modifyLineBreaks:
      preserveBlankLines: 1
      condenseMultipleBlankLinesInto: 1
    lookForAlignDelims:
      align:
        delims: 1
        alignDoubleBackSlash: 1
        spacesBeforeDoubleBackSlash: 1
        spacesAfterDoubleBackSlash: 1
      tabular:
        delims: 1
        alignDoubleBackSlash: 1
        spacesBeforeDoubleBackSlash: 1
        spacesAfterDoubleBackSlash: 1
  '';
}
