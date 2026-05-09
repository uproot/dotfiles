{
  x = ''SHIFT, Print, exec, sh -c 'grim - | wl-copy && notify-send -a "Screenshot" "Full screen" "Copied to clipboard"' '';
  y = ''$mod SHIFT, S, exec, sh -c 'grim -g "$(slurp -d -c \#c8d2ffdd -b \#00000066 -s \#c8d2ff11)" - | wl-copy && notify-send -a "Screenshot" "Region" "Copied to clipboard"' '';
}
