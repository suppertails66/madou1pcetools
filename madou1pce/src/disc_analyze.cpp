#include "smpce/SmPceMsgScriptDecmp.h"
#include "smpce/SmPceVarScriptDecmp.h"
#include "smpce/SmPceFileIndex.h"
#include "smpce/SmPceGraphic.h"
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
#include <string>
#include <iostream>
#include <sstream>

using namespace std;
using namespace BlackT;
using namespace Pce;

struct ReferencedFile {
  std::string name;
  SmPceFileIndexEntry indexEntry;
};

std::map<std::string, bool> readExternalFileList(std::istream& ifs) {
  std::map<std::string, bool> result;
  while (ifs.good()) {
    std::string line;
    getline(ifs, line);
    
    if (line.size() <= 0) continue;
    if (line[0] == '#') continue;
    
    bool allSpace = true;
    for (int i = 0; i < line.size(); i++) {
      if (!isspace(line[i])) {
        allSpace = false;
        break;
      }
    }
    if (allSpace) continue;
    
    istringstream iss;
    iss.str(line);
    std::string name;
    iss >> name;
    
    result[name] = false;
  }
  
  return result;
}

int main(int argc, char* argv[]) {
//  TBufStream test(TStringConversion::stringToInt(string(argv[1])));
//  TBufStream test(0x10000000);  // capacity = 256 MB
//  return 0;

/*  {
    TIfstream ifs("files/5859EB.bin", ios_base::binary);
    ifs.seek(4);
    PcePalette palette(5,
                       5, 10, 0,
                       0x03E0,
                       0x7C00,
                       0x001F);
    palette.read(ifs);
    palette.generatePreviewFile("test.png");
  }
  return 0; */
  
/*  {
    TIfstream ifs("files/5186E4.bin", ios_base::binary);
    SmPceGraphic grp;
    grp.read(ifs);
    grp.save("grptest");
  }
  return 0; */
            
  TIfstream ifs("bssm_24.iso", ios_base::binary);
  
  TCsv labelCsv;
  std::map<std::string, std::string> enLabels;
  {
    TIfstream ifs("scriptlabels.txt", ios_base::binary);
    labelCsv.readSjis(ifs);
    for (int i = 0; i < labelCsv.numRows(); i++) {
      enLabels[labelCsv.cell(0, i)] = labelCsv.cell(1, i);
    }
  }
  
  SmPceFileIndex index;
  ifs.seek(0x29000);
  index.read(ifs, 5177);
  
/*  for (int i = 0; i < index.entries.size(); i++) {
    TBufStream scrifs(index.entries[i].getByteSize());
    ifs.seek(index.entries[i].getBytePos());
    scrifs.writeFrom(ifs, index.entries[i].getByteSize());
    scrifs.seek(0);
    string fname = string("files/") + index.entries[i].hash + ".bin";
    scrifs.save(fname.c_str());
  }
  return 0; */
  
  scriptStrings["start.mes"] = false;
  // these files aren't referenced in any script, but they're in the filesystem
  // possibly unused?
  scriptStrings["amiend.mes"] = false;
  scriptStrings["makoend.mes"] = false;
  scriptStrings["reiend.mes"] = false;
  scriptStrings["minend1.mes"] = false;
  scriptStrings["minend2.mes"] = false;
  // there are also some files on the disc that aren't in the filesystem at
  // all, including script files -- see 0x490000 in the ISO for an example
  // of this (appears to be a different version of one of Usagi's scripts?)
  // hopefully these are just unused leftovers
  
  std::ofstream dummy;
  
  std::map<std::string, bool> unusedHashes;
  for (int i = 0; i < index.entries.size(); i++) {
    unusedHashes[index.entries[i].hash] = false;
  }
  
  std::map<std::string, bool> labels;
  
  while (true) {
    
    bool done = true;
    for (std::map<std::string, bool>::iterator it = scriptStrings.begin();
         it != scriptStrings.end();
         ++it) {
      if (!it->second) {
        SmPceFileIndexEntry* indexEntry = index.findEntry(it->first);
        if (indexEntry == NULL) {
          // error in original game: this file does not exist, but is referenced
          // in a playSound op in mako08.mes
          // 
          // this should cause the game to freeze while infinitely searching the
          // file index for a non-existent hash, but by sheer luck, after
          // cycling through the entire address space it finds the memory
          // containing the original computed value of the hash and treats that
          // as the index entry
          // this results in a long pause while the game loads some garbage
          // data from the CD and ultimately ends up producing no sound at all
          if (it->first.compare("se00") == 0) {
          
          }
          // ditto this in mako05.mes
          else if (it->first.compare("j165") == 0) {
          
          }
          else {
            std::cerr << "Unknown file: " << it->first << std::endl;
            done = true;
            break;
          }
        }
        
        it->second = true;
        done = false;
        if (indexEntry != NULL) {
          std::map<std::string, bool>::iterator findIt
            = unusedHashes.find(indexEntry->hash);
          if (findIt != unusedHashes.end()) unusedHashes.erase(findIt);
        }
        
        if (it->first.size() < 4) continue;
        
        std::string basename = it->first.substr(0,
                                          it->first.size() - 4);
        std::string extension = it->first.substr(it->first.size() - 4,
                                          std::string::npos);
        if (extension.compare(".mes") != 0) continue;
        
        TBufStream scrifs(indexEntry->getByteSize());
        ifs.seek(indexEntry->getBytePos());
        scrifs.writeFrom(ifs, indexEntry->getByteSize());
        scrifs.seek(0);
        
        CharacterDictionary dic;
        int numEntries = (scrifs.readu16le() / 2) - 1;
        for (int i = 0; i < numEntries; i++) {
          dic[i] = scrifs.readu16be();
        }
      
//        std::cout << "Message file: " << it->first << std::endl;
//        std::ofstream ofs((std::string("scripts/") + it->first).c_str(),
//                          ios_base::binary);
        std::ostringstream ofs;
        SmPceMsgScriptDecmp(scrifs, ofs, 0, &dic)();
//        SmPceMsgScriptDecmp(scrifs, dummy, 0, &dic)();

        // output message file
//        std::ofstream msgofs((std::string("messages/") + basename
//                               + ".csv").c_str(),
//                             ios_base::binary);
        std::ostringstream msgofs;
        int msgnum = 10;
        for (std::vector<std::string>::iterator it = scriptMessages.begin()
              + msgnum;
             it != scriptMessages.end();
             ++it) {
          
          std::string label;
          std::string output;
          std::string str = prepReadString(*it, label, output);
          
          msgofs << msgnum;// << ",\"";
          {
            msgofs << std::string(",");
            std::map<int, std::string>::iterator findIt
              = msgNumToSoundFile.find(msgnum);
            if (findIt != msgNumToSoundFile.end()) {
              msgofs << std::string("\"") + findIt->second + "\"";
            }
          }
          msgofs << std::string(",\"") + label + "\"";
          msgofs << std::string(",\"") + output + "\"";
          msgofs << std::string(",\"")
            + (!label.empty() ? enLabels[label] : "") + "\"";
          
          msgofs << std::endl;
          
          if (label.size() > 0)
            labels[label] = true;
          
          ++msgnum;
        }
        scriptMessages.clear();
        activeMessage.clear();
        lastScriptString.clear();
        msgNumToSoundFile.clear();
      }
    }
    
    if (done) break;
  }
  
  // unused stuff for future reference...
  // we only have hashes for thes, but the names are highly probable
  // guesses derived from disc ordering/usage
/*  std::map<std::string, bool> unusedLoadedFiles;
  unusedLoadedFiles["e867"] = false;
  unusedLoadedFiles["e901"] = false;
  unusedLoadedFiles["e903a"] = false;
  unusedLoadedFiles["e912"] = false;
  unusedLoadedFiles["e917"] = false;
  unusedLoadedFiles["e917a"] = false;
  unusedLoadedFiles["e918"] = false;
  unusedLoadedFiles["e919"] = false;
  unusedLoadedFiles["e919a"] = false;
  unusedLoadedFiles["e919b"] = false;
  unusedLoadedFiles["e919c"] = false;
  unusedLoadedFiles["e922"] = false;
  unusedLoadedFiles["e926"] = false;
  unusedLoadedFiles["e926a"] = false;
  unusedLoadedFiles["e929"] = false;
  unusedLoadedFiles["e929a"] = false;
  unusedLoadedFiles["e935a"] = false;
  unusedLoadedFiles["e935b"] = false;
  unusedLoadedFiles["e935c"] = false;
  unusedLoadedFiles["e935d"] = false;
  unusedLoadedFiles["e938a"] = false;
  unusedLoadedFiles["e938b"] = false;
  unusedLoadedFiles["e944b"] = false;
  unusedLoadedFiles["e956"] = false;
  unusedLoadedFiles["e957"] = false;
  unusedLoadedFiles["e957a"] = false;
  unusedLoadedFiles["e957b"] = false;
  unusedLoadedFiles["e957c"] = false;
  unusedLoadedFiles["e960"] = false;
  unusedLoadedFiles["e960a"] = false;
  unusedLoadedFiles["e960b"] = false;
  unusedLoadedFiles["e960c"] = false;
  unusedLoadedFiles["e960d"] = false;
  unusedLoadedFiles["e960e"] = false;
  unusedLoadedFiles["e970d"] = false;
  unusedLoadedFiles["e983"] = false;
  unusedLoadedFiles["e983a"] = false;
  unusedLoadedFiles["e983b"] = false;
  unusedLoadedFiles["e995"] = false;
  unusedLoadedFiles["e1012c"] = false; */
  
  std::map<string, bool> unusedBitmapNames;
  {
    std::ifstream ifs("unused_bitmap_names", std::ios_base::binary);
    unusedBitmapNames = readExternalFileList(ifs);
  }
  
  std::map<string, bool> unusedSoundNames;
  {
    std::ifstream ifs("unused_sound_names", std::ios_base::binary);
    unusedSoundNames = readExternalFileList(ifs);
  }
  
  std::map<std::string, bool> allLoadedFiles;
  for (std::map<std::string, bool>::iterator it = loadedFileNames.begin();
       it != loadedFileNames.end();
       ++it) {
    allLoadedFiles[it->first] = it->second;
  }
  for (std::map<std::string, bool>::iterator it = loaded2FileNames.begin();
       it != loaded2FileNames.end();
       ++it) {
    allLoadedFiles[it->first] = it->second;
  }
  for (std::map<std::string, bool>::iterator it = soundFileNames.begin();
       it != soundFileNames.end();
       ++it) {
    allLoadedFiles[it->first] = it->second;
  }
  for (std::map<std::string, bool>::iterator it = scriptStrings.begin();
       it != scriptStrings.end();
       ++it) {
    allLoadedFiles[it->first] = it->second;
  }
/*  for (std::map<std::string, bool>::iterator it = unusedBitmapNames.begin();
       it != unusedBitmapNames.end();
       ++it) {
    allLoadedFiles[it->first] = it->second;
  }
  for (std::map<std::string, bool>::iterator it = unusedSoundNames.begin();
       it != unusedSoundNames.end();
       ++it) {
    allLoadedFiles[it->first] = it->second;
  } */
  
  std::map<int, ReferencedFile> posToFileReference;
  for (int i = 0; i < index.entries.size(); i++) {
    ReferencedFile file;
    file.indexEntry = index.entries[i];
    posToFileReference[index.entries[i].getBytePos()] = file;
  }
  
  for (std::map<std::string, bool>::iterator it = allLoadedFiles.begin();
       it != allLoadedFiles.end();
       ++it) {
//    cout << it->first << endl;
    SmPceFileIndexEntry* indexEntry = index.findEntry(it->first);
    if (indexEntry == NULL) {
      cout << "referenced but nonexistent file: " << it->first << endl;
      continue;
    }
    
    int pos = indexEntry->getBytePos();
//    int size = indexEntry->getByteSize();
    
    posToFileReference[pos].name = it->first;
  }
  
/*  for (std::map<std::string, bool>::iterator it = unusedSoundNames.begin();
       it != unusedSoundNames.end();
       ++it) {
//    std::cerr << it->first << std::endl;
    
    std::cerr << "playSound\n(\n  \"" << it->first << "\"\n)" << endl;
    std::cerr << "func_op1A\n(\n  [\n    pushImmed       $2\n    retVar\n  ]\n)"
      << endl;
  } */
  
  for (std::map<int, ReferencedFile>::iterator it = posToFileReference.begin();
       it != posToFileReference.end();
       ++it) {
    ReferencedFile file = it->second;
    
    cout << std::hex << it->first;
    cout << " " << std::hex << file.indexEntry.getByteSize() << ": ";
    if (!file.name.empty()) {
      cout << " " << file.name;
      cout << ": hash = " << file.indexEntry.hash;
    }
    else {
      cout << " [UNREFERENCED]: hash = " << file.indexEntry.hash;
    }
    
    cout << endl;
    
    int trueSize = file.indexEntry.getByteSize();
    if ((trueSize % 0x800) != 0) trueSize = (((trueSize / 0x800) + 1) * 0x800);
    
    int endPos = it->first + trueSize;
    
    if (posToFileReference.find(endPos) == posToFileReference.end()) {
      cout << "  unused content at: " << std::hex << endPos << endl;
    }
  }
  
  for (std::map<std::string, bool>::iterator it = unusedBitmapNames.begin();
       it != unusedBitmapNames.end();
       ++it) {
    std::cerr << it->first << std::endl;
    
    SmPceFileIndexEntry* indexEntry = index.findEntry(it->first);
    if (indexEntry == NULL) {
//      if (it->first.compare("se00") == 0) {
//        continue;
//      }
      std::cerr << "Unknown file: " << it->first << std::endl;
      continue;
    }
    
    
    TBufStream sndifs(indexEntry->getByteSize());
    ifs.seek(indexEntry->getBytePos());
    sndifs.writeFrom(ifs, indexEntry->getByteSize());
    sndifs.seek(0);
    
    SmPceGraphic grp;
    grp.read(sndifs);
    
    std::string filename = std::string("unused/gfx/") + it->first;
    grp.save(filename.c_str());
  }
  
  for (std::map<std::string, bool>::iterator it = unusedSoundNames.begin();
       it != unusedSoundNames.end();
       ++it) {
    std::cerr << it->first << std::endl;
    
    SmPceFileIndexEntry* indexEntry = index.findEntry(it->first);
    if (indexEntry == NULL) {
      if (it->first.compare("se00") == 0) {
        continue;
      }
      // ditto this in mako05.mes
      else if (it->first.compare("j165") == 0) {
        continue;
      }
      else {
        std::cerr << "Unknown sound file: " << it->first << std::endl;
        continue;
      }
    }
    
    TBufStream sndifs(indexEntry->getByteSize());
    ifs.seek(indexEntry->getBytePos());
    sndifs.writeFrom(ifs, indexEntry->getByteSize());
    sndifs.seek(0x32);
    
    TSoundFile sound;
    sound.setChannels(1);
    sound.setRate(16000);
       
    OKIADPCM_Decoder<OKIADPCM_MSM5205> dec;
    dec.SetSample(0x800);
    dec.SetSSI(0);
    
    while (!sndifs.eof()) {
      unsigned char next = sndifs.get();
      unsigned char nyb1 = (next & 0xF0) >> 4;
      unsigned char nyb2 = (next & 0x0F);
      
      int samp1raw = dec.Decode(nyb1);
      int samp2raw = dec.Decode(nyb2);
      
      double samp1 = (((double)samp1raw / (double)0xFFF) - 0.5) * 2;
      double samp2 = (((double)samp2raw / (double)0xFFF) - 0.5) * 2;
      
      sound.addSample(samp1);
      sound.addSample(samp2);
    }
    
    std::string filename = std::string("unused/sounds/") + it->first + ".wav";
    TOfstream sndofs(filename.c_str(), ios_base::binary);
    sound.exportWav(sndofs);
  }
  
  return 0;
}
