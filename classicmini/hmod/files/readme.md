# EmulationStation

![ES-PORT](https://raw.githubusercontent.com/DefKorns/es-port/classicmini/classicmini/docs/banner.png)

EmulationStation 2.12 (RetroPie fork) as the front end of the NES/SNES Classic, driven by the games hakchi syncs.

Needs the RetroArch (S)NESCE hmod for the libretro cores.

**Alpha build, for testers.** You can always get the stock UI back: hold **Select** while the console boots, or remove the module with "Remove modules" in hakchi. If EmulationStation crashes twice in a row right after starting, the next boot goes to the stock UI by itself.

Known issues: no video playback; the first boot builds the library, which takes a while on large collections; the interface slows down while the scraper runs; the NES Classic is tested much less than the SNES Classic; games need the RetroArch hmod and its cores (the KMFD RetroArch with fceumm has worked on the Famicom).

To report a problem, send `/var/lib/hakchi/emulationstation/home/.emulationstation/es_log.txt` and, after a crash, `/var/lib/hakchi/emulationstation/crash.log` (over ssh as root).

**Needs an SD card or USB stick.** While it installs, the hmod mounts the card itself and puts its default theme, [es-theme-simple](https://github.com/RetroPie/es-theme-simple), in `/media/data/emulationstation/themes/simple`; nothing of the theme goes to the NAND. Without a card or stick the install stops and EmulationStation is not installed; the hakchi log says so, but the PC may still report the install as done and mark the module as installed, so remove it in hakchi before trying again. Extra themes go in the same folder. Updating keeps the theme files you changed.

Hold Select while the console boots to get the stock UI. After two fast crashes in a row it falls back to the stock UI by itself.

Uninstalling removes EmulationStation, its settings and library cache from the NAND but keeps the favourites list. It also mounts the card and removes the theme files you did not change; the ones you changed or added stay.

**Return to EmulationStation tile.** If you end up in the stock menu (after a crash or booting with Select), a tile can start EmulationStation again without rebooting. It is a hakchi game package: add `CLV-Z-ESRET.clvg` (from the `hakchi-app` folder of the es-port repository) with "Add more games" in hakchi and sync. EmulationStation does not list it as a game.
