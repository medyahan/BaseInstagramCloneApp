//
//  HomeViewController.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var posts: [PostData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        fetchPostData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchPostData()
    }
    
    private func setupTableView()
    {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchPostData() {
        let firestoreDatabase = Firestore.firestore()
        
        // İlk veriyi bir kez çek
        firestoreDatabase.collection("Posts").order(by: "creationDate", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching initial data: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            self.updatePosts(from: snapshot)
        }
        
        // Dinleyiciyi ekle
        firestoreDatabase.collection("Posts").order(by: "creationDate", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error with snapshot listener: \(error.localizedDescription)")
                return
            }
            
            self.updatePosts(from: snapshot)
        }
    }
    
    private func updatePosts(from snapshot: QuerySnapshot?) {
        guard let snapshot = snapshot else { return }
        
        self.posts.removeAll()
        
        for document in snapshot.documents {
            let data = document.data()
            
            if let imageUrl = data["imageUrl"] as? String,
               let postedBy = data["postedBy"] as? String,
               let postDescription = data["postDescription"] as? String,
               let likeCount = data["likeCount"] as? Int,
               let id = data["id"] as? String,
               let timestamp = data["creationDate"] as? Timestamp {
                
                let post = PostData(
                    imageUrl: imageUrl,
                    postedBy: postedBy,
                    postDescription: postDescription,
                    creationDate: timestamp.dateValue(),
                    likeCount: likeCount,
                    id: id
                )
                
                self.posts.append(post)
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
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
