#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceFileIndex.h"
#include "smpce/SmPceGraphic.h"
#include "smpce/SmPceNameHasher.h"
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
#include "util/TFreeSpace.h"
#include "util/TOpt.h"
#include <string>
#include <vector>
#include <map>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Pce;

const static int discCapacity = 0x10000000; // assume max 256 MB disc
                                            // (original is 211 MB)
const static int origNumDiscFiles = 5177; // number of files in original
                                          // game filesystem
const static int sectorSize = 0x800;
const static int freeSpaceBaseSectorNum = 0xA8;
const static int freeSpaceBaseAddr = freeSpaceBaseSectorNum * sectorSize;
const static int freeSpaceSize = discCapacity - freeSpaceBaseAddr;
const static int filesystemIndexAddress = 0x29000;

bool honorifics = false;

/*
  - read original index to create canonical, inviolable file ordering
    - default source of every file is raw dump from files/%.bin
  - read override script
    - need commands to:
      - replace an indexed file and force it to appear at a certain position
        - target entry can be specified by "name" or [hash]
      - directly place raw, unindexed data at a given position
  - file locations are initially unset; after reading override script,
    resolve them
    - override script will force some files to certain locations --
      respect this
    - do not allocate below 0x29000
*/

struct DiscFileEntry {
  DiscFileEntry()
    : sectorNum(-1) { };
  
  std::string hash;
  int sectorNum;
  int size;
  std::string srcFile;
};

struct UnindexedFileEntry {
  UnindexedFileEntry()
    : address(0) { };
  
  int address;
  TArray<TByte> data;
};

enum FileIdentifierType {
  fileIdentifierName,
  fileIdentifierHash
};

int readInt(std::istream& ifs) {
  string result;
  ifs >> result;
  return TStringConversion::stringToInt(result);
}

std::string readName(std::istream& ifs) {
  string result;
  ifs.get();
  while (ifs.peek() != '"') result += ifs.get();
  ifs.get();
  return result;
}

std::string readHash(std::istream& ifs) {
  string result;
  ifs.get();
  while (ifs.peek() != ']') result += ifs.get();
  ifs.get();
  return result;
}

FileIdentifierType readFileIdentifier(std::istream& ifs,
                               std::string& result) {
  while (isspace(ifs.peek())) ifs.get();
  switch (ifs.peek()) {
  case '"':
    result = readName(ifs);
    return fileIdentifierName;
    break;
  case '[':
    result = readHash(ifs);
    return fileIdentifierHash;
    break;
  default:
    throw TGenericException(T_SRCANDLINE,
                            "readFileIdentifier()",
                            std::string("Unknown file identifier type: ")
                            + (char)ifs.peek());
    break;
  }
}

enum IfBlockStatus {
  if_notInBlock,
  if_inIfBlock,
  if_inElseBlock
};

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "Bishoujo Senshi Sailor Moon (PCE-CD) disc builder" << endl;
    cout << "Usage: " << argv[0]
      << " <origindex> <origfolder> <buildscript> <outfile> [options]" << endl;
    cout << "Options:" << endl;
    cout << "  --honorifics      Enable honorifics" << endl;
    cout << "  --nohonorifics    Disable honorifics (default)" << endl;
    
    return 0;
  }
  
  std::string origIndexName(argv[1]);
  std::string origFolderName(argv[2]);
  std::string buildScriptName(argv[3]);
  std::string outfileName(argv[4]);
  
  if (TOpt::hasFlag(argc, argv, "--honorifics")) {
    honorifics = true;
  }
  else if (TOpt::hasFlag(argc, argv, "--nohonorifics")) {
    honorifics = false;
  }
  
  TBufStream dscofs(discCapacity);
  
  //============================================
  // Read original disc index
  //============================================
  SmPceFileIndex origIndex;
  {
    TIfstream ifs(origIndexName.c_str(), ios_base::binary);
    origIndex.read(ifs, origNumDiscFiles);
  }
  
  //============================================
  // Get file ordering and hashes from original
  // index
  //============================================
  
  std::vector<DiscFileEntry> discFileEntries;
  discFileEntries.resize(origIndex.entries.size());
  
  for (unsigned int i = 0; i < origIndex.entries.size(); i++) {
    const SmPceFileIndexEntry& entry = origIndex.entries[i];
    discFileEntries[i].hash = entry.hash;
    discFileEntries[i].srcFile = origFolderName + entry.hash + ".bin";
  }
  
  //============================================
  // Lay out disc
  //============================================
  
  TFreeSpace discSpace;
  discSpace.free(freeSpaceBaseAddr, freeSpaceSize);
  
  //============================================
  // Read override script
  //============================================
  
//  std::vector<UnindexedFileEntry> unindexedFileEntries;
  
  IfBlockStatus ifBlockStatus = if_notInBlock;
  
  {
    std::ifstream ifs(buildScriptName.c_str());
    
    while (ifs.good()) {
      std::string command;
      ifs >> command;
      
      if (command.empty() || !ifs.good()) break;
      
      // comment
      if (command[0] == '#') {
        
      }
      // directive
      else if (command[0] == '.') {
        command = command.substr(1, std::string::npos);
        if (command.compare("ifHonorifics") == 0) {
          if (ifBlockStatus == if_inIfBlock) {
            throw TGenericException(T_SRCANDLINE,
                                    "main()",
                                    "Error: nested if-honorifics block (if)");
          }
          else if (ifBlockStatus == if_inElseBlock) {
            throw TGenericException(T_SRCANDLINE,
                                    "main()",
                                    "Error: nested if-honorifics block (else)");
          }
          else {
            ifBlockStatus = if_inIfBlock;
          }
        }
        else if (command.compare("else") == 0) {
          if (ifBlockStatus == if_inIfBlock) {
            ifBlockStatus = if_inElseBlock;
          }
          else if (ifBlockStatus == if_inElseBlock) {
            throw TGenericException(T_SRCANDLINE,
                                    "main()",
                                    "Error: nested if-honorifics block (else)");
          }
          else {
            throw TGenericException(T_SRCANDLINE,
                                    "main()",
                                    "Error: else with no if-honorifics block");
          }
        }
        else if (command.compare("endif") == 0) {
          if (ifBlockStatus == if_inIfBlock) {
            ifBlockStatus = if_notInBlock;
          }
          else if (ifBlockStatus == if_inElseBlock) {
            ifBlockStatus = if_notInBlock;
          }
          else {
            throw TGenericException(T_SRCANDLINE,
                                    "main()",
                                    "Error: endif with no preceding block");
          }
        }
        else {
          throw TGenericException(T_SRCANDLINE,
                                 "main()",
                                 std::string("Unknown directive: ")
                                 + command);
        }
      }
      else {
        // skip if in block and condition not met
        if (((ifBlockStatus == if_inIfBlock) && !honorifics)
            || ((ifBlockStatus == if_inElseBlock) && honorifics)) {
          
        }
        else if (command.compare("force") == 0) {
          std::string srcFile;
          readFileIdentifier(ifs, srcFile);
          int address = readInt(ifs);
          
          dscofs.seek(address);
          TBufStream ifs(1);
          ifs.open(srcFile.c_str());
          dscofs.writeFrom(ifs, ifs.size());
        }
        else if (command.compare("setsrc") == 0) {
          std::string id;
          FileIdentifierType idType = readFileIdentifier(ifs, id);
          
          std::string srcFile;
          readFileIdentifier(ifs, srcFile);
          
          std::string hash;
          if (idType == fileIdentifierHash) {
            hash = id;
          }
          else if (idType == fileIdentifierName) {
            hash = SmPceNameHasher::hash(id);
          }
          
          bool success = false;
          for (unsigned int i = 0; i < discFileEntries.size(); i++) {
            DiscFileEntry& entry = discFileEntries[i];
            if (entry.hash.compare(hash) == 0) {
              entry.srcFile = srcFile;
              success = true;
              break;
            }
          }
          
          if (!success) {
            throw TGenericException(T_SRCANDLINE,
                           "main()",
                           std::string("Can't setsrc nonexistent file: ")
                           + id);
          }
        }
        else if (command.compare("replace") == 0) {
          std::string id;
          FileIdentifierType idType = readFileIdentifier(ifs, id);
          
          std::string srcFile;
          readFileIdentifier(ifs, srcFile);
          
          int sectorNum = readInt(ifs);
          
          std::string hash;
          if (idType == fileIdentifierHash) {
            hash = id;
          }
          else if (idType == fileIdentifierName) {
            hash = SmPceNameHasher::hash(id);
          }
          
          bool success = false;
          for (unsigned int i = 0; i < discFileEntries.size(); i++) {
            DiscFileEntry& entry = discFileEntries[i];
            if (entry.hash.compare(hash) == 0) {
              entry.srcFile = srcFile;
              entry.sectorNum = sectorNum;
              success = true;
              break;
            }
          }
          
          if (!success) {
            throw TGenericException(T_SRCANDLINE,
                           "main()",
                           std::string("Can't replace nonexistent file: ")
                           + id);
          }
        }
        else if ((command.compare("insertafter") == 0)
                 || (command.compare("insertbefore") == 0)) {
          bool after = true;
          if ((command.compare("insertbefore") == 0)) after = false;
          
          std::string id;
          FileIdentifierType idType = readFileIdentifier(ifs, id);
          
          std::string srcFile;
          readFileIdentifier(ifs, srcFile);
          
          std::string dstName;
          readFileIdentifier(ifs, dstName);
          
          std::string hash;
          if (idType == fileIdentifierHash) {
            hash = id;
          }
          else if (idType == fileIdentifierName) {
            hash = SmPceNameHasher::hash(id);
          }
          
          DiscFileEntry newEntry;
          newEntry.hash = SmPceNameHasher::hash(dstName);
          newEntry.srcFile = srcFile;
          
          bool success = false;
          for (unsigned int i = 0; i < discFileEntries.size(); i++) {
            DiscFileEntry& entry = discFileEntries[i];
            if (entry.hash.compare(hash) == 0) {
              if (after)
                discFileEntries.insert(discFileEntries.begin() + i + 1, newEntry);
              else
                discFileEntries.insert(discFileEntries.begin() + i, newEntry);
              success = true;
              break;
            }
          }
          
          if (!success) {
            throw TGenericException(T_SRCANDLINE,
                           "main()",
                           std::string("Can't insert after nonexistent file: ")
                           + id);
          }
        }
        else {
          throw TGenericException(T_SRCANDLINE,
                                 "main()",
                                 std::string("Unknown override script command: ")
                                 + command);
        }
      }
      
      // skip remainder of line
      string garbage;
      getline(ifs, garbage);
    }
  }
  
  //============================================
  // Write unindexed files to disc
  //============================================
  
  
  
  //============================================
  // Write files to disc (allocating to free
  // space any that have not been manually
  // assigned)
  //============================================
  
  for (unsigned int i = 0; i < discFileEntries.size(); i++) {
    DiscFileEntry& entry = discFileEntries[i];
    
    TBufStream ifs(1);
    ifs.open(entry.srcFile.c_str());
    entry.size = ifs.size();
    
    if (entry.size == 0) {
      throw TGenericException(T_SRCANDLINE,
                              "main()",
                              entry.hash
                              + ": src file "
                              + entry.srcFile
                              + " does not exist");
    }
    
    // if entry has not been manually assigned a sector, allocate one
    // one from the free space
    if (entry.sectorNum == -1) {
      int numFileSectors = ifs.size() / sectorSize;
      if ((ifs.size() % sectorSize) != 0) ++numFileSectors;
      int totalSize = numFileSectors * sectorSize;
      
      int address = discSpace.claim(totalSize);
      
      if (address == -1) {
        throw TGenericException(T_SRCANDLINE,
                                "main()",
                                entry.srcFile
                                + ": Couldn't claim "
                                + TStringConversion::intToString(totalSize)
                                + " bytes");
      }
      
      if ((address % sectorSize) != 0) {
        throw TGenericException(T_SRCANDLINE,
                                "main()",
                                "Tried to claim space not at sector boundary");
      }
      
      entry.sectorNum = address / sectorSize;
    }
    
    std::cout << TStringConversion::intToString(entry.sectorNum * sectorSize,
                    TStringConversion::baseHex)
      << ": " << entry.srcFile << " -> " << entry.hash << std::endl;
    
    // write to disc buffer
    dscofs.seek(entry.sectorNum * sectorSize);
    dscofs.writeFrom(ifs, ifs.size());
    
    // pad to sector boundary
    int numPadBytes = (sectorSize - (ifs.size() % sectorSize)) % sectorSize;
    for (int i = 0; i < numPadBytes; i++) dscofs.put(0x00);
  }
  
  //============================================
  // Update filesystem index
  //============================================
  
  dscofs.seek(filesystemIndexAddress);
  for (unsigned int i = 0; i < discFileEntries.size(); i++) {
//    std::cerr << std::dec << i << " " << std::hex << dscofs.tell() << " " << (dscofs.tell() - filesystemIndexAddress) % 7 << std::endl;
    DiscFileEntry& entry = discFileEntries[i];
    
    int intHash = TStringConversion::stringToInt(std::string("0x")
      + entry.hash);
    dscofs.writeInt(intHash, 3, EndiannessTypes::big, SignednessTypes::nosign);
    
    dscofs.writeu16be(entry.sectorNum);
    dscofs.writeu16le(entry.size);
  }
  
  //============================================
  // ensure output ISO size is padded to
  // sector boundary
  //============================================
  
  int numPadBytes = (sectorSize - (dscofs.size() % sectorSize)) % sectorSize;
  dscofs.seek(dscofs.size());
  for (int i = 0; i < numPadBytes; i++) dscofs.put(0x00);
  
  //============================================
  // Save final ISO
  //============================================
  dscofs.save(outfileName.c_str());
  
  return 0;
}
