//
//  PostCell.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseFirestore

class PostCell: UITableViewCell {
    @IBOutlet var postImageView: UIImageView!
    @IBOutlet weak var postedByLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    var postId : String? = ""
    var likeCount : Int? = 0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func setData(postData: PostData) {
        postId = postData.id
        likeCount = postData.likeCount
        
        postedByLabel.text = postData.postedBy
        descriptionLabel.text = postData.postDescription
        likeCountLabel.text = "\(postData.likeCount)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        creationDateLabel.text = dateFormatter.string(from: postData.creationDate)
        
        // Görsel URL'sini ayarla
        if let url = URL(string: postData.imageUrl) {
            postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
    }
    
    @IBAction func likeButtonClicked(_ sender: Any) {
        
        let firestoreDatabase = Firestore.firestore()
        
        let likeStore = ["like" : (likeCount ?? 0) + 1] as [String : Any]
        firestoreDatabase.collection("Posts").document((postId)!).setData(likeStore, merge: true)
    }
}
