# Region screenshot -> clipboard + ~/Pictures/Screenshots + notification.
mkdir -p "$HOME/Pictures/Screenshots"
file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
geometry="$(slurp)" || exit 0
grim -g "$geometry" - | tee "$file" | wl-copy --type image/png
notify-send -a Screenshot -i "$file" "Region captured" "Copied to clipboard and saved to $(basename "$file")"
