#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceMsgScriptCmp.h"
//#include "smpce/SmPceVarScriptCmp.h"
#include "smpce/SmPceFileIndex.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TThingyTable.h"
#include "util/TCsv.h"
#include "util/TIniFile.h"
#include "util/TBitmapFont.h"
#include "util/TOpt.h"
#include "exception/TGenericException.h"
#include <string>
#include <vector>
#include <iostream>
#include <sstream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Pce;

struct CharData {
  CharData()
    : //data(0x18),
      width(0) { }
  
//  TBufStream data;
  int width;
};

bool honorifics = false;

// scripts are loaded to 0x7200 in memory and may extend up to 0xB000.
// larger sizes are not allowed.
//const int maxScriptFileSize = 0x6E00;
//const int maxScriptFileSize = 0x3E00;
// unfortunately, the limit is apparently not static.
// some scripts (e.g. minigames) rely on using memory as low as A000 for
// variables, while others fill space far beyond that.
// we'll just have to take this on a case-by-case basis.
const int maxScriptFileSize = 0xFFFF;

std::string scriptfileName;
//std::vector<CharData> chars;
TBitmapFont chars;
bool hadError;

const static int charW = 12;
const static int charH = 12;
// 13 14x12 characters per line
//const static int messageBoxW = (13 * 14) - 8;
const static int messageBoxW = 170;
//const static int messageBoxH = 3 * 12;
const static int messageBoxH = 4 * 12;

std::string encodeMessage(std::string msg,
                   TThingyTable& table) {
  std::string str;
  
//  std::cerr << msg << std::endl;
  while (!msg.empty()) {
    
    // ignore cr
    if (msg[0] == '\r') {
      msg = msg.substr(1, std::string::npos);
      continue;
    }
    // handle linebreaks
    else if (msg[0] == '\n') {
      str += (char)(0x7F + 0x80);
      msg = msg.substr(1, std::string::npos);
      continue;
    }
    
//    std::pair<int, int> result = table.matchTableEntry(msg);
    TThingyTable::MatchResult result = table.matchTableEntry(msg);
    if (result.id == -1) {
      throw TGenericException(T_SRCANDLINE,
                              "encodeMessage()",
                              "Couldn't match string at: "
                                + msg);
    }
    else if (result.size == 0) {
      throw TGenericException(T_SRCANDLINE,
                              "encodeMessage()",
                              "Null entry in table file! Check entry"
                                + TStringConversion::intToString(result.id,
                                    TStringConversion::baseHex));
    }
    
    // encoded value is +0x80 to avoid conflict with opcodes
    str += (char)(result.id + 0x80);
    
    msg = msg.substr(result.size, std::string::npos);
  }
  
  return str;
}

std::pair<std::string, int> matchNextCharacter(std::string& msg,
                TThingyTable& table) {
//  std::string str;
  std::pair<std::string, int> result;
  
//  std::cerr << msg << std::endl;
  while (true) {
    
    // ignore cr
    if (msg[0] == '\r') {
      msg = msg.substr(1, std::string::npos);
      continue;
    }
    // handle linebreaks
    else if (msg[0] == '\n') {
      result.first = std::string("\n");
      result.second = (char)(0x7F);
      msg = msg.substr(1, std::string::npos);
      break;
    }
    
    TThingyTable::MatchResult temp = table.matchTableEntry(msg);
    if (temp.id == -1) {
      throw TGenericException(T_SRCANDLINE,
                              "matchNextCharacter()",
                              "Couldn't match string at: "
                                + msg);
    }
    else if (temp.size == 0) {
      throw TGenericException(T_SRCANDLINE,
                              "matchNextCharacter()",
                              "Null entry in table file! Check entry"
                                + TStringConversion::intToString(temp.id,
                                    TStringConversion::baseHex));
    }
    
    result.first = msg.substr(0, temp.size);
    result.second = (char)(temp.id);
    msg = msg.substr(temp.size, std::string::npos);
    
    break;
  }
  
  return result;
}

bool doNextWord(std::string& msg,
                std::string& result,
                TThingyTable& table,
                int& x, int& y) {
  bool whitespaceDone = false;
  while (!msg.empty()) {
    std::pair<std::string, int> next = matchNextCharacter(msg, table);  
    
//    cerr << hex << (int)((unsigned char)(next.first[0])) << " " << next.first << endl;
    if (next.first[0] == '\n') {
      if (whitespaceDone) {
        // "unget"
        msg = next.first + msg;
//        break;
        return true;
      }
      
      y += 12;
      x = 0;
    }
    else if (next.first[0] == ' ') {
      if (whitespaceDone) {
        // "unget"
        msg = next.first + msg;
        break;
      }
    }
    else {
      whitespaceDone = true;
    }
    
    result += next.first;
    x += chars.fontChar(next.second).advanceWidth;
  }
  
  return false;
}

class TextFmtExp : public std::exception {
public:
  TextFmtExp(std::string result__)
    : result(result__) { }
  
  std::string result;
};

int getMsgWidth(std::string msg, TThingyTable& table) {
  int x = 0;
  while (!msg.empty()) {
    std::pair<std::string, int> next = matchNextCharacter(msg, table);  
    
//    cerr << hex << (int)((unsigned char)(next.first[0])) << " " << next.first << endl;
    if (next.first[0] == '\n') {
      // ???
    }
    
    x += chars.fontChar(next.second).advanceWidth;
  }
  
  return x;
}

std::string formatMessage(std::string msg, TThingyTable& table,
                          bool nowrap = false,
                          bool center = false,
                          int centerAreaW = 0) {
  std::string origmsg = msg;
  std::string result;

  int x = 0;
  int y = 12;
  
  while (!msg.empty()) {
    
/*    // ignore cr
    if (msg[0] == '\r') {
      msg = msg.substr(1, std::string::npos);
      continue;
    }
    // handle linebreaks
    else if (msg[0] == '\n') {
      result += '\n';
      y += 12;
      x = 0;
      continue;
    } */
    
    std::string nextWord;
    bool hitLinebreak = doNextWord(msg, nextWord, table, x, y);
    
//    if (nextWord.size() > 0) {
//      std::cerr << nextWord << " " << x << " " << y << endl;
//    }
    
    if (!nowrap) {
      // check for auto linebreak
      if (x > messageBoxW) {
        y += 12;
        x = 0;
        result += '\n';
        
        // remove leading whitespace
        while ((nextWord.size() > 0)
               && ((nextWord[0] == ' ')
                   || (nextWord[0] == '\n'))) {
          nextWord = nextWord.substr(1, std::string::npos);
        }
        
        x += getMsgWidth(nextWord, table);
      }
    }
    
    result += nextWord;
    
    if (center && (hitLinebreak || msg.empty())) {
      if (x != 0) {
  //      int end = result.size() - 1;
        int start = result.size() - 2;
        while ((start >= 0) && (result[start] != '\n')) --start;
  //      if (start < 0) start = 0;
        ++start;
        
        int padWidth = (centerAreaW - x) / 2;
        
        int spaceW = getMsgWidth(" ", table);
        int numSpaces = padWidth / spaceW;
        int coarseRemainder = padWidth % spaceW;
        
        for (int i = 0; i < numSpaces; i++) {
          result.insert(start, std::string(" "));
        }
        for (int i = 0; i < coarseRemainder; i++) {
  //        result.insert(result.begin() + start, '\x3E');
          result.insert(start, std::string("[space1px]"));
        }
        
        x = getMsgWidth(nextWord, table);
      }
    }
    
    if (!nowrap) {
      if (y >= messageBoxH) {
        throw TextFmtExp(result);
      }
    }
  }
  
  return result;
}

std::string preformatMessage(std::string msg) {
  std::string result;
  
  TBufStream ifs;
  ifs.writeString(msg);
  ifs.seek(0);
  
  bool inSubSection = false;
  while (!ifs.eof()) {
    // FIXME: not safe
    if (ifs.peek() == '+') {
      ifs.get();
      inSubSection = !inSubSection;
      
      if (inSubSection) {
        // starting new subsection
        if (!honorifics) {
          // skip to next section marker
          while (ifs.get() != '+');
        }
      }
      else {
        // ending last subsection
        if (honorifics) {
          // skip to next section marker
          while (ifs.get() != '+');
        }
      }
      
    }
    else {
      result += ifs.get();
    }
  }
  
  if (inSubSection) {
//    std::cerr << "Error: unbalanced sections in line " << msg << endl;
    throw TGenericException(T_SRCANDLINE,
                            "preformatMessage()",
                            string("Error: unbalanced sections in line '")
                              + msg
                              + "'");
  }
  
  return result;
}

void readMessageFile(TCsv& csv, TThingyTable& table,
                     MessageDictionary& dst) {
  for (int i = 0; i < csv.numRows(); i++) {
    bool nofmt = false;
    bool center = true;
    int centerAreaW = 0;
    
    std::string msglabel;
    {
      std::istringstream ss;
      ss.str(csv.cell(0, i));
      ss >> msglabel;
      
      // ignore unlabeled rows
      if (msglabel.size() == 0) continue;
      
      while (ss.good()) {
        std::string fmtcmd;
        ss >> fmtcmd;
        
        if (fmtcmd.compare("nowrap") == 0) {
          nofmt = true;
        }
        else if (fmtcmd.compare("center") == 0) {
          center = true;
          ss >> centerAreaW;
        }
        else {
          std::cerr << "Error:" << endl;
          std::cerr << "Row " << i + 1 << ":" << endl;
          std::cerr << "  Unknown format command: " << fmtcmd << endl;
          std::cerr << endl << endl;
          throw TGenericException(T_SRCANDLINE,
                                  "main()",
                                  "");
        }
      }
      
/*      std::string nofmtcheck;
      ss >> nofmtcheck;
      if (nofmtcheck.size() > 0) {
        nofmt = true;
      } */
//      msglabel = csv.cell(0, i);
    }
    
    std::string name;
    if (csv.numCols() >= 5) name = csv.cell(4, i);
    
    std::string content;
    if (csv.numCols() >= 6) content = csv.cell(5, i);
    
    name = preformatMessage(name);
    content = preformatMessage(content);
    
//    if (!nofmt) {
      try {
        content = formatMessage(content, table, nofmt, center, centerAreaW);
      }
      catch (TextFmtExp& e) {
        std::cerr << "Error formatting " << scriptfileName << ", row "
          << i + 1 << "! Gave up at: " << endl;
        std::cerr << e.result << endl;
        cerr << endl << endl;
        hadError = true;
      }
      catch (TGenericException& e) {
        std::cerr << "Error:" << endl;
        std::cerr << "Row " << i + 1 << ":" << endl;
        std::cerr << "  " << e.problem() << endl;
        std::cerr << endl << endl;
        throw e;
      }
//    }
    
    std::string message;
    
    // add name and linebreak if not empty
    if (!name.empty()) {
      name += '\n';
      message += encodeMessage(name, table);
//      message += (char)(0x7F + 0x80);
    }
    
    // add content
    message += encodeMessage(content, table);
    
    // add to dictionary
    dst[msglabel] = message;
  }
}

int main(int argc, char* argv[]) {
  if (argc < 7) {
    cout << "Bishoujo Senshi Sailor Moon (PCECD) script assembler" << endl;
    cout << "Usage: " << argv[0]
      << " <scriptfile> <tablefile> <font> <commonfile> <msgfile>"
      << " <outfile> [options]" << endl;
    cout << "Options:" << endl;
    cout << "  --honorifics      Enable honorifics" << endl;
    cout << "  --nohonorifics    Disable honorifics (default)" << endl;
    
    return 0;
  }
  
  hadError = false;
  
  scriptfileName = std::string(argv[1]);
//  std::string scriptfileName(argv[1]);
  std::string tablefileName(argv[2]);
  std::string fontName(argv[3]);
  std::string commonfileName(argv[4]);
  std::string msgfileName(argv[5]);
  std::string outfileName(argv[6]);
  
  if (TOpt::hasFlag(argc, argv, "--honorifics")) {
    honorifics = true;
  }
  else if (TOpt::hasFlag(argc, argv, "--nohonorifics")) {
    honorifics = false;
  }
  
//  if (argc >= 8)
//    honorifics
//      = (TStringConversion::stringToInt(std::string(argv[7])) != 0);

  std::ifstream ifs(scriptfileName.c_str(), ios_base::binary);
  TBufStream ofs;
  
  TThingyTable table;
  table.readSjis(tablefileName);
  
/*  TIniFile info = TIniFile(fontindexName);
  
  int numChars = TStringConversion::stringToInt(
    info.valueOfKey("Properties", "numChars"));
  
  chars.resize(numChars);
  for (int i = 0; i < numChars; i++) {
    std::string num = TStringConversion::intToString(i);
    while (num.size() < 3) num = std::string("0") + num;
    std::string section = std::string("char") + num;
    
    if (info.hasSection(section)) {
      int width = TStringConversion::stringToInt(
        info.valueOfKey(section, "width"));
//      cerr << width << endl;
      chars[i].width = width;
    }
  } */
  
  chars.load(fontName);
  
  MessageDictionary dic;
  {
    // common messages
    {
      TCsv common;
      TIfstream ifs(commonfileName.c_str(), ios_base::binary);
      common.readSjis(ifs);
      readMessageFile(common, table, dic);
    }
    
    // script messages
    {
      TCsv msg;
      TIfstream ifs(msgfileName.c_str(), ios_base::binary);
      msg.readSjis(ifs);
      readMessageFile(msg, table, dic);
    }
  }
  
  // TEMP: placeholder stuff for dictionary
//  ofs.writeu16le(0x04);
//  ofs.writeu16le(0x00);
  ofs.writeu16le(0x02);
  
  int lineNum = 1;
  SmPceMsgScriptCmp(ifs, ofs, lineNum, &dic)();
  
  ofs.save(outfileName.c_str());
  
  if (ofs.size() > maxScriptFileSize) {
    std::cerr << "Error: maximum script size exceeded!" << std::endl;
    std::cerr << "Limit is " << maxScriptFileSize
      << ", generated " << ofs.size() << std::endl;
    hadError = true;
  }
  
  if (hadError) return 1;
  
  return 0;
}
