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

out=${1:?output dir}
store=${ES_STORE:-$(findGameStorage)} || { echo "no games storage" >&2; exit 1; }
max_depth=8
covers=/media/data/emulationstation/covers
us=$(printf '\037')

chdRead() {
  dd if="$1" bs=1 skip="$2" count="$3" 2>/dev/null | od -An -tx1 | tr -d ' \n'
}

chdSystem() {
  local file tag meta len track steps=0
  for file in "$store/.storage/$code"/*.chd "$game_dir"/*.chd; do [ -f "$file" ] && break; done
  [ -f "$file" ] || return 1
  [ "$(chdRead "$file" 0 8)" = 4d436f6d70724844 ] || return 1
  meta=$((0x$(chdRead "$file" 48 8)))
  while [ "$meta" -gt 0 ] && [ "$steps" -lt 32 ]; do
    tag=$(chdRead "$file" "$meta" 4)
    case $tag in
      44564420) system=psp; return 0 ;;
      43485432|43485452)
        len=$((0x$(chdRead "$file" $((meta + 5)) 3)))
        track=$(dd if="$file" bs=1 skip=$((meta + 16)) count="$len" 2>/dev/null | tr -d '\000')
        case $track in
          *MODE2*) system=psx; return 0 ;;
          *MODE1*) system=segacd; return 0 ;;
        esac
        ;;
    esac
    meta=$((0x$(chdRead "$file" $((meta + 8)) 8)))
    steps=$((steps + 1))
  done
  return 1
}

systemOf() {
  case ${exe#km_} in
    clover-canoe-shvc*|snes|snes05*|snes9x*|snes10*|mednafen-snes-faust-xtreme) system=snes ;;
    nestopia|quicknes|fceumm*|kachikachi*|clover-kachikachi*|nes)
      if [ "$ext" = fds ]; then system=fds; else system=nes; fi ;;
    gambatte|gearboy|tgbdual|gb|gbc)
      if [ "$ext" = gbc ] || [ "$exe" = gbc ]; then system=gbc; else system=gb; fi ;;
    mgba|gpsp|gba) system=gba ;;
    melonds|desmume|drastic*|nds) system=nds ;;
    gg) system=gamegear ;;
    sms|smsplus|gearsystem)
      if [ "$ext" = gg ]; then system=gamegear; else system=mastersystem; fi ;;
    segacd) system=segacd ;;
    32x) system=sega32x ;;
    md) system=megadrive ;;
    genesis*|picodrive*)
      case $ext in
        sms) system=mastersystem ;;
        gg) system=gamegear ;;
        32x) system=sega32x ;;
        sg) system=sg-1000 ;;
        cue|chd|iso) system=segacd ;;
        *) system=megadrive ;;
      esac
      ;;
    mednafen-pce-fast|pce|pcecd|mednafen-supergrafx|sgfx) system=pcengine ;;
    mednafen-pcfx|mednafen_pcfx|pcfx) system=pcfx ;;
    mednafen-ngp|ngp|ngc) system=ngp ;;
    mednafen-wswan|mednafen_wswan|ws|wsc) system=wonderswan ;;
    mednafen-vb|mednafen_vb|vb) system=virtualboy ;;
    mednafen-psx|mednafen_psx|pcsx*|psx|neon) system=psx ;;
    neocd|neo) system=neogeo ;;
    fbalpha*|fba*|fbneo*|cps1|cps2|cps3|mame*) system=arcade ;;
    n64|z64|v64|glupen64*|mupen64*|parallel-n64*|ludicrousn64*) system=n64 ;;
    ppsspp*|psp) system=psp ;;
    yabause*) system=saturn ;;
    morpheuscast*|vemulator|vmu) system=dreamcast ;;
    opera-xtreme) system=3do ;;
    stella|a26) system=atari2600 ;;
    prosystem|a78) system=atari7800 ;;
    a52) system=atari5200 ;;
    atari800) system=atari800 ;;
    handy|lnx) system=atarilynx ;;
    virtualjaguar|j64) system=atarijaguar ;;
    hatari*) system=atarist ;;
    vice*|c64|c128|vic20) system=c64 ;;
    puae*|uae4arm*|amiga) system=amiga ;;
    col) system=colecovision ;;
    fmsx|bluemsx|msx) system=msx ;;
    caprice32|cap32|crocods) system=amstradcpc ;;
    fuse|z80|zx) system=zxspectrum ;;
    freeintv|int) system=intellivision ;;
    freechaf) system=channelf ;;
    o2em|odyssey) system=videopac ;;
    vecx|vec) system=vectrex ;;
    gw|mgw) system=gameandwatch ;;
    pokemini|min|pokemon) system=pokemini ;;
    dosbox*) system=pc ;;
    scummvm) system=scummvm ;;
    np2*|nekop2|pc98) system=pc98 ;;
    px68k*|sharp) system=x68000 ;;
    quasi88|d88) system=pc88 ;;
    x1|x1-millennium) system=x1 ;;
    tic80|tic) system=tic80 ;;
    openbor*) system=openbor ;;
    easyrpg|ldb|chai*|lutro|lua|prboom*|wad|nxengine|cavestory|ecwolf|tyrquake|pak|xrick|mrboom|jumpnbump|cannonball|reminiscence|flashback|2048|dinothawr|bk|eighty-one|81|emux*|ch8|uzem|uze|potator) system=ports ;;
    *) system=other ;;
  esac
  if [ "$system" = other ] && [ "$ext" = chd ]; then chdSystem; fi
}

xmlPath() {
  case $1 in
    *[\&\<\>]*) printf '%s\n' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

readGames() {
  local has=0
  [ -d "$covers" ] && has=1
  printf '%s\n' "$store"/*/CLV-*/CLV-*.desktop |
  awk -v dir="$covers" -v has="$has" -v root=000 -v maxdepth="$max_depth" -v sep="$us" '
  function esc(s) {
    gsub(/&/, "\\&amp;", s)
    gsub(/</, "\\&lt;", s)
    gsub(/>/, "\\&gt;", s)
    return s
  }
  function walk(menu, depth,    i, id, target, words) {
    onpath[menu] = 1
    for (i = 1; i <= count[menu]; i++) {
      id = recs[menu, i]
      if (exec[id] ~ /^\/bin\/chmenu /) {
        split(exec[id], words, " ")
        target = words[2]
        if ((target in onpath) || depth >= maxdepth) continue
        walk(target, depth + 1)
        continue
      }
      print menuOf[id] sep code[id] sep exe[id] sep ext[id] sep icon[id] sep esc(name[id]) sep esc(desc[id]) sep year[id] sep players[id] sep esc(genre[id]) sep esc(cover[id])
    }
    delete onpath[menu]
  }
  BEGIN {
    if (has) {
      cmd = "ls -1a \"" dir "\" 2>/dev/null"
      while ((cmd | getline f) > 0) {
        exact[f] = 1
        lf = tolower(f)
        if (lf ~ /\.png$/ && !(lf in ci)) ci[lf] = f
      }
      close(cmd)
      af = dir "/aliases.txt"
      while ((getline line < af) > 0) {
        gsub(/\r/, "", line)
        t = index(line, "\t"); if (!t) continue
        k = substr(line, 1, t - 1)
        v = substr(line, t + 1); sub(/\t.*/, "", v)
        if (!(k in alias)) alias[k] = v
      }
      close(af)
    }
  }
  {
    p = $0; n = split(p, a, "/")
    if (n < 3) next
    c = a[n - 1]; m = a[n - 2]
    if (a[n] != c ".desktop") next
    if (c == "CLV-Z-ESRET") next

    nm = ""; ex = ""; ic = ""; rel = ""; pl = ""; ge = ""; sg = ""; ds = ""; indesc = 0
    haveName = haveExec = haveIcon = haveRel = havePl = haveGe = haveSg = 0
    while ((getline line < p) > 0) {
      gsub(/\r/, "", line)
      if (line ~ /^\[Description\]/) { indesc = 1; continue }
      if (line ~ /^\[/) indesc = 0
      if (indesc) {
        text = line
        sub(/^Text *= */, "", text)
        if (text != "") ds = (ds == "" ? text : ds " " text)
      }
      if (!haveName && line ~ /^Name *= */) { sub(/^Name *= */, "", line); nm = line; haveName = 1 }
      else if (!haveExec && line ~ /^Exec *= */) { sub(/^Exec *= */, "", line); ex = line; haveExec = 1 }
      else if (!haveIcon && line ~ /^Icon *= */) { sub(/^Icon *= */, "", line); ic = line; haveIcon = 1 }
      else if (!haveRel && line ~ /^ReleaseDate *= */) { sub(/^ReleaseDate *= */, "", line); rel = line; haveRel = 1 }
      else if (!havePl && line ~ /^Players *= */) { sub(/^Players *= */, "", line); pl = line; havePl = 1 }
      else if (!haveGe && line ~ /^Genre *= */) { sub(/^Genre *= */, "", line); ge = line; haveGe = 1 }
      else if (!haveSg && line ~ /^sortRawGenre *= */) { sub(/^sortRawGenre *= */, "", line); sg = line; haveSg = 1 }
    }
    close(p)
    if (ge == "") ge = sg

    id = ++total
    menuOf[id] = m; code[id] = c; name[id] = nm; exec[id] = ex; icon[id] = ic; desc[id] = ds; players[id] = pl
    recs[m, ++count[m]] = id

    split(ex, w, " ")
    e = w[1]; sub(/.*\//, "", e); exe[id] = e
    r = ""
    for (i = 2; i in w; i++) if (w[i] !~ /^-/) { r = w[i]; break }
    sub(/.*\//, "", r)
    r = tolower(r)
    sub(/\.(7z|zip|gz)$/, "", r)
    x = r; sub(/.*\./, "", x)
    ext[id] = (r ~ /\./) ? x : ""

    y = rel; gsub(/-/, "", y)
    year[id] = y
    genre[id] = ge

    cv = ""
    if (has) {
      if ((c ".png") in exact) {
        cv = dir "/" c ".png"
      } else {
        if ((c in alias) && alias[c] != "") {
          k = tolower(alias[c] ".png")
          if (k in ci) cv = dir "/" ci[k]
        }
        if (cv == "") {
          s = nm
          gsub(/\([^)]*\)/, "", s)
          gsub(/\[[^]]*\]/, "", s)
          s = tolower(s)
          gsub(/[^a-z0-9]/, "", s)
          if (s != "" && ((s ".png") in ci)) cv = dir "/" ci[s ".png"]
        }
      }
    }
    cover[id] = cv
  }
  END { walk(root, 0) }'
}

default_covers=" "
small_covers=$(find "$store/.storage" -maxdepth 2 -name '*.png' ! -name '*_small.png' -size -8k 2>/dev/null)
while IFS= read -r png; do
  [ -n "$png" ] && [ "$(chdRead "$png" 16 8)" = 0000008c000000cc ] || continue
  png=${png##*/}
  default_covers="$default_covers${png%.png} "
done <<EOF
$small_covers
EOF

parts=$(mktemp -d)
rm -rf "$out"
mkdir -p "$out"
seen=" "

readGames | while IFS=$us read -r menu code exe ext icon name desc year players genre cover; do
  game_dir=$store/$menu/$code
  system=other
  systemOf
  [ -f "$out/$system/$code.desktop" ] && continue
  case $seen in
    *" $system "*) ;;
    *) mkdir -p "$out/$system"; seen="$seen$system " ;;
  esac
  cp "$game_dir/$code.desktop" "$out/$system/$code.desktop"

  [ -n "$cover" ] && [ -f "${covers}_small/${cover##*/}" ] && cover=${covers}_small/${cover##*/}
  case $icon in /var/games/*) icon=$store/$menu/${icon#/var/games/} ;; esac
  [ -f "$icon" ] || icon=
  [ -n "$cover" ] && icon=$cover
  small=$game_dir/${code}_small.png
  [ -f "$small" ] || small=$icon
  [ -n "$cover" ] && small=$cover
  case $default_covers in *" $code "*) [ -z "$cover" ] && { icon=; small=; } ;; esac

  {
    echo "  <game>"
    echo "    <path>./$code.desktop</path>"
    echo "    <name>$name</name>"
    [ -n "$icon" ] && echo "    <image>$(xmlPath "$icon")</image>"
    [ -n "$desc" ] && echo "    <desc>$desc</desc>"
    [ ${#year} -eq 8 ] && echo "    <releasedate>${year}T000000</releasedate>"
    [ -n "$players" ] && echo "    <players>$players</players>"
    [ -n "$genre" ] && echo "    <genre>$genre</genre>"
    echo "    <code>$code</code>"
    [ -n "$small" ] && echo "    <marquee>$(xmlPath "$small")</marquee>"
    echo "  </game>"
  } >> "$parts/$system.xml"
done

for part in "$parts"/*.xml; do
  [ -f "$part" ] || continue
  system=${part##*/}; system=${system%.xml}
  {
    echo '<?xml version="1.0"?>'
    echo '<gameList>'
    cat "$part"
    echo '</gameList>'
  } > "$out/$system/gamelist.xml"
done
rm -rf "$parts"
