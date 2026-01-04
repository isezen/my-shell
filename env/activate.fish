#!/usr/bin/env fish
# activate.fish - Fish environment activation
# Usage: source activate.fish

# Proje root dizinini bul
if not set -q MY_SHELL_ROOT
    set -gx MY_SHELL_ROOT (cd (dirname (status -f))/.. && pwd)
end

# Zaten aktif mi kontrol et
if set -q MY_SHELL_ACTIVATED
    echo "my-shell environment is already activated"
    return 0
end

# PATH'e scripts/ ekle
set -gx MY_SHELL_OLD_PATH $PATH
set -gx PATH "$MY_SHELL_ROOT/scripts" $PATH

# my_settings.fish'i source et
if test -f "$MY_SHELL_ROOT/my_settings.fish"
    source "$MY_SHELL_ROOT/my_settings.fish"
end

# colortable.sh fonksiyonu
function colortable
    bash "$MY_SHELL_ROOT/colortable.sh" $argv
end

# Prompt'a environment name ekle
function __my_shell_prompt_prefix
    echo -n "(my-shell) "
end

# fish_prompt'u yedekle ve değiştir
if not functions -q __my_shell_old_fish_prompt
    functions -c fish_prompt __my_shell_old_fish_prompt
    function fish_prompt
        __my_shell_prompt_prefix
        __my_shell_old_fish_prompt
    end
end

# Reactivate fonksiyonu
function reactivate -d "Reload my-shell environment files"
    if not set -q MY_SHELL_ACTIVATED
        echo "my-shell environment is not activated"
        echo "Use 'source env/activate.fish' to activate first"
        return 1
    end

    echo "Reloading my-shell environment files..."

    # my_settings.fish'i yeniden source et
    if test -f "$MY_SHELL_ROOT/my_settings.fish"
        source "$MY_SHELL_ROOT/my_settings.fish"
    end

    # colortable.sh fonksiyonunu yeniden tanımla
    function colortable
        bash "$MY_SHELL_ROOT/colortable.sh" $argv
    end

    echo "my-shell environment reloaded"
end

# Deactivate fonksiyonu
function deactivate -d "Deactivate my-shell environment"
    if not set -q MY_SHELL_ACTIVATED
        echo "my-shell environment is not activated"
        return 1
    end

    # PATH'i geri yükle
    set -gx PATH $MY_SHELL_OLD_PATH
    set -e MY_SHELL_OLD_PATH

    # fish_prompt'u geri yükle
    if functions -q __my_shell_old_fish_prompt
        functions -c __my_shell_old_fish_prompt fish_prompt
        functions -e __my_shell_old_fish_prompt
    end
    functions -e __my_shell_prompt_prefix
    functions -e colortable
    functions -e deactivate
    functions -e reactivate

    # Değişkenleri temizle
    set -e MY_SHELL_ACTIVATED
    set -e MY_SHELL_ROOT

    echo "my-shell environment deactivated"
end

set -gx MY_SHELL_ACTIVATED 1
echo "my-shell environment activated (fish)"

