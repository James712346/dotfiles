# Init Zoxide
#
~/.secrets
eval "$(zoxide init zsh --cmd cd)"

# Set delete key to delete charaters
bindkey "^[[3~" delete-char

# Use bat for Man page
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# Matlab Library, idk Why its needed
export LD_LIBRARY_PATH="/opt/cuda/lib64:/home/jamesp/extra/matlab/gnutls/usr/lib/:$LD_LIBRARY_PATH"

# Moving to doas, change sudo to doas
alias sudo=doas

# Use NeoVim as the default editor
#
export EDITOR="/usr/bin/nvim"\

export BROWSER="zen-browser"
# fzf Search cmd
alias hfz="fd --full-path /home/jamesp/ | fzf --preview='rsp {}' | xargs -r rso"
alias cfz="fd . | fzf --preview='rsp {}' | xargs -r rso"

eval "$(oh-my-posh init zsh --config '~/.config/oh-my-posh/config.json')"

# set golang to ~/.local/
export GOPATH=$HOME/.local/share/go

if [[ -o interactive ]]; then
    fastfetch --config arch 
fi

source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select
# addding history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
export PATH=/opt/cuda/bin:/home/jamesp/.local/bin:$PATH


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/jamesp/.opam/opam-init/init.zsh' ]] || source '/home/jamesp/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration
