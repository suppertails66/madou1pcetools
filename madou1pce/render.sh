
set -o errexit

tempFontFile=".fontrender_temp"



function renderString() {
  printf "$2" > $tempFontFile
  
#  ./fontrender "font/12px_outline/" "$tempFontFile" "font/12px_outline/table.tbl" "$1.png"
#  ./fontrender "font/" "$tempFontFile" "font/table.tbl" "$1.png"
  ./fontrender "font/arle_12px/" "$tempFontFile" "font/arle_12px/table.tbl" "$1.png"
}



make blackt && make fontrender

#renderString intro_render_1 "1999. Mankind is attacked by superweapons of unknown origin."
#renderString intro_render_2 "Four robots, appearing suddenly out of nowhere."
#renderString intro_render_3 "Are they a country's secret weapons? The start of an alien invasion?"
#renderString intro_render_4 "The identity of these mysterious robots remains unknown..."

#renderString test "There are words on the wall. The path below shall open only to those who have two Magic Orbs. To obtain the final Orb, you must acquire the four Slates."
#renderString render1 "Boys and girls, today is the day of the Magic Kindergarten graduation test!"
#renderString render2 "But unfortunately, there is only one among you who will be taking the test this time."
#renderString render3 "I'm so sorry!"
#renderString render4 "But..."
#renderString render1 "Please play using an Arcade Card."
#renderString render1 "Please format the Backup Memory before playing."
renderString render1 "Please dispose of unneeded files in the Backup Memory before playing."


rm $tempFontFile