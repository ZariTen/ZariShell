dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
# Freeze the screen while selecting (hyprpicker -z draws a still frame).
hyprpicker -r -z & freeze=$!
trap 'kill $freeze 2>/dev/null || true' EXIT
sleep 0.15
geometry=$(slurp -d) || exit 0
file="$dir/Screenshot_$(date +%Y%m%d_%H%M%S).png"
grim -g "$geometry" "$file"
kill $freeze 2>/dev/null || true
wl-copy --type image/png < "$file"
notify-send -a "Screenshot" -i applets-screenshooter -h "string:image-path:$file" "Screenshot saved" "$(basename "$file")"
