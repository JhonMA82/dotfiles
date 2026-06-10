source /usr/share/cachyos-fish-config/cachyos-config.fish
set -gx EDITOR nvim

set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path $PNPM_HOME

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

