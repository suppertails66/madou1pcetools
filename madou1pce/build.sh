
echo "*******************************************************************************"
echo "Setting up environment..."
echo "*******************************************************************************"

set -o errexit

BASE_PWD=$PWD
PATH=".:$PATH"
INROM="madou1_02.iso"
OUTROM="madou1_02_build.iso"
WLADX="./wla-dx/binaries/wla-huc6280"
WLALINK="./wla-dx/binaries/wlalink"

function remapPalette() {
  oldFile=$1
  palFile=$2
  newFile=$3
  
  convert "$oldFile" -dither None -remap "$palFile" PNG32:$newFile
}

mkdir -p log
mkdir -p out

echo "********************************************************************************"
echo "Building project tools..."
echo "********************************************************************************"

make blackt
make libpce
make

if [ ! -f $WLADX ]; then
  
  echo "********************************************************************************"
  echo "Building WLA-DX..."
  echo "********************************************************************************"
  
  cd wla-dx
    cmake -G "Unix Makefiles" .
    make
  cd $BASE_PWD
  
fi

echo "*******************************************************************************"
echo "Copying binaries..."
echo "*******************************************************************************"

cp -r base out

cp "$INROM" "$OUTROM"

echo "*******************************************************************************"
echo "Building font..."
echo "*******************************************************************************"

mkdir -p out/font
fontbuild "font/" "out/font/font.bin" "out/font/fontwidth.bin"

echo "*******************************************************************************"
echo "Building graphics..."
echo "*******************************************************************************"

cp -r rsrc_raw/pal out

mkdir -p out/cut_patches
mkdir -p out/grp

cp -r rsrc/grp out

remapPalette "out/grp/title_background.png" "out/grp/orig/title_logo.png" "out/grp/title_background.png"
remapPalette "out/grp/title_wreath.png" "out/grp/orig/title_logo.png" "out/grp/title_wreath.png"
remapPalette "out/grp/title_main.png" "out/grp/subtitle_remap.png" "out/grp/title_main.png"
remapPalette "out/grp/title_sub.png" "out/grp/subtitle_remap.png" "out/grp/title_sub.png"
remapPalette "out/grp/title_overlay.png" "out/grp/title_overlay_remap.png" "out/grp/title_overlay.png"

remapPalette "out/grp/loading.png" "out/grp/orig/loading.png" "out/grp/loading.png"
remapPalette "out/grp/dungeon_logo.png" "out/grp/orig/dungeon_logo.png" "out/grp/dungeon_logo.png"

convert -page +0+0 "out/grp/title_main_wreath_bg_mod.png" -page +0+0 "out/grp/title_main.png" -background none -layers mosaic PNG32:out/grp/title_main.png

convert -page +0+0 "out/grp/title_sub.png" -page +0+0 "out/grp/title_overlay.png" -background none -layers mosaic -crop 240x24+0+0 PNG32:out/grp/title_sub.png

for file in tilemappers/*.txt; do
  tilemapper_pce "$file"
done;

patchtilemap "out/grp/title_background.map" 64 "out/grp/title_wreath.map" 40 0 3 "out/grp/title_background.map"
patchtilemap "out/grp/title_background.map" 64 "out/grp/title_main.map" 30 5 3 "out/grp/title_background.map"
patchtilemap "out/grp/title_background.map" 64 "out/grp/title_sub.map" 30 5 12 "out/grp/title_background.map"

spriteoverlaymaker "out/grp/title_overlay.png" "rsrc_raw/pal/title_logo.pal" 0x220 "out/grp/title_overlay_grp.bin" "out/grp/title_overlay_sprites.bin"

grpundmp_pce "out/grp/dungeon_logo.png" 96 "out/grp/dungeon_logo.bin" -p "rsrc_raw/pal/dungeon_logo_line.pal"
grpundmp_pce "out/grp/button_yesno.png" 24 "out/grp/button_yesno.bin" -p "rsrc_raw/pal/dungeon_button_line.pal" -r 6
grpundmp_pce "out/grp/button_onoff.png" 24 "out/grp/button_onoff.bin" -p "rsrc_raw/pal/dungeon_button_line.pal" -r 6

convert "out/grp/mrflea_bayoen.png" -crop 32x16+0+0 "out/grp/mrflea_bayoen1.png"
convert "out/grp/mrflea_bayoen.png" -crop 16x16+32+0 "out/grp/mrflea_bayoen2.png"
convert -size 160x16 xc:none\
  -page +0+0 "out/grp/mrflea_here.png"\
  -page +64+0 "out/grp/mrflea_bayoen1.png"\
  -page +144+0 "out/grp/mrflea_bayoen2.png"\
  -page +96+0 "out/grp/mrflea_think.png"\
  -background none -layers mosaic\
  PNG32:out/grp/mrflea.png

spriteundmp_pce "out/grp/mrflea.png" "out/grp/mrflea.bin" -n 10 -p "rsrc_raw/pal/dungeon_mrflea_line.pal"

convert "out/grp/bayoen.png" -crop 32x32+0+0 "out/grp/bayoen1.png"
convert "out/grp/bayoen.png" -crop 32x32+32+0 "out/grp/bayoen2.png"
convert "out/grp/bayoen.png" -crop 32x32+64+0 "out/grp/bayoen3.png"
convert "out/grp/bayoen.png" -crop 32x32+96+0 "out/grp/bayoen4.png"

spriteundmp_pce "out/grp/bayoen1.png" "out/grp/bayoen1.bin" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -n 4
spriteundmp_pce "out/grp/bayoen2.png" "out/grp/bayoen2.bin" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -n 4
spriteundmp_pce "out/grp/bayoen3.png" "out/grp/bayoen3.bin" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -n 4
spriteundmp_pce "out/grp/bayoen4.png" "out/grp/bayoen4.bin" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -n 4
spriteundmp_pce "out/grp/bayoen_tilde.png" "out/grp/bayoen_tilde.bin" -p "rsrc_raw/pal/dungeon_bayoen_line.pal" -r 2 -n 4
cp "rsrc_raw/grp/bayoen.bin" "out/grp/bayoen.bin"
datpatch "out/grp/bayoen.bin" "out/grp/bayoen.bin" "out/grp/bayoen1.bin" 0x0
datpatch "out/grp/bayoen.bin" "out/grp/bayoen.bin" "out/grp/bayoen2.bin" 0x800
datpatch "out/grp/bayoen.bin" "out/grp/bayoen.bin" "out/grp/bayoen3.bin" 0x400
datpatch "out/grp/bayoen.bin" "out/grp/bayoen.bin" "out/grp/bayoen4.bin" 0xC00
datpatch "out/grp/bayoen.bin" "out/grp/bayoen.bin" "out/grp/bayoen_tilde.bin" 0x200

echo "*******************************************************************************"
echo "Patching graphics..."
echo "*******************************************************************************"

# these one-by-one patches directly to the ISO are extremely slow and wasteful,
# but good enough for our limited purposes

datpatch "out/base/loading_1129.bin" "out/base/loading_1129.bin" "out/grp/loading.map" 0x0000
datpatch "out/base/loading_1129.bin" "out/base/loading_1129.bin" "out/grp/loading.bin" 0x2000

datpatch "$OUTROM" "$OUTROM" "out/grp/dungeon_logo.bin" 0x9D8800
# ?
datpatch "$OUTROM" "$OUTROM" "out/grp/dungeon_logo.bin" 0x10299A3

datpatch "$OUTROM" "$OUTROM" "out/grp/button_yesno.bin" 0x9EA600
datpatch "$OUTROM" "$OUTROM" "out/grp/button_onoff.bin" 0x9EA900

datpatch "$OUTROM" "$OUTROM" "out/grp/mrflea.bin" 0xDD4E20
datpatch "$OUTROM" "$OUTROM" "out/grp/mrflea.bin" 0x1022400
datpatch "$OUTROM" "$OUTROM" "out/grp/mrflea.bin" 0x199E800

datpatch "$OUTROM" "$OUTROM" "out/grp/bayoen.bin" 0x9F7400
datpatch "$OUTROM" "$OUTROM" "out/grp/bayoen.bin" 0x11585A3

# mr flea bayoen sprite definitions:
# remove recycled いる that we can't use
#printf \
#"\x05\
#\x81\x00\x56\x00\x08\x01\x86\x01\
#\x81\x00\x76\x00\x12\x01\x86\x00\
#\x91\x00\x66\x00\x04\x01\x86\x01\
#\xA9\x00\x66\x00\x16\x01\x86\x00\
#\xC1\x00\x6C\x00\x1A\x01\x86\x00\
#" > "out/grp/mrflea_spritedef.bin"
printf \
"\x04\
\x81\x00\x56\x00\x08\x01\x86\x01\
\x81\x00\x76\x00\x12\x01\x86\x00\
\xA9\x00\x66\x00\x16\x01\x86\x00\
\xC1\x00\x6C\x00\x1A\x01\x86\x00\
" > "out/grp/mrflea_spritedef.bin"
datpatch "$OUTROM" "$OUTROM" "out/grp/mrflea_spritedef.bin" 0x102460D
datpatch "$OUTROM" "$OUTROM" "out/grp/mrflea_spritedef.bin" 0x19A74D0

datpatch "$OUTROM" "$OUTROM" "out/grp/error_accard.map" 0x924800
datpatch "$OUTROM" "$OUTROM" "out/grp/error_accard.bin" 0x926800

datpatch "$OUTROM" "$OUTROM" "out/grp/error_clearbak.map" 0x948800
datpatch "$OUTROM" "$OUTROM" "out/grp/error_clearbak.bin" 0x94A800

datpatch "$OUTROM" "$OUTROM" "out/grp/error_clearfiles.map" 0x900800
datpatch "$OUTROM" "$OUTROM" "out/grp/error_clearfiles.bin" 0x902800

echo "*******************************************************************************"
echo "Building script..."
echo "*******************************************************************************"

mkdir -p out/script
mkdir -p out/script/include

madou1pce_scriptbuild "script/" "out/script/"

echo "*******************************************************************************"
echo "Building subtitles..."
echo "*******************************************************************************"

cp -r rsrc/subs out

for file in {out/subs/intro,out/subs/preboss,out/subs/ending}/*.png; do
  name=$(basename $file .png)
  dname=$(basename $(dirname $file))
  
  mkdir -p "out/subs_build/$dname"
  
  spriteblockmaker "$file" "out/subs_build/$dname/$name.bin"
done

# these subtitles need a different vertical video position from everything
# else...
for i in `seq -w 03 15`; do
  spriteblockmaker "out/subs/intro/$i.png" "out/subs_build/intro/$i.bin" -y -8
done

echo "*******************************************************************************"
echo "Prepping disc..."
echo "*******************************************************************************"

mkdir -p out/include

discprep "$OUTROM" "$OUTROM" "out/include/"

echo "********************************************************************************"
echo "Applying ASM patches..."
echo "********************************************************************************"

function applyAsmPatch() {
  infile=$1
  asmname=$2
  linkfile=$3
  infile_base=$(basename $infile)
  infile_base_noext=$(basename $infile .bin)
  
  cp "$infile" "asm/$infile_base"
  
  cd asm
    # apply hacks
    ../$WLADX -I ".." -o "$asmname.o" "$asmname.s"
    ../$WLALINK -v -S "$linkfile" "${infile_base}_build"
  cd $BASE_PWD
  
  mv -f "asm/${infile_base}_build" "out/base/${infile_base}"
  rm "asm/${infile_base}"
  
  rm asm/*.o
}

padfile "out/base/boot_11.bin" 0x2000
padfile "out/base/intro_21.bin" 0x1A000
padfile "out/base/boot2_1121.bin" 0x2000
padfile "out/base/dungeon_12B1.bin" 0x34000

applyAsmPatch "out/base/boot_11.bin" "boot" "boot_link"
applyAsmPatch "out/base/intro_21.bin" "intro" "intro_link"
applyAsmPatch "out/base/boot2_1121.bin" "boot2" "boot2_link"
applyAsmPatch "out/base/dungeon_12B1.bin" "dungeon_text" "dungeon_text_link"
applyAsmPatch "out/base/dungeon_12B1.bin" "dungeon" "dungeon_link"

echo "********************************************************************************"
echo "Patching disc..."
echo "********************************************************************************"

./datpatch "$OUTROM" "$OUTROM" "out/base/boot_11.bin" $((0x11*0x800)) 0 0x1000
./datpatch "$OUTROM" "$OUTROM" "out/base/intro_21.bin" $((0x21*0x800)) 0 0x18800
./datpatch "$OUTROM" "$OUTROM" "out/base/boot2_1121.bin" $((0x1121*0x800)) 0 0x1800
./datpatch "$OUTROM" "$OUTROM" "out/base/dungeon_12B1.bin" $((0x12B1*0x800)) 0 0x32800
./datpatch "$OUTROM" "$OUTROM" "out/base/loading_1129.bin" $((0x1129*0x800)) 0 0x18000

echo "*******************************************************************************"
echo "Success!"
echo "Output file:" $OUTROM
echo "*******************************************************************************"
