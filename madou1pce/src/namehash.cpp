#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceNameHasher.h"
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
  if (argc < 2) {
    cout << "Sailor Moon (PC-Engine) name hash calculator" << endl;
    cout << "Usage: " << argv[0] << " <name>" << endl;
    
    return 0;
  }
  
  string str(argv[1]);
  cout << SmPceNameHasher::hash(str) << endl;
  
  return 0;
}
