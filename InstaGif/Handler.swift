//
//  Handler.swift
//  InstaGif
//
//  Created by Quintin John Balsdon on 09/09/2020.
//  Copyright © 2020 Quintin Balsdon. All rights reserved.
//

import Foundation
import mobileffmpeg
import Photos
import UIKit

class Handler : EventHandler {
    private func cut(str: String, prefix: String, suffix: String) -> String {
        var result = str.replacingOccurrences(of: prefix, with: "")
        
        if let range = result.range(of: prefix) {
            result.removeSubrange(result.startIndex..<range.lowerBound)
        }
        
        if let range = result.range(of: suffix) {
            result.removeSubrange(range.lowerBound..<result.endIndex)
        }
        
        return result
    }
    
    func downloadData(url: String, fps: Int, scaleW: Int, onComplete: @escaping (String, PHAsset) -> Void, onFail: () -> Void) {
        if !url.contains("https://www.instagram.com/p/") {
            onFail()
            return
        }
        
        let code = cut(str: url, prefix: "https://www.instagram.com/p/", suffix: "/")
                
        let actualURL = "https://www.instagram.com/p/\(code)/?__a=1"
        
        if let url = URL(string: actualURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let res = try JSONDecoder().decode(Response.self, from: data)
                        
                        //self.saveVideo(urlString: res.graphql.shortcodeMedia.videoURL)
                        self.convertURLtoGif(res.graphql.shortcodeMedia.videoURL, fps: fps, scaleW: scaleW, onComplete: onComplete)
                        
                    } catch let error {
                        print(error)
                    }
                }
            }.resume()
        }
    }
    
    func saveVideo(urlString: String) {
        guard let videoUrl = URL(string: urlString) else {
            return
        }
        
        do {
            
            let videoData = try Data(contentsOf: videoUrl)
            
            let fm = FileManager.default
            
            guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Unable to reach the documents folder")
                return
            }
            
            let localUrl = docUrl.appendingPathComponent("test.mp4")
            
            try videoData.write(to: localUrl)
            
            print ("Saved to \(localUrl)")
        } catch  {
            print("could not save data")
        }
    }
    
    func convertURLtoGif(_ urlString: String, fps: Int, scaleW: Int, onComplete: @escaping (String, PHAsset) -> Void) {
        do {
            let data = try Data(contentsOf: URL(string: urlString)!)
            
            let fileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "html5gif.mp4")
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            
            try data.write(to: fileURL, options: [.atomic])
            
            print("Downloaded, starting GIF conversion…")
            
            let outfileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "outfile.gif")
            let outfileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outfileName)
            let _ = MobileFFmpeg.execute("-i \(fileURL.path) -vf fps=\(fps),scale=\(scaleW):-1 \(outfileURL.path)")
            //let _ = MobileFFmpeg.execute("-i \(fileURL.path) fps=20,scale=450:-1 \(outfileURL.path)")
            
            var placeHolder: PHObjectPlaceholder? = nil
            PHPhotoLibrary.shared().performChanges({
                let changeRequest = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: outfileURL)
                placeHolder = changeRequest?.placeholderForCreatedAsset
            }) { (saved, err) in
                if let localIdentifier = placeHolder?.localIdentifier, saved {
                    let fetchOptions = PHFetchOptions()
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
                    if let phAsset = fetchResult.firstObject {
                        DispatchQueue.main.async {
                            onComplete(outfileURL.absoluteString, phAsset)
                        }
                    }
                }
            }
        } catch {
            print("Error was:", error)
        }
    }
    
    func sendTextToWhatsApp(_ fileURL: URL) {
        
        let msg = "I love you and I want to kiss you"
        
        //let urlWhats = " https://wa.me/\(lesley)?text=\(msg)"
        let urlWhats = "whatsapp://send/?text=\(msg)"
        print("FILE URL: \(fileURL)")
        
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                    UIApplication.shared.open(whatsappURL as URL, options: [:], completionHandler: nil)
                } else {
                    print("please install watsapp")
                }
            }
        }
    }
}
