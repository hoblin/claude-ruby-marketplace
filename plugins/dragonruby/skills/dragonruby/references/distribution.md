# Distribution

## Overview

DragonRuby builds cross-platform with one command via `dragonruby-publish`.

| Platform | Output Format | Notes |
|----------|---------------|-------|
| Windows | `.exe` | 64-bit only |
| macOS | `.app` bundle | Intel + Apple Silicon |
| Linux | Binary | Including SteamOS |
| HTML5 | `.zip` | Requires SharedArrayBuffer |
| Android | `.apk` / `.aab` | Requires signing |
| iOS | `.ipa` | Requires signing |

## game_metadata.txt

Located at `mygame/metadata/game_metadata.txt`. **All fields required.**

```txt
devid=youritchusername
devtitle=Your Studio Name
gameid=my-game-slug
gametitle=My Game Title
version=0.1
icon=metadata/icon.png
```

| Field | Purpose | Notes |
|-------|---------|-------|
| `devid` | itch.io username | Lowercase, no spaces |
| `devtitle` | Developer display name | Can have spaces |
| `gameid` | itch.io project URL slug | Must match exactly |
| `gametitle` | Game display name | Can have spaces |
| `version` | Release version | MAJOR.MINOR format |
| `icon` | Path to icon | Relative to mygame/ |

**Optional fields:**

```txt
# Mobile package ID (required for Android/iOS)
packageid=com.yourstudio.mygame

# Exclude directories from builds
ignore_directories=saves,debug
ignore_directories_recursively=true

# High-DPI support
hd=true
highdpi=true
```

## Version Numbering

Simple `MAJOR.MINOR` scheme:

| Phase | Version | When to increment |
|-------|---------|-------------------|
| Development | `0.1` → `0.2` → `0.3` | Each development milestone |
| Initial Release | `1.0` | Game is complete |
| Updates | `1.1` → `1.2` | Bug fixes, content updates |
| Major Overhaul | `2.0` | Significant changes |

## dragonruby-publish Tool

**Package only (creates builds/):**

```sh
./dragonruby-publish --only-package
# OR
./dragonruby-publish --package mygame
```

**Package and upload to itch.io:**

```sh
./dragonruby-publish mygame
```

Requires `gameid` to match itch.io project slug exactly.

**Build output location:** `./builds/` directory

## Pre-Release Checklist

Before running `dragonruby-publish`:

1. **Delete player-specific data:**
   ```sh
   rm -f mygame/high-score.txt
   rm -f mygame/saves/*
   ```

2. **Verify metadata:**
   - All 6 required fields filled
   - `gameid` matches itch.io project
   - Version incremented

3. **Test local build:**
   - Run platform-appropriate binary from `builds/`
   - Verify game plays correctly

## itch.io Deployment

### First-Time Setup

1. Create project at https://itch.io/game/new
2. Set **Project URL** (becomes `gameid`)
3. Select **HTML** as project type (supports web + downloads)
4. Run `./dragonruby-publish --only-package`
5. Upload builds manually

### HTML5 Configuration (Critical)

| Setting | Value | Required |
|---------|-------|----------|
| "This file will be played in browser" | Checked | Yes |
| SharedArrayBuffer support | **Enabled** | **Yes** |
| Viewport width | 1280 | Landscape |
| Viewport height | 720 | Landscape |

**For portrait games:** 540x960

**Without SharedArrayBuffer, HTML5 builds will not run.**

### Subsequent Updates

```sh
./dragonruby-publish mygame
```

Auto-uploads if `gameid` matches project slug.

### Publishing States

| State | Visibility | Use Case |
|-------|------------|----------|
| Private | Only you | Development |
| Secret URL | Shared link only | Playtesting |
| Public | Everyone | Release |

## Steam Deployment

Requires Steam publisher account and app configuration.

**Create `metadata/steam_metadata.txt`:**

```txt
steam.publish=true
steam.branch=public
steam.username=YOUR_STEAM_USERNAME
steam.appid=YOUR_APP_ID
steam.linux_depotid=LINUX_DEPOT_ID
steam.windows_depotid=WINDOWS_DEPOT_ID
steam.mac_depotid=MAC_DEPOT_ID
```

## Mobile Deployment

**Required in game_metadata.txt:**

```txt
packageid=com.yourstudio.mygame
```

Uses reverse domain notation.

### Build Outputs

| Platform | Files | Notes |
|----------|-------|-------|
| Android | `APP-android.apk`, `APP-googleplay.aab` | AAB for Play Store |
| iOS | `.ipa` | Requires Xcode signing |

**APK Signing (external tools):**

```sh
# Generate keystore
keytool -genkey -v -keystore my-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my-key-alias

# Sign APK
apksigner sign --ks my-release-key.jks \
  --out signed.apk unsigned.apk
```

## Platform Detection

Runtime platform checks for platform-specific behavior:

```ruby
if args.gtk.platform?(:ios)
  # iOS-specific code
elsif args.gtk.platform?(:android)
  # Android-specific code
elsif args.gtk.platform?(:web)
  # HTML5/browser code
else
  # Desktop (Windows, macOS, Linux)
end
```

## Background Pause (Web/Mobile)

Handle focus loss gracefully:

```ruby
def tick(args)
  if !args.inputs.keyboard.has_focus &&
     args.gtk.production &&
     Kernel.tick_count != 0
    # Game paused
    args.outputs.background_color = [0, 0, 0]
    args.outputs.labels << {
      x: 640, y: 360,
      text: "Click to resume",
      alignment_enum: 1,
      r: 255, g: 255, b: 255
    }
    return  # Skip game logic
  end

  # Normal game tick
  tick_game(args)
end
```

**Disable via cvars.txt:**

```txt
renderer.background_sleep=0
```

## In-Game Rating Prompts

```ruby
def open_rating_page(args)
  if args.gtk.platform?(:ios)
    args.gtk.openurl "itms-apps://itunes.apple.com/app/idYOURGAMEID?action=write-review"
  elsif args.gtk.platform?(:android)
    args.gtk.openurl "https://play.google.com/store/apps/details?id=YOURGAMEID"
  elsif args.gtk.platform?(:web)
    args.gtk.openurl "https://yourusername.itch.io/yourgame/purchase"
  else
    args.gtk.openurl "https://yourusername.itch.io/yourgame/rate?source=game"
  end
end
```

## Icon Preparation

Default location: `mygame/metadata/icon.png`

| Platform | Requirements |
|----------|-------------|
| Desktop | Any size, PNG recommended |
| itch.io | 315x250 cover image separate |
| Mobile | Multiple sizes via asset catalogs |

## Project Structure for Distribution

**Recommended .gitignore:**

```gitignore
# Always ignore
/tmp/
/logs/

# For public/open-source repos
/builds/
/samples/
/docs/
/.dragonruby/
```

**Best practice:** Commit entire engine per project. Ensures known-working version years later.

## Console Wizard

Interactive metadata setup via console:

```ruby
$wizards.itch.start
```

Prompts for all required fields, then runs `dragonruby-publish --only-package`.

## Common Antipatterns

| Don't | Why | Instead |
|-------|-----|---------|
| Ship with dev data | Players see your high scores | Delete temp files pre-build |
| Skip local testing | Broken builds on platforms | Test each platform build |
| Wrong viewport size | Layout issues on itch.io | Use 1280x720 (landscape) |
| Forget SharedArrayBuffer | HTML5 won't run | Enable in itch.io settings |
| Inconsistent versioning | Players confused about updates | Increment on every release |
| Share engine folder | Path issues, version conflicts | Copy engine per project |

## Decision Tree

```
What platform are you targeting?
│
├─► Desktop only (Windows/macOS/Linux)
│   └─► Use: game_metadata_minimal.txt
│       • Fill 6 required fields
│       • Run: ./dragonruby-publish --only-package
│       • Upload to itch.io or Steam
│
├─► Web (HTML5) + Desktop
│   └─► Use: game_metadata_hd.txt
│       • Add hd=true, highdpi=true
│       • CRITICAL: Enable SharedArrayBuffer on itch.io
│       • Set viewport: 1280x720
│
├─► Mobile (Android/iOS)
│   └─► Use: game_metadata_mobile.txt
│       • Add packageid=com.studio.game
│       • Set orientation=portrait or landscape
│       • Sign APK externally
│
└─► Steam Distribution
    └─► Use: steam_metadata.txt
        • Get Steamworks publisher account
        • Configure depot IDs
        • Run: ./dragonruby-publish

Publishing workflow?
│
├─► First release
│   ├─► 1. Clean dev data (rm saves/*, high-score.txt)
│   ├─► 2. Configure game_metadata.txt
│   ├─► 3. ./dragonruby-publish --only-package
│   ├─► 4. Test builds locally
│   ├─► 5. Create itch.io project
│   ├─► 6. Upload builds manually
│   └─► See: build_workflow.sh
│
└─► Update release
    ├─► 1. Increment version in game_metadata.txt
    ├─► 2. Clean dev data
    ├─► 3. ./dragonruby-publish mygame
    └─► Auto-uploads to itch.io

Platform-specific behavior needed?
│
├─► Different rating URLs → platform_detection.rb
├─► Handle tab-away/minimize → background_pause.rb
└─► Different save paths → platform_detection.rb
```

## Examples

| Example | Purpose |
|---------|---------|
| `game_metadata_minimal.txt` | Required fields only |
| `game_metadata_hd.txt` | HD desktop/web game |
| `game_metadata_mobile.txt` | Mobile with portrait orientation |
| `cvars_production.txt` | Production runtime settings |
| `steam_metadata.txt` | Steam publishing config |
| `build_workflow.sh` | Complete publishing script |
| `platform_detection.rb` | Runtime platform checks |
| `background_pause.rb` | Handle focus loss |
