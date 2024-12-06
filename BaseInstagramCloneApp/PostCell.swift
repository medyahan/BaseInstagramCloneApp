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
    @IBOutlet weak var profileImageView: UIImageView!
    
    var postId : String? = ""
    var likeCount : Int? = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupProfileImageView()
        setupDoubleTapGesture()
    }
    
    private func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
    }
    
    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func handleDoubleTap() {
        likePost()
        showHeartAnimation()
    }
    
    private func showHeartAnimation() {
        let heartImageView = UIImageView(image: UIImage(systemName: "heart.fill"))
        heartImageView.tintColor = .systemRed
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        heartImageView.center = postImageView.center
        heartImageView.alpha = 0
        
        addSubview(heartImageView)
        
        UIView.animateKeyframes(withDuration: 0.6, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                heartImageView.alpha = 1
                heartImageView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.4) {
                heartImageView.alpha = 0
                heartImageView.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            }
        }) { _ in
            heartImageView.removeFromSuperview()
        }
    }
    
    func setData(postData: PostData) {
        postId = postData.id
        likeCount = postData.likeCount
        
        postedByLabel.text = postData.postedBy
        descriptionLabel.text = postData.postDescription
        likeCountLabel.text = "\(likeCount ?? 0)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: postData.creationDate)
        
        creationDateLabel.text = formattedDate
        
        // Görsel URL'sini ayarla
        if let url = URL(string: postData.imageUrl) {
            postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
        
        loadProfileImage(email: postData.postedBy)
        observeLikeCount()
    }
    
    private func observeLikeCount() {
        guard let postId = postId else { return }
        
        let firestoreDatabase = Firestore.firestore()
        firestoreDatabase.collection("Posts").document(postId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening for like count: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            self.likeCount = data["likeCount"] as? Int ?? 0
            DispatchQueue.main.async {
                self.likeCountLabel.text = "\(self.likeCount ?? 0)"
            }
        }
    }
    
    private func loadProfileImage(email: String) {
        let firestoreDatabase = Firestore.firestore()
        
        firestoreDatabase.collection("Users").whereField("email", isEqualTo: email).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
                self.profileImageView.image = UIImage(systemName: "person.circle.fill") // Varsayılan görsel
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No user profile found for email: \(email)")
                self.profileImageView.image = UIImage(systemName: "person.circle.fill") // Varsayılan görsel
                return
            }
            
            let data = document.data()
            if let profileImageUrl = data["profileImageUrl"] as? String,
               let url = URL(string: profileImageUrl) {
                self.profileImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle.fill"))
            } else {
                self.profileImageView.image = UIImage(systemName: "person.circle.fill") // Varsayılan görsel
            }
        }
    }
    
    
    
    @IBAction func likeButtonClicked(_ sender: Any) {
        
        likePost()
    }
    
    private func likePost() {
        guard let postId = postId else { return }
        
        let firestoreDatabase = Firestore.firestore()
        likeCount = (likeCount ?? 0) + 1
        
        let likeStore = ["likeCount": likeCount ?? 0]
        firestoreDatabase.collection("Posts").document(postId).setData(likeStore, merge: true) { error in
            if let error = error {
                print("Error liking post: \(error.localizedDescription)")
            } else {
                print("Post liked successfully!")
                DispatchQueue.main.async {
                    self.likeCountLabel.text = "\(self.likeCount ?? 0)"
                }
            }
        }
    }
}
