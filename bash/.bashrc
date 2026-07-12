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
