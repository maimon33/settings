#!/usr/bin/env bash

bash -c 'cat > ~/Library/Application\ Support/Code/User/settings.json <<EOL
{
    "files.autoSave": "onFocusChange",
    "vim.disableAnnoyingNeovimMessage": true,
    "workbench.colorTheme": "Monokai Dimmed"
}
EOL'
