#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "madou1pce/Madou1PceScriptReader.h"
#include "madou1pce/Madou1PceLineWrapper.h"
#include "exception/TGenericException.h"
#include <string>
#include <vector>
#include <map>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;


TThingyTable table;


string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHexPrefix(int num) {
  return "$" + as2bHex(num) + "";
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

const static int scriptPageBaseOffset = 0x16000;
//const static int pointerTable0Offset = 0x2E3;
//const static int pointerTable1Offset = 0x4B1;
//const static int pointerTable2Offset = 0x58B;
//const static int pointerTable3Offset = 0x45D;



const static int textCharsStart = 0x40;
const static int textCharsEnd = 0xA0;
const static int textEncodingMax = 0x100;
const static int maxDictionarySymbols = textEncodingMax - textCharsEnd;


typedef std::map<std::string, int> UseCountTable;
//typedef std::map<std::string, double> EfficiencyTable;
typedef std::map<double, std::string> EfficiencyTable;

bool isCompressable(std::string& str) {
  for (int i = 0; i < str.size(); i++) {
    if (str[i] < textCharsStart) return false;
    if (str[i] >= textCharsEnd) return false;
  }
  
  return true;
}

void addStringToUseCountTable(std::string& input,
                        UseCountTable& useCountTable,
                        int minLength, int maxLength) {
  int total = input.size() - minLength;
  if (total <= 0) return;
  
  for (int i = 0; i < total; ) {
    int basePos = i;
    for (int j = minLength; j < maxLength; j++) {
      int length = j;
      if (basePos + length >= input.size()) break;
      
      std::string str = input.substr(basePos, length);
      if (!isCompressable(str)) break;
      
      ++(useCountTable[str]);
    }
    
    // skip literal arguments to ops
    if ((unsigned char)input[i] < textCharsStart) {
      ++i;
      int opSize = numOpParamWords((unsigned char)input[i]);
      i += opSize;
    }
    else {
      ++i;
    }
  }
}

void addRegionsToUseCountTable(Madou1PceScriptReader::RegionToResultMap& input,
                        UseCountTable& useCountTable,
                        int minLength, int maxLength) {
  for (Madou1PceScriptReader::RegionToResultMap::iterator it = input.begin();
       it != input.end();
       ++it) {
    Madou1PceScriptReader::ResultCollection& results = it->second;
    for (Madou1PceScriptReader::ResultCollection::iterator jt = results.begin();
         jt != results.end();
         ++jt) {
//      std::cerr << jt->srcOffset << std::endl;
      addStringToUseCountTable(jt->str, useCountTable,
                               minLength, maxLength);
    }
  }
}

void buildEfficiencyTable(UseCountTable& useCountTable,
                        EfficiencyTable& efficiencyTable) {
  for (UseCountTable::iterator it = useCountTable.begin();
       it != useCountTable.end();
       ++it) {
    std::string str = it->first;
    // penalize by 1 byte (length of the dictionary code)
    double strLen = str.size() - 1;
    double uses = it->second;
//    efficiencyTable[str] = strLen / uses;
    efficiencyTable[strLen / uses] = str;
  }
}

/*TThingyTable* fuck;
void printit(std::string fake) {
  TBufStream temp;
  temp.writeString(fake);
  temp.seek(0);
  std::cout << "\"";
  while (!temp.eof()) {
    std::cout << fuck->getEntry((unsigned char)temp.get());
  }
  std::cout << "\"" << std::endl;
}  */

void applyDictionaryEntry(std::string entry,
                          Madou1PceScriptReader::RegionToResultMap& input,
                          std::string replacement) {
  for (Madou1PceScriptReader::RegionToResultMap::iterator it = input.begin();
       it != input.end();
       ++it) {
    Madou1PceScriptReader::ResultCollection& results = it->second;
    int index = -1;
    for (Madou1PceScriptReader::ResultCollection::iterator jt = results.begin();
         jt != results.end();
         ++jt) {
      ++index;
      
      std::string str = jt->str;
      if (str.size() < entry.size()) continue;
      
      std::string newStr;
      int i;
      for (i = 0; i < str.size() - entry.size(); ) {
//        int basePos = i;
        
        if ((unsigned char)str[i] < textCharsStart) {
//          ++i;
//          i += numOpParamWords((unsigned char)str[i]);
          int numParams = numOpParamWords((unsigned char)str[i]);
          
          newStr += str[i];
          for (int j = 0; j < numParams; j++) {
            newStr += str[i + 1 + j];
          }
          
          ++i;
          i += numParams;
          continue;
        }
        
//        std::cerr << basePos << " " << entry.size() << " " << str.size() << std::endl;
        if (entry.compare(str.substr(i, entry.size())) == 0) {
          newStr += replacement;
          i += entry.size();
        }
        else {
          newStr += str[i];
          ++i;
        }
      }
      
      while (i < str.size()) newStr += str[i++];
      
//      if ((it->first == 0) && (index == 2)) {
//        printit(newStr);
//        char c;
//        std::cin >> c;
//      }
      
      jt->str = newStr;
    }
  }
}
                      

void binToDcb(TStream& ifs, std::ostream& ofs) {
  int constsPerLine = 16;
  
  while (true) {
    if (ifs.eof()) break;
    
    ofs << "  .db ";
    
    for (int i = 0; i < constsPerLine; i++) {
      if (ifs.eof()) break;
      
      TByte next = ifs.get();
      ofs << as2bHexPrefix(next);
      if (!ifs.eof() && (i != constsPerLine - 1)) ofs << ",";
    }
    
    ofs << std::endl;
  }
}

void packStringTable(Madou1PceScriptReader::ResultCollection& strings,
                     int regionNum,
                     std::string outPrefix) {
  // output:
  // - an include file with dcb conversion of strings + labels
  // - an include file with generated pointer table
  
  std::string labelPrefix = std::string("strings_region")
    + TStringConversion::intToString(regionNum)
    + "_";
  std::string outBinName
    = outPrefix
      + "strings_region"
      + TStringConversion::intToString(regionNum)
      + "_bin.inc";
  std::string outTableName
    = outPrefix
      + "strings_region"
      + TStringConversion::intToString(regionNum)
      + "_table.inc";
  
//  std::map<int, std::vector<int> > rawIndexToOutputOffsets;
  std::map<int, int> outputOffsetToRawIndex;
  
  // binary
  {
    std::ofstream ofs(outBinName.c_str(),
                      std::ios_base::trunc);
//    ofs << ".section \"Script strings, region" << 
//      regionNum
//      << "\" free" << std::endl;
    {
      int indexNum = 0;
      for (Madou1PceScriptReader::ResultCollection::iterator it = strings.begin();
           it != strings.end();
           ++it) {
        ofs << ".section \"Script strings, region" << 
          regionNum
          << ", string "
          << indexNum
          << "\" free" << std::endl;
          
        ofs << "  " << labelPrefix << indexNum << ":" << std::endl;
        
        TBufStream ifs;
        ifs.writeString(it->str);
        ifs.seek(0);
        binToDcb(ifs, ofs);
        
        ofs << "  .define " << labelPrefix << indexNum << "_size "
          << it->str.size() << std::endl;
        
        for (int i = 0; i < it->indices.size(); i++) {
//          rawIndexToOutputOffsets[indexNum].push_back(it->indices[i]);
          outputOffsetToRawIndex[it->indices[i]] = indexNum;
        }
        
        ++indexNum;
        ofs << ".ends" << std::endl << std::endl;
      }
    }
//    ofs << ".ends" << std::endl << std::endl;
  }
  
  // table
  {
    std::ofstream ofs(outTableName.c_str(),
                      std::ios_base::trunc);
    ofs << ".section \"Script string table, region" << 
      regionNum
      << "\" overwrite" << std::endl;
    {
      // low byte
      for (std::map<int, int>::iterator it = outputOffsetToRawIndex.begin();
           it != outputOffsetToRawIndex.end();
           ++it) {
        ofs << "  .db <" << labelPrefix << it->second << std::endl;
      }
      
      // high byte
      for (std::map<int, int>::iterator it = outputOffsetToRawIndex.begin();
           it != outputOffsetToRawIndex.end();
           ++it) {
        ofs << "  .db >" << labelPrefix << it->second << std::endl;
      }
    }
    ofs << ".ends" << std::endl << std::endl;
  }
}



int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Madou Monogatari I (PC-Engine CD) script builder" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [outprefix]" << endl;
    return 0;
  }
  
  string inPrefix = string(argv[1]);
  string outPrefix = string(argv[2]);
  
  TThingyTable table;
  table.readSjis("table/madou1pce_en.tbl");
//  fuck = &table;
  
  // wrap script
  {
    // read size table
    Madou1PceLineWrapper::CharSizeTable sizeTable;
    {
      TBufStream ifs;
      ifs.open("out/font/fontwidth.bin");
      int pos = 0;
      while (!ifs.eof()) {
        sizeTable[textCharsStart + (pos++)] = ifs.readu8();
      }
    }
    
    {
      TBufStream ifs;
      ifs.open((inPrefix + "script.txt").c_str());
      
      TLineWrapper::ResultCollection results;
      Madou1PceLineWrapper(ifs, results, table, sizeTable)();
      
      if (results.size() > 0) {
        TOfstream ofs((outPrefix + "script_wrapped.txt").c_str());
        for (int i = 0; i < results.size(); i++) {
          ofs.write(results[i].str.c_str(), results[i].str.size());
        }
      }
    }
  }
  
  Madou1PceScriptReader::RegionToResultMap results;
  {
    TBufStream ifs;
//    ifs.open((inPrefix + "script.txt").c_str());
    ifs.open((outPrefix + "script_wrapped.txt").c_str());
    Madou1PceScriptReader(ifs, results, table)();
  }
  
/*  UseCountTable useCountTable;
  addRegionsToUseCountTable(results, useCountTable, 2, 16);
  EfficiencyTable efficiencyTable;
  buildEfficiencyTable(useCountTable, efficiencyTable);
  for (int i = 0; i < maxDictionarySymbols; i++) {
    std::cout << efficiencyTable.begin()->first << std::endl;
    TBufStream temp;
    temp.writeString(efficiencyTable.begin()->second);
    temp.seek(0);
    binToDcb(temp, cout);
    efficiencyTable.erase(efficiencyTable.begin());
  } */
  
  // generate compression dictionary
  {
    TBufStream dictOfs;
    for (int i = 0; i < maxDictionarySymbols; i++) {
      UseCountTable useCountTable;
      addRegionsToUseCountTable(results, useCountTable, 2, 3);
      EfficiencyTable efficiencyTable;
      buildEfficiencyTable(useCountTable, efficiencyTable);
      
  //    std::cout << efficiencyTable.begin()->first << std::endl;
      int symbol = i + textCharsEnd;
      applyDictionaryEntry(efficiencyTable.begin()->second,
                           results,
                           std::string() + (char)symbol);
      
  /*    TBufStream temp;
      temp.writeString(efficiencyTable.begin()->second);
      temp.seek(0);
  //    binToDcb(temp, cout);
      std::cout << "\"";
      while (!temp.eof()) {
        std::cout << table.getEntry(temp.get());
      }
      std::cout << "\"" << std::endl; */
      
      dictOfs.writeString(efficiencyTable.begin()->second);
    }
    
    dictOfs.save((outPrefix + "dictionary.bin").c_str());
  }
  
//  packStringTable(results.at(0), 0, outPrefix + "include/");
  for (Madou1PceScriptReader::RegionToResultMap::iterator it = results.begin();
       it != results.end();
       ++it) {
    int regionNum = it->first;
    
    Madou1PceScriptReader::ResultCollection& strings = it->second;
    packStringTable(strings, regionNum, outPrefix + "include/");
  }

  // credits

  TThingyTable creditsTable;
  creditsTable.readSjis("table/credits_en.tbl");
  Madou1PceScriptReader::RegionToResultMap creditsResults;
  {
    TBufStream ifs;
    ifs.open((inPrefix + "credits.txt").c_str());
    Madou1PceScriptReader(ifs, creditsResults, creditsTable)();
    
    TBufStream ofs;
    ofs.writeString(creditsResults.at(0).at(0).str);
    ofs.save((outPrefix + "credits.bin").c_str());
  }
  
  return 0;
}
