//
//  ISEParams.swift
//  Shifu
//
//  Created by Codebele 05 on 08/04/20.
//  Copyright © 2020 Codebele 05. All rights reserved.
//

import Foundation

import UIKit


let KCLanguageZHCN = "zh_cn"
let KCLanguageENUS = "en_us"
let KCCategorySentence = "read_sentence"
let KCCategoryWord = "read_word"
let KCCategorySyllable = "read_syllable"
let KCRstLevelPlain = "plain"
let KCRstLevelComplete = "complete"
let KCBOSDefault = "5000"
let KCEOSDefault = "1800"
let KCTimeoutDefault = "-1"
let KCIseDictionaryKey = "ISEParams"
let KCLanguage = "language"
let KCLanguageShow = "languageShow"
let KCCategory = "category"
let KCCategoryShow = "categoryShow"
let KCRstLevel = "rstLevel"
let KCBOS = "bos"
let KCEOS = "eos"
let KCTimeout = "timeout"
let KCSourceType = "audio_source"
let KCSourceMIC = "1"
let KCSourceSTREAM = "-1"

// MARK: -
class ISEParams: NSObject {
    
static let sharedInstance = ISEParams()
    
    var language = ""
    var languageShow = ""
    var category = ""
    var categoryShow = ""
    var rstLevel = ""
    var bos = ""
    var eos = ""
    var timeout = ""
    var audioSource = ""
    
    func toString() -> String? {
        
        var strIseParams = ""
        
        if language.count > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.language())=\(language)")
        }
        
        if category.count  > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.ise_CATEGORY())=\(category)")
        }
        if rstLevel.count > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.ise_RESULT_LEVEL())=\(rstLevel)")
        }
        
        if bos.count > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.vad_BOS())=\(bos)")
        }
        
        if eos.count > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.vad_EOS())=\(eos)")
        }
        
        if timeout.count > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.speech_TIMEOUT())=\(timeout)")
        }
        
        if audioSource.count > 0 {
            strIseParams = strIseParams + (",\(IFlySpeechConstant.audio_SOURCE())=\(audioSource)")
        }
        
        
        return strIseParams
    }
    
    func setDefaultParams(evaText: String) {
        
        language = KCLanguageZHCN
        languageShow = "K_LangCHZN"
        if evaText.contains(" ") {
            category = KCCategorySentence
            print("category: \(category)")
        }else {
        category = KCCategorySyllable
            print("category: \(category)")
        }
        categoryShow = "K_ISE_CateSent"
        rstLevel = KCRstLevelComplete
        bos = KCBOSDefault
        eos = KCEOSDefault
        timeout = KCTimeoutDefault
        audioSource = KCSourceMIC
    }
    
    func fromUserDefaults(checkEvaluationText: String) -> ISEParams? {
        
        let params = ISEParams()
        params.setDefaultParams(evaText: checkEvaluationText)
        let paramsDic = UserDefaults.standard.dictionary(forKey: KCIseDictionaryKey)
        if paramsDic != nil {
            params.language = paramsDic?[KCLanguage] as! String
            params.languageShow = paramsDic?[KCLanguageShow] as! String
            params.category = paramsDic?[KCCategory] as! String
            params.categoryShow = paramsDic?[KCCategoryShow] as! String
            params.rstLevel = paramsDic?[KCRstLevel] as! String
            params.bos = paramsDic?[KCBOS] as! String
            params.eos = paramsDic?[KCEOS] as! String
            params.timeout = paramsDic?[KCTimeout] as! String
            params.audioSource = paramsDic?[KCSourceType] as! String
        }
        return params
    }

    
    func toUserDefaults() {
        
        var paramsDic = [AnyHashable : Any](minimumCapacity: 8)
        if paramsDic != nil {
//            if language {
                paramsDic[KCLanguage] = language
//            }
//            if languageShow {
                paramsDic[KCLanguageShow] = languageShow
//            }
//            if category {
                paramsDic[KCCategory] = category
//            }
//            if categoryShow {
                paramsDic[KCCategoryShow] = categoryShow
//            }
//            if rstLevel {
                paramsDic[KCRstLevel] = rstLevel
//            }
//            if bos {
                paramsDic[KCBOS] = bos
//            }
//            if eos {
                paramsDic[KCEOS] = eos
//            }
//            if timeout {
                paramsDic[KCTimeout] = timeout
//            }
            if audioSource != nil {
                paramsDic[KCSourceType] = audioSource
            }
        }
        UserDefaults.standard.set(paramsDic, forKey: KCIseDictionaryKey)
    }
    
}
