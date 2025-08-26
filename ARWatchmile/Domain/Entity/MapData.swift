//
//  MapData.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/25/25.
//

import Foundation

// 전체 데이터 구조
struct MapData: Codable {
    let data: MapInnerData
}

struct MapInnerData: Codable {
    let poi: [String: POI]
    let floor: [Floor]
}

// POI 정보
struct POI: Codable {
    let poiNm: String
    let x: Int
    let y: Int
    let pkfSeq: String
    let catSeq: String
}

// 층 정보
struct Floor: Codable {
    let pkfSeq: String
    let pkfNm: String
    let spgSeq: String
    let spgContents: String
    let poi: [String]
    let beacon: [String]
    let route: [Route]
    let routePaths: [RoutePath]
    let anchor: [CloudAnchor]
}

// 경로 점
struct Route: Codable {
    let rotSeq: String
    let x: Int
    let y: Int
}

// 경로 연결
struct RoutePath: Codable {
    let rphSeq: String
    let srcRotSeq: String
    let dscRotSeq: String
}

// 앵커
struct CloudAnchor: Codable {
    let id: String
    let name: String
    let x: Int
    let y: Int
}
