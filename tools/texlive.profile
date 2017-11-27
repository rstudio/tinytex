selected_scheme scheme-infraonly

TEXDIR ./texlive

TEXMFSYSCONFIG ./texlive/texmf-config
TEXMFCONFIG $TEXMFSYSCONFIG

TEXMFLOCAL ./texlive/texmf-local
TEXMFHOME $TEXMFLOCAL

TEXMFSYSVAR ./texlive/texmf-var
TEXMFVAR $TEXMFSYSVAR

option_doc 0
option_src 0
option_autobackup 0

portable 1
