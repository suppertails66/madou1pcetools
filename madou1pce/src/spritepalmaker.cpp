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
  if (argc < 2) {
    cout << "Sailor Moon PCECD lyric sprite palette builder" << endl;
    cout << "Usage: " << argv[0] << " <outfile>"
//      << " [options]"
      << endl;
    
    return 0;
  }
  
  string outfileName(argv[1]);
  
  TBufStream ofs;
  
  // palette
  
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
  
  ofs.save(outfileName.c_str());
  
  return 0;
}
