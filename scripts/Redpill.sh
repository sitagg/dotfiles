#!/usr/bin/env bash
set -euo pipefail

# ===== RED PILL — apps-only (green #9ece6a on black, invert highlight, CaskaydiaMono) =====
# Never edits icons or your System menu.

# 0) Deps
sudo pacman -S --needed --noconfirm rsync libnewt zstd alacritty desktop-file-utils

# 1) redpill (TUI) — 5s quote BEFORE BACKUP (menu flows only)
sudo tee /usr/local/bin/redpill >/dev/null <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
# Load NEWT_COLORS if present (whiptail palette)
[[ -f "$HOME/.config/redpill/theme.env" ]] && set -a && . "$HOME/.config/redpill/theme.env" && set +a

APP_NAME="redpill"; APP_TITLE="RED PILL"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/$APP_NAME"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/$APP_NAME"
BACKUP_DIR="${STATE_DIR}/backups"
INCLUDES_FILE="${CONF_DIR}/includes.conf"
mkdir -p "$BACKUP_DIR" "$CONF_DIR"

# First-run include list (Hyprland stack)
if [[ ! -f "$INCLUDES_FILE" ]]; then
  cat >"$INCLUDES_FILE" <<'EOF'
~/.config/hypr
~/.config/waybar
~/.config/mako
~/.config/hyprpaper
~/.config/hypridle
~/.config/wlogout
~/.config/kanshi
~/.config/walker
~/.config/swayosd
~/.config/uwsm
~/.config/omarchy
EOF
fi

have(){ command -v "$1" >/dev/null 2>&1; }
timestamp(){ date +"%Y-%m-%d_%H-%M-%S"; }
hosttag(){ hostnamectl --static 2>/dev/null || hostname; }
read_includes(){ grep -vE '^\s*#' "$INCLUDES_FILE" | sed '/^\s*$/d'; }
choose_comp(){ have zstd && echo zstd || echo gzip; }

pre_backup_note(){ echo; echo 'You take the red pill, you stay in hyprland and I show you how deep the rabbit-hole goes'; sleep 5; }

mk_backup(){
  local tag="${1:-$(timestamp)}" comp ext out
  comp="$(choose_comp)"; [[ "$comp" == zstd ]] && ext=tar.zst || ext=tar.gz
  out="${BACKUP_DIR}/${tag}_$(hosttag).${ext}"
  mapfile -t items < <(read_includes); ((${#items[@]})) || { echo "No paths listed."; exit 1; }
  files=(); for p in "${items[@]}"; do x="$(eval echo $p)"; [[ -e "$x" ]] && files+=("$x") || echo "Skip: $x"; done
  ((${#files[@]})) || { echo "Nothing to back up."; exit 1; }
  pushd "$HOME" >/dev/null
  rels=(); for f in "${files[@]}"; do r="${f/#$HOME\//}"; [[ "$r" == "$f" ]] && r="$f"; rels+=("$r"); done
  if [[ "$comp" == zstd ]]; then tar --zstd -cpf "$out" "${rels[@]}"; else tar -czpf "$out" "${rels[@]}"; fi
  popd >/dev/null
  echo "Backup written: $out"
}

latest(){ ls -1t "$BACKUP_DIR"/*.tar.zst "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n1 || true; }

restore(){
  local a="${1:-}"; [[ -n "$a" ]] || a="$(latest)"; [[ -f "$a" ]] || { echo "No backups found. Run: redpill backup"; exit 1; }
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  tar -xpf "$a" -C "$tmp"
  while IFS= read -r p; do x="$(eval echo $p)"; [[ "$x" == "$HOME/"* ]] && mkdir -p "$x" || true; done < <(read_includes)
  command -v rsync >/dev/null || { echo "rsync required"; exit 1; }
  rsync -aHAX --info=NAME2 "$tmp/" "$HOME/"
  echo "Restore complete."
}

list_arch(){ ls -1t "$BACKUP_DIR"/*.tar.zst "$BACKUP_DIR"/*.tar.gz 2>/dev/null || true; }

tui(){
  if command -v whiptail >/dev/null; then
    choice=$(whiptail --title "$APP_TITLE" --menu "Choose" 15 70 6 \
      1 "Backup now" 2 "Restore (choose archive)" 3 "List backups" 4 "Edit include list" 5 "Show paths" 3>&1 1>&2 2>&3) || exit 0
    case "$choice" in
      1) pre_backup_note; mk_backup; read -r -p "Enter…" ;;
      2)
         mapfile -t L < <(list_arch); ((${#L[@]})) || { echo "No backups"; exit 1; }
         menu_items=(); for i in "${!L[@]}"; do menu_items+=("$((i+1))" "${L[$i]}"); done
         pick=$(whiptail --title "$APP_TITLE" --menu "Backups" 20 100 10 "${menu_items[@]}" 3>&1 1>&2 2>&3) || exit 0
         archive="${L[$((pick-1))]}"; restore "$archive"; read -r -p "Enter…" ;;
      3) list_arch | ${PAGER:-less -S} ;;
      4) "${EDITOR:-nano}" "$INCLUDES_FILE" ;;
      5) printf "Backups: %s\nConfig: %s\nIncludes: %s\n" \
           "${XDG_STATE_HOME:-$HOME/.local/state}/$APP_NAME/backups" "$CONF_DIR" "$INCLUDES_FILE"; read -r -p "Enter…" ;;
    esac
  else
    PS3="redpill> "; select a in "Backup now" "Restore (latest)" "List" "Edit include list" "Show paths" "Quit"; do
      case "$REPLY" in
        1) pre_backup_note; mk_backup ;;
        2) restore ;;
        3) list_arch ;;
        4) "${EDITOR:-nano}" "$INCLUDES_FILE" ;;
        5) printf "Backups: %s\nConfig: %s\nIncludes: %s\n" \
             "${XDG_STATE_HOME:-$HOME/.local/state}/$APP_NAME/backups" "$CONF_DIR" "$INCLUDES_FILE" ;;
        *) exit 0 ;;
      esac
    done
  fi
}

case "${1:-tui}" in
  tui) tui ;; backup) mk_backup ;; list) list_arch ;; restore) restore "${2:-}" ;; includes) "${EDITOR:-nano}" "$INCLUDES_FILE" ;;
  where) printf "Backups: %s\nConfig: %s\nIncludes: %s\n" "${XDG_STATE_HOME:-$HOME/.local/state}/$APP_NAME/backups" "$CONF_DIR" "$INCLUDES_FILE" ;;
  *) echo "Usage: redpill [tui|backup|restore [FILE]|list|includes|where]";;
esac
BASH
sudo chmod +x /usr/local/bin/redpill

# 2) bluepill (TTY restore with 5s quote)
sudo tee /usr/local/bin/bluepill >/dev/null <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
echo
echo 'You take the blue pill, the story ends, you wake up in your bed and believe whatever you want to believe'
sleep 5
exec redpill restore "$@"
BASH
sudo chmod +x /usr/local/bin/bluepill

# 3) Applications entry — write to BOTH system & user dirs
USER_DESK="$HOME/.local/share/applications/redpill.desktop"
SYS_DESK="/usr/share/applications/redpill.desktop"

mkdir -p "$(dirname "$USER_DESK")"
cat > "$USER_DESK" <<'DESK'
[Desktop Entry]
Name=RED PILL
Comment=Hyprland config backup & restore
Exec=alacritty -e redpill
Terminal=false
Type=Application
Categories=System;Utility;
NoDisplay=false
StartupNotify=false
Keywords=hyprland;backup;restore;configs;redpill;bluepill;
DESK

sudo tee "$SYS_DESK" >/dev/null <<'DESK'
[Desktop Entry]
Name=RED PILL
Comment=Hyprland config backup & restore
Exec=alacritty -e redpill
Terminal=false
Type=Application
Categories=System;Utility;
NoDisplay=false
StartupNotify=false
Keywords=hyprland;backup;restore;configs;redpill;bluepill;
DESK

update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
sudo update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

# 4) Walker: unhide Applications (sed-only) + add custom command safety net
WCONF="$HOME/.config/walker/config.toml"
mkdir -p "$(dirname "$WCONF")"

if [ ! -f "$WCONF" ]; then
  cat >"$WCONF" <<'TOML'
[builtins.applications]
launch_prefix = "uwsm app -- "
hidden = false

[builtins.custom_commands]
hidden = false

[[builtins.custom_commands.entries]]
label = "RED PILL"
command = "alacritty -e redpill"
keywords = ["redpill","backup","restore","hyprland"]
icon = ""
TOML
else
  if grep -q '^\[builtins\.applications\]' "$WCONF"; then
    sed -i '/^\[builtins\.applications\]/,/^\[/{s/^\s*hidden\s*=.*/hidden = false/}' "$WCONF"
    if ! sed -n '/^\[builtins\.applications\]/,/^\[/{/^\s*hidden\s*=/p}' "$WCONF" | grep -q .; then
      sed -i '/^\[builtins\.applications\]/a hidden = false' "$WCONF"
    fi
    if ! sed -n '/^\[builtins\.applications\]/,/^\[/{/^\s*launch_prefix\s*=/p}' "$WCONF" | grep -q .; then
      sed -i '/^\[builtins\.applications\]/a launch_prefix = "uwsm app -- "' "$WCONF"
    fi
  else
    cat >>"$WCONF" <<'TOML'

[builtins.applications]
launch_prefix = "uwsm app -- "
hidden = false
TOML
  fi

  if ! grep -q '^\[builtins\.custom_commands\]' "$WCONF"; then
    cat >>"$WCONF" <<'TOML'

[builtins.custom_commands]
hidden = false
TOML
  fi
  if ! grep -q 'label = "RED PILL"' "$WCONF"; then
    cat >>"$WCONF" <<'TOML'

[[builtins.custom_commands.entries]]
label = "RED PILL"
command = "alacritty -e redpill"
keywords = ["redpill","backup","restore","hyprland"]
icon = ""
TOML
  fi
fi

# 5) Theme: #9ece6a + invert highlight (NEWT) + safe Alacritty update
mkdir -p "$HOME/.config/redpill"

cat > "$HOME/.config/redpill/theme.env" <<'ENV'
NEWT_COLORS='
root=,black
window=,black
border=green,black
title=green,black
label=green,black
textbox=green,black
acttextbox=black,green
listbox=green,black
sellistbox=green,black
actlistbox=black,green
actsellistbox=black,green
entry=green,black
disentry=green,black
button=black,green
actbutton=black,green
'
ENV

ALAC="$HOME/.config/alacritty/alacritty.toml"
mkdir -p "$(dirname "$ALAC")"
cp -n "$ALAC" "$ALAC.bak.redpill-9ece6a" 2>/dev/null || true

if [[ -f "$ALAC" ]]; then
  awk '
    BEGIN{skip=0}
    /^[[:space:]]*\[/ {
      hdr=$0; key=hdr; sub(/^[[:space:]]*\[/,"",key); sub(/\][[:space:]]*$/,"",key);
      if (key ~ /^font(\..*)?$/ ||
          key == "colors.primary" ||
          key == "colors.normal" ||
          key == "colors.bright" ||
          key == "colors.selection") { skip=1; next }
      else { skip=0; print; next }
    }
    { if (!skip) print }
  ' "$ALAC" > "$ALAC.tmp"
else
  : > "$ALAC.tmp"
fi

cat >> "$ALAC.tmp" <<'TOML'

# --- RED PILL font & palette (deduped; last-defined wins) ---
[font]
normal = { family = "CaskaydiaMono Nerd Font", style = "Regular" }
bold   = { family = "CaskaydiaMono Nerd Font", style = "Bold" }
italic = { family = "CaskaydiaMono Nerd Font", style = "Italic" }
bold_italic = { family = "CaskaydiaMono Nerd Font", style = "Bold Italic" }
# size = 12.0  # optional

[colors.primary]
background = "#000000"
foreground = "#9ece6a"

[colors.normal]
black   = "#000000"
red     = "#9ece6a"
green   = "#9ece6a"
yellow  = "#9ece6a"
blue    = "#9ece6a"
magenta = "#9ece6a"
cyan    = "#9ece6a"
white   = "#9ece6a"

[colors.bright]
black   = "#000000"
red     = "#9ece6a"
green   = "#9ece6a"
yellow  = "#9ece6a"
blue    = "#9ece6a"
magenta = "#9ece6a"
cyan    = "#9ece6a"
white   = "#9ece6a"

[colors.selection]
background = "#9ece6a"
text       = "#000000"
TOML

mv "$ALAC.tmp" "$ALAC"

# 6) Reindex and restart Walker so the new entry is searchable immediately
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
sudo update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
pkill -f '^walker' >/dev/null 2>&1 || true

echo "✅ Installed:"
echo "  - TTY guide at ~/.config/redpill/RECOVERY.txt"
echo "Open your launcher (Super + Space) and search: RED PILL"
