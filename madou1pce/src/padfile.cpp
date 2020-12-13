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

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Pad file to target size" << endl;
    cout << "Usage: " << argv[0] << " <infile> <target_size> <outfile>" << endl;
    
    return 0;
  }
  
  TBufStream ifs;
  ifs.open(argv[1]);
  
  int targetSize = TStringConversion::stringToInt(string(argv[2]));
  
  ifs.seek(ifs.size());
  while (ifs.size() < targetSize) ifs.put(0x00);
  
  ifs.save(argv[3]);
  
  return 0;
}
