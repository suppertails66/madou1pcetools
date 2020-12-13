#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TIniFile.h"
#include "util/TBufStream.h"
#include "util/TOfstream.h"
#include "util/TIfstream.h"
#include "util/TStringConversion.h"
#include "util/TBitmapFont.h"
#include "util/TOpt.h"
#include "pce/PceSpritePattern.h"
#include "pce/PceColor.h"
#include <iostream>
#include <vector>

using namespace std;
using namespace BlackT;
using namespace Pce;

int spriteBaseY1 = 184 - 16;
int spriteBaseY2 = 16 - 8;

//bool altFormat = false;

void convertToPatterns(const TGraphic& grp,
                       TStream& ofs) {
  int numHorizontalPatterns = (grp.w() / PceSpritePattern::w);
  if ((grp.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns;
  int numVerticalPatterns = (grp.h() / PceSpritePattern::h);
  if ((grp.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns;
  
  for (int j = 0; j < numVerticalPatterns; j++) {
    for (int i = 0; i < numHorizontalPatterns; i++) {
      int x = (i * PceSpritePattern::w);
      int y = (j * PceSpritePattern::h);
      
      PceSpritePattern pattern;
      pattern.fromGraphic(grp, x, y, NULL); 
      pattern.write(ofs);
    }
  }
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Sailor Moon PCECD lyric sprite block builder" << endl;
    cout << "Usage: " << argv[0] << " <lyric_en> <lyric_jp> <outfile>"
//      << " [options]"
      << endl;
    
    return 0;
  }
  
  string graphic1Name(argv[1]);
  string graphic2Name(argv[2]);
  string outfileName(argv[3]);
  
//  if (TOpt::hasFlag(argc, argv, "--altformat")) {
//    altFormat = true;
//  }
  
  TBufStream ofs;
  
  // graphic 1 patterns
  TGraphic grp1;
  TPngConversion::RGBAPngToGraphic(graphic1Name, grp1);
  convertToPatterns(grp1, ofs);
  
  // graphic 1 sprites
  for (int j = 0; j < 2; j++) {
    for (int i = 0; i < 16; i++) {
      // y-coordinate
      ofs.writeu16le(64 + (j * PceSpritePattern::h) + spriteBaseY1);
      // x-coordinate
      ofs.writeu16le(32 + (i * PceSpritePattern::w));
      // pattern
      ofs.writeu16le((0x1C + (j * 16) + i) * 2);
      // info
      // set palette 0 + high priority
      ofs.writeu16le(0x0000 | 0x0000 | 0x0080);
    }
  }
  
  // graphic 2 sprites
  for (int j = 0; j < 2; j++) {
    for (int i = 0; i < 16; i++) {
      // y-coordinate
      ofs.writeu16le(64 + (j * PceSpritePattern::h) + spriteBaseY2);
      // x-coordinate
      ofs.writeu16le(32 + (i * PceSpritePattern::w));
      // pattern
      ofs.writeu16le((0x1C0 + (j * 16) + i) * 2);
      // info
      // set palette 1 + high priority
      ofs.writeu16le(0x0000 | 0x0001 | 0x0080);
    }
  }
  
  // palette
  
/*  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x0000);
  ofs.writeu16le(0x01FF); */
  
  // grayscale
  for (int i = 0; i < 16; i++) {
    PceColor color;
    int level = (i << 4) | i;
    color.setRealColor(TColor(level, level, level));
    ofs.writeu16le(color.getNative());
  }
  
  // bluegreen-scale
  for (int i = 0; i < 16; i++) {
    PceColor color;
    int level = (i << 4) | i;
    color.setRealColor(TColor(0, level, level));
    ofs.writeu16le(color.getNative());
  }
  
  // dummy palettes
  for (int i = 0; i < 14; i++)
    for (int i = 0; i < 16; i++)
      ofs.writeu16le(0x0000);
  
  // graphic 2 patterns
  TGraphic grp2;
  TPngConversion::RGBAPngToGraphic(graphic2Name, grp2);
  convertToPatterns(grp2, ofs);
  
  ofs.save(outfileName.c_str());
  
  return 0;
}
