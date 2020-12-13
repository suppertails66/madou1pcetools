#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceFileIndex.h"
#include "smpce/SmPceGraphic.h"
#include "smpce/SmPceNameHasher.h"
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
#include "util/TFreeSpace.h"
#include "util/TOpt.h"
#include <string>
#include <vector>
#include <map>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

void patchTilemap(TBufStream& dst, int tilemapW,
                  std::string srcName, int srcW,
                  int x, int y) {
  TBufStream src;
  src.open(srcName.c_str());
  
  int srcH = (src.size() / 2) / srcW;
  
  int dstBase = dst.tell();
  for (int j = 0; j < srcH; j++) {
    dst.seek(dstBase + ((y + j) * tilemapW * 2) + (x * 2));
    dst.writeFrom(src, srcW * 2);
  }
}

int main(int argc, char* argv[]) {
  if (argc < 8) {
    cout << "PC Engine tilemap patcher tool" << endl;
    cout << "Usage: " << argv[0]
      << " <basemap> <basemap_w> <patchmap> <patchmap_w> <x> <y> <outfile>" << endl;
    
    return 0;
  }
  
  std::string basefileName(argv[1]);
  int basemapW = TStringConversion::stringToInt(string(argv[2]));
  std::string patchfileName(argv[3]);
  int patchmapW = TStringConversion::stringToInt(string(argv[4]));
  int x = TStringConversion::stringToInt(string(argv[5]));
  int y = TStringConversion::stringToInt(string(argv[6]));
  std::string outfile(argv[7]);
  
  TBufStream baseIfs;
  baseIfs.open(basefileName.c_str());
  
  patchTilemap(baseIfs, basemapW,
               patchfileName, patchmapW,
               x, y);
  
  baseIfs.save(outfile.c_str());
  
  return 0;
}
