#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Pce;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Split low/high byte pointer table decoder" << endl;
    cout << "Usage: " << argv[0] << " [file] [offset] [numentries]" << endl;
    
    return 0;
  }
  
  TBufStream ifs;
  ifs.open(argv[1]);
  
  int tableBase = TStringConversion::stringToInt(string(argv[2]));
  int numEntries = TStringConversion::stringToInt(string(argv[3]));
  
  for (int i = 0; i < numEntries; i++) {
    ifs.seek(tableBase + i);
    int lo = ifs.readu8();
    ifs.seek(tableBase + numEntries + i);
    int hi = ifs.readu8();
    
    int value = lo | (hi << 8);
    
    cout << TStringConversion::intToString(value, TStringConversion::baseHex)
      << endl;
  }
  
  return 0;
}
