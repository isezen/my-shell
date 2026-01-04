#!/bin/bash
# activate.bash - Bash environment activation
# Usage: source activate.bash

# Proje root dizinini bul
if [ -z "$MY_SHELL_ROOT" ]; then
    MY_SHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Zaten aktif mi kontrol et
if [ -n "$MY_SHELL_ACTIVATED" ]; then
    echo "my-shell environment is already activated"
    return 0 2>/dev/null || true
fi

# PATH'e scripts/ ekle
export MY_SHELL_OLD_PATH="$PATH"
export PATH="$MY_SHELL_ROOT/scripts:$PATH"

# alias.sh'i source et
if [ -f "$MY_SHELL_ROOT/alias.sh" ]; then
    source "$MY_SHELL_ROOT/alias.sh"
fi

# bash.sh'i source et ve prompt'u güncelle
if [ -f "$MY_SHELL_ROOT/bash.sh" ]; then
    export MY_SHELL_OLD_PS1="$PS1"
    source "$MY_SHELL_ROOT/bash.sh"
    export PS1="(my-shell) $PS1"
fi

# colortable.sh alias'ı
alias colortable="$MY_SHELL_ROOT/colortable.sh"

# Reactivate fonksiyonu
reactivate() {
    if [ -z "$MY_SHELL_ACTIVATED" ]; then
        echo "my-shell environment is not activated"
        echo "Use 'source env/activate.bash' to activate first"
        return 1
    fi

    echo "Reloading my-shell environment files..."

    # alias.sh'i yeniden source et
    if [ -f "$MY_SHELL_ROOT/alias.sh" ]; then
        source "$MY_SHELL_ROOT/alias.sh"
    fi

    # bash.sh'i yeniden source et ve prompt'u güncelle
    if [ -f "$MY_SHELL_ROOT/bash.sh" ]; then
        source "$MY_SHELL_ROOT/bash.sh"
        # Prompt'u güncelle (eğer (my-shell) prefix yoksa ekle)
        if [[ "$PS1" != "(my-shell)"* ]]; then
            export PS1="(my-shell) $PS1"
        fi
    fi

    # colortable.sh alias'ını yeniden tanımla
    alias colortable="$MY_SHELL_ROOT/colortable.sh"

    echo "my-shell environment reloaded"
}

# Deactivate fonksiyonu
deactivate() {
    if [ -z "$MY_SHELL_ACTIVATED" ]; then
        echo "my-shell environment is not activated"
        return 1
    fi

    # PATH'i geri yükle
    export PATH="$MY_SHELL_OLD_PATH"
    unset MY_SHELL_OLD_PATH

    # PS1'i geri yükle
    if [ -n "$MY_SHELL_OLD_PS1" ]; then
        export PS1="$MY_SHELL_OLD_PS1"
        unset MY_SHELL_OLD_PS1
    fi

    # Alias'ları kaldır
    unalias colortable 2>/dev/null || true

    # Değişkenleri temizle
    unset MY_SHELL_ACTIVATED
    unset MY_SHELL_ROOT
    unset -f deactivate
    unset -f reactivate

    echo "my-shell environment deactivated"
}

export MY_SHELL_ACTIVATED=1
export MY_SHELL_ROOT
echo "my-shell environment activated (bash)"

