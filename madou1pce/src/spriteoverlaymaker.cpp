#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TIniFile.h"
#include "util/TBufStream.h"
#include "util/TOfstream.h"
#include "util/TIfstream.h"
#include "util/TStringConversion.h"
#include "util/TBitmapFont.h"
#include "util/TOpt.h"
#include "util/TRect.h"
#include "pce/PceSpritePattern.h"
#include "pce/PceColor.h"
#include "pce/PcePaletteLine.h"
#include <iostream>
#include <vector>

using namespace std;
using namespace BlackT;
using namespace Pce;

//int spriteBaseY1 = 194;
int spriteBaseY1 = 0;
int spriteBaseY2 = 4;
int targetW = 256;
int targetH = 32;
//const int basePatternNum = 0x6000 / 0x40;
const int basePatternNum = 0x140;

//bool altFormat = false;

struct OutputPattern {
  int x;
  int y;
  PceSpritePattern pattern;
};


TRect computeBoundingBox(const TGraphic& grp) {
  int left = grp.w();
  int right = 0;
  int top = grp.h();
  int bottom = 0;
  
  for (int j = 0; j < grp.h(); j++) {
    for (int i = 0; i < grp.w(); i++) {
      if (grp.getPixel(i, j).a() != TColor::fullAlphaTransparency) {
        if (i < left) left = i;
        if (i > right) right = i;
        if (j < top) top = j;
        if (j > bottom) bottom = j;
      }
    }
  }
  
  return TRect(left, top, (right - left) + 1, (bottom - top) + 1);
}

void convertToPatterns(const TGraphic& grp,
                       std::vector<OutputPattern>& output,
                       const PcePaletteLine& paletteLine) {
  TRect boundingBox = computeBoundingBox(grp);
  
//  int numHorizontalPatterns = (grp.w() / PceSpritePattern::w);
//  if ((grp.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns;
//  int numVerticalPatterns = (grp.h() / PceSpritePattern::h);
//  if ((grp.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns;
  int numHorizontalPatterns = (boundingBox.w() / PceSpritePattern::w);
  if ((boundingBox.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns;
  int numVerticalPatterns = (boundingBox.h() / PceSpritePattern::h);
  if ((boundingBox.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns;
  
  TGraphic input(numHorizontalPatterns * PceSpritePattern::w,
                 numVerticalPatterns * PceSpritePattern::h);
  input.clearTransparent();
//  input.copy(grp,
//             TRect(0, 0, 0, 0));
  input.copy(grp,
             TRect(0, 0, 0, 0),
             boundingBox);
  
  for (int j = 0; j < numVerticalPatterns; j++) {
    for (int i = 0; i < numHorizontalPatterns; i++) {
      int x = (i * PceSpritePattern::w);
      int y = (j * PceSpritePattern::h);
      
      // ignore empty areas
      bool empty = true;
      for (int j = 0; j < PceSpritePattern::h; j++) {
        for (int i = 0; i < PceSpritePattern::w; i++) {
          if (input.getPixel(x + i, y + j).a()
                != TColor::fullAlphaTransparency) {
            empty = false;
            break;
          }
        }
        if (!empty) break;
      }
      if (empty) continue;
      
      PceSpritePattern pattern;
//      pattern.fromGraphic(input, x, y, NULL);
      if (pattern.fromGraphic(input, x, y, &paletteLine) != 0) {
//        cerr << "Error: failed converting pattern at ("
//          << i << "," << j << ")" << endl;
        throw TGenericException(T_SRCANDLINE,
                                "convertToPatterns()",
                                string("Error: failed converting pattern at (")
                                + TStringConversion::intToString(i)
                                + ","
                                + TStringConversion::intToString(j)
                                + ")");
      }
      
      OutputPattern outputPattern;
//      outputPattern.x = x;
//      outputPattern.y = y;
      outputPattern.x = x + boundingBox.x();
      outputPattern.y = y + boundingBox.y();
      outputPattern.pattern = pattern;
      output.push_back(outputPattern);
    }
  }
}


int main(int argc, char* argv[]) {
  if (argc < 6) {
    cout << "Madou Monogatari I PCECD title overlay sprite block builder"
      << endl;
    cout << "Usage: " << argv[0] << " <graphic> <palette> <paloffset>"
      << " <outgrp> <outsprites>"
      << " [options]"
      << endl;
    cout << "Options:" << endl;
    cout << "   -x    Offset x-positions by this amount" << endl;
    cout << "   -y    Offset y-positions by this amount" << endl;
    
    return 0;
  }
  
  string graphic1Name(argv[1]);
//  string graphic2Name(argv[2]);
  string paletteName(argv[2]);
  int paletteOffset = TStringConversion::stringToInt(string(argv[3]));
  string outgrpName(argv[4]);
  string outspritesName(argv[5]);
  
  int xOffset = 0;
  int yOffset = 0;
  
  TOpt::readNumericOpt(argc, argv, "-x", &xOffset);
  TOpt::readNumericOpt(argc, argv, "-y", &yOffset);
  
  PcePaletteLine paletteLine;
  {
    TBufStream ifs;
    ifs.open(paletteName.c_str());
    ifs.seek(paletteOffset);
    paletteLine.read(ifs);
    
    // HACK: trash the first half of the palette (containing the
    // non-cycling colors)
    for (int i = 0; i < 8; i++) {
      paletteLine.colors[i].setRealColor(TColor(0xFF, 0xFF, 0x00));
    }
  }
  
//  if (TOpt::hasFlag(argc, argv, "--altformat")) {
//    altFormat = true;
//  }
  
  // palette
  
  // grayscale
/*  for (int i = 0; i < 16; i++) {
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
      ofs.writeu16le(0x0000); */
  
  // graphic 1 patterns
  TGraphic grp1;
  TPngConversion::RGBAPngToGraphic(graphic1Name, grp1);
  
//  TRect boundingBox = computeBoundingBox(grp1);
//  std::cout << boundingBox.x() << " " << boundingBox.y() << " "
//     << boundingBox.w() << " " << boundingBox.h() << " " << endl;
  
  vector<OutputPattern> outputPatterns1;
  convertToPatterns(grp1, outputPatterns1, paletteLine);
  
//  int numHorizontalPatterns1 = (grp1.w() / PceSpritePattern::w);
//  if ((grp1.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns1;
  int numVerticalPatterns1 = (grp1.h() / PceSpritePattern::h);
  if ((grp1.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns1;
  
  int graphic1OffsetX = (targetW - grp1.w()) / 2;
//  int graphic1OffsetY = (targetH - grp1.h()) / 2;
  int graphic1OffsetY
    = (targetH - (numVerticalPatterns1 * PceSpritePattern::h)) / 2;
  
//  int numPatternsUsed = 0;
  
  {
    TBufStream ofs;
    
  //  ofs.writeu8(outputPatterns1.size() + outputPatterns2.size());
    
    for (int i = 0; i < outputPatterns1.size(); i++) {
      OutputPattern& pattern = outputPatterns1[i];
      pattern.pattern.write(ofs);
    }
    
    ofs.save(outgrpName.c_str());
  }
    
  {
    TBufStream ofs;
    
    // size
    ofs.writeu8(outputPatterns1.size());
    
    int totalPatternNum = 0;
    
  //  ofs.writeu16le(outputPatterns1.size());
    for (int i = 0; i < outputPatterns1.size(); i++) {
      OutputPattern& pattern = outputPatterns1[i];
      
//      int x = 32 + graphic1OffsetX + pattern.x;
//      int y = 64 + graphic1OffsetY + pattern.y + spriteBaseY1;
      int x = graphic1OffsetX + pattern.x;
      int y = graphic1OffsetY + pattern.y + spriteBaseY1;
      
      // y-coordinate
      ofs.writeu16le(y);
      // x-coordinate
      ofs.writeu16le(x);
      // pattern
      ofs.writeu16le((basePatternNum + totalPatternNum) * 2);
      // info
      // set palette F + high priority
  //    ofs.writeu16le(0x000F | 0x0000 | 0x0080);
      ofs.writeu16le(0x0081);
      
      ++totalPatternNum;
    }
    
    ofs.save(outspritesName.c_str());
  }
  
  return 0;
}
