#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;

std::string readPatternString(std::string str) {
  std::string result;
  
  TBufStream ifs;
  ifs.writeString(str);
  ifs.seek(0);
  
  while (!ifs.eof()) {
    char next = ifs.get();
    
    if (next == '\\') {
      if (ifs.peek() == 'n') {
        ifs.get();
        result += '\n';
        continue;
      }
      else if (ifs.peek() == '\\') {
        ifs.get();
        result += '\\';
        continue;
      }
    }
    
    result += next;
  }
  
  return result;
}

bool checkMatch(TStream& ifs, const std::string& pattern) {
  if (ifs.remaining() < pattern.size()) return false;
  int initialPos = ifs.tell();
  
  for (unsigned int i = 0; i < pattern.size(); i++) {
    if (ifs.get() != pattern[i]) {
      ifs.clear();
      ifs.seek(initialPos);
      return false;
    }
  }
  
  return true;
}

int main(int argc, char* argv[]) {
  if (argc < 5) {
    std::cout << "Find and replace" << std::endl;
    std::cout << "Usage: " << argv[0] << " [infile] [pattern] [replacement]"
      << " [outfile]" << std::endl;
    
    return 1;
  }
  
  std::string infile = argv[1];
  std::string patternRaw = argv[2];
  std::string replacementRaw = argv[3];
  std::string outfile = argv[4];
  
  std::string pattern = readPatternString(patternRaw);
  std::string replacement = readPatternString(replacementRaw);
  
  std::cout << pattern << std::endl;
  std::cout << replacement << std::endl;
    
  TBufStream ifs;
  ifs.open(infile.c_str());
  
  TBufStream ofs;
  
  while (!ifs.eof()) {
    bool matches = checkMatch(ifs, pattern);
    if (matches) {
      ofs.writeString(replacement);
    }
    else {
      ofs.put(ifs.get());
    }
  }
  
  ofs.save(outfile.c_str());
  
  return 0;
}
