selected_scheme scheme-infraonly

TEXDIR ./

TEXMFSYSCONFIG ./texmf-config
TEXMFCONFIG $TEXMFSYSCONFIG

TEXMFLOCAL ./texmf-local
TEXMFHOME $TEXMFLOCAL

TEXMFSYSVAR ./texmf-var
TEXMFVAR $TEXMFSYSVAR

option_doc 0
option_src 0
option_autobackup 0

portable 1
