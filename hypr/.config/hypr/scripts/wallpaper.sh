#!/usr/bin/env bash
# ============================================================
# wallpaper.sh — carousel wallpaper picker (kitty + awww + mpvpaper)
#   Images → awww (animated transitions)
#   Videos (.mp4/.webm/.mkv) → mpvpaper (looping video wallpaper)
#   ← → browse · desktop applies when you pause on one
#   Enter = keep · Esc = revert
#   Opens on the CURRENT wallpaper (no change on open).
# Requires: awww (daemon running), mpvpaper, kitty, imagemagick, ffmpeg
# ============================================================

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-picker"

TRANSITION_FPS=60
TRANSITION_DURATION=0.7
TRANSITION_STEP=90
DEBOUNCE=0.35
MONITOR='*'          # mpvpaper output: '*' = all monitors

# --- Palette (ANSI truecolor, matches the Waybar theme) ---
CREAM=$'\033[38;2;207;194;166m'     # #cfc2a6
LIGHT=$'\033[38;2;235;227;211m'     # #ebe3d3
GREY=$'\033[38;2;138;131;119m'      # #8a8377
ACCENT=$'\033[38;2;217;130;46m'     # #d9822e
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

is_video() { [[ "$1" =~ \.(mp4|webm|mkv)$ ]]; }

stop_video() { pkill -x mpvpaper 2>/dev/null; }

apply() {
    # $1 = filename, $2 = transition type
    if is_video "$1"; then
        local frame="$CACHE_DIR/$1.first.png"
        stop_video
        (
            # transition into the video's first frame, then start the video on top
            if [ -f "$frame" ]; then
                awww img "$frame" \
                    --transition-type "${2:-grow}" \
                    --transition-fps "$TRANSITION_FPS" \
                    --transition-duration "$TRANSITION_DURATION" \
                    --transition-step "$TRANSITION_STEP" >/dev/null 2>&1
                sleep "$TRANSITION_DURATION"
            fi
            setsid -f mpvpaper -o "no-audio loop-file=inf" "$MONITOR" "$WALLPAPER_DIR/$1" >/dev/null 2>&1
        ) &
    else
        stop_video
        local ttype="${2:-grow}"
        awww img "$WALLPAPER_DIR/$1" \
            --transition-type "$ttype" \
            --transition-fps "$TRANSITION_FPS" \
            --transition-duration "$TRANSITION_DURATION" \
            --transition-step "$TRANSITION_STEP" >/dev/null 2>&1 &
    fi
}

# --- Gather wallpapers (images + videos) ---
mapfile -t walls < <(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
       -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) \
    -printf "%f\n" | sort)

n=${#walls[@]}
if [ "$n" -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    sleep 2
    exit 1
fi

# --- Thumbnail cache (video thumbs + first frames via ffmpeg) ---
mkdir -p "$CACHE_DIR"
for wp in "${walls[@]}"; do
    thumb="$CACHE_DIR/$wp.png"
    src="$WALLPAPER_DIR/$wp"
    if [ ! -f "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        if is_video "$wp"; then
            firstframe="$CACHE_DIR/$wp.first.png"
            ffmpeg -y -ss 1 -i "$src" -frames:v 1 "$firstframe" >/dev/null 2>&1
            magick "$firstframe" -resize 800x450 "$thumb" 2>/dev/null \
                || convert "$firstframe" -resize 800x450 "$thumb" 2>/dev/null
        else
            magick "$src" -resize 800x450 "$thumb" 2>/dev/null \
                || convert "$src" -resize 800x450 "$thumb" 2>/dev/null
        fi
    fi
done

thumb_of() { echo "$CACHE_DIR/$1.png"; }

# --- Start on the CURRENT wallpaper (video or image) ---
if pgrep -x mpvpaper >/dev/null; then
    ORIGINAL_NAME=$(basename "$(pgrep -ax mpvpaper | head -1 | grep -oP "$WALLPAPER_DIR/\K[^ ]+")" 2>/dev/null)
else
    ORIGINAL_PATH=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
    ORIGINAL_NAME=$(basename "$ORIGINAL_PATH" 2>/dev/null)
fi

idx=0
for i in "${!walls[@]}"; do
    [ "${walls[$i]}" = "$ORIGINAL_NAME" ] && idx=$i && break
done

last_applied="$ORIGINAL_NAME"

# --- Geometry ---
geom() {
    cols=$(tput cols); lines=$(tput lines)

    # frame around the center thumbnail
    fw=$(( cols * 46 / 100 ))               # frame width
    fh=$(( lines - 8 ))                     # frame height
    fx=$(( (cols - fw) / 2 ))               # frame x
    fy=2                                    # frame y

    cw=$(( fw - 4 )); ch=$(( fh - 2 ))      # center image inside frame
    cx=$(( fx + 2 )); cy=$(( fy + 1 ))

    sw=$(( cols * 20 / 100 ))               # side thumbs
    sh=$(( ch * 55 / 100 ))
    sy=$(( fy + (fh - sh) / 2 ))
    lx=$(( fx - sw - 3 ))
    rx=$(( fx + fw + 3 ))
}

place() {
    kitten icat --transfer-mode=memory --stdin=no --place "$2" "$1" 2>/dev/null
}

frame() {
    # rounded cream frame around the center image
    local i top bot
    top="╭$(printf '─%.0s' $(seq 1 $(( fw - 2 ))))╮"
    bot="╰$(printf '─%.0s' $(seq 1 $(( fw - 2 ))))╯"

    tput cup "$fy" "$fx";               printf '%s%s%s' "$CREAM" "$top" "$RESET"
    for i in $(seq 1 $(( fh - 2 ))); do
        tput cup $(( fy + i )) "$fx";              printf '%s│%s' "$CREAM" "$RESET"
        tput cup $(( fy + i )) $(( fx + fw - 1 )); printf '%s│%s' "$CREAM" "$RESET"
    done
    tput cup $(( fy + fh - 1 )) "$fx";  printf '%s%s%s' "$CREAM" "$bot" "$RESET"
}

dots() {
    # position indicator: ● for current (accent), ○ for others
    local out="" i
    for i in $(seq 0 $(( n - 1 ))); do
        if [ "$i" -eq "$idx" ]; then out+="${ACCENT}●${RESET} "
        else out+="${GREY}○${RESET} "; fi
    done
    local vlen=$(( n * 2 ))
    tput cup $(( lines - 3 )) $(( (cols - vlen) / 2 ))
    printf '%b' "$out"
}

draw() {
    geom
    clear
    kitten icat --clear 2>/dev/null

    # header
    local title="  Wallpapers"
    tput cup 0 $(( (cols - ${#title}) / 2 ))
    printf '%s%s%s%s' "$BOLD" "$LIGHT" "$title" "$RESET"

    frame

    local prev=$(( (idx - 1 + n) % n ))
    local next=$(( (idx + 1) % n ))

    place "$(thumb_of "${walls[$prev]}")" "${sw}x${sh}@${lx}x${sy}"
    place "$(thumb_of "${walls[$idx]}")"  "${cw}x${ch}@${cx}x${cy}"
    place "$(thumb_of "${walls[$next]}")" "${sw}x${sh}@${rx}x${sy}"

    # filename + counter under the frame (▶ marks videos)
    local name="${walls[$idx]%.*}"
    is_video "${walls[$idx]}" && name="▶ ${name}"
    local counter="$(( idx + 1 ))/${n}"
    local line="${name}  ·  ${counter}"
    tput cup $(( fy + fh )) $(( (cols - ${#line}) / 2 ))
    printf '%s%s%s%s  %s·  %s%s' "$BOLD" "$LIGHT" "$name" "$RESET" "$GREY" "$counter" "$RESET"

    dots

    # footer hints
    local hints="←  → browse    ⏎ keep    esc revert"
    tput cup $(( lines - 1 )) $(( (cols - ${#hints}) / 2 ))
    printf '%s%s%s' "$DIM$GREY" "$hints" "$RESET"
}

cleanup() {
    kitten icat --clear 2>/dev/null
    clear
    tput cnorm
}
trap cleanup EXIT

tput civis
draw

# --- Input loop (debounced live apply) ---
PENDING=""
dir="grow"

apply_pending() {
    if [ -n "$PENDING" ] && [ "$PENDING" != "$last_applied" ]; then
        pkill -f "awww img" 2>/dev/null
        apply "$PENDING" "$dir"
        last_applied="$PENDING"
    fi
    PENDING=""
}

while true; do
    if [ -n "$PENDING" ]; then
        IFS= read -rsn1 -t "$DEBOUNCE" key || { apply_pending; continue; }
    else
        IFS= read -rsn1 key
    fi

    if [[ $key == $'\x1b' ]]; then
        IFS= read -rsn2 -t 0.05 rest
        case "$rest" in
            "[C") idx=$(( (idx + 1) % n )); dir="left"  ;;
            "[D") idx=$(( (idx - 1 + n) % n )); dir="right" ;;
            "")
                pkill -f "awww img" 2>/dev/null
                [ -n "$ORIGINAL_NAME" ] && [ "$last_applied" != "$ORIGINAL_NAME" ] && apply "$ORIGINAL_NAME" "grow"
                sleep 0.3
                exit 0 ;;
            *) continue ;;
        esac
        PENDING="${walls[$idx]}"
        draw
    elif [[ -z $key ]]; then
        pkill -f "awww img" 2>/dev/null
        [ "${walls[$idx]}" != "$last_applied" ] && apply "${walls[$idx]}" "grow"
        sleep 0.3
        exit 0
    fi
done
