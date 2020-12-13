#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TIniFile.h"
#include "util/TBufStream.h"
#include "util/TOfstream.h"
#include "util/TIfstream.h"
#include "util/TStringConversion.h"
#include "util/TBitmapFont.h"
#include "pce/PceSpritePattern.h"
#include <iostream>
#include <string>
#include <vector>
#include <cmath>

using namespace std;
using namespace BlackT;
using namespace Pce;

//const int numSubtitlePatternsAvailable = 16;
const int numSubtitlePatternsAvailable = 32;

bool outline = false;

void setPixelIfNotUsed(TGraphic& grp, int x, int y, TColor color) {
  if ((x >= grp.w()) || (x < 0) || (y >= grp.h()) || y < 0) return;
  if (grp.getPixel(x, y).a() == TColor::fullAlphaTransparency) {
    grp.setPixel(x, y, color);
  }
}

void setPixelIfExists(TGraphic& grp, int x, int y, TColor color) {
  if ((x >= grp.w()) || (x < 0) || (y >= grp.h()) || y < 0) return;
  grp.setPixel(x, y, color);
}

void outlinePixelSquare(TGraphic& grp, int i, int j,
                       TColor emptyColor,
                       TColor color,
                       int radius) {
  bool fullTrans = false;
  if (emptyColor.a() == TColor::fullAlphaTransparency) fullTrans = true;
  for (int b = -radius; b <= radius; b++) {
    for (int a = -radius; a <= radius; a++) {
      if ((a == 0) && (b == 0)) continue;
      
      if (fullTrans) {
        if (grp.getPixel(i + a, j + b).a() == TColor::fullAlphaTransparency) {
          setPixelIfExists(grp, i + a, j + b, color);
        }
      }
      else {
        if (grp.getPixel(i + a, j + b) == emptyColor) {
          setPixelIfExists(grp, i + a, j + b, color);
        }
      }
    }
  }
}

void outlinePixelCross(TGraphic& grp, int i, int j,
                       TColor emptyColor,
                       TColor color,
                       int radius) {
  bool fullTrans = false;
  if (emptyColor.a() == TColor::fullAlphaTransparency) fullTrans = true;
  for (int b = -radius; b <= radius; b++) {
    for (int a = -radius; a <= radius; a++) {
      if ((std::abs(a) == radius) && (std::abs(b) == radius)) continue;
      if ((a == 0) && (b == 0)) continue;
      
      if (fullTrans) {
        if (grp.getPixel(i + a, j + b).a() == TColor::fullAlphaTransparency) {
          setPixelIfExists(grp, i + a, j + b, color);
        }
      }
      else {
        if (grp.getPixel(i + a, j + b) == emptyColor) {
          setPixelIfExists(grp, i + a, j + b, color);
        }
      }
    }
  }
  
/*//  setPixelIfNotUsed(grp, i - 2, j - 2, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 2, j - 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 2, j - 0, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 2, j + 1, TColor(0x11, 0x11, 0x11));
//  setPixelIfNotUsed(grp, i - 2, j + 2, TColor(0x11, 0x11, 0x11));
  
  setPixelIfNotUsed(grp, i - 1, j - 2, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 1, j - 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 1, j - 0, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 1, j + 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 1, j + 2, TColor(0x11, 0x11, 0x11));
  
  setPixelIfNotUsed(grp, i - 0, j - 2, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 0, j - 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 0, j - 0, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 0, j + 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i - 0, j + 2, TColor(0x11, 0x11, 0x11));
  
  setPixelIfNotUsed(grp, i + 1, j - 2, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 1, j - 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 1, j - 0, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 1, j + 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 1, j + 2, TColor(0x11, 0x11, 0x11));
  
//  setPixelIfNotUsed(grp, i + 2, j - 2, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 2, j - 1, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 2, j - 0, TColor(0x11, 0x11, 0x11));
  setPixelIfNotUsed(grp, i + 2, j + 1, TColor(0x11, 0x11, 0x11));
//  setPixelIfNotUsed(grp, i + 2, j + 2, TColor(0x11, 0x11, 0x11)); */
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Sprite subtitle image generator" << endl;
    cout << "Usage: " << argv[0] << " <textfile> <outfile>"
      << endl;
    
    return 0;
  }
  
  char* stringfile = argv[1];
  char* outfile = argv[2];
  
  TBitmapFont font;
//  font.load(std::string("font/12px_outline/"));
  font.load(std::string("font/12px/"));
  
  std::vector<std::string> inputs;
  {
    TBufStream ifs;
    ifs.open(stringfile);
    std::string next;
    while (!ifs.eof()) {
      if ((ifs.peek() == '\r')
          || (ifs.peek() == '\n')) {
        inputs.push_back(next);
        next = "";
        while (!ifs.eof()
               && ((ifs.peek() == '\r') || (ifs.peek() == '\n')))
          ifs.get();
        if (ifs.eof()) break;
      }
      
      next += ifs.get();
    }
    
    if (!next.empty()) inputs.push_back(next);
  }
  
  TThingyTable table;
//  table.readSjis("font/12px_outline/table.tbl");
  table.readSjis("font/12px/table.tbl");
  
  std::vector<TGraphic> outputs;
  int outputW = 0;
  int outputH = 0;
  int lineHeight = 0;
  for (unsigned int i = 0; i < inputs.size(); i++) {
    TGraphic grp;
    
    TBufStream ifs;
    ifs.writeString(inputs[i]);
    ifs.seek(0);
    
    font.render(grp, ifs, table);
    
/*    if (outline) {
      TGraphic grpnew(grp.w() + 4, grp.h() + 4);
      grpnew.clearTransparent();
      grpnew.copy(grp,
                  TRect(2, 2, 0, 0));
      grp = grpnew;
    } */
    
    outputs.push_back(grp);
    
    if (grp.w() > outputW) outputW = grp.w();
    outputH += grp.h();
    lineHeight = grp.h();
  }
  
  TGraphic output(outputW, outputH);
  output.clearTransparent();
  for (unsigned int i = 0; i < outputs.size(); i++) {
    TGraphic& grp = outputs[i];
    
    // correct colors
    // grayscale mapping
    // transparent = color 0 (no correction needed)
    // input of pure black = color 1
    // input of pure white = color F (no correction needed)
    for (int j = 0; j < grp.h(); j++) {
      for (int i = 0; i < grp.w(); i++) {
        TColor color = grp.getPixel(i, j);
        if (color == TColor(0, 0, 0, TColor::fullAlphaOpacity)) {
          grp.setPixel(i, j, TColor(0x11, 0x11, 0x11));
        }
        
/*        if (outline) {
//          if (color == TColor(255, 255, 255, TColor::fullAlphaOpacity)) {
//            outlinePixel(grp, i, j);
//          }
          if (color == TColor(255, 255, 255, TColor::fullAlphaOpacity)) {
            outlinePixelCross(grp, i, j,
                              TColor(255, 255, 255, TColor::fullAlphaTransparency),
                              TColor(0x11, 0x11, 0x11),
                              2);
            outlinePixelCross(grp, i, j,
                              TColor(0x11, 0x11, 0x11),
                              TColor(0x33, 0x33, 0x33),
                              1);
          }
        } */
      }
    }
    
    int x = (outputW - grp.w()) / 2;
    int y = (i * lineHeight);
    output.copy(grp,
                TRect(x, y, 0, 0));
    output.regenerateTransparencyModel();
  }
  
/*  int finalOutputPatternH = output.h() / PceSpritePattern::h;
  if ((output.h() % PceSpritePattern::h) != 0) ++finalOutputPatternH;
  int finalOutputPatternW = numSubtitlePatternsAvailable / finalOutputPatternH; */
  int finalOutputPatternW = 16;
  int finalOutputPatternH = 2;
  
  int finalOutputW = finalOutputPatternW * PceSpritePattern::w;
  int finalOutputH = finalOutputPatternH * PceSpritePattern::h;
  
  if ((finalOutputW < output.w())
      || (finalOutputH < output.h())) {
    std::cerr << "Error: text does not fit target dimensions"
      << " (image width is " << output.w() << ", limit is " << finalOutputW
      << ")" << endl;
    return 1;
  }
  
  TGraphic finalOutput(finalOutputW, finalOutputH);
//  finalOutput.clearTransparent();
  finalOutput.clear(TColor(0, 0, 0));
  
  int finalX = (finalOutput.w() - output.w()) / 2;
  int finalY = (finalOutput.h() - output.h()) / 2;
  finalOutput.blit(output,
                   TRect(finalX, finalY, 0, 0));
  
  if (outline) {
//          if (color == TColor(255, 255, 255, TColor::fullAlphaOpacity)) {
//            outlinePixel(grp, i, j);
//          }
    for (int j = 0; j < finalOutput.h(); j++) {
      for (int i = 0; i < finalOutput.w(); i++) {
        TColor color = finalOutput.getPixel(i, j);
        if (color == TColor(255, 255, 255, TColor::fullAlphaOpacity)) {
          outlinePixelCross(finalOutput, i, j,
                            TColor(255, 255, 255, TColor::fullAlphaTransparency),
                            TColor(0x11, 0x11, 0x11),
                            2);
          outlinePixelCross(finalOutput, i, j,
                            TColor(0x11, 0x11, 0x11),
                            TColor(0x33, 0x33, 0x33),
                            1);
/*          outlinePixelSquare(finalOutput, i, j,
                            TColor(255, 255, 255, TColor::fullAlphaTransparency),
                            TColor(0x11, 0x11, 0x11),
                            1); */
        }
      }
    }
  
    for (int j = 0; j < finalOutput.h(); j++) {
      for (int i = 0; i < finalOutput.w(); i++) {
        if ((i % 2) && !(j % 2)) continue;
        if (!(i % 2) && (j % 2)) continue;
        
//        setPixelIfNotUsed(finalOutput, i, j, TColor(0x11, 0x11, 0x11));
      }
    }
  }
  
  TPngConversion::graphicToRGBAPng(std::string(outfile), finalOutput);
  
  return 0;
}
