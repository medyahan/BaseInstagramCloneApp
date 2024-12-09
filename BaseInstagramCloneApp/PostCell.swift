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
import FirebaseAuth

class PostCell: UITableViewCell {
    @IBOutlet var postImageView: UIImageView!
    @IBOutlet weak var postedByLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    
    let firestoreDatabase = Firestore.firestore()
    
    var postId : String? = ""
    var likeCount : Int? = 0
    
    var isLikedByCurrentUser : Bool? = false
    
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
        showHeartAnimation()
        likePost(withDoubleTap: true)
    }
    
    private func showHeartAnimation() {
        let heartImageView = UIImageView(image: UIImage(systemName: "heart.fill"))
        heartImageView.tintColor = .systemRed
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        heartImageView.center = postImageView.center
        heartImageView.alpha = 0
        
        addSubview(heartImageView)
        
        UIView.animateKeyframes(withDuration: 0.8, delay: 0, options: [], animations: {
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
        
        loadProfile(userId: postData.postedBy)
        observeLikeCount()
        checkLikeButton()
    }
    
    private func observeLikeCount() {
        guard let postId = postId else { return }
        
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
    
    private func loadProfile(userId: String) {
        firestoreDatabase.collection("Users").whereField("id", isEqualTo: userId).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No user profile found for email: \(userId)")
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                return
            }
            
            let data = document.data()
            if let profileImageUrl = data["profileImageUrl"] as? String,
               let url = URL(string: profileImageUrl) {
                self.profileImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle.fill"))
            } else {
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
            }
            
            if let username = data["username"] as? String{
                postedByLabel.text = username
            }
        }
    }
    
    private func checkLikeButton() {
        guard let postId = postId, let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let postRef = firestoreDatabase.collection("Posts").document(postId)
        
        postRef.getDocument { document, error in
            if let error = error {
                print("Error fetching post: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Post does not exist.")
                return
            }
            
            let data = document.data() ?? [:]
            let likedBy = data["likedBy"] as? [String] ?? []
            
            DispatchQueue.main.async {
                if likedBy.contains(currentUserId) {
                    self.isLikedByCurrentUser = true
                    self.likeButton.setTitle("Unlike", for: .normal)
                } else {
                    self.isLikedByCurrentUser = false
                    self.likeButton.setTitle("Like", for: .normal)
                }
            }
        }
    }
    
    
    @IBAction func likeButtonClicked(_ sender: Any) {
        likePost(withDoubleTap: false)
    }
    
    private func likePost(withDoubleTap: Bool) {
        guard let postId = postId, let currentUserId = Auth.auth().currentUser?.uid else { return }
        if withDoubleTap == true && isLikedByCurrentUser == true { return }
        
        let postRef = firestoreDatabase.collection("Posts").document(postId)
        
        postRef.getDocument { document, error in
            if let error = error {
                print("Error fetching post: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Post does not exist.")
                return
            }
            
            let data = document.data() ?? [:]
            var likedBy = data["likedBy"] as? [String] ?? []
            var newLikeCount : Int
            
            let isLiked : Bool
            
            if likedBy.contains(currentUserId) {
                
                if let index = likedBy.firstIndex(of: currentUserId) {
                    likedBy.remove(at: index)
                }
                newLikeCount = (data["likeCount"] as? Int ?? 0) - 1
                
                isLiked = false
            }
            else {
                likedBy.append(currentUserId)
                newLikeCount = (data["likeCount"] as? Int ?? 0) + 1
                
                isLiked = true
            }
            
            let postData: [String: Any] = [
                "likeCount": newLikeCount,
                "likedBy": likedBy
            ]
            
            postRef.updateData(postData) { error in
                if let error = error {
                    print("Error updating likes: \(error.localizedDescription)")
                    return
                }
                
                print("Post likes updated successfully!")
                
                if isLiked == true{
                    DispatchQueue.main.async {
                        self.showHeartAnimation()
                    }
                }
                self.checkLikeButton()
            }
        }
    }
    
}
