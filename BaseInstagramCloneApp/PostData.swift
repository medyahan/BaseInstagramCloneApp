//
//  PostData.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import Foundation

struct PostData {
    let imageUrl: String
    let postedBy: String
    let postDescription: String
    let creationDate: Date
    let likeCount: Int
    let id: String
    let likedBy : [String]
}
