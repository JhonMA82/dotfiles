source /usr/share/cachyos-fish-config/cachyos-config.fish
set -gx EDITOR nvim

set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path $PNPM_HOME

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end


# Vault Linux Brain — sync-brain function
source ~/dev/linux_brain/90-meta/config/sync-brain.fish

if status is-interactive
    atuin init fish | source
end
