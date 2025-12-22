# FZF key bindings configuration
# Source fzf key bindings if available
if test -f /usr/share/doc/fzf/examples/key-bindings.fish
  source /usr/share/doc/fzf/examples/key-bindings.fish
  fzf_key_bindings
end
