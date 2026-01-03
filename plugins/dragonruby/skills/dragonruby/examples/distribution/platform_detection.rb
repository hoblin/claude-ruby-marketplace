# Platform-specific behavior at runtime

def tick(args)
  handle_platform_quirks(args)
  tick_game(args)
end

def handle_platform_quirks(args)
  # Open app store rating page
  if args.state.show_rating_prompt
    open_rating_page(args)
    args.state.show_rating_prompt = false
  end
end

def open_rating_page(args)
  if args.gtk.platform?(:ios)
    args.gtk.openurl "itms-apps://itunes.apple.com/app/idYOURGAMEID?action=write-review"
  elsif args.gtk.platform?(:android)
    args.gtk.openurl "https://play.google.com/store/apps/details?id=com.yourstudio.mygame"
  elsif args.gtk.platform?(:web)
    args.gtk.openurl "https://yourusername.itch.io/yourgame/purchase"
  else
    # Desktop (Windows, macOS, Linux)
    args.gtk.openurl "https://yourusername.itch.io/yourgame/rate?source=game"
  end
end

# Platform-specific asset paths
def get_save_path(args)
  if args.gtk.platform?(:web)
    "save.dat"  # Web uses IndexedDB via same path
  else
    "saves/game.dat"
  end
end
