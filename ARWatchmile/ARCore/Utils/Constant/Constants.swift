//
//  Constants.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/11/25.
//

import Foundation

enum Constants {
    /// Google Cloud API Key.
    static let apiKey = "AIzaSyDb0PzlE22LQ6RWMB3cxTc62dfWQPP4Vh4"
    /// User defaults key for storing anchor creation timestamps.
    static let timeDictionaryKey = "TimeStampDictionary"
    /// User defaults key for storing anchor IDs.
    static let anchorIdDictionaryKey = "AnchorIdDictionary"
    /// 3D model object filename.
    static let cloudAnchorName = "cloud_anchor"
    /// Office map image asset name.
    static let officeImage = "VestellaOfficeMap"
}

enum Seconds {
    static let minute: TimeInterval = 60
    static let hour: TimeInterval = 60 * minute
    static let day: TimeInterval = 24 * hour
    static let month: TimeInterval = 30 * day
    static let year: TimeInterval = 12 * month
}
