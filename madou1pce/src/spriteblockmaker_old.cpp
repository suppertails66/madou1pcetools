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

int spriteBaseY = 184;

//bool altFormat = false;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "PC-Engine grayscale sprite block builder" << endl;
    cout << "Usage: " << argv[0] << " <graphic> <outfile>"
//      << " [options]"
      << endl;
    
    return 0;
  }
  
  string graphicName(argv[1]);
  string outfileName(argv[2]);
  
//  if (TOpt::hasFlag(argc, argv, "--altformat")) {
//    altFormat = true;
//  }
  
  TGraphic grp;
  TPngConversion::RGBAPngToGraphic(graphicName, grp);
  
  int numHorizontalPatterns = (grp.w() / PceSpritePattern::w);
  if ((grp.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns;
  int numVerticalPatterns = (grp.h() / PceSpritePattern::h);
  if ((grp.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns;
  
  TBufStream ofs;
  for (int j = 0; j < numVerticalPatterns; j++) {
    for (int i = 0; i < numHorizontalPatterns; i++) {
      int x = (i * PceSpritePattern::w);
      int y = (j * PceSpritePattern::h);
      
      PceSpritePattern pattern;
      pattern.fromGraphic(grp, x, y, NULL); 
      pattern.write(ofs);
    }
  }
  
  // write sprite table entry
  // 16 sprites, starting at 0x0700
/*  if (numVerticalPatterns == 1) {
    for (int i = 0; i < 16; i++) {
      // y-coordinate
      ofs.writeu16le(64 + spriteBaseY);
      // x-coordinate
      ofs.writeu16le(32 + (i * PceSpritePattern::w));
      // pattern
      ofs.writeu16le((0x2C + i) * 2);
      // info
      // set high priority
      ofs.writeu16le(0x0000 | 0x0080);
    }
  }
  else {
    for (int i = 0; i < 16; i++) {
      // y-coordinate
      ofs.writeu16le(64 + spriteBaseY + ((i / 8) * 16) - 8);
      // x-coordinate
      ofs.writeu16le(32 + (i * PceSpritePattern::w));
      // pattern
      ofs.writeu16le((0x2C + i) * 2);
      // info
      // set high priority
      ofs.writeu16le(0x0000 | 0x0080);
    }
  }
  
  // remaining sprites are null
  for (int i = 0; i < 48; i++) {
    // y-coordinate
    ofs.writeu16le(0x0000);
    // x-coordinate
    ofs.writeu16le(0x0000);
    // pattern
    ofs.writeu16le(0x0000);
    // info
    // set high priority
    ofs.writeu16le(0x0000);
  } */
  
  for (int j = 0; j < 2; j++) {
    for (int i = 0; i < 16; i++) {
      // y-coordinate
      ofs.writeu16le(64 + (j * PceSpritePattern::h) + spriteBaseY);
      // x-coordinate
      ofs.writeu16le(32 + (i * PceSpritePattern::w));
      // pattern
      ofs.writeu16le((0x1C + (j * 16) + i) * 2);
      // info
      // set high priority
      ofs.writeu16le(0x0000 | 0x0080);
    }
  }
  
  // remaining sprites are null
  for (int i = 0; i < 32; i++) {
    // y-coordinate
    ofs.writeu16le(0x0000);
    // x-coordinate
    ofs.writeu16le(0x0000);
    // pattern
    ofs.writeu16le(0x0000);
    // info
    ofs.writeu16le(0x0000);
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
  for (int i = 0; i < 16; i++) {
    PceColor color;
    int level = (i << 4) | i;
    color.setRealColor(TColor(level, level, level));
    ofs.writeu16le(color.getNative());
  }
  
  // dummy palettes
  for (int i = 0; i < 15; i++)
    for (int i = 0; i < 16; i++)
      ofs.writeu16le(0x0000);
  
  ofs.save(outfileName.c_str());
  
  return 0;
}
