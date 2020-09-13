//
//  ContentView.swift
//  InstaGif
//
//  Created by Quintin John Balsdon on 09/09/2020.
//  Copyright © 2020 Quintin Balsdon. All rights reserved.
//

import SwiftUI
import Photos

protocol EventHandler {
    func downloadData(url: String,
                      fps: Int,
                      scaleW: Int,
                      onComplete: @escaping (String, PHAsset) -> Void,
                      onFail: () -> Void)
}

struct ContentView: View {
    @State var colour = Color.purple
    let textPadding: Int = 15
    @State var userEnteredUrl: String = ""
    
    @State private var isSharePresented: Bool = false
    
    @State private var fpsIndex: Int = 3
    private let fpsOptions = [10,20,30,40,50,60,70,80,90,100,110,120]
    
    @State private var scaleWIndex: Int = 24
    private let scaleWOptions = 100
    
    @State var fileUrl = ""
    @State var loading = false
    @State var asset: PHAsset? = nil
    
    var handler: EventHandler? = nil
    var body: some View {
        VStack{
            Button(action: {
                if let clip = UIPasteboard.general.string {
                    self.userEnteredUrl = clip
                    //self.userEnteredUrl = "https://www.instagram.com/p/CE62r9bDmKi/?igshid=1g9a6norbk4ma"
                    self.download()
                }
            }) {
                Text("Paste and download")
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(colour)
                    .cornerRadius(40)
                    .foregroundColor(.white)
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(colour, lineWidth: 5)
                            .frame(maxWidth: .infinity)
                )
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.top, 20)
            
            if self.loading {
                ActivityIndicator().frame(maxWidth: 100, maxHeight: 100)
                Text("Loading: \(self.userEnteredUrl)")
            }
            
            if !self.fileUrl.isEmpty {
                Button(action: {
                    self.isSharePresented = true
                }) {
                    Text("Share image \(self.sizeOf(self.asset))")
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(colour)
                        .cornerRadius(40)
                        .foregroundColor(.white)
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(colour, lineWidth: 5)
                                .frame(maxWidth: .infinity)
                    )
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
                .sheet(isPresented: $isSharePresented, onDismiss: {
                    print("Dismiss")
                    self.deleteFile(self.asset!)
                    self.userEnteredUrl = ""
                    self.fileUrl = ""
                }, content: {
                    ActivityViewController(activityItems: [URL(string: self.fileUrl)!])
                })
                
                HStack {
                    createImageView(self.asset!)
                    VStack {
                    Button(action:{
                        self.deleteFile(self.asset!)
                    }) {
                        Image(systemName: "trash")
                        .resizable()
                            .frame(
                                maxWidth: 30,
                                maxHeight: 30)
                    }
                        Spacer()
                    }
                }
            }
            Spacer()
            NavigationView {
                Form {
                    Section {
                        Picker(selection: $fpsIndex, label: Text("FPS")) {
                            ForEach(0 ..< fpsOptions.count, id: \.self) {
                                Text("\(self.fpsOptions[$0])")
                            }
                        }
                        Picker(selection: $scaleWIndex, label: Text("Scale")) {
                            ForEach(1 ..< scaleWOptions, id: \.self) {
                                Text("\($0 * 10)")
                            }
                        }
                    }
                }
                .navigationBarTitle("Settings")
            }
        }
    }
    
    func sizeOf(_ phAsset: PHAsset?) -> String {
        guard let asset = phAsset else {
            return "??"
        }
        
        let resources = PHAssetResource.assetResources(for: asset)
        
        var sizeOnDisk: Int64? = 0
        
        if let resource = resources.first {
            let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
            sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
        }
        
        let formatter:ByteCountFormatter = ByteCountFormatter()
        formatter.countStyle = .binary
        if let size = sizeOnDisk {
            return formatter.string(fromByteCount: Int64(size))
        } else {
            return "??"
        }
    }
    
    func download() {
        self.loading = true
        self.handler?.downloadData(url: self.userEnteredUrl, fps: self.fpsOptions[self.fpsIndex], scaleW: self.scaleWIndex * 10, onComplete: { reference, phAsset in
            self.fileUrl = reference
            self.asset = phAsset
            self.loading = false
        }, onFail: {
            self.fileUrl = ""
            self.asset = nil
            self.loading = false
            self.colour = .red
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.colour = .purple
            }
        })
    }
    
    func createImageViewFile(_ fileReference: String) -> AnyView {
        return AnyView(Image(uiImage: UIImage(contentsOfFile: fileReference)!))
    }
    
    func createImageView(_ phAsset: PHAsset) -> AnyView {
        var view = AnyView(Text("Image not found"))
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true // adjust the parameters as you wish

        PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: requestOptions, resultHandler: { (imageData, _, _, _) in
            if let data = imageData {
                let advTimeGif = UIImage.gifImageWithData(data)
                let imageView = UIImageView(image: advTimeGif)
                let wrapper = UIWrapper<UIImageView>(imageView, updater: {_ in })
                view = AnyView(wrapper)
            }
        })
        
        return view
    }

    
    func deleteFile(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { (saved, err) in
            self.fileUrl = ""
            self.asset = nil
            self.loading = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct animatedImage: UIViewRepresentable {
    let animatedUIImage: UIImage
    
    func makeUIView(context: Self.Context) -> UIView {
        let someView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        let someImage = UIImageView(frame: CGRect(x: 20, y: 100, width: 360, height: 180))
        someImage.clipsToBounds = true
        someImage.layer.cornerRadius = 20
        someImage.autoresizesSubviews = true
        someImage.contentMode = UIView.ContentMode.scaleAspectFill
        someImage.image = animatedUIImage
        someView.addSubview(someImage)
        return someView
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<animatedImage>) {
        
    }
}
