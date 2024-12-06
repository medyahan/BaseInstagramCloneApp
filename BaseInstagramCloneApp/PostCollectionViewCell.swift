//
//  PostCollectionViewCell.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 6.12.2024.
//

import UIKit
import SDWebImage

class PostCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setData(postData: PostData) {
        if let url = URL(string: postData.imageUrl) {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
    }
}
