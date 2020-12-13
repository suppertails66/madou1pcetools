#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TIniFile.h"
#include "util/TBufStream.h"
#include "util/TOfstream.h"
#include "util/TIfstream.h"
#include "util/TStringConversion.h"
#include "util/TBitmapFont.h"
#include <iostream>
#include <vector>

using namespace std;
using namespace BlackT;

const static int charW = 12;
const static int charH = 11;

void charToData(const TGraphic& src,
                int xOffset, int yOffset,
                TStream& ofs) {
  for (int j = 0; j < charH; j++) {
    int output = 0;
    
    int mask = 0x8000;
    for (int i = 0; i < charW; i++) {
      int x = xOffset + i;
      int y = yOffset + j;
      TColor color = src.getPixel(x, y);
      
      if ((color.a() == TColor::fullAlphaTransparency)
          || (color.r() < 0x80)) {
        
      }
      else {
        output |= mask;
      }
      
      mask >>= 1;
    }
    
    // TODO: this currently stores the 12-pixel wide characters to a full word
    // each. we could reduce size by 1/4 by packing the characters together,
    // at the cost of having to do additional masking and shifting during
    // the composition phase.
    // will do only if necessary.
    ofs.writeu16be(output);
  }
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I PCECD font builder" << endl;
    cout << "Usage: " << argv[0] << " <font> <outfontfile> <outwidthfile>"
      << endl;
    
    return 0;
  }
  
  string fontName(argv[1]);
  string outFontFileName(argv[2]);
  string outWidthFileName(argv[3]);
  
  TBitmapFont font;
  font.load(fontName);
  
  TBufStream fontofs;
  TBufStream widthofs;
  
  for (int i = 0; i < font.numFontChars(); i++) {
    const TBitmapFontChar& fontChar = font.fontChar(i);
    int width = fontChar.advanceWidth;
    
    charToData(fontChar.grp, 0, 0, fontofs);
    widthofs.writeu8(width);
  }
  
  fontofs.save(outFontFileName.c_str());
  widthofs.save(outWidthFileName.c_str());
  
  return 0;
}
