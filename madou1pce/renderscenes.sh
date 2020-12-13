
tempFontFile=".fontrender_temp"

set -o errexit

function outlineSolidPixels() {
  convert "$1" \( +clone -channel A -morphology EdgeOut Square:1 -negate -threshold 15% -negate +channel +level-colors \#111111 \) -compose DstOver -composite "$2"
}

function renderString() {
  echo "Rendering text: '$2'"
  printf "$2" > $tempFontFile
  
  file=$1.png
#  fontname=DejaVu-Sans-Condensed-Bold
#   fontname=Nimbus-Sans-L-Bold-Condensed
  fontname=Liberation-Sans-Narrow-Bold
#  xoffset=$3
#  yoffset=$4
  text=$2
  # fontsize is optional
#   fontsize=$3
#   if [ "$fontsize" == "" ]; then
#     fontsize=14
#   fi

#  convert -size 256x32 xc: -alpha transparent "$file"
  
#  convert $file -font $fontname -pointsize $fontsize -fill white -gravity Center -draw "text 0,0 '$text'" $file
  
#  convert $file -font $fontname -density 72 -pointsize 14 -fill white -gravity Center -annotate +0-1 "$text" $file
#  convert -background none -font $fontname -density 72 -pointsize 13 -fill white -gravity North -size 224x caption:"$text" $file
  convert -background none -font $fontname -density 72 -pointsize 13 -fill white -gravity North -size 224x caption:"$text" $file
  
  outlineSolidPixels "$file" "$file"
  
  convert "$file" \( +clone -channel A -negate -threshold 0 -negate +channel +level-colors \#111111 \) -compose DstOver -composite "$file"
  convert -size 256x32 xc: -alpha transparent "$file" -gravity center -geometry +0+0 -composite "$file"
}

function renderStringAlt() {
  echo "Rendering text with alt method: '$2'"
  printf "$2" > $tempFontFile
  
  file=$1.png
  fontname=Liberation-Sans-Narrow-Bold
  text=$2
  
#  convert -background none -font $fontname -density 72 -pointsize 13 -fill white -gravity North -size 256x caption:"$text" $file
  convert -background none -font $fontname -density 72 -pointsize 13 -fill white -gravity North -size 256x caption:"$text" $file
  
  outlineSolidPixels "$file" "$file"
  
  convert "$file" \( +clone -channel A -negate -threshold 0 -negate +channel +level-colors \#111111 \) -compose DstOver -composite "$file"
  convert -size 256x32 xc: -alpha transparent "$file" -gravity center -geometry +0+0 -composite "$file"
}

# function renderString() {
#   echo "Rendering text: '$2'"
#   printf "$2" > $tempFontFile
#   
#   ./spritesubtitlerender "$tempFontFile" "$1.png"
# }

# function renderStringAlt() {
#   echo "Rendering text with alt format: '$2'"
#   printf "$2" > $tempFontFile
#   
#   ./spritesubtitlerender "$tempFontFile" "$1.png" --altformat
# }



#make spritesubtitlerender

mkdir -p rsrc/subs/intro
renderStringAlt rsrc/subs/intro/00 "Boys and girls, today is the day of the Magic Kindergarten graduation test!"
#renderStringAlt rsrc/subs/intro/01 "But unfortunately, there is only one among you who will be taking the test this time."
renderStringAlt rsrc/subs/intro/01 "But I'm afraid only one of you will be taking the test this time."
renderString rsrc/subs/intro/02 "I'm so sorry, but...!"
renderString rsrc/subs/intro/03 "I'm so nervous about this exam.\nMy heart is beating like crazy."
#renderString rsrc/subs/intro/04 ""
#renderString rsrc/subs/intro/05 "To pass, I have to collect the three Magic Orbs hidden somewhere inside."
# splitting this line up for technical reasons...
# we're fibbing a bit about the content
# (the first part of the line actually corresponds to "inside the tower"),
# but due to the way we need to load the tiles here, this makes more sense
# than any other option
renderString rsrc/subs/intro/04 "In order to pass,"
#renderString rsrc/subs/intro/05 "I have to collect the three Magic Orbs hidden somewhere inside."
renderString rsrc/subs/intro/05 "I have to collect the three Magic Orbs hidden somewhere in there."
#renderString rsrc/subs/intro/06 "But it's a super scary place full of all kinds of Illusion Monsters and traps."
renderString rsrc/subs/intro/06 "But it's a super scary place,"
renderStringAlt rsrc/subs/intro/07 "full of all kinds of Illusion Monsters and traps."
# there are clearly two separate lines here;
# with subtitles, we can't really get away with combining them
#renderString rsrc/subs/intro/08 "My knees are shaking just looking at the tower..."
renderString rsrc/subs/intro/08 "I feel so anxious with the tower right there..."
renderString rsrc/subs/intro/09 "My knees are shaking just looking at it."
renderString rsrc/subs/intro/10 "That's why I have to work up my courage!"
renderString rsrc/subs/intro/11 "Arle!"
renderString rsrc/subs/intro/12 "Hang in there!"
renderString rsrc/subs/intro/13 "You're gonna pass for sure!"
renderString rsrc/subs/intro/14 "Thanks!"
renderString rsrc/subs/intro/15 "See you later!"

mkdir -p rsrc/subs/preboss
renderString rsrc/subs/preboss/00 "*huff* *huff*"
renderStringAlt rsrc/subs/preboss/01 "It's been hours since I said goodbye to the teacher and my friends and entered the tower..."
renderString rsrc/subs/preboss/02 "I've been through a lot, but I've finally found the three Magic Orbs."
renderString rsrc/subs/preboss/03 "Now I just need to find the exit and I can see Teacher and my friends again!"
# repeated
renderString rsrc/subs/preboss/04 "Arle!"
renderString rsrc/subs/preboss/05 "You did it, Arle!"
renderString rsrc/subs/preboss/06 "Congratulations!"
renderString rsrc/subs/preboss/07 "Ah, there they are!"
renderString rsrc/subs/preboss/08 "This must be the exit!"
renderString rsrc/subs/preboss/09 "CongraaAAaaAAaa..."
renderString rsrc/subs/preboss/10 "Wha--?"
renderString rsrc/subs/preboss/11 "GraaaAAAaaaAAaaa..."
renderString rsrc/subs/preboss/12 "EEEEK!"
renderString rsrc/subs/preboss/13 "Wh-Why?!\nThey're all melting like ice!"
renderString rsrc/subs/preboss/14 "I thought...\nI thought I was finally out!"
renderString rsrc/subs/preboss/15 "Bwaaaah!"
renderString rsrc/subs/preboss/16 "Arle..."
renderString rsrc/subs/preboss/17 "Arle!"
renderString rsrc/subs/preboss/18 "...Huh?"
renderString rsrc/subs/preboss/19 "Who are you?"
#renderString rsrc/subs/preboss/20 "We are the spirits living inside the Magic Orbs."
renderStringAlt rsrc/subs/preboss/20 "We are the spirits which dwell within the Magic Orbs."
renderString rsrc/subs/preboss/21 "You are...spirits?"
renderString rsrc/subs/preboss/22 "Yes."
renderString rsrc/subs/preboss/23 "What you've witnessed was an illusion created by the Sorcerot."
renderString rsrc/subs/preboss/24 "This illusion exploits the weakness in your heart to make you lose hope."
renderString rsrc/subs/preboss/25 "You've come this far, Arle."
renderStringAlt rsrc/subs/preboss/26 "You cannot afford to succumb to despair now."
renderString rsrc/subs/preboss/27 "Don't you want to graduate and see your dear teacher and friends again?"
renderString rsrc/subs/preboss/28 "I...I do..."
renderString rsrc/subs/preboss/29 "Then you must remember."
renderString rsrc/subs/preboss/30 "Think back to what you've seen and what you've done to obtain the Magic Orbs."
#renderString rsrc/subs/preboss/31 "I have to remember...?"
renderString rsrc/subs/preboss/31 "Remember...?"
renderString rsrc/subs/preboss/32 "Indeed."
renderString rsrc/subs/preboss/33 "Think back to your reason for obtaining the Magic Orbs."
renderString rsrc/subs/preboss/34 "My reason..."
renderString rsrc/subs/preboss/35 "That's right!"
renderString rsrc/subs/preboss/36 "No matter how scary the monster,\nor how tricky the trap,"
#renderString rsrc/subs/preboss/37 "I never gave up, because I wanted to realize my dream!"
renderString rsrc/subs/preboss/37 "I never gave up...because I wanted to realize my dream!"
renderString rsrc/subs/preboss/38 "Yes, that's it."
renderString rsrc/subs/preboss/39 "I want to pass the exam, and see the teacher and my friends again!"
renderString rsrc/subs/preboss/40 "Very good!"
renderStringAlt rsrc/subs/preboss/41 "Then do you know what you should do now?"
renderString rsrc/subs/preboss/42 "Yeah!"
#renderString rsrc/subs/preboss/43 "I'll keep going forward, without ever losing hope!"
renderString rsrc/subs/preboss/43 "I'll keep going forward..."
renderString rsrc/subs/preboss/44 "...without ever losing hope!"
renderString rsrc/subs/preboss/45 "Could you keep watching over me, spirits?"
renderString rsrc/subs/preboss/46 "We exist inside your heart."
renderString rsrc/subs/preboss/47 "Your anxiety simply made you forget about us."
renderString rsrc/subs/preboss/48 "We are always watching over you."
renderString rsrc/subs/preboss/49 "Yeah...Yeah, that's right!"
renderString rsrc/subs/preboss/50 "Okay, time to teach that mean Sorcerot a lesson!"
renderStringAlt rsrc/subs/preboss/51 "Then I'll pass the exam and see\nTeacher and my friends again!"
renderString rsrc/subs/preboss/52 "Thank you, spirits."
renderString rsrc/subs/preboss/53 "I won't lose hope again."
renderString rsrc/subs/preboss/54 "And I'll never forget about you."
renderString rsrc/subs/preboss/55 "After all, you live inside my heart..."

mkdir -p rsrc/subs/ending
renderString rsrc/subs/ending/00 "Congratulations!"
renderString rsrc/subs/ending/01 "You did it, Arle!"
#renderString rsrc/subs/ending/02 "No need to worry.\nThis is not an illusion."
renderString rsrc/subs/ending/02 "No need to worry.\nThis is no illusion."
renderString rsrc/subs/ending/03 "You've found the Magic Orbs and successfully left the tower."
renderString rsrc/subs/ending/04 "Congratulations."
renderString rsrc/subs/ending/05 "Now you have truly passed the exam."
renderString rsrc/subs/ending/06 "You passed!"
#renderString rsrc/subs/ending/07 "Congratulations!"
renderString rsrc/subs/ending/07 "Congrats!"
#renderString rsrc/subs/ending/08 "Way to go, Arle!"
renderString rsrc/subs/ending/08 "Go, Arle!"
renderString rsrc/subs/ending/09 "...Thanks, everyone!"


rm $tempFontFile