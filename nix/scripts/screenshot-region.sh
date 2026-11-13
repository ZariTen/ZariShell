dir=${ZARISHELL_SCREENSHOT_DIR:-}
if [ -z "$dir" ]; then
    pictures=${XDG_PICTURES_DIR:-}
    user_dirs="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
    if [ -z "$pictures" ] && [ -r "$user_dirs" ]; then
        # Parse the XDG quoted value as data, never source shell assignments.
        pictures=$(awk '
            /^XDG_PICTURES_DIR="/ {
                value = $0; sub(/^XDG_PICTURES_DIR="/, "", value)
                if (value !~ /"$/) next
                sub(/"$/, "", value); prefix = ""; out = ""; valid = 1
                for (h = 1; h <= 2; h++) {
                    home = h == 1 ? "$HOME" : "${HOME}"
                    if (value == home || index(value, home "/") == 1) {
                        prefix = ENVIRON["HOME"]; value = substr(value, length(home) + 1); break
                    }
                }
                for (i = 1; i <= length(value); i++) {
                    ch = substr(value, i, 1)
                    if (ch == "\\") {
                        ch = substr(value, ++i, 1)
                        if (ch == "") { valid = 0; break }
                        if (ch != "\\" && ch != "\"" && ch != "$" && ch != "`") out = out "\\"
                    } else if (ch == "\"") { valid = 0; break }
                    out = out ch
                }
                out = prefix out
                if (valid && substr(out, 1, 1) == "/") { print out; exit }
            }
        ' "$user_dirs")
    fi
    case "$pictures" in /*) ;; *) pictures="$HOME/Pictures" ;; esac
    dir="$pictures/Screenshots"
fi
mkdir -p -- "$dir"
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
