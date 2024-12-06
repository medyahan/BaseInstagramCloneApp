//
//  ProfileViewController.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    @IBOutlet weak var postCollectionView: UICollectionView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var biographyLabel: UILabel!
    
    private var posts: [PostData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProfileImageView()
        setupCollectionView()
        loadUserProfile()
        fetchUserPosts()
    }
    
    private func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    private func setupCollectionView() {
        postCollectionView.delegate = self
        postCollectionView.dataSource = self
        
        let spacing = 1
        let columnCount = 3
        let size = Int(postCollectionView.frame.width) / columnCount - spacing
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: size, height: size)
        layout.minimumLineSpacing = CGFloat(7)
        layout.minimumInteritemSpacing = CGFloat(spacing)
        postCollectionView.collectionViewLayout = layout
    }
    
    private func loadUserProfile() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        let firestoreDatabase = Firestore.firestore()
        
        firestoreDatabase.collection("Users").whereField("email", isEqualTo: userEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("User profile not found. Using system profile image.")
                self.setDefaultProfile()
                return
            }
            
            let data = document.data()
            let username = data["username"] as? String ?? "No Username"
            let biography = data["biography"] as? String ?? ""
            let profileImageUrl = data["profileImageUrl"] as? String
            
            DispatchQueue.main.async {
                self.usernameLabel.text = username
                self.biographyLabel.text = biography
                
                if let profileImageUrl = profileImageUrl, let url = URL(string: profileImageUrl) {
                    self.profileImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle.fill"))
                } else {
                    print("No profile image URL found. Using system profile image.")
                    self.setDefaultProfile()
                }
            }
        }
    }
    
    private func setDefaultProfile() {
        DispatchQueue.main.async {
            self.profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    
    private func fetchUserPosts() {
        let firestoreDatabase = Firestore.firestore()
        
        if let userEmail = Auth.auth().currentUser?.email {
            firestoreDatabase.collection("Posts").whereField("postedBy", isEqualTo: userEmail).order(by: "creationDate", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error fetching user posts: \(error.localizedDescription)")
                        return
                    }
                    
                    self.posts.removeAll()
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found")
                        return
                    }
                    
                    for document in documents {
                        let data = document.data()
                        if let imageUrl = data["imageUrl"] as? String,
                           let postedBy = data["postedBy"] as? String,
                           let postDescription = data["postDescription"] as? String,
                           let likeCount = data["likeCount"] as? Int,
                           let id = data["id"] as? String,
                           let timestamp = data["creationDate"] as? Timestamp {
                            
                            let creationDate = timestamp.dateValue()
                            let post = PostData(
                                imageUrl: imageUrl,
                                postedBy: postedBy,
                                postDescription: postDescription,
                                creationDate: creationDate,
                                likeCount: likeCount,
                                id: id
                            )
                            
                            self.posts.append(post)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.postCollectionView.reloadData()
                    }
                }
        }
    }
    
    
    @IBAction func logOutButtonClicked(_ sender: Any) {
        logOut()
    }
    
    @IBAction func editButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "toProfileEditVC", sender: nil)
    }
    
    private func logOut() {
        do {
            try Auth.auth().signOut()
            navigateToLogin()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
            showAlert(title: "Error", message: signOutError.localizedDescription)
        }
    }
    
    private func navigateToLogin() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.navigateToLogin()
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = postCollectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionCell", for: indexPath) as! PostCollectionViewCell
        let post = posts[indexPath.row]
        cell.setData(postData: post)
        return cell
    }
    
    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
