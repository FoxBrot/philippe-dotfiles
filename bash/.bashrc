# ============================================================
# .bashrc — by Philippe Pereira (FoxBrot) (2026)
# ============================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ---- Aliases (using your installed tools) ----
alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias grep='rg'

# ---- zoxide ----
eval "$(zoxide init bash)"

# ---- Starship prompt ----
eval "$(starship init bash)"

# ---- Search on youtube ----
yt() {
  local query="$*"
  if [ -z "$query" ]; then
    setsid firefox --new-tab "https://www.youtube.com/" >/dev/null 2>&1 &
  else
    setsid firefox --new-tab "https://www.youtube.com/results?search_query=${query// /+}" >/dev/null 2>&1 &
  fi
  disown
}

ytm() {
  local query="$*"
  if [ -z "$query" ]; then
    setsid firefox --new-tab "https://music.youtube.com" >/dev/null 2>&1 &
  else
    setsid firefox --new-tab "https://music.youtube.com/search?q=${query// /+}" >/dev/null 2>&1 &
  fi
  disown
}

google() {
  local query="$*"
  if [ -z "$query" ]; then
    setsid firefox --new-tab "https://www.google.com/" >/dev/null 2>&1 &
  else
    setsid firefox --new-tab "https://www.google.com/search?q=${query// /+}" >/dev/null 2>&1 &
  fi
  disown
}

aur() {
  local query="$*"
  xdg-open "https://aur.archlinux.org/packages?K=${query// /+}"
}

roblox() {
  setsid flatpak run org.vinegarhq.Sober >/dev/null 2>&1 &
  disown
}
