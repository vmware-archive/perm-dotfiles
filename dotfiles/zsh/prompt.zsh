setopt promptsubst

user_prompt() {
  local user="%B%F{magenta}%n%f%b"

  if [[ "${SSH_TTY}" ]]; then
    user+="%F{255} at "
    user+="%B%F{magenta}%m%f%b"
  fi

  echo -e "${user}"
}

workdir_prompt() {
  echo -e "%F{255} in %f%B%F{green}%~%f%b"
}

git_prompt() {
  local branch_name=''
  local git_status=''

  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == 'true' ]]; then
    branch_name="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || \
      git rev-parse --short HEAD 2>/dev/null || \
      echo 'UNKNOWN')"

    if [[ -n "$(git status --porcelain)" ]]; then
      git_status=" %B%F{red}[+]%f%b"
    fi

    echo -e " %F{255}on%f %B%F{blue}${branch_name}%f%b${git_status}"
  fi
}

command_prompt() {
  echo -e "\n%(?:%B%F{255}❯%f%b:%B%F{red}❯%f%b) "
}

PS1='$(user_prompt)'
PS1+='$(workdir_prompt)'
PS1+='$(git_prompt)'
PS1+='$(command_prompt)'

export PS1
