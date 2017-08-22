# Adapted from oh-my-zsh

zmodload -i zsh/complist
autoload -U compaudit compinit

setopt always_to_end
setopt auto_list
setopt auto_menu
setopt complete_in_word
setopt glob_complete
unsetopt menu_complete

# colours!
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# [Enter] picks menu option without executing command
zstyle ':completion:*:*:*:*:*' menu select

# case insensitive (all), partial-word and substring completion
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR
