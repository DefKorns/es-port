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
export ES_GAME=1
shim=/tmp/es-shim
profile=/var/lib/clover/profiles/0
volatile=/var/cache/clover/volatile

desktop=$1
cmd=$(tr -d '\r' < "$desktop" | sed -n 's/^Exec=//p' | head -n 1)
path=$(tr -d '\r' < "$desktop" | sed -n 's/^Path=//p' | head -n 1)
code=$(tr -d '\r' < "$desktop" | sed -n 's/^Code=//p' | head -n 1)
resume=$2
[ -n "$cmd" ] || exit 1
if [ -d "$path" ]; then cd "$path" || exit 1; fi

if [ -n "$code" ]; then
  out=$volatile/$code/suspendpoint0
  for stale in "$volatile"/*/suspendpoint0; do
    [ "$stale" = "$out" ] || rm -rf "$stale"
  done
  rm -rf "$out"
  mkdir -p "$profile/$code" "$out/rollback"
  suspend_dir=$profile/$code/suspendpoint$resume
  native=
  case "$cmd" in
    *kachikachi*)
      case " $cmd " in
        *" --retroarch "*|*" -retroarch "*|*" --core "*|*" -core "*) ;;
        *) native=1 ;;
      esac
      ;;
  esac
  if [ -n "$native" ]; then
    cmd="$cmd --save-data-backing-file $profile/$code/cartridge.sram --save-screenshot-on-quit $out/state.png --save-on-quit $out/state"
    [ -n "$resume" ] && cmd="$cmd --load-state-file $suspend_dir/state"
  else
    cmd="$cmd --save-data-backing-file $profile/$code/cartridge.sram --title-code $code --video-mode keep-aspect-ratio"
    cmd="$cmd --save-time-path $out/state.time --save-screenshot-on-quit $out/state.png"
    case "$cmd" in
      *kachikachi*)
        cmd="$cmd --save-on-quit $out/state"
        [ -n "$resume" ] && cmd="$cmd --load-state-file $suspend_dir/state --load-time-path $suspend_dir/state.time"
        ;;
      *)
        cmd="$cmd --rollback-mode record --rollback-output-dir $out/rollback/"
        [ -n "$resume" ] && cmd="$cmd --load-time-path $suspend_dir//state.time --rollback-input-dir $suspend_dir/rollback/"
        ;;
    esac
  fi
fi

mkdir -p "$shim"
printf '#!/bin/sh\nexec retroarch-clover-child "$@"\n' > "$shim/retroarch-clover"
chmod +x "$shim/retroarch-clover"

PATH="$shim:$PATH" sh -c "$cmd"
