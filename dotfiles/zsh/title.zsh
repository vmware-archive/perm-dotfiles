if [[ "${TERM}" == xterm* ]]; then
  precmd() {
    local title='%n'

    if [[ "${SSH_TTY}" ]]; then
      title+="@%m"
    fi

    title+=":%~"

    print -Pn "\e]0;${title}\a"
  }
fi
