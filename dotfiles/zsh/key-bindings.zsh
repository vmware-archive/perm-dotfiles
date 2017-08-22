# Adapted from oh-my-zsh

# Bash-style word delimiting
export WORDCHARS=''

# start typing + [Up-Arrow] - fuzzy find history forward
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search

# start typing + [Down-Arrow] - fuzzy find history backward
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

bindkey '^[^[[C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey "^[^[[D" backward-word # [Ctrl-LeftArrow] - move backward one word

bindkey "^[[H" beginning-of-line      # [Home] - Go to beginning of line
bindkey "^[[F"  end-of-line            # [End] - Go to end of line

bindkey "^[[Z" reverse-menu-complete   # [Shift-Tab] - move through the completion menu backwards

bindkey '^r' history-incremental-search-backward      # [Ctrl-r] - Search backward incrementally for a specified string. The string may begin with ^ to anchor the search to the beginning of the line.

bindkey "^[[5~" up-line-or-history # [PageUp] - Up a line of history
bindkey "^[[6~" down-line-or-history # [PageDown] - Down a line of history
