#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TIniFile.h"
#include "util/TBufStream.h"
#include "util/TOfstream.h"
#include "util/TIfstream.h"
#include "util/TStringConversion.h"
#include <iostream>
#include <vector>

using namespace std;
using namespace BlackT;

const static int charW = 12;
const static int charH = 12;

void charToData(const TGraphic& src,
                TStream& ofs,
                int xOffset, int yOffset) {
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
    
    ofs.writeu16be(output);
  }
}

struct CharData {
  CharData()
    : data(0x18),
      width(0) { }
  
  TBufStream data;
  int width;
};

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "12x12 1bpp font builder" << endl;
    cout << "Usage: " << argv[0]
      << " <fontsheet> <infofile> <outfontfile> <outwidthfile>" << endl;
    
    return 0;
  }
  
  
  TGraphic sheet;
  TPngConversion::RGBAPngToGraphic(std::string(argv[1]), sheet);
  int charsPerRow = sheet.w() / charW;
  
  TIniFile info = TIniFile(std::string(argv[2]));
  
  TOfstream fontofs(argv[3], ios_base::binary);
  TOfstream widthofs(argv[4], ios_base::binary);
  
  int numChars = TStringConversion::stringToInt(
    info.valueOfKey("Properties", "numChars"));
  
  std::vector<CharData> chars;
  chars.resize(numChars);
  for (int i = 0; i < numChars; i++) {
    std::string num = TStringConversion::intToString(i);
    while (num.size() < 3) num = std::string("0") + num;
    std::string section = std::string("char") + num;
    
    if (info.hasSection(section)) {
      int width = TStringConversion::stringToInt(
        info.valueOfKey(section, "width"));
//      cerr << width << endl;
      chars[i].width = width;

      int x = (i % charsPerRow) * charW;
      int y = (i / charsPerRow) * charH;
      
      charToData(sheet, chars[i].data, x, y);
      
      chars[i].data.seek(0);
      fontofs.write((char*)chars[i].data.data().data(),
                    chars[i].data.data().size());
      widthofs.writeu8(chars[i].width);
    }
    
    
  }
  
  
  return 0;
}
