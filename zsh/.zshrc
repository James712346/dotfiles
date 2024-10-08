# Init Zoxide
#
eval "$(zoxide init zsh --cmd cd)"

# Set delete key to delete charaters
bindkey "^[[3~" delete-char

# Use bat for Man page
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# Use NeoVim as the default editor
#
export EDITOR="/usr/bin/nvim"\

# fzf Search cmd
alias hfz="fd --full-path /home/jamesp/ | fzf --preview='rsp {}' | xargs -r rso"
alias cfz="fd . | fzf --preview='rsp {}' | xargs -r rso"

eval "$(oh-my-posh init zsh --config '~/.config/oh-my-posh/config.toml')"

# set ssh to kitten
#alias ssh="kitten ssh"

# set golang to ~/.local/
export GOPATH=$HOME/.local/share/go
