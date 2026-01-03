#!/bin/bash
# DragonRuby publishing workflow

# 1. Clean up player-specific data before packaging
rm -f mygame/high-score.txt
rm -f mygame/saves/*
rm -rf mygame/tmp/*

# 2. Package only (creates ./builds/ directory)
./dragonruby-publish --only-package

# 3. Test locally before uploading
# - Linux:   ./builds/mygame-linux-amd64.bin
# - macOS:   open ./builds/mygame-mac-*/My\ Game.app
# - Windows: ./builds/mygame-windows-amd64.exe

# 4. Publish to itch.io (after first manual setup)
./dragonruby-publish mygame

# Alternative: Manual upload mode
# ./dragonruby-publish --package mygame
# Then upload ./builds/*.zip to itch.io manually

# 5. Publish to Steam (requires steam_metadata.txt)
# ./dragonruby-publish
# Uses steamcmd for authentication
