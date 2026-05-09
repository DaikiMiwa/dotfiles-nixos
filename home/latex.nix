{ pkgs, lib, ... }:

let
  texlive = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-medium
      latexmk
      latexindent
      chktex
      collection-bibtexextra
      collection-fontsrecommended
      collection-langcjk
      collection-langjapanese
      collection-latexextra
      collection-luatex
      collection-pictures
      collection-publishers
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
in
{
  home.packages = [
    texlive
    latexmk-lualatex
    latexmk-pdflatex
    latexmk-platex
    latexmk-uplatex
    pkgs.python3Packages.pygments
    pkgs.tex-fmt
    pkgs.texlab
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.zathura
  ];
}
