//
//  Response.swift
//  InstaGif
//
//  Created by Quintin John Balsdon on 09/09/2020.
//  Copyright © 2020 Quintin Balsdon. All rights reserved.
//

import Foundation

// MARK: - Response
struct Response: Codable {
    let graphql: Graphql
}

// MARK: - Graphql
struct Graphql: Codable {
    let shortcodeMedia: ShortcodeMedia

    enum CodingKeys: String, CodingKey {
        case shortcodeMedia = "shortcode_media"
    }
}

// MARK: - ShortcodeMedia
struct ShortcodeMedia: Codable {
    let videoURL: String
    let isVideo: Bool

    enum CodingKeys: String, CodingKey {
        case videoURL = "video_url"
        case isVideo = "is_video"
    }
}
