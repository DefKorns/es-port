#!/bin/sh
#  Copyright (C) 2026 DefKorns (https://defkorns.github.io/LICENSE)
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
es_dir=/var/lib/hakchi/emulationstation
source /etc/preinit
script_init

export ES_PAD=snes
[ "$sftype" = snes ] || ES_PAD=nes

drawSplash(){
  decodepng "$es_dir/resources/$1.png" > /dev/fb0
}

stopPowerWatch(){
  [ -f /run/es-power.pid ] && kill -TERM -- "-$(cat /run/es-power.pid)" 2>/dev/null
  rm -f /run/es-power.pid
}

restore_ui=1
trap '[ ! -f /tmp/es-stopping ] && stopPowerWatch; [ "$restore_ui" = 1 ] && [ ! -f /tmp/es-stopping ] && { type stockUistart >/dev/null 2>&1 && stockUistart || uistart; }' EXIT
uistop
stopPowerWatch
setsid sh "$es_dir/es-power-watch.sh" &
echo $! > /run/es-power.pid
mkdir -p "$es_dir/home/.emulationstation"
for cfg in es_settings.cfg es_input.cfg; do
  [ -f "$es_dir/home/.emulationstation/$cfg" ] || cp "$es_dir/defaults/$cfg" "$es_dir/home/.emulationstation/"
done
library_stamp=$es_dir/library.stamp
games_dir=$(findGameStorage)
games_count=$(find "$games_dir" -name '*.desktop' ! -path '*/CLV-Z-ESRET/*' | wc -l)
if [ -d "$es_dir/library" ] && [ "$(cat "$library_stamp.count" 2>/dev/null)" = "$games_count" ]   && [ -z "$(find "$games_dir" /media/data/emulationstation/covers "$es_dir/es-library.sh" \( -name '*.desktop' -o -name '*.png' -o -name 'aliases.txt' -o -name 'es-library.sh' \) ! -path '*/CLV-Z-ESRET/*' -newer "$library_stamp" 2>/dev/null | head -n 1)" ]; then
  rm -rf /tmp/es-library
  cp -a "$es_dir/library" /tmp/es-library
else
  sh "$es_dir/es-library.sh" /tmp/es-library
  rm -rf "$es_dir/library"
  cp -a /tmp/es-library "$es_dir/library"
  echo "$games_count" > "$library_stamp.count"
  touch "$library_stamp"
fi
sh "$es_dir/es-favorites.sh" /tmp/es-library "$es_dir/favorites.txt"
sh "$es_dir/es-systems.sh" /tmp/es-library "$es_dir/es_systems.cfg" "$es_dir/home/.emulationstation/es_systems.cfg"
[ -f /media/data/emulationstation/audio/bgm_home.wav ] || sh "$es_dir/es-tools.sh" audio import >/dev/null 2>&1
while true; do
  rm -f /tmp/es-quit /tmp/es-restart /tmp/es-sysrestart /tmp/es-shutdown
  es_started=$(date +%s)
  HOME=$es_dir/home LD_LIBRARY_PATH=$es_dir ES_FAVORITES_FILE=$es_dir/favorites.txt "$es_dir/emulationstation" "$@"
  es_status=$?
  case $es_status in 129|143) restore_ui=0; break ;; esac
  if [ "$es_status" -ne 0 ] && [ $(($(date +%s) - es_started)) -lt 15 ]; then
    es_failures=$(($(cat "$es_dir/boot_failures" 2>/dev/null || echo 0) + 1))
    echo "$es_failures" > "$es_dir/boot_failures"
    if [ "$es_failures" -ge 2 ]; then
      echo stock > "$es_dir/boot_default"
      break
    fi
    continue
  fi
  rm -f "$es_dir/boot_failures"
  [ -f /tmp/es-restart ] && continue
  if [ -f /tmp/es-sysrestart ] || [ -f /tmp/es-shutdown ] || { [ "$es_status" -eq 0 ] && [ ! -f /tmp/es-quit ]; }; then
    restore_ui=0
  fi
  if [ -f /tmp/es-sysrestart ]; then
    touch /tmp/es-restarting
    drawSplash restart
    reboot
  elif [ -f /tmp/es-shutdown ]; then
    drawSplash shutdown
    poweroff
  fi
  break
done
