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

int spriteBaseY1 = 194;
int spriteBaseY2 = 4;
int targetW = 256;
int targetH = 32;
const int basePatternNum = 0x6000 / 0x40;

//bool altFormat = false;

struct OutputPattern {
  int x;
  int y;
  PceSpritePattern pattern;
};

/*void convertToPatterns(const TGraphic& grp,
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
} */

void convertToPatterns(const TGraphic& grp,
                       std::vector<OutputPattern>& output) {
  int numHorizontalPatterns = (grp.w() / PceSpritePattern::w);
  if ((grp.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns;
  int numVerticalPatterns = (grp.h() / PceSpritePattern::h);
  if ((grp.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns;
  
  TGraphic input(numHorizontalPatterns * PceSpritePattern::w,
                 numVerticalPatterns * PceSpritePattern::h);
  input.clearTransparent();
  input.copy(grp,
             TRect(0, 0, 0, 0));
  
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
      pattern.fromGraphic(input, x, y, NULL);
      
      OutputPattern outputPattern;
      outputPattern.x = x;
      outputPattern.y = y;
      outputPattern.pattern = pattern;
      output.push_back(outputPattern);
    }
  }
}


int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I PCECD lyric sprite block builder" << endl;
    cout << "Usage: " << argv[0] << " <graphic> <outfile>"
//      << " [options]"
      << endl;
    
    return 0;
  }
  
  string graphic1Name(argv[1]);
//  string graphic2Name(argv[2]);
  string outfileName(argv[2]);
  
//  if (TOpt::hasFlag(argc, argv, "--altformat")) {
//    altFormat = true;
//  }
  
  TBufStream ofs;
  
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
  vector<OutputPattern> outputPatterns1;
  convertToPatterns(grp1, outputPatterns1);
  
//  int numHorizontalPatterns1 = (grp1.w() / PceSpritePattern::w);
//  if ((grp1.w() % PceSpritePattern::w) != 0) ++numHorizontalPatterns1;
  int numVerticalPatterns1 = (grp1.h() / PceSpritePattern::h);
  if ((grp1.h() % PceSpritePattern::h) != 0) ++numVerticalPatterns1;
  
  int graphic1OffsetX = (targetW - grp1.w()) / 2;
//  int graphic1OffsetY = (targetH - grp1.h()) / 2;
  int graphic1OffsetY
    = (targetH - (numVerticalPatterns1 * PceSpritePattern::h)) / 2;
  
//  int numPatternsUsed = 0;
  
  // size
  ofs.writeu8(outputPatterns1.size());
//  ofs.writeu8(outputPatterns1.size() + outputPatterns2.size());
  
  for (int i = 0; i < outputPatterns1.size(); i++) {
    OutputPattern& pattern = outputPatterns1[i];
    pattern.pattern.write(ofs);
  }
  
  int totalPatternNum = 0;
  
//  ofs.writeu16le(outputPatterns1.size());
  for (int i = 0; i < outputPatterns1.size(); i++) {
    OutputPattern& pattern = outputPatterns1[i];
    
    int x = 32 + graphic1OffsetX + pattern.x;
    int y = 64 + graphic1OffsetY + pattern.y + spriteBaseY1;
    
    // y-coordinate
    ofs.writeu16le(y);
    // x-coordinate
    ofs.writeu16le(x);
    // pattern
    ofs.writeu16le((basePatternNum + totalPatternNum) * 2);
    // info
    // set palette 0 + high priority
    ofs.writeu16le(0x0000 | 0x0000 | 0x0080);
    
    ++totalPatternNum;
  }
  
  ofs.save(outfileName.c_str());
  
  return 0;
}
