//
//  WavFile.swift
//  YiChi


import Foundation

class ARFileManager {

      static let shared = ARFileManager()
      let fileManager = FileManager.default

      var documentDirectoryURL: URL? {
          return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
      }

      func createWavFile(using rawData: Data) throws -> URL {
           //Prepare Wav file header
           let waveHeaderFormate = createWaveHeader(data: rawData) as Data

           //Prepare Final Wav File Data
           let waveFileData = waveHeaderFormate + rawData

           //Store Wav file in document directory.
           return try storeMusicFile(data: waveFileData)
       }

       private func createWaveHeader(data: Data) -> NSData {

            let sampleRate:Int32 = 16000
            let chunkSize:Int32 = 36 + Int32(data.count)
            let subChunkSize:Int32 = 16
            let format:Int16 = 1
            let channels:Int16 = 1
            let bitsPerSample:Int16 = 8
            let byteRate:Int32 = sampleRate * Int32(channels * bitsPerSample / 8)
            let blockAlign: Int16 = channels * bitsPerSample / 8
            let dataSize:Int32 = Int32(data.count)

            let header = NSMutableData()

            header.append([UInt8]("RIFF".utf8), length: 4)
            header.append(intToByteArray(chunkSize), length: 4)

            //WAVE
            header.append([UInt8]("WAVE".utf8), length: 4)

            //FMT
            header.append([UInt8]("fmt ".utf8), length: 4)

            header.append(intToByteArray(subChunkSize), length: 4)
            header.append(shortToByteArray(format), length: 2)
            header.append(shortToByteArray(channels), length: 2)
            header.append(intToByteArray(sampleRate), length: 4)
            header.append(intToByteArray(byteRate), length: 4)
            header.append(shortToByteArray(blockAlign), length: 2)
            header.append(shortToByteArray(bitsPerSample), length: 2)

            header.append([UInt8]("data".utf8), length: 4)
            header.append(intToByteArray(dataSize), length: 4)

            return header
       }

      private func intToByteArray(_ i: Int32) -> [UInt8] {
            return [
              //little endian
              UInt8(truncatingIfNeeded: (i      ) & 0xff),
              UInt8(truncatingIfNeeded: (i >>  8) & 0xff),
              UInt8(truncatingIfNeeded: (i >> 16) & 0xff),
              UInt8(truncatingIfNeeded: (i >> 24) & 0xff)
             ]
       }

       private func shortToByteArray(_ i: Int16) -> [UInt8] {
              return [
                  //little endian
                  UInt8(truncatingIfNeeded: (i      ) & 0xff),
                  UInt8(truncatingIfNeeded: (i >>  8) & 0xff)
              ]
        }

       func storeMusicFile(data: Data) throws -> URL {

            guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                return URL(string: "")!
            }
            // create file url
            let fileurl =  directory.appendingPathComponent("\(Date()).wav")
        // if file exists then write data
            if FileManager.default.fileExists(atPath: fileurl.path) {
                if let fileHandle = FileHandle(forWritingAtPath: fileurl.path) {
                    // seekToEndOfFile, writes data at the last of file(appends not override)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
                else {
                    print("Can't open file to write.")
                }
            }
            else {
                // if file does not exist write data for the first time
                do{
                    try data.write(to: fileurl, options: .atomic)
                }catch {
                    print("Unable to write in new file.")
                }
            }

             return fileurl //Save file's path respected to document directory.
        }
 }
