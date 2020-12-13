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

const static int sectorSize = 0x800;
const static int discCapacity = 0x514C8 * sectorSize;
const static int origNumDiscFiles = 5177; // number of files in original
                                          // game filesystem
const static int freeSpaceBaseSectorNum = 0x4377;
const static int freeSpaceBaseAddr = freeSpaceBaseSectorNum * sectorSize;
const static int freeSpaceSize = discCapacity - freeSpaceBaseAddr;

const static int spritePatternSize = 0x80;

TFreeSpace discSpace;

// original implementation, which expands the main data track.
// turns out this game, in a fit of insanity, plays back some or all
// of its CD audio using direct disc pointers rather than going through
// the track index.
// so expanding the data track throws off all these numbers and sends the
// whole thing to hell.
// fortuitously, the disc actually allocates a full 2 megabytes for each
// cutscene's arcade card data despite only a portion of it being used
// (probably for the exact purpose of being able to precompute the data track
// size and thus the target positions of the audio tracks).
// so the used implementation below just overwrites these on the disc at their
// original locations.
// why is the pc engine such an absurd mess?
/*void addCutscene(TBufStream& dscofs,
                 std::string baseFileName,
                 std::string inprefix,
                 int numFiles,
                 std::string includeNamePrefix,
                 std::ostream& includeOfs) {
  TBufStream ifs;
  ifs.open(baseFileName.c_str());
  ifs.seek(ifs.size());
  
  for (int i = 0; i < numFiles; i++) {
    std::string nameStr = TStringConversion::intToString(i);
    while (nameStr.size() < 2) nameStr = std::string("0") + nameStr;
    
    std::string numStr = nameStr;
    
    nameStr = inprefix + nameStr + ".bin";
    TBufStream subifs;
    subifs.open(nameStr.c_str());
    
    int numPatterns = subifs.readu8();
    int patternDataStart = subifs.tell() + ifs.tell();
    ifs.seekoff(numPatterns * spritePatternSize);
    int attributeDataStart = subifs.tell() + ifs.tell();
//    int subOffset = ifs.tell();
    
    subifs.seek(0);
    ifs.writeFrom(subifs, subifs.size());
    
//    includeOfs << ".define " << includeNamePrefix
//      << "sub" << numStr << "Offset "
//      << subOffset << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "NumPatterns "
      << numPatterns << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "PatternsOffset "
      << patternDataStart << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "AttributesOffset "
      << attributeDataStart << std::endl;
  }
  
  ifs.alignToBoundary(sectorSize);
  
  int outFileSectorSize = ifs.size() / sectorSize;
  int outFileOffset = discSpace.claim(ifs.size());
  
  dscofs.seek(outFileOffset);
  ifs.seek(0);
  dscofs.writeFrom(ifs, ifs.size());
  
  includeOfs << ".define " << includeNamePrefix
    << "dataSectorNum "
    << outFileOffset / sectorSize
    << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorNumLo "
      << ((outFileOffset / sectorSize) & 0xFF)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorNumMid "
      << (((outFileOffset / sectorSize) & 0xFF00) >> 8)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorNumHi "
      << (((outFileOffset / sectorSize) & 0xFF0000) >> 16)
      << std::endl;
  includeOfs << ".define " << includeNamePrefix
    << "dataSectorSize "
    << outFileSectorSize
    << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorSizeLo "
      << ((outFileSectorSize) & 0xFF)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorSizeMid "
      << (((outFileSectorSize) & 0xFF00) >> 8)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorSizeHi "
      << (((outFileSectorSize) & 0xFF0000) >> 16)
      << std::endl;
} */

void writeInclude(int value,
                       std::string name,
                       std::ostream& includeOfs) {
  includeOfs << ".define " << name << " "
    << value << std::endl;
}

void writeInclude24Bit(int value,
                       std::string name,
                       std::ostream& includeOfs) {
  includeOfs << ".define " << name << "Lo "
    << ((value & 0xFF)) << std::endl;
  includeOfs << ".define " << name << "Mid "
    << ((value & 0xFF00) >> 8) << std::endl;
  includeOfs << ".define " << name << "Hi "
    << ((value & 0xFF0000) >> 16) << std::endl;
}

void patchTilemap(TBufStream& dst, int tilemapW,
                  std::string srcName, int srcH,
                  int x, int y) {
  TBufStream src;
  src.open(srcName.c_str());
  
  int srcW = (src.size() / 2) / srcH;
  
  int dstBase = dst.tell();
  for (int j = 0; j < srcH; j++) {
    dst.seek(dstBase + ((y + j) * tilemapW * 2) + (x * 2));
    dst.writeFrom(src, srcW * 2);
  }
}

void addCutscene(TBufStream& dscofs,
                 int slotIndex,
                 std::string baseFileName,
                 std::string inprefix,
                 int numFiles,
                 std::string includeNamePrefix,
                 std::ostream& includeOfs) {
  TBufStream ifs;
  ifs.open(baseFileName.c_str());
  ifs.seek(ifs.size());
  
  for (int i = 0; i < numFiles; i++) {
    std::string nameStr = TStringConversion::intToString(i);
    while (nameStr.size() < 2) nameStr = std::string("0") + nameStr;
    
    std::string numStr = nameStr;
    
    nameStr = inprefix + nameStr + ".bin";
    TBufStream subifs;
    subifs.open(nameStr.c_str());
    
    int numPatterns = subifs.readu8();
    int patternDataStart = subifs.tell() + ifs.tell();
    subifs.seekoff(numPatterns * spritePatternSize);
    int attributeDataStart = subifs.tell() + ifs.tell();
//    int subOffset = ifs.tell();

    int patternDataSize = attributeDataStart - patternDataStart;
    int attributeDataSize = subifs.size() - subifs.tell();
    
    subifs.seek(0);
    ifs.writeFrom(subifs, subifs.size());
    
//    includeOfs << ".define " << includeNamePrefix
//      << "sub" << numStr << "Offset "
//      << subOffset << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "NumPatterns "
      << numPatterns << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "PatternsOffset "
      << patternDataStart << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "AttributesOffset "
      << attributeDataStart << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "PatternsSize "
      << patternDataSize << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "AttributesSize "
      << attributeDataSize << std::endl;
    // jesus fucking christ
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "PatternsOffsetLo "
      << ((patternDataStart & 0xFF)) << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "PatternsOffsetMid "
      << ((patternDataStart & 0xFF00) >> 8) << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "PatternsOffsetHi "
      << ((patternDataStart & 0xFF0000) >> 16) << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "AttributesOffsetLo "
      << ((attributeDataStart & 0xFF)) << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "AttributesOffsetMid "
      << ((attributeDataStart & 0xFF00) >> 8) << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "sub" << numStr << "AttributesOffsetHi "
      << ((attributeDataStart & 0xFF0000) >> 16) << std::endl;
  }
  
  // oops let's hack in some things we need
  
  
  // intro
  if (slotIndex == 0) {
    // title graphics main
/*    {
      TBufStream newifs;
      newifs.open("out/grp/title.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "titleGrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "titleGrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    } */
    {
      ifs.seek(0x1001);
      TBufStream newifs;
      newifs.open("out/grp/title.bin");
      ifs.writeFrom(newifs, newifs.size());
      ifs.seek(ifs.size());
    }
    // title map main
    {
      ifs.seek(0x1);
      TBufStream newifs;
      newifs.open("out/grp/title_background.map");
      ifs.writeFrom(newifs, newifs.size());
      ifs.seek(ifs.size());
    }
    
    // subtitle sprite overlay graphics
    {
      TBufStream newifs;
      newifs.open("out/grp/title_overlay_grp.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "subtitleOverlayGrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "subtitleOverlayGrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    }
  }
  // preboss
  else if (slotIndex == 1) {
    
    // 0
    {
      TBufStream newifs;
      newifs.open("out/cut_patches/preboss_0.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch0GrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "patch0GrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    }
    {
      ifs.seek(0xB001);
      patchTilemap(ifs, 64,
                   "out/cut_patches/preboss_0.map", 3,
                   10, 25);
      ifs.seek(ifs.size());
    }
    {
      ifs.seek(0x1A001);
      TBufStream newifs;
//      newifs.open("out/cut_patches/preboss_0.pal");
      newifs.open("out/pal/preboss_0.pal");
      ifs.writeFrom(newifs, newifs.size());
      ifs.seek(ifs.size());
    }
    
    // 1
    {
      TBufStream newifs;
      newifs.open("out/cut_patches/preboss_1.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch1GrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "patch1GrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    }
    {
      ifs.seek(0xB001);
        TBufStream mapifs;
        mapifs.writeFrom(ifs, 0x1000);
      ifs.seek(ifs.size());
      
      mapifs.seek(0);
      patchTilemap(mapifs, 64,
                   "out/cut_patches/preboss_1.map", 3,
                   10, 25);
      mapifs.seek(0);
//      mapifs.save("debug.bin");
//      std::cerr << std::hex << ifs.tell() << std::endl;
      
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch1MapOffset",
                        includeOfs);
      writeInclude(mapifs.size(), includeNamePrefix + "patch1MapSize",
                   includeOfs);
      ifs.writeFrom(mapifs, mapifs.size());
    }
    
    // 2
    {
      TBufStream newifs;
      newifs.open("out/cut_patches/preboss_2.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch2GrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "patch2GrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    }
    {
      ifs.seek(0x5F001);
        TBufStream mapifs;
        mapifs.writeFrom(ifs, 0x1000);
      ifs.seek(ifs.size());
      
      mapifs.seek(0);
      patchTilemap(mapifs, 64,
                   "out/cut_patches/preboss_2.map", 6,
                   10, 24);
//      patchTilemap(mapifs, 64,
//                   "out/cut_patches/preboss_2.map", 10,
//                   9, 20);
      mapifs.seek(0);
      
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch2MapOffset",
                        includeOfs);
      writeInclude(mapifs.size(), includeNamePrefix + "patch2MapSize",
                   includeOfs);
      ifs.writeFrom(mapifs, mapifs.size());
    }
/*    {
      ifs.seek(0x5F001);
      patchTilemap(ifs, 64,
                   "out/cut_patches/preboss_2.map", 6,
                   10, 24);
      ifs.seek(ifs.size());
    } */
    {
      ifs.seek(0x5BE01);
      TBufStream newifs;
      newifs.open("out/pal/preboss_2.pal");
      ifs.writeFrom(newifs, newifs.size());
      ifs.seek(ifs.size());
    }
    
    // 3
    {
      TBufStream newifs;
      newifs.open("out/cut_patches/preboss_3.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch3GrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "patch3GrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    }
    {
      ifs.seek(0x5F001);
        TBufStream mapifs;
        mapifs.writeFrom(ifs, 0x1000);
      ifs.seek(ifs.size());
      
      mapifs.seek(0);
      patchTilemap(mapifs, 64,
                   "out/cut_patches/preboss_3.map", 10,
                   9, 20);
      mapifs.seek(0);
      
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch3MapOffset",
                        includeOfs);
      writeInclude(mapifs.size(), includeNamePrefix + "patch3MapSize",
                   includeOfs);
      ifs.writeFrom(mapifs, mapifs.size());
    }
  }
  // ending
  else if (slotIndex == 2) {
    // 0
    {
      TBufStream newifs;
      newifs.open("out/cut_patches/ending_0.bin");
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch0GrpOffset",
                        includeOfs);
      writeInclude(newifs.size(), includeNamePrefix + "patch0GrpSize",
                   includeOfs);
      ifs.writeFrom(newifs, newifs.size());
    }
    {
      ifs.seek(0x23801);
        TBufStream mapifs;
        mapifs.writeFrom(ifs, 0x1000);
      ifs.seek(ifs.size());
      
      mapifs.seek(0);
      patchTilemap(mapifs, 64,
                   "out/cut_patches/ending_0.map", 6,
                   13, 24);
      mapifs.seek(0);
      
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "patch0MapOffset",
                        includeOfs);
      writeInclude(mapifs.size(), includeNamePrefix + "patch0MapSize",
                   includeOfs);
      ifs.writeFrom(mapifs, mapifs.size());
    }
    {
      ifs.seek(0x31001);
      TBufStream newifs;
      newifs.open("out/pal/ending_0.pal");
      ifs.writeFrom(newifs, newifs.size());
      ifs.seek(ifs.size());
    }
    
    // credits data
    {
      TBufStream creditsifs;
      creditsifs.open("out/script/credits.bin");
      
      writeInclude24Bit(ifs.tell(), includeNamePrefix + "creditsDataOffset",
                        includeOfs);
      writeInclude(creditsifs.size(), includeNamePrefix + "creditsDataSize",
                   includeOfs);
      ifs.writeFrom(creditsifs, creditsifs.size());
    }
  }
  
  ifs.alignToBoundary(sectorSize);
  
  int outFileSectorSize = ifs.size() / sectorSize;
//  int outFileOffset = discSpace.claim(ifs.size());
  int outFileOffset = (0x121 + (slotIndex * 0x400)) * sectorSize;
  
  dscofs.seek(outFileOffset);
  ifs.seek(0);
  dscofs.writeFrom(ifs, ifs.size());
  
  includeOfs << ".define " << includeNamePrefix
    << "dataSectorNum "
    << outFileOffset / sectorSize
    << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorNumLo "
      << ((outFileOffset / sectorSize) & 0xFF)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorNumMid "
      << (((outFileOffset / sectorSize) & 0xFF00) >> 8)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorNumHi "
      << (((outFileOffset / sectorSize) & 0xFF0000) >> 16)
      << std::endl;
  includeOfs << ".define " << includeNamePrefix
    << "dataSectorSize "
    << outFileSectorSize
    << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorSizeLo "
      << ((outFileSectorSize) & 0xFF)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorSizeMid "
      << (((outFileSectorSize) & 0xFF00) >> 8)
      << std::endl;
    includeOfs << ".define " << includeNamePrefix
      << "dataSectorSizeHi "
      << (((outFileSectorSize) & 0xFF0000) >> 16)
      << std::endl;
}
                 

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I (PCECD) disc prep tool" << endl;
    cout << "Usage: " << argv[0]
      << " <iniso> <outiso> <include_outprefix>" << endl;
    
    return 0;
  }
  
  std::string infileName(argv[1]);
  std::string outfileName(argv[2]);
  std::string includeOutprefix(argv[3]);
  
  // copy old iso
  
  TBufStream dscofs;
  dscofs.open(infileName.c_str());
//  {
//    TBufStream ifs;
//    ifs.open(infileName.c_str());
//    dscofs.writeFrom(ifs, ifs.size());
//  }
  
  discSpace.free(freeSpaceBaseAddr, freeSpaceSize);
  
  //============================================
  // add cutscenes
  //============================================
  
  {
//    TBufStream baseofs;
//    baseofs.open("base/cutscene0_121.bin");
    std::ofstream ofs((includeOutprefix + "cutscenes.inc").c_str());
    addCutscene(dscofs,
                0,
                "base/cutscene0_121.bin", "out/subs_build/intro/",
                16,
                "intro_",
                ofs);
    addCutscene(dscofs,
                1,
                "base/cutscene1_521.bin", "out/subs_build/preboss/",
                56,
                "preboss_",
                ofs);
    addCutscene(dscofs,
                2,
                "base/cutscene2_921.bin", "out/subs_build/ending/",
                10,
                "ending_",
                ofs);
  }
  
  //============================================
  // Write files to disc (allocating to free
  // space any that have not been manually
  // assigned)
  //============================================
  
/*  for (unsigned int i = 0; i < discFileEntries.size(); i++) {
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
  } */
  
  //============================================
  // ensure output ISO size is padded to
  // sector boundary
  //============================================
  
//  int numPadBytes = (sectorSize - (dscofs.size() % sectorSize)) % sectorSize;
//  dscofs.seek(dscofs.size());
//  for (int i = 0; i < numPadBytes; i++) dscofs.put(0x00);
  dscofs.seek(dscofs.size());
  dscofs.alignToBoundary(0x800);
  
  //============================================
  // Save final ISO
  //============================================
  dscofs.save(outfileName.c_str());
  
  return 0;
}
