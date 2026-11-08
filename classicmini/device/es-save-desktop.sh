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
source /etc/preinit
script_init

code=${1:?game code}
store=$(findGameStorage) || exit 1
backup=/media/data/emulationstation/desktop_pre_scrape
mkdir -p "$backup"

find "$store" -path "$store/.storage" -prune -o -name "$code.desktop" -print | while read -r desktop; do
  [ -f "$backup/$code.desktop" ] || cp "$desktop" "$backup/$code.desktop"
  awk '
    BEGIN {
      name = ENVIRON["ES_NAME"]; desc = ENVIRON["ES_DESC"]; released = ENVIRON["ES_RELEASED"]
      players = ENVIRON["ES_PLAYERS"]; publisher = ENVIRON["ES_PUBLISHER"]; genre = ENVIRON["ES_GENRE"]
      overwrite = ENVIRON["ES_OVERWRITE"] != ""
    }
    FNR == NR {
      if ($0 ~ /^\[/) in_desc_scan = ($0 == "[Description]")
      else if (in_desc_scan) { line = $0; sub(/^Text *= */, "", line); if (line != "") have_desc = 1 }
      if ($0 ~ /^ReleaseDate=./) have_released = 1
      if ($0 ~ /^Players=./) have_players = 1
      if ($0 ~ /^SortRawPublisher=./) have_publisher = 1
      if ($0 ~ /^sortRawGenre=./) have_genre = 1
      next
    }
    FNR == 1 {
      if (!overwrite) {
        if (have_desc) desc = ""
        if (have_released) released = ""
        if (have_players) players = ""
        if (have_publisher) publisher = ""
        if (have_genre) genre = ""
      }
    }
    /^\[/ { in_desc = 0 }
    in_desc { next }
    /^\[Description\]/ && desc != "" { print; print "Text = " desc; in_desc = 1; wrote_desc = 1; next }
    /^Name=/ && name != "" { print "Name=" name; next }
    /^ReleaseDate=/ && released != "" { print "ReleaseDate=" released; next }
    /^Players=/ && players != "" { print "Players=" players; next }
    /^SortRawPublisher=/ && publisher != "" { print "SortRawPublisher=" toupper(publisher); next }
    /^sortRawGenre=/ && genre != "" { print "sortRawGenre=" genre; next }
    { print }
    END { if (desc != "" && !wrote_desc) { print ""; print "[Description]"; print "Text = " desc } }
  ' "$desktop" "$desktop" > "$desktop.tmp" && mv "$desktop.tmp" "$desktop"
done
