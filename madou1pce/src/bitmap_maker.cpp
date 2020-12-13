#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TIniFile.h"
#include "util/TStringConversion.h"
#include "util/TFreeSpace.h"
#include "util/TFileManip.h"
#include "util/TArray.h"
#include "util/TByte.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TParse.h"
#include "util/TOpt.h"
#include "pce/PcePattern.h"
#include "pce/PcePalette.h"
#include "pce/PceTilemap.h"
#include "smpce/SmPceGraphic.h"
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <cctype>
#include <cstring>

using namespace std;
using namespace BlackT;
using namespace Pce;

// stupid and inefficient, but good enough for what we're doing
typedef vector<int> Blacklist;

std::vector<bool> allowedPalettes;

struct UsedPaletteLineColorSet {
  UsedPaletteLineColorSet() {
    availableColors.resize(PcePaletteLine::numColors);
    for (int i = 0; i < PcePaletteLine::numColors; i++)
      availableColors[i] = false;
  }
  
  int numAvailableIndices() const {
    int count = 0;
    for (int i = 0; i < PcePaletteLine::numColors; i++)
      if (availableColors[i]) ++count;
    return count;
  }
  
  int nextAvailableIndex() const {
    for (int i = 0; i < PcePaletteLine::numColors; i++)
      if (availableColors[i]) return i;
    return -1;
  }
  
  bool getAvailability(int index) const {
    return availableColors.at(index);
  }
  
  void unclaimIndex(int index) {
    if (index == 0) return;
    availableColors[index] = true;
  }
  
  void claimIndex(int index) {
    if (index == 0) return;
    availableColors[index] = false;
  }
  
  std::vector<bool> availableColors;
};

struct PaletteUseInfo {
  PaletteUseInfo() {
    lineInfo.resize(PcePalette::numPaletteLines);
  }
  
  UsedPaletteLineColorSet& getLineInfo(int index) {
    return lineInfo.at(index);
  }
  
  void readSpecifierString(std::string spec) {
    TBufStream ifs;
    ifs.writeString(spec);
    ifs.seek(0);
    while (!ifs.eof()) {
      int lineNum = TParse::matchInt(ifs);
      if (ifs.eof() || !TParse::checkChar(ifs, '/')) {
        // no specifier = enable entire palette
        for (int i = 0; i < PcePaletteLine::numColors; i++) {
          lineInfo[lineNum].unclaimIndex(i);
        }
      }
      else {
        while (TParse::checkChar(ifs, '/')) {
          TParse::matchChar(ifs, '/');
          int first = TParse::matchInt(ifs);
          int second = first;
          
          if (TParse::checkChar(ifs, '-')) {
            TParse::matchChar(ifs, '-');
            second = TParse::matchInt(ifs);
          }
          
          for (int i = first; i <= second; i++) {
            lineInfo[lineNum].unclaimIndex(i);
          }
        }
      }
    }
  }
  
  std::vector<UsedPaletteLineColorSet> lineInfo;
};

PaletteUseInfo paletteUseInfo;

std::map<TColor, bool> getColorsInArea(
    const TGraphic& grp, int x, int y, int w, int h) {
  std::map<TColor, bool> usedColors;
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      TColor color = grp.getPixel(x + i, y + j);
      usedColors[color] = true;
    }
  }
  return usedColors;
}

int readIntString(const string& src, int* pos) {
  string numstr;
  while (*pos < src.size()) {
    // accept "x" for hex
    if (!isalnum(src[*pos]) && !(src[*pos] == 'x')) break;
    else {
      numstr += src[(*pos)++];
    }
  }
  
  if (*pos < src.size()) ++(*pos);
  
  return TStringConversion::stringToInt(numstr);
}

void readBlacklist(Blacklist& blacklist, const string& src) {
  int pos = 0;
  
  while ((pos < src.size())) {
    int next = readIntString(src, &pos);
    
    // check if this is a range
    if ((pos < src.size()) && (src[(pos - 1)] == '-')) {
      int next2 = readIntString(src, &pos);
      for (unsigned int i = next; i <= next2; i++) {
        blacklist.push_back(i);
      }
    }
    else {
      blacklist.push_back(next);
    }
  }
}

bool isBlacklisted(Blacklist blacklist, int value) {
  for (unsigned int i = 0; i < blacklist.size(); i++) {
    if (blacklist[i] == value) return true;
  }
  
  return false;
}

int processTile(const TGraphic& srcG, int x, int y,
                PcePalette& palette,
                bool transparency,
                PceTileId* dstId,
                vector<PcePattern>& rawTiles,
                int forcePaletteLine = -1) {
  int paletteNum = 0;
  PcePattern pattern;
  
  // If palette forcing is on, use the specified palette
  if (forcePaletteLine != -1) {
    paletteNum = forcePaletteLine;
    int result = pattern.fromGraphic(
                   srcG, x, y, &(palette.paletteLines[forcePaletteLine]),
                   transparency);
    if (result != 0) paletteNum = PcePalette::numPaletteLines;
  }
  else {
    // try to find a palette that matches this part of the image
    for ( ; paletteNum < PcePalette::numPaletteLines; paletteNum++) {
      if (!allowedPalettes[paletteNum]) continue;
      int result = pattern.fromGraphic(
                     srcG, x, y, &(palette.paletteLines[paletteNum]),
                     transparency);
      if (result == 0) {
        // ensure none of the colors selected is actually a free color,
        // which may change later
        bool canUse = true;
        for (int j = 0; j < PcePattern::h; j++) {
          for (int i = 0; i < PcePattern::w; i++) {
            int index = pattern.getPixel(i, j);
            if (paletteUseInfo.getLineInfo(paletteNum).getAvailability(index)) {
              canUse = false;
              break;
            }
          }
        }
/*        for (int i = 0; i < PcePaletteLine::numColors; i++) {
          if (paletteUseInfo.getLineInfo(paletteNum).getAvailability(i)) {
            canUse = false;
            break;
          }
        } */
        if (!canUse) continue;
        
        break;
      }
    }
    
    // if no palette matches, try to modify an existing one to include
    // the needed colors
    if (paletteNum >= PcePalette::numPaletteLines) {
      std::map<TColor, bool> usedColors
        = getColorsInArea(srcG, x, y, PcePattern::w, PcePattern::h);
      for (int i = 0; i < PcePalette::numPaletteLines; i++) {
        if (!allowedPalettes[i]) continue;
        
        // init "needs insertion" bool for each used color to true
        for (std::map<TColor, bool>::iterator it = usedColors.begin();
             it != usedColors.end();
             ++it) {
          it->second = true;
        }
      
        UsedPaletteLineColorSet& lineInfo = paletteUseInfo.getLineInfo(i);
        
        int freeColorsNeeded = usedColors.size();
//        cerr << freeColorsNeeded << endl;
        
        // subtract any colors already in this line from the number of free
        // colors needed
        for (std::map<TColor, bool>::iterator it = usedColors.begin();
             it != usedColors.end();
             ++it) {
          int checkIndex = palette.paletteLines[i].matchColor(it->first);
          if (checkIndex != -1) {
            // only check colors not marked as available (i.e. filled slots)
            if (lineInfo.getAvailability(checkIndex) == false) {
              --freeColorsNeeded;
              it->second = false;
            }
          }
        }
        
//        cerr << "x: " << freeColorsNeeded << endl;
        
        
        // check if number of indices remaining in this line is enough to hold
        // all needed colors
        if (lineInfo.numAvailableIndices() < freeColorsNeeded) continue;
        
        // add new colors to line
        for (std::map<TColor, bool>::iterator it = usedColors.begin();
             it != usedColors.end();
             ++it) {
          if (it->second == false) continue;
          
          PceColor pceColor;
          pceColor.setRealColor(it->first);
          
          int nextIndex = lineInfo.nextAvailableIndex();
          
          if (nextIndex == -1) {
            throw TGenericException(T_SRCANDLINE,
                                    "processTile()",
                                    "Impossible palette line condition");
          }
          
          lineInfo.claimIndex(nextIndex);
          palette.paletteLines[i].colors[nextIndex] = pceColor;
        }
        
        // use this line
        paletteNum = i;
        break;
      }
      
      // check for failure
      if (paletteNum < PcePalette::numPaletteLines) {
        int result = pattern.fromGraphic(
                       srcG, x, y, &(palette.paletteLines[paletteNum]),
                       transparency);
        if (result != 0) {
          throw TGenericException(T_SRCANDLINE,
                                  "processTile()",
                                  "Impossible pattern conversion condition");
        }
      }
    }
  }
  
  if (paletteNum >= PcePalette::numPaletteLines) return -1;
  
//  std::cerr << paletteNum << std::endl;
  
  dstId->palette = paletteNum;
  
  // Determine if target graphic matches any existing tile.
  // If so, we don't need to add a new tile.
/*  bool foundMatch = false;
  for (int i = 0; i < rawTiles.size(); i++) {
    if (pattern == rawTiles[i]) {
      dstId->pattern = i;
      
      foundMatch = true;
      break;
    }
  }
  
  // if we found a match, we're done
  if (foundMatch) {
//    cout << dstId->pattern << endl;
    return 0;
  } */
  
  // otherwise, add a new tile
  
  rawTiles.push_back(pattern);
  
  dstId->pattern = rawTiles.size() - 1;
  
  return 0;
}



int main(int argc, char* argv[]) {
  // Input:
  // * output filename for graphics
  //   (tilemaps assumed from input names)
  // * raw graphic(s)
  // * target offset in VRAM of tilemapped data
  // * optional output prefix
  // * palette
  //   (don't think we need this on a per-file basis?)
  
  if (argc < 4) {
    cout << "Sailor Moon (PCECD) bitmap generator" << endl;
    cout << "Usage: " << argv[0] << " <graphic> <palettecmd> <outfile>"
      << " [options]" << endl;
    cout << "Options:" << endl;
    cout << "  -b0    Set value of unknown byte 0" << endl;
    cout << "  -b1    Set value of unknown byte 1" << endl;
    cout << "  -p     Load initial 15-bit palette from specified file"
      << endl;
    cout << "  -a     Blacklist palette command list"
      << endl;
    
    return 0;
  }
  
  std::string graphicName(argv[1]);
  std::string freepalettesStr(argv[2]);
  std::string outfileName(argv[3]);
  
  std::cout << "processing: " << graphicName << std::endl;
  
  allowedPalettes.resize(16);
  for (int i = 0; i < allowedPalettes.size(); i++) allowedPalettes[i] = true;
  
  char* paletteBlacklist = TOpt::getOpt(argc, argv, "-a");
  if (paletteBlacklist != NULL) {
    TBufStream ifs;
    ifs.writeString(std::string(paletteBlacklist));
    ifs.seek(0);
    while (!ifs.eof()) {
      int lineNum = TParse::matchInt(ifs);
      if (ifs.eof() || !TParse::checkChar(ifs, '/')) {
        allowedPalettes[lineNum] = false;
      }
    }
  }
  
  TGraphic grp;
  TPngConversion::RGBAPngToGraphic(graphicName, grp);
  
  int patW = grp.w() / PcePattern::w;
  int patH = grp.h() / PcePattern::h;
  int numTiles = patW * patH;
  
  paletteUseInfo.readSpecifierString(freepalettesStr);
  
  int byte0 = 0x00;
  int byte1 = 0x00;
  PcePalette palette;
  PceTilemap tilemap;
  tilemap.resize(patW, patH);
  vector<PcePattern> tiles;
  
  TOpt::readNumericOpt(argc, argv, "-b0", &byte0);
  TOpt::readNumericOpt(argc, argv, "-b1", &byte1);
  
  SmPceGraphic baseGraphic;
  palette = baseGraphic.palette_;
  
  char* baseGraphicName = TOpt::getOpt(argc, argv, "-p");
  if (baseGraphicName != NULL) {
    TBufStream ifs;
    ifs.open(baseGraphicName);
    baseGraphic.read(ifs);
    palette = baseGraphic.palette_;
  }
  
//  cerr << patW << " " << patH << endl;
  for (int j = 0; j < patH; j++) {
    for (int i = 0; i < patW; i++) {
//  cerr << i << " " << j << endl;
//      std::cerr << "processing tile " << i << ", " << j << endl;
      PceTileId& tileId = tilemap.tileIds.data(i, j);
      int result = processTile(grp,
                  i * PcePattern::w,
                  j * PcePattern::h,
                  palette,
                  false,
                  &tileId,
                  tiles);
      if (result != 0) {
        std::cerr << "Error processing tile: ("
          << i << ", " << j << ")" << endl;
        return 1;
      }
    }
  }
  
  baseGraphic.colorMap_.resize(patW, patH);
  baseGraphic.patterns_.resize(patW, patH);
  baseGraphic.palette_ = palette;
  
  TBufStream test;
  palette.write(test);
//  test.save("debug.bin");
  
  for (int i = 0; i < numTiles; i++) {
    int x = (i % patW);
    int y = (i / patW);
//  cerr << i << " " << x << " " << y << endl;
    
    baseGraphic.patterns_.data(x, y) = tiles[i];
    baseGraphic.colorMap_.data(x, y) = tilemap.tileIds.data(x, y).palette;
  }
  
  TBufStream ofs;
  baseGraphic.write(ofs);
  ofs.save(outfileName.c_str());
//        palette.generatePreviewFile("debug.png");
  
  return 0;
}
