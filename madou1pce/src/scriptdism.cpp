#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceFileIndex.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

int main(int argc, char* argv[]) {

  TIfstream ifs(argv[1], ios_base::binary);
  
  CharacterDictionary dic;
  int numEntries = (ifs.readu16le() / 2) - 1;
  for (int i = 0; i < numEntries; i++) {
    dic[i] = ifs.readu16be();
  }
  
//  while (ifs.remaining() > 0) {
    SmPceMsgScriptDecmp(ifs, std::cout, 0, &dic)();
//  }
  
/*  TIfstream ifs("bssm_24.iso", ios_base::binary);
  ifs.seek(0x29000);
  
  // 5266??
  for (int i = 0; i < 35177; i++) {
    int id1 = ifs.readu8();
    int id2 = ifs.readu8();
    int id3 = ifs.readu8();
    int recordNum = ifs.readu16be();
    int recByte1 = ifs.readu8();
    int recByte2 = ifs.readu8();
    int nextpos = ifs.tell();
    
    int id = 0;
    id |= id3;
    id |= (id2 << 8);
    id |= (id1 << 16);
//    id |= id1;
//    id |= (id2 << 8);
//    id |= (id3 << 16);
    string fname;
    fname += TStringConversion::intToString(id,
                        TStringConversion::baseHex).substr(2, string::npos);
    while (fname.size() < 6) fname = string("0") + fname;
    fname = string("files/") + fname + ".bin";
    cout << dec << i << " " << hex << ifs.tell() - 7 << " " << fname << " " << recordNum
      << " " << recByte1 << " " << recByte2 << endl;
      
    int numRecords = (recByte2 >> 3);
    if (((recByte2 & 0x07) == 0) && (recByte1 == 0)) {
      
    }
    else {
      ++numRecords;
    }
    
    cout << numRecords << endl;
    
//    ifs.seek(recordNum * 0x800);
//    
//    TBufStream ofs(0x100000);
//    ofs.writeFrom(ifs, numRecords * 0x800);
//    ofs.save(fname.c_str()); 
    
    ifs.seek(nextpos);
  } */
  
  return 0;
}
