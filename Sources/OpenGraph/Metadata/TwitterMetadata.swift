//
//  TwitterMetadata.swift
//  OpenGraph
//
//  Created by p-x9 on 2021/12/04.
//  Copyright © 2021 Satoshi Takano. All rights reserved.
//

import Foundation

extension SiteMetadata {
    
    typealias twitter = TwitterMetadata
    
    enum TwitterMetadata: String, CaseIterable {
        
        case url = "twitter:url"
        case title = "twitter:title"
        case image = "twitter:image"
        case card = "twitter:card"
        case site = "twitter:site"
        case creator = "twitter:creator"
        
    }
    
}
