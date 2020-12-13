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
#include "util/TThingyTable.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

std::string getNumStr(int num) {
  std::string str = TStringConversion::intToString(num,
    TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  return string("<$") + str + ">";
}

int main(int argc, char* argv[]) {
  if (argc < 2) {
    cout << "Madou Monogatari I (PCECD) credits dumper" << endl;
    cout << "Usage: " << argv[0] << " [outfile]" << endl;
    return 0;
  }
  
  TThingyTable table;
  table.readSjis("table/credits.tbl");
  
  TBufStream ifs;
  ifs.open("base/intro_21.bin");
  ifs.seek(0x18000);
  
  TBufStream ofs;
  
  while (true) {
    TThingyTable::MatchResult result = table.matchId(ifs);
    if (result.id == -1) {
      cerr << "bad id" << endl;
      return 1;
    }
    
    // linebreak
//    if (result.id == 0x0D) {
//      
//    }
    else {
      ofs.writeString(table.getEntry(result.id));
    }
    
    // linebreak
    if (result.id == 0x0D) {
      ofs.writeString(string("\r\n"));
    }
    // terminator
    else if (result.id == 0x1A) {
      ofs.writeString(string("\r\n"));
      break;
    }
    // change text color
    else if (result.id == 0x1B) {
      int value = ifs.readu8();
      ofs.writeString(getNumStr(value));
      ofs.writeString(string("\r\n"));
    }
  }
  
  ofs.save(argv[1]);
  
  return 0;
}
