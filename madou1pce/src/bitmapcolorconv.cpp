#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceFileIndex.h"
#include "smpce/SmPceGraphic.h"
#include "pce/okiadpcm.h"
#include "pce/PcePalette.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TSoundFile.h"
#include "pce/PceColor.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    std::cout << "Sailor Moon (PCECD) bitmap 3-to-5-bit converter" << std::endl;
    std::cout << "Usage: " << argv[0] << " [infile] [outfile]" << std::endl;
    
    return 1;
  }
  
  std::string infile = argv[1];
  std::string outfile = argv[2];
    
  TBufStream ifs;
  ifs.open(infile.c_str());
  
  TBufStream ofs;
  
  while (!ifs.eof()) {
//    int next = ifs.readu16le();
    
    PceColor color;
    color.read(ifs);
    
    int native = color.getNative();
    
    int b = (native & 0x0007);
    int r = (native & 0x0038) >> 3;
    int g = (native & 0x01C0) >> 6;
    
    int output = 0;
    output |= (b << 2);
    output |= (r << 7);
    output |= (g << 12);
    
    ofs.writeu16be(output);
    
//    int b = (next & 0x001F);
//    int r = (next & 0x03E0) >> 5;
//    int g = (next & 0x7C00) >> 10;
  }
  
  ofs.save(outfile.c_str());
  
  return 0;
}
