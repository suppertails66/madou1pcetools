set -o errexit

mkdir -p rsrc/grp/orig

make

./grpunmap_pce rsrc_raw/grp/title_logo_grp.bin rsrc_raw/grp/title_logo_map.bin 64 32 rsrc/grp/orig/title_logo.png -v 0x100 -p rsrc_raw/pal/title_logo.pal -t
./grpunmap_pce rsrc_raw/grp/title_logo_grp.bin rsrc_raw/grp/title_logo_map.bin 64 32 rsrc/grp/orig/title_logo_grayscale.png -v 0x100 -t
./grpunmap_pce "rsrc_raw/grp/loading_grp.bin" "rsrc_raw/map/loading.map" 64 64 "rsrc/grp/orig/loading.png" -v 0x0 -p "rsrc_raw/pal/loading.pal"
./grpdmp_pce "rsrc_raw/grp/dungeon_logo.bin" "rsrc/grp/orig/dungeon_logo.png" -p "rsrc_raw/pal/dungeon_logo_line.pal" -r 16
./grpdmp_pce "rsrc_raw/grp/button_yesno.bin" "rsrc/grp/orig/button_yesno.png" -p "rsrc_raw/pal/dungeon_button_line.pal" -r 6
./grpdmp_pce "rsrc_raw/grp/button_onoff.bin" "rsrc/grp/orig/button_onoff.png" -p "rsrc_raw/pal/dungeon_button_line.pal" -r 6

./spritedmp_pce "rsrc_raw/grp/mrflea.bin" "rsrc/grp/orig/mrflea.png" -p "rsrc_raw/pal/dungeon_mrflea_line.pal" -r 16

./spritedmp_pce "rsrc_raw/grp/bayoen.bin" "rsrc/grp/orig/bayoen_ba.png" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -s 0x0
./spritedmp_pce "rsrc_raw/grp/bayoen.bin" "rsrc/grp/orig/bayoen_yo.png" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -s 0x800
./spritedmp_pce "rsrc_raw/grp/bayoen.bin" "rsrc/grp/orig/bayoen_e.png" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -s 0x400
./spritedmp_pce "rsrc_raw/grp/bayoen.bin" "rsrc/grp/orig/bayoen_n.png" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -s 0xC00

./grpunmap_pce "rsrc_raw/grp/error_accard.bin" "rsrc_raw/grp/error_accard.bin" 64 64 "rsrc/grp/orig/error_accard.png" -v 0x0 -p "rsrc_raw/pal/error_accard.pal"
./grpunmap_pce "rsrc_raw/grp/error_clearbak.bin" "rsrc_raw/grp/error_clearbak.bin" 64 64 "rsrc/grp/orig/error_clearbak.png" -v 0x0 -p "rsrc_raw/pal/error_clearbak.pal"
./grpunmap_pce "rsrc_raw/grp/error_clearfiles.bin" "rsrc_raw/grp/error_clearfiles.bin" 64 64 "rsrc/grp/orig/error_clearfiles.png" -v 0x0 -p "rsrc_raw/pal/error_clearfiles.pal"
