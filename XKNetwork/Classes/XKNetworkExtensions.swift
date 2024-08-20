//
//  XKHandyJSONExtension.swift
//  XKNetworkSwift
//
//  Created by kenneth on 2021/6/11.
//

import UIKit
import XKHandyJson
import Moya
import Alamofire

extension String: HandyJSON {}

extension Int: HandyJSON {}

extension Bool: HandyJSON {}

public extension TargetType {
    
    func request(withParameters paras: [String : Any]?, encoding: ParameterEncoding = URLEncoding.default) -> Task {
        
        return .requestParameters(parameters: paras ?? [:], encoding: encoding)
    }
    
    func handleImages(images: [Data], imageNames: [String], fileNames: [String]) -> [Moya.MultipartFormData] {
        
        var formDatas = [Moya.MultipartFormData]()
        
        for (index, data) in images.enumerated() {
            let imageName = imageNames[index]
            let fileName  = fileNames[index]
            let formData  = MultipartFormData(provider: .data(data), name: imageName, fileName: fileName + ".png", mimeType: "image/png")
            formDatas.append(formData)
        }
        if images.count == 0 {
            let tmpData = "".data(using: .utf8)!
            let formData = MultipartFormData(provider: .data(tmpData), name: "")
            formDatas.append(formData)
        }
        return formDatas
    }
    func handleUploadParametersToFormData(images: [Data], imageNames: [String], fileNames: [String], parameters: [String : Any]) -> Task {
        var formData = handleImages(images: images, imageNames: imageNames, fileNames: fileNames)
        let varPara = NSMutableDictionary(dictionary: parameters) as! [String : Any]
        
        for element in varPara {
            
            let data = String(describing: element.value).data(using: .utf8)!
            
            let tmpFormData = MultipartFormData(provider: .data(data), name: element.key)
            formData.append(tmpFormData)
        }
        return .uploadMultipart(formData)
    }
    func handleUploadVideoParametersToFormData(videos: [Data], keys: [String], videoNames: [String], parameters: [String : Any]) -> Task {
        
        var formDatas = [Moya.MultipartFormData]()
        for (index, data) in videos.enumerated() {
            let imageName = videoNames[index]
            let key       = keys[index]
            let formData  = MultipartFormData(provider: .data(data), name: key, fileName: imageName, mimeType: "video/mp4")
            formDatas.append(formData)
        }
        
        if videos.count == 0 {
            let tmpData = "".data(using: .utf8)!
            let formData = MultipartFormData(provider: .data(tmpData), name: "")
            formDatas.append(formData)
        }
        
        let varPara = NSMutableDictionary(dictionary: parameters) as! [String : Any]
        
        for element in varPara {
            
            let data = String(describing: element.value).data(using: .utf8)!
            
            let tmpFormData = MultipartFormData(provider: .data(data), name: element.key)
            formDatas.append(tmpFormData)
        }
        
        return .uploadMultipart(formDatas)
        
    }
    
}

