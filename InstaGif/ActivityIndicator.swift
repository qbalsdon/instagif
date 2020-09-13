//
//  ActivityIndicator.swift
//  InstaGif
//
//  Created by Quintin John Balsdon on 10/09/2020.
//  Copyright © 2020 Quintin Balsdon. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView()
        view.color = .white
        return view
    }

    func updateUIView(_ uiView: UIActivityIndicatorView,
                      context: Context) {
            uiView.startAnimating()
    }
}


struct UIWrapper<Wrapper : UIView>: UIViewRepresentable {
    typealias Updater = (Wrapper, Context) -> Void

    var makeView: () -> Wrapper
    var update: (Wrapper, Context) -> Void

    init(_ makeView: @escaping @autoclosure () -> Wrapper,
         updater update: @escaping (Wrapper) -> Void) {
        self.makeView = makeView
        self.update = { view, _ in update(view) }
    }

    func makeUIView(context: Context) -> Wrapper {
        makeView()
    }

    func updateUIView(_ view: Wrapper, context: Context) {
        update(view, context)
    }
}
