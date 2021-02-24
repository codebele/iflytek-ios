//
//  RecordViewController.swift
//  SpeechEvaluation
//

import UIKit
import Starscream
import Accelerate
import SwiftyXMLParser


class RecordViewController: UIViewController, AVAudioRecorderDelegate {
    
    
    @IBOutlet var recordButton: UIButton!
    
    @IBOutlet var waveFormView: WaveformView!
    
    @IBOutlet var wordLabel: UILabel!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var totalScoreLabel: UILabel!
    @IBOutlet var exceptValueLabel: UILabel!
    @IBOutlet var isRejectedValueLabel: UILabel!
    
    let text = "你好" //Nǐ hǎo
    
    var IFlySpeechEva: IFlySpeechEvaluator!
    var isBeginOfSpeech = Bool()
    var pcmRecorder: IFlyPcmRecorder?
    var praser: ISEResultXmlParser?
    var xmlParser: XMLParserDelegate?
    var iseparams: ISEParams?
    var iFlySpeechSynthesizer: IFlySpeechSynthesizer?
    var offlineiFlySpeechSynthesizer = IFlySpeechSynthesizer()
    
    var IFLY_response_score = String()
    var isSpeechEvaluationOn: Bool?
    var isTTSon: Bool?
    var recordingsList = [URL?](repeating: nil, count: 50)//[URL]()
    var newRecorder: AVAudioRecorder!
    var newPlayer: AVAudioPlayer!
    var soundFileURL: URL!
    var recordedAudio_Base64 = String()
    
    //MARK:- for playing audio on tap score
    var avPlayer:AVPlayer?
    var avPlayerItem:AVPlayerItem?
    
    
    var playStartSound: AVAudioPlayer?
    
    
    
    //Code for WebApi
    var category="read_sentence";
    
    //服务类型   开放评测ise
    var sub="ise";
    
    //语言标记参数 ise下（cn中文，en英文）
    var ent="cn_vip";
    //全维度multi_dimension
    var extra_ability="";
    
    var StatusFirstFrame = 0;
    var StatusContinueFrame = 1;
    var StatusLastFrame = 2;
    // 开始时间
    var dateBegin = Date();
    // 结束时间
    var dateEnd = Date();
    var sdf = Date()
    var audioBufferData = Data()
    
    
    var hostUrl = "http://ise-api-sg.xf-yun.com/v2/ise";//测试地址
    var webapiapiKey = "5fd7d06f479f8d40372d38da5811a1c5";
    var apiSecret = "ac99cb4f72f159737d8f2aabdafa4ce6";
    var appid = "g97cbd43";
    var socket: WebSocket!
    var isConnected = false
    var webChineseText = String()
    var bufferSize = 1280 * 2
    var status = 0
    var stoptimer = 0
    var mainBuffer = [UInt8]()
    var audioFrameCount = Int()
    var displayLink: CADisplayLink?
    
    // engine for getting audio pcm stream
    var engine: AVAudioEngine?
    var mp3buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
     var averagePowerForChannel0: Float = 0
     var averagePowerForChannel1: Float = 0
    let LEVEL_LOWPASS_TRIG:Float32 = 1.80
    
    // this is for testing purposes
    var file = NSMutableData()
    var pcmBase64String = String()
    var audioBuffer = AVAudioPCMBuffer()
    var xmlResult = ISEResult()
    var pcmData = Data()
    var recordedFile: AVAudioFile?
    var url2: URL!
    var recordedFileLocally: AVAudioFile?
    
    
    deinit {
        mp3buf.deallocate()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wordLabel.text = text + " (nihao)"
        waveFormView.isHidden = true
        isTTSon = false
        isSpeechEvaluationOn = false
        
        deleteAllRecordings()
        soundFileURL = nil
        //        recordingsList.removeAll()
        setupRecorder()
        recordButton.addTarget(self, action: #selector(start_Speaking(_:)), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    
    //Start recording
    @objc func start_Speaking(_ sender: UIButton) {
        
        let item = text // nihao
        stackView.isHidden = true
        waveFormView.isHidden = false
//        setIfly(evaluationText: item)
        
        var time = 3000.0
        if text.count == 1{
            time = 1500.0
            
        }else if text.count < 8{
            time = (Double(text.count) / 1.2) * 1500.0
        }else{
            time = ((Double(text.count) / 2.0) * 1000.0)
        }
        self.stoptimer = Int(time / 1000.0)
        
        self.getSignature()
        
        status = 0
//        readDataFromRecorder()
        startRecording()
        displayLink = CADisplayLink(target: self, selector: #selector(updateMeters))
        displayLink!.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        
        
        isSpeechEvaluationOn = true
        print(self.stoptimer)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(self.stoptimer), execute: {
            self.stopRecording()
            self.displayLink!.remove(from: RunLoop.current, forMode: RunLoop.Mode.common)
            self.stackView.isHidden = false
            self.waveFormView.isHidden = true
            
        })
        
    }
    
    
    
   

}

//Websocket connection
extension RecordViewController {
    //generate HMAC signature and establish socket connection
    func getSignature(){
        //Some URL example...
        let url = URL(string: hostUrl)
        
        let date = DateFormatter()
        date.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        date.locale = Locale(identifier: "en_US_POSIX")
        date.timeZone = TimeZone(identifier:"GMT")
        let newDate = date.string(from: Date())
        
        let builder = "host: \(url?.host ?? "")\ndate: \(newDate)\nGET \(url?.path ?? "") HTTP/1.1"
        
        //Create a signature
        let stringToSign = builder
        print("The string to sign is : ", stringToSign)
        if let dataToSign = stringToSign.data(using: .utf8)
        {
            let signingSecret = apiSecret
            if let signingSecretData = signingSecret.data(using: .utf8)
            {
                let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
                let digestBytes = UnsafeMutablePointer<UInt8>.allocate(capacity:digestLength)
                
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), [UInt8](signingSecretData), signingSecretData.count, [UInt8](dataToSign), dataToSign.count, digestBytes)
                
                //base64 output
                let hmacData = Data(bytes: digestBytes, count: digestLength)
                let signature = hmacData.base64EncodedString()
                print("The HMAC signature in base64 is " + signature)
                
                //or HEX output
                let hexString = NSMutableString()
                for i in 0..<digestLength
                {
                    hexString.appendFormat("%02x", digestBytes[i])
                }
                print("The HMAC signature in HEX is", hexString)
                
                let authorization = String(format: "api_key=\"%@\", algorithm=\"%@\", headers=\"%@\", signature=\"%@\"", webapiapiKey, "hmac-sha256", "host date request-line", signature)
                print(authorization)
                
                let authURL = authorization.data(using: .utf8)?.base64EncodedString() ?? ""
                print(authURL)
                
                var components = URLComponents()
                components.scheme = url?.scheme
                components.host = url?.host
                components.path = url!.path
                components.queryItems = [
                    URLQueryItem(name: "authorization", value: authURL),
                    URLQueryItem(name: "date", value: newDate),
                    URLQueryItem(name: "host", value: url?.host)
                ]
                //Set the Signature header
                var request = URLRequest(url: URL(string: (components.url?.absoluteString.replacingOccurrences(of: "http://", with: "ws://"))!)!)
                print(request)
                request.setValue("14", forHTTPHeaderField: "Sec-WebSocket-Version")
                request.timeoutInterval = 5
                socket = WebSocket(request: request)
                socket.delegate = self
                
                socket.disconnect()
                socket.connect()
                
            }
        }
    }
}

//Socket connection delegate functions
extension RecordViewController: WebSocketDelegate, StreamDelegate, XMLParserDelegate{
    
    //Start recording from audioengine
    func startRecording() {
        let format16KHzMono = AVAudioFormat(settings: [AVFormatIDKey: AVAudioCommonFormat.pcmFormatInt16,
                                                       AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                                                       AVEncoderBitRateKey: 16,
                                                       AVNumberOfChannelsKey: 1,
                                                       AVSampleRateKey: 16000] as [String : Any])
        self.mainBuffer.removeAll()
        do{
            try AVAudioSession.sharedInstance().setPreferredSampleRate(16000)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
//            try AVAudioSession.sharedInstance().
            try AVAudioSession.sharedInstance().setActive(true)
//            try AVAudioSession.sharedInstance().s
        }catch{
            print("setting sample rate failed")
        }
        
        Thread(block: {
        
            self.engine = AVAudioEngine()
            let auengine = self.engine
            let input = auengine!.inputNode
            input.volume = 0

            input.installTap(onBus: 0, bufferSize:1280, format:format16KHzMono, block: { [weak self] buffer, when in

                try? self?.recordedFileLocally?.write(from: buffer)
                let bytebuffer = self?.audioBufferToData(audioBuffer: buffer)

                self?.mainBuffer.append(contentsOf: bytebuffer!)
                //  firebase logs
                print("buffer sampleRate: \(buffer.format.sampleRate)")
                print("reading recorder: total count: \(self?.mainBuffer.count) read count: \(bytebuffer?.count)")


                guard let this = self else {
                    return
                }
                this.audioMetering(buffer: buffer)

            })

            auengine!.prepare()

            do {
                try auengine!.start()
            } catch {
                // @TODO: error out
            }
        }).start()
 
    }
    
    //update waveform as user stats recording
    func audioMetering(buffer:AVAudioPCMBuffer) {
                buffer.frameLength = 1600
                let inNumberFrames:UInt = UInt(buffer.frameLength)
                if buffer.format.channelCount > 0 {
                    let samples = (buffer.floatChannelData![0])
                    var avgValue:Float32 = 0
                    vDSP_meamgv(samples,1 , &avgValue, inNumberFrames)
                    var v:Float = -100
                    if avgValue != 0 {
                        v = 20.0 * log10f(avgValue)
                        
                    }
                    print("v: \(v)")
                    self.averagePowerForChannel0 = (self.LEVEL_LOWPASS_TRIG*v) + ((1-self.LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel0)
//                    self.averagePowerForChannel1 = self.averagePowerForChannel0
                }

        
        print("self.averagePowerForChannel0: \(self.averagePowerForChannel0)")
        print("self.averagePowerForChannel1: \(self.averagePowerForChannel1)")
        }
    
    //Convert audio buffer to Data
    func audioBufferToData(audioBuffer: AVAudioPCMBuffer) -> Data {
        let channelCount = 1
        let bufferLength = (audioBuffer.frameCapacity * audioBuffer.format.streamDescription.pointee.mBytesPerFrame)

        let channels = UnsafeBufferPointer(start: audioBuffer.floatChannelData, count: channelCount)
        let data = Data(bytes: channels[0], count: Int(bufferLength))

        return data
    }
   
    //Convert bytes to audio buffer
    func bytesToAudioBuffer(_ buf: [UInt8]) -> AVAudioPCMBuffer {
        // format assumption! make this part of your protocol?
        let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: true)
        let frameLength = UInt32(buf.count) / fmt!.streamDescription.pointee.mBytesPerFrame
        print("bytesToAudioBufferFrameLength: \(frameLength)")
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: fmt!, frameCapacity: frameLength)
        audioBuffer!.frameLength = frameLength

        let dstLeft = audioBuffer?.floatChannelData![0]
        // for stereo
        // let dstRight = audioBuffer.floatChannelData![1]

        buf.withUnsafeBufferPointer {
            let src = UnsafeRawPointer($0.baseAddress!).bindMemory(to: Float.self, capacity: Int(frameLength))
            dstLeft!.initialize(from: src, count: Int(frameLength))
        }

        return audioBuffer!
    }
    
    //convert PCMBuffer to NSData
    func toNSData(PCMBuffer: AVAudioPCMBuffer) -> NSData {
        let channelCount = 1  // given PCMBuffer channel count is 1
        var channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: channelCount)
        var ch0Data = NSData(bytes: channels[0], length:Int(PCMBuffer.frameCapacity * PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))
        return ch0Data
    }

    //End recording
    func stopRecording() {
        
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        
        do {
            var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            url.appendPathComponent("mic.mp3")
            
            file.write(to: url, atomically: true)
            
            print("path: \(url)")
        } catch {
            
        }
    }
   
    //Socket connection events
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        
        
        switch event {
        case .connected(let headers):
            isConnected = true
            websocketDidConnect(client)
            
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            onMessage(client, message: string)
//            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            handleError(error)
        }
    }
    
    //error functions for socket connection
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
    //
    public func websocketDidConnect(_ socket: Starscream.WebSocket) {
        
        print("connected")
        ssb()
        sendData(isRecord: true)
        
    }
    
    
    func ssb(){
        
        var data = [String:Any]()
        data["status"] = 0
        data["data"] = ""
        
        var businessData = [String:Any]()
        businessData["category"] = self.category
        businessData["rstcd"] = "utf8"
        businessData["ise_unite"] = "1"
        businessData["plev"] = "0"
        businessData["cver"] = "1.0"
        businessData["extra_ability"] = self.extra_ability
        businessData["sub"] = self.sub
        businessData["ent"] = self.ent
        businessData["ssb_txt"] = "welcome to iflytek"
        businessData["tte"] = "utf-8"
        businessData["cmd"] = "ssb"
        businessData["ssm"] = "1"
        businessData["auf"] = "audio/L16;rate=16000"
        businessData["aue"] = "raw"
        businessData["text"] = "\u{FEFF}" + "\(self.text)"
        
        
        var finalData = [String:Any]()
        finalData["app_id"] = self.appid
        
        
        var sendfinalData = [String:Any]()
        sendfinalData["common"] = finalData
        sendfinalData["business"] = businessData
        sendfinalData["data"] = data
        
        let jsonData = try! JSONSerialization.data(withJSONObject: sendfinalData, options: [])
        let decoded = String(data: jsonData, encoding: .utf8)!
        print(decoded)
        
        socket.write(string: decoded)
        
    }
    
    func send(websocket:WebSocket, aus: Int, status: Int, data: String){
        print("sending data to socket: aus: \(aus), dataSize: \(data.count)")
        var senddata = [String:Any]()
        senddata["status"] = status
        senddata["data"] = data
        senddata["data_type"] = 1
        senddata["encoding"] = "raw"
        
        var businessData = [String:Any]()
        businessData["cmd"] = "auw"
        businessData["aus"] = aus
        businessData["aue"] = "raw"
        
        
        
        var finalData = [String:Any]()
        finalData["business"] = businessData
        finalData["data"] = senddata
        
        let jsonData = try! JSONSerialization.data(withJSONObject: finalData, options: [])
        let decoded = String(data: jsonData, encoding: .utf8)!
        
        socket.write(string: decoded)
        
    }
    
    func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    
    
    func jsonToString(json: AnyObject){
            do {
                let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
                let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
                print(convertedString) // <-- here is ur string

            } catch let myJSONError {
                print(myJSONError)
            }

        }
    
    func sendData(isRecord: Bool){
        
        Thread(block: {
            let frameSize = self.bufferSize //1280
            
            var read = Int()
            
            var buffer = [UInt8](repeating: 0, count:frameSize)
//                print(buffer.count)
            var i = 0
            var rawData = Data()
            
            end:
            while true{
                let mainArray = self.mainBuffer
                    print("reading mainbuffer: total count: \(mainArray.count)")
                if mainArray.count < (i * self.bufferSize + self.bufferSize){
                        read = 0
                }else{
                    read = self.bufferSize //1280
                    
                }
                //            print(mainArray.count)
                
                
                var k = 0
                print("reading from: \(i * self.bufferSize) to \(i * self.bufferSize + self.bufferSize)")
                while read > 0 && k < self.bufferSize { //1280
                    buffer[k] = mainArray[i * self.bufferSize + k]
                    k += 1
                }

                i += 1
                let bytetobuffer = self.bytesToAudioBuffer(buffer)
                rawData.append(self.toNSData(PCMBuffer: bytetobuffer) as Data)
                
                
                let len = read
//                    let len = currentDataSize
                if len < buffer.count {
//                    if len == 0{
                    self.status = self.StatusLastFrame
                }
                
                switch self.status {
                
                case self.StatusFirstFrame:
                    print("StatusFirstFrame:\(self.status)")
                    self.send(websocket: self.socket, aus: 1, status: 1, data: Data(bytes: buffer, count: self.bufferSize).base64EncodedString())
                    self.status = self.StatusContinueFrame
                    break
                case self.StatusContinueFrame:
                    print("StatusContinueFrame:\(self.status)")
                    self.send(websocket: self.socket, aus: 2, status: 1, data: Data(bytes: buffer, count: self.bufferSize).base64EncodedString())
                    break
                case self.StatusLastFrame:
                    print("StatusLastFrame:\(self.status)")
                    if len <= 0{
                        self.send(websocket: self.socket, aus: 4, status: 2, data: "")
                        break end
                    }else{
                        self.send(websocket: self.socket, aus: 4, status: 2, data: Data(bytes: buffer, count: self.bufferSize).base64EncodedString())
                        break
                    }
                    
                    
                default:
                    break
                }

                    Thread.sleep(forTimeInterval: 0.04)
//
            }
//            self.writeWaveHead(rawData, sampleRate: 16000)
            do{
                let filename = try ARFileManager.shared.createWavFile(using: rawData)
                print(filename)
                if let base64String = try? Data(contentsOf: filename).base64EncodedString() {
                    let recordedAudio = "data:audio/wav;base64,\(base64String)"
                }
            }catch{
                print("error while sending data")
            }
            
        }).start()
        
        
        
        
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    public func onMessage(_ socket: Starscream.WebSocket, message: String){
        print("message received from socket: \(message)")
        let jsonData = convertToDictionary(text: message)
        if let errorcode = jsonData!["code"] as? Int{
            print("String:\(errorcode)")
            if errorcode != 0{
                setUpFileUrl()
                showAlertOnWindow(title: nil, message: "Error Evaluating please try again!", titles: ["Ok"], completionHanlder: nil)
            }
            
        }
        if let base64 = jsonData!["data"] as? NSDictionary{
            if let sendData = base64["data"] as? String{
                print(fetchResults(Data(base64Encoded: sendData)))
                let xmlString = fetchResults(Data(base64Encoded: sendData))
                
                let xml = try! XML.parse(xmlString)
                print(xml.xml_result.read_sentence.rec_paper.read_sentence.attributes["total_score"]!)
                let totalScore = xml.xml_result.read_sentence.rec_paper.read_sentence.attributes["total_score"]
                print("totalScore?.toInt:\(Int(totalScore ?? "0.00"))")
                let intValue = Double(totalScore ?? "0.00")
                
                self.IFLY_response_score = Int(intValue!).toStr ?? "0"
                
                
                totalScoreLabel.text = self.IFLY_response_score
                exceptValueLabel.text = xml.xml_result.read_sentence.rec_paper.read_sentence.attributes["except_info"]
                isRejectedValueLabel.text = xml.xml_result.read_sentence.rec_paper.read_sentence.attributes["is_rejected"]
                
                
                
                
                if let base64String = try? Data(contentsOf: soundFileURL).base64EncodedString() {
                    let recordedAudio = "data:audio/mpeg;base64,\(base64String)"
                    self.recordedAudio_Base64 = recordedAudio
                    setUpFileUrl()
                }
                
                
            }
        }
        
    }
    
    
    func fetchResults(_ result: Data!) -> String {

        let chResult = Data(result)
//        let isUTF8: Bool = IFlySpeechEva.parameter(forKey: IFlySpeechConstant.result_ENCODING()) == "utf-8"
        var strResults: String? = nil
       
            
            // Encodings
            let cfEnc = CFStringEncodings.GB_18030_2000
            let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
            
        let str = String(data: chResult, encoding: .utf8)
            print("-----------------------------------------------------------------------------------------------")
            strResults = str
            print(str!)
            
            print("-----------------------------------------------------------------------------------------------")
        return strResults ?? ""
    }
    
    
}

extension RecordViewController {
    
    @objc func updateMeters() {
//        engine.updateMeters()
        let normalizedValue = pow(10, self.averagePowerForChannel0 / 20)
        
        waveFormView.updateWithLevel(CGFloat(normalizedValue))
    }
    
    func setupRecorder() {
        print("\(#function)")
        
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).wav"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        print("writing to soundfile url: '\(soundFileURL!)'")
        
        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 32000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0
        ]
        
        
        do {
            newRecorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
            newRecorder.delegate = self
            newRecorder.isMeteringEnabled = true
            newRecorder.prepareToRecord()
        } catch {
            newRecorder = nil
            print(error.localizedDescription)
        }
        
    }
    
    func setUpFileUrl(){
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).wav"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        print("writing to soundfile url: '\(soundFileURL!)'")
        
        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
    }
    
    func deleteAllRecordings() {
        print("\(#function)")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory,
                                                            includingPropertiesForKeys: nil,
                                                            options: .skipsHiddenFiles)
            //                let files = try fileManager.contentsOfDirectory(at: documentsDirectory)
            var recordings = files.filter({ (name: URL) -> Bool in
                return name.pathExtension == "wav"
                //                    return name.hasSuffix("m4a")
            })
            for i in 0 ..< recordings.count {
                //                    let path = documentsDirectory.appendPathComponent(recordings[i], inDirectory: true)
                //                    let path = docsDir + "/" + recordings[i]
                //                    print("removing \(path)")
                print("removing \(recordings[i])")
                do {
                    try fileManager.removeItem(at: recordings[i])
                } catch {
                    print("could not remove \(recordings[i])")
                    print(error.localizedDescription)
                }
            }
        } catch {
            print("could not get contents of directory at \(documentsDirectory)")
            print(error.localizedDescription)
        }
    }
}
