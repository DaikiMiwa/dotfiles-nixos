{ pkgs, ... }:
let
  shell-advisor = pkgs.writeShellApplication {
    name = "shell-advisor";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./shell-advisor.py} "$@"
    '';
  };
in
{
  home.packages = [ shell-advisor ];
  programs.zsh.initContent = ''
    autoload -Uz add-zsh-hook
    typeset -g _shell_advisor_next=0
    _shell_advisor_precmd() {
      (( SECONDS < _shell_advisor_next )) && return
      _shell_advisor_next=$(( SECONDS + 300 ))
      command shell-advisor show
      HISTFILE="$HISTFILE" command shell-advisor run >/dev/null 2>&1 &!
    }
    add-zsh-hook precmd _shell_advisor_precmd
  '';
}
