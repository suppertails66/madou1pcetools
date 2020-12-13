#include "util/TStringConversion.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TThingyTable.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include <string>
#include <map>
#include <fstream>
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Psx;

TThingyTable table;

void fixScript(TStream& src, TStream& ofs) {
  int lineNum = 0;
  
  bool doubleQuoteActive = false;
  bool singleQuoteActive = false;
  while (!src.eof()) {
    std::string line;
    src.getLine(line);
    ++lineNum;
    
//    std::cerr << lineNum << std::endl;
//    if (line.size() <= 0) continue;
    if (line.size() <= 0) {
      ofs.put('\n');
      continue;
    }
    
    TBufStream ifs(line.size());
    ifs.write(line.c_str(), line.size());
    ifs.seek(0);
    
    // check for special stuff
    if (ifs.peek() == '#') {
      int pos = ifs.tell();
      string name;
      while (!ifs.eof() && (ifs.peek() != '(')) name += ifs.get();
      ifs.seek(pos);
      
      if (name.compare("STARTSTRING") == 0) {
        
      }
      else if (name.compare("ENDSTRING") == 0) {
        if (doubleQuoteActive) {
          std::cerr << "WARNING: Line " << lineNum
            << ": unterminated double quote" << std::endl;
          doubleQuoteActive = false;
        }
        
        if (singleQuoteActive) {
          std::cerr << "WARNING: Line " << lineNum
            << ": unterminated single quote" << std::endl;
          singleQuoteActive = false;
        }
      }
      
      // copy directive to output
      while (!ifs.eof()) ofs.put(ifs.get());
      ofs.put('\n');
      continue;
    }
    
    while (!ifs.eof()) {
      // check for comments
      if ((ifs.remaining() >= 2)
          && (ifs.peek() == '/')) {
        ifs.get();
        if (ifs.peek() == '/') {
          ifs.unget();
          while (!ifs.eof()) ofs.put(ifs.get());
          break;
        }
        else ifs.unget();
      }
      
      // 2-byte sjis sequence
//      if ((TByte)ifs.peek() >= 0x80) {
//        ofs.put(ifs.get());
//        ofs.put(ifs.get());
//        continue;
//      }
      
      if (ifs.peek() == '"') {
        if (doubleQuoteActive) {
          ifs.get();
          ofs.put('}');
          doubleQuoteActive = false;
        }
        else {
          ifs.get();
          ofs.put('{');
          doubleQuoteActive = true;
        }
      }
      else if (ifs.peek() == '{') {
        if (singleQuoteActive) {
          std::cerr << "WARNING: Line " << lineNum
            << ": double single quote?" << std::endl;
          ofs.put(ifs.get());
        }
        else {
          ifs.get();
          ofs.put('<');
          singleQuoteActive = true;
        }
      }
      else if (ifs.peek() == '}') {
        if (singleQuoteActive) {
          ifs.get();
          ofs.put('>');
          singleQuoteActive = false;
        }
        else {
          std::cerr << "WARNING: Line " << lineNum
            << ": uninitialized single quote?" << std::endl;
          ofs.put(ifs.get());
        }
      }
      else {
        ofs.put(ifs.get());
      }
      
//      outputNextSymbol(ifs);
    }
    
    ofs.put('\n');
  }
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Script fixer" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [thingy] [outprefix]"
      << endl;
    
    return 0;
  }
  
  string inPrefix = string(argv[1]);
  string tableName = string(argv[2]);
  string outPrefix = string(argv[3]);
  
  table.readSjis(tableName);

  {
    TBufStream ifs;
    ifs.open((inPrefix + "script.txt").c_str());
    
    TBufStream ofs;
    fixScript(ifs, ofs);
    ofs.save((outPrefix + "script.txt").c_str());
  }
  
  return 0;
}

