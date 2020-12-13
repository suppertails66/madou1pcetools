#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceFileIndex.h"
#include "smpce/SmPceGraphic.h"
#include "pce/okiadpcm.h"
#include "pce/PcePalette.h"
#include "pce/PcePaletteLine.h"
#include "pce/PceColor.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TSoundFile.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

std::string getNumStr(int num) {
  std::string str = TStringConversion::intToString(num);
  while (str.size() < 2) str = string("0") + str;
  return str;
}

std::string getHexWordNumStr(int num) {
  std::string str = TStringConversion::intToString(num,
    TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 4) str = string("0") + str;
  return string("$") + str;
}

void replaceColor(TGraphic& grp, TColor src, TColor dst) {
  for (int j = 0; j < grp.h(); j++) {
    for (int i = 0; i < grp.w(); i++) {
      TColor color = grp.getPixel(i, j);
      if (color == src) {
        grp.setPixel(i, j, dst);
      }
    }
  }
}

int main(int argc, char* argv[]) {
  PcePaletteLine palLine;
  TBufStream palifs;
  palifs.open("rsrc_raw/pal/title_logo.pal");
  
  // read palette line
  palifs.seek(0xA0);
  palLine.read(palifs);
  
  // read src image
  TGraphic grp;
  TPngConversion::RGBAPngToGraphic(string("rsrc/grp/title_main_wreath_bg.png"), grp);
  
  for (int i = 9; i < 16; i++) {
    int shade = (i - 8);
    // G/R/B
    int native = 7 | (shade << 3) | (shade);
    PceColor color;
    color.fromNative(native);
    
    replaceColor(grp,
                 palLine.colors[i].realColor(),
                 color.realColor());
    
    palLine.colors[i] = color;
  }
  
  // save new palette
  palifs.seek(0xA0);
  palLine.write(palifs);
  palifs.save("rsrc_raw/pal/title_logo_mod.pal");
  
  // save src image
  TPngConversion::graphicToRGBAPng(string("rsrc/grp/title_main_wreath_bg_mod.png"), grp);
  
  return 0;
}
