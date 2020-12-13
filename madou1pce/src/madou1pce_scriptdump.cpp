#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "exception/TGenericException.h"
#include <string>
#include <vector>
#include <map>
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Pce;


TThingyTable table;


string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
  return "<$" + str + ">";
}

string as4bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 4) str = string("0") + str;
  
  return "<$" + str + ">";
}

void addComment(std::ostream& ofs, string comment) {
  ofs << "//====================================================================="
    << endl;
  ofs << "// " << comment << endl;
  ofs << "//====================================================================="
    << endl;
  ofs << endl;
}

void addSubComment(std::ostream& ofs,
               string comment = "") {
  if (comment.size() > 0) {
    ofs << "//=======================================" << endl;
    ofs << "// " << comment << endl;
    ofs << "//=======================================" << endl;
    ofs << endl;
  }
}



const static int op_leftbox = 0x00;
const static int op_rightbox = 0x01;
const static int op_centerbox = 0x02;
const static int op_br = 0x03;
const static int op_delay = 0x04;
const static int op_wait = 0x05;
const static int op_06 = 0x06;
const static int op_clear = 0x07;
const static int op_08 = 0x08;
const static int op_09 = 0x09;
const static int op_end = 0x0A;
const static int op_enemy = 0x0B;
const static int op_item1 = 0x0C;
const static int op_item2 = 0x0D;
const static int op_spell = 0x0E;
const static int op_0F = 0x0F;
const static int op_10 = 0x10;
const static int op_gold = 0x11;
const static int op_12 = 0x12;
const static int op_13 = 0x13;
const static int op_14 = 0x14;
const static int op_15 = 0x15;
const static int op_16 = 0x16;
const static int op_17 = 0x17;
const static int op_floorlabel = 0x18;
const static int op_19 = 0x19;
const static int op_1A = 0x1A;
const static int op_1B = 0x1B;
const static int op_1C = 0x1C;
const static int op_color = 0x1D;
const static int op_1E = 0x1E;
const static int op_1F = 0x1F;
const static int op_20 = 0x20;
const static int op_21 = 0x21;
const static int op_item3 = 0x22;
const static int op_23 = 0x23;
const static int op_24 = 0x24;
const static int op_25 = 0x25;
const static int op_26 = 0x26;
const static int op_27 = 0x27;
const static int op_28 = 0x28;
const static int op_29 = 0x29;
const static int op_2A = 0x2A;
const static int op_2B = 0x2B;
const static int op_jump = 0x2C;
const static int op_waitForVoice = 0x2D;
const static int op_2E = 0x2E;
const static int op_2F = 0x2F;
const static int op_30 = 0x30;
const static int op_31 = 0x31;
const static int op_32 = 0x32;

int numOpParamWords(int op) {
  switch (op) {
  case op_delay:
  case op_25:
  case op_26:
  case op_27:
  case op_28:
  case op_29:
  case op_2A:
  case op_2B:
  case op_30:
  case op_32:
    return 1;
    break;
  case op_jump:
  case op_31:
    return 2;
    break;
  default:
    break;
  }
  
  return 0;
}

bool isSharedOp(int op) {
  switch (op) {
  case op_br:
  case op_enemy:
  case op_item1:
  case op_item2:
  case op_floorlabel:
  case op_spell:
  case op_gold:
  case op_color:
  case op_item3:
    return false;
    break;
  default:
    break;
  }
  
  return true;
}

// number of linebreaks that should precede an op type
int numOpPreLines(int op) {
  switch (op) {
  case op_wait:
  case op_delay:
  case op_end:
//  case op_2B:
    return 1;
    break;
  case op_leftbox:
  case op_rightbox:
  case op_centerbox:
    return 2;
    break;
  default:
    break;
  }
  
  return 0;
}

// number of linebreaks that should follow an op type
int numOpPostLines(int op) {
  
  switch (op) {
  case op_br:
    return 1;
    break;
  case op_wait:
  case op_waitForVoice:
  case op_end:
    return 2;
    break;
  default:
    break;
  }
  
  if (isSharedOp(op)) return 1;
  
  return 0;
}

bool isTerminator(int op) {
  switch (op) {
  case op_end:
    return true;
    break;
  default:
    break;
  }
  
  return false;
}



typedef map<int, std::vector<int> > PointerToIndexListMap;

struct RegionInfo {
  PointerToIndexListMap pointerToIndexListMap;
  
  int regionNum;
  
  int pointerTableOffset;
  
  // base offset in dungeon file of region's containing section
  int sectionBaseOffset;
  
  // subtract from region pointers to get offset from start of section
  int pointerBaseOffset;
  
  RegionInfo() { }
  RegionInfo(int regionNum__,
             int sectionBaseOffset__,
             int pointerBaseOffset__)
    : regionNum(regionNum__),
      sectionBaseOffset(sectionBaseOffset__),
      pointerBaseOffset(pointerBaseOffset__) { }
  
  void readPointerTable(TStream& ifs, int tableBase, int numEntries) {
    pointerTableOffset = tableBase;
    
    for (int i = 0; i < numEntries; i++) {
      ifs.seek(tableBase + i);
      int lo = ifs.readu8();
      ifs.seek(tableBase + numEntries + i);
      int hi = ifs.readu8();
      
      int value = lo | (hi << 8);
      
      pointerToIndexListMap[value].push_back(i);
    }
  }
  
  void outputScriptContent(TStream& ifs, ostream& ofs,
                           int scriptPointer,
                           std::vector<int> indexList) {
    ofs << "//[TEXT]" << endl;
    ofs << "#STARTSCRIPT("
      << TStringConversion::intToString(ifs.tell(),
                                        TStringConversion::baseHex)
      << ", "
      << TStringConversion::intToString(scriptPointer, TStringConversion::baseHex)
      << ")" << std::endl;
    
    ofs << "#SETINDEXLIST(";
    for (unsigned int i = 0; i < indexList.size(); i++) {
      ofs << TStringConversion::intToString(indexList[i],
                                            TStringConversion::baseHex);
      if ((unsigned int)i != (indexList.size() - 1)) ofs << ", ";
    }
    ofs << ")" << endl;
    ofs << endl;
    
    // assume ifs is already at the correct input position
    
    std::ostringstream oss_final;
    std::ostringstream oss_textline;
    
    bool atLineStart = true;
    bool lastWasBr = false;
    while (!ifs.eof()) {
      if ((unsigned char)ifs.peek() >= 0x80) {
        // sjis
        oss_textline.put(ifs.get());
        oss_textline.put(ifs.get());
        
        lastWasBr = false;
        atLineStart = false;
        continue;
      }
      
      TThingyTable::MatchResult result = table.matchId(ifs);
      if (result.id == -1) {
        throw TGenericException(T_SRCANDLINE,
                                "outputScriptContent()",
                                string("At file offset ")
                                  + TStringConversion::intToString(
                                      ifs.tell(),
                                      TStringConversion::baseHex)
                                  + ": could not match character from table");
      }
      
      int id = result.id;
      string resultStr = table.getEntry(result.id);
      bool isOp = true;
      
      if (isOp) {
        bool shared = isSharedOp(id);
        
        std::ostringstream* targetOss = NULL;
        if (shared) {
          targetOss = &oss_final;
          
          // empty comment line buffer
          if (oss_textline.str().size() > 0) {
            oss_final << "// " << oss_textline.str();
            oss_final << std::endl << std::endl;
            oss_textline.str("");
            atLineStart = true;
          }
            
          // if the final op of the text sequence was a linebreak,
          // output an additional linebreak so the content that follows
          // will not be flush with the commented line
          if (atLineStart && lastWasBr) {
            oss_final << std::endl;
//            oss_final << table.getEntry(op_br);
//            oss_final << std::endl;
            atLineStart = true;
          }
        }
        else {
          targetOss = &oss_textline;
        }
        
        //===========================================
        // output pre-linebreaks
        //===========================================
        
        int numPreLines = numOpPreLines(id);
        if ((!atLineStart || (atLineStart && lastWasBr))
            && (numPreLines > 0)) {
          if (oss_textline.str().size() > 0) {
            oss_final << "// " << oss_textline.str();
            oss_textline.str("");
          }
          
          for (int i = 0; i < numPreLines; i++) {
            oss_final << std::endl;
          }

          atLineStart = true;
        }
        
        //===========================================
        // if op is shared, output it directly to
        // the final text on its own line, separate
        // from the commented-out original
        //===========================================
        
        // non-shared op: add to commented-out original line
        *targetOss << resultStr;
//        if (shared)
          atLineStart = false;
        
        //===========================================
        // output param words
        //===========================================
        
        int numParamWords = numOpParamWords(id);
        for (int i = 0; i < numParamWords; i++) {
//          *targetOss << as4bHex(ifs.readu16be());
          *targetOss << as2bHex(ifs.readu8());
          atLineStart = false;
        }
        
        //===========================================
        // output post-linebreaks
        //===========================================
       
        int numPostLines = numOpPostLines(id);
        if (numPostLines > 0) {
          if (oss_textline.str().size() > 0) {
            oss_final << "// " << oss_textline.str();
            oss_textline.str("");
          }
         
          for (int i = 0; i < numPostLines; i++) {
            oss_final << std::endl;
          }

          atLineStart = true;
        }
      }
      else {
       // not an op: add to commented-out original line
        oss_textline << resultStr;
        
        atLineStart = false;
      }
      
      // check for terminators
      if (isTerminator(id)) break;
      
      lastWasBr = (id == op_br);
    }
    
    ofs << oss_final.str();
    
    ofs << "#ENDSCRIPT()" << std::endl << std::endl;
  }
  
  void outputScript(TStream& ifs, ostream& ofs) {
//    addComment(ofs,
//               string("Region ") + TStringConversion::intToString(regionNum));
  
    ofs << "#STARTREGION(" << regionNum
      << ", "
      << TStringConversion::intToString(pointerTableOffset,
                                        TStringConversion::baseHex)
      << ")" << endl << endl;
    
    for (PointerToIndexListMap::iterator it = pointerToIndexListMap.begin();
         it != pointerToIndexListMap.end();
         ++it) {
//      std::vector<int> indexList = it->first;
      int rawPointer = it->first;
      
      ifs.seek(rawPointer - pointerBaseOffset + sectionBaseOffset);
      outputScriptContent(ifs, ofs, rawPointer, it->second);
    }
    
    ofs << "#ENDREGION(" << regionNum << ")" << endl << endl;
  }
};

const static int scriptPageBaseOffset = 0x16000;
//const static int pointerTable0Offset = 0x2E3;
//const static int pointerTable1Offset = 0x4B1;
//const static int pointerTable2Offset = 0x58B;
//const static int pointerTable3Offset = 0x45D;

int main(int argc, char* argv[]) {
  if (argc < 2) {
    cout << "Madou Monogatari I (PC-Engine CD) script dumper" << endl;
    cout << "Usage: " << argv[0] << " [outprefix]" << endl;
    return 0;
  }
  
  string outprefix = string(argv[1]);
  
  TBufStream ifs;
  ifs.open("base/dungeon_12B1.bin");
  
  table.readSjis("table/madou1pce_ops.tbl");
  
  RegionInfo region0Info(0, 0x18000, 0x8000);
  RegionInfo region1Info(1, 0x18000, 0x8000);
  RegionInfo region2Info(2, 0x1C000, 0x8000);
  RegionInfo region3Info(3, 0x18000, 0x8000);
  RegionInfo region4Info(4, 0x18000, 0x8000);
  RegionInfo region5Info(5, 0x18000, 0x8000);
  RegionInfo region6Info(6, 0x18000, 0x8000);
  RegionInfo region7Info(7, 0x18000, 0x8000);
  RegionInfo region8Info(8, 0x18000, 0x8000);
  RegionInfo region9Info(9, 0x18000, 0x8000);
  RegionInfo region10Info(10, 0x18000, 0x8000);
  RegionInfo region11Info(11, 0x18000, 0x8000);
  RegionInfo region12Info(12, 0x18000, 0x8000);
  RegionInfo region13Info(13, 0x18000, 0x8000);
  RegionInfo region14Info(14, 0x18000, 0x8000);
  RegionInfo region15Info(15, 0x18000, 0x8000);
  RegionInfo region16Info(16, 0x18000, 0x8000);
  RegionInfo region17Info(17, 0x18000, 0x8000);
  RegionInfo region18Info(18, 0x18000, 0x8000);
  RegionInfo region19Info(19, 0x18000, 0x8000);
  RegionInfo region20Info(20, 0x18000, 0x8000);
  RegionInfo region21Info(21, 0x18000, 0x8000);
  
  region0Info.readPointerTable(ifs, scriptPageBaseOffset + 0x2E3, 189);
  region1Info.readPointerTable(ifs, scriptPageBaseOffset + 0x4B1, 109);
  region2Info.readPointerTable(ifs, scriptPageBaseOffset + 0x58B, 148);
  region3Info.readPointerTable(ifs, scriptPageBaseOffset + 0x45D, 42);
  region4Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1365, 5);
  region5Info.readPointerTable(ifs, scriptPageBaseOffset + 0x136F, 17);
  region6Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1391, 17);
  region7Info.readPointerTable(ifs, scriptPageBaseOffset + 0x13B3, 8);
  region8Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1456, 8);
  region9Info.readPointerTable(ifs, scriptPageBaseOffset + 0x14F3, 8);
  region10Info.readPointerTable(ifs, scriptPageBaseOffset + 0x15AB, 8);
  region11Info.readPointerTable(ifs, scriptPageBaseOffset + 0x166D, 16);
  region12Info.readPointerTable(ifs, scriptPageBaseOffset + 0x179F, 4);
  region13Info.readPointerTable(ifs, scriptPageBaseOffset + 0x17E7, 5);
  region14Info.readPointerTable(ifs, scriptPageBaseOffset + 0x17F1, 5);
  region15Info.readPointerTable(ifs, scriptPageBaseOffset + 0x17FB, 68);
  region16Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1AB8, 15);
  region17Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1B75, 16);
  region18Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1CE6, 32);
  region19Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1CCA, 14);
  region20Info.readPointerTable(ifs, scriptPageBaseOffset + 0x1C42, 68);
  region21Info.readPointerTable(ifs, scriptPageBaseOffset + 0x4FB6, 8);
  
  std::ofstream ofs((outprefix + "script.txt").c_str());
  
  addComment(ofs, "General script region 0");
  region0Info.outputScript(ifs, ofs);
  addComment(ofs, "General script region 1");
  region1Info.outputScript(ifs, ofs);
  addComment(ofs, "General script region 2");
  region2Info.outputScript(ifs, ofs);
  addComment(ofs, "Shop messages");
  region3Info.outputScript(ifs, ofs);
  addComment(ofs, "Messages for enemy strength compared to Arle's level");
  region4Info.outputScript(ifs, ofs);
  addComment(ofs, "Enemy HP messages");
  region5Info.outputScript(ifs, ofs);
  addComment(ofs, "Arle HP messages");
  region6Info.outputScript(ifs, ofs);
  addComment(ofs, "Arle MP messages");
  region7Info.outputScript(ifs, ofs);
  addComment(ofs, "Arle HP restoration messages");
  region8Info.outputScript(ifs, ofs);
  addComment(ofs, "Arle MP restoration messages");
  region9Info.outputScript(ifs, ofs);
  addComment(ofs, "Arle HP+MP restoration messages");
  region10Info.outputScript(ifs, ofs);
  addComment(ofs, "Arle damage taken messages");
  region11Info.outputScript(ifs, ofs);
  addComment(ofs, "Random messages for using Megaphone item");
  region12Info.outputScript(ifs, ofs);
  addComment(ofs, "Messages for random effects of Colored Pencils item");
  region13Info.outputScript(ifs, ofs);
  addComment(ofs, "Random colors for Colored Pencils item");
  region14Info.outputScript(ifs, ofs);
  addComment(ofs, "Item names");
  region15Info.outputScript(ifs, ofs);
  addComment(ofs, "Spell names");
  region16Info.outputScript(ifs, ofs);
  addComment(ofs, "Menu labels");
  region17Info.outputScript(ifs, ofs);
  addComment(ofs, "Monster names");
  region18Info.outputScript(ifs, ofs);
  addComment(ofs, "Spell descriptions");
  region19Info.outputScript(ifs, ofs);
  addComment(ofs, "Item descriptions");
  region20Info.outputScript(ifs, ofs);
  addComment(ofs, "Enemy damage taken messages");
  region21Info.outputScript(ifs, ofs);
  
  return 0;
}
