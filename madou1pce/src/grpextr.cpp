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
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    std::cout << "Sailor Moon (PCECD) graphic extractor" << std::endl;
    std::cout << "Usage: " << argv[0] << " [infile] [outfile]" << std::endl;
    
    return 1;
  }
  
  std::string infile = argv[1];
  std::string outfile = argv[2];
    
  TBufStream sndifs;
  sndifs.open(infile.c_str());
  
  SmPceGraphic grp;
  grp.read(sndifs);
  
  grp.save(outfile.c_str());
  
  return 0;
}
