//
//  ProfileEditViewController.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 6.12.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage
import FirebaseStorage

class ProfileEditViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var biographyTextField: UITextField!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIButton!
    
    let defaultImage = UIImage(systemName: "person.circle.fill")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserProfile()
    }
    
    private func setupUI() {
        loadingSpinner.isHidden = true
        setupImageView()
        saveButton.layer.cornerRadius = 8
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
    }
    
    private func setupImageView() {
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    private func loadUserProfile() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        Firestore.firestore()
            .collection("Users")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching user profile: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("No user profile found.")
                    return
                }
                
                let data = document.data()
                let username = data["username"] as? String ?? ""
                let biography = data["biography"] as? String ?? ""
                let profileImageUrl = data["profileImageUrl"] as? String
                
                DispatchQueue.main.async {
                    self.usernameTextField.text = username
                    self.biographyTextField.text = biography
                    
                    if let profileImageUrl = profileImageUrl, let url = URL(string: profileImageUrl) {
                        self.imageView.sd_setImage(with: url, placeholderImage: self.defaultImage)
                    } else {
                        self.imageView.image = self.defaultImage
                    }
                }
            }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }
        
        saveUserProfile(username: username, biography: biographyTextField.text ?? "")
    }
    
    
    private func saveUserProfile(username: String, biography: String) {
        
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Error: User email not found.")
            return
        }
        
        toggleLoading(true)
        
        if imageView.image == defaultImage {
            updateUserProfile(username: username, biography: biography, profileImageUrl: nil)
            return
        }
        
        guard let profileImage = imageView.image,
              let imageData = profileImage.jpegData(compressionQuality: 0.5) else {
            showAlert(title: "Error", message: "Failed to process the image.")
            toggleLoading(false)
            return
        }
        
        let storageRef = Storage.storage().reference().child("profileImages/\(UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: error.localizedDescription)
                self.toggleLoading(false)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    self.toggleLoading(false)
                    return
                }
                
                guard let profileImageUrl = url?.absoluteString else {
                    print("Error: Profile image URL is nil.")
                    return
                }
                
                self.updateUserProfile(username: username, biography: biography, profileImageUrl: profileImageUrl)
            }
        }
    }
    
    private func updateUserProfile(username: String, biography: String, profileImageUrl: String?) {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Error: User email not found.")
            return
        }
        
        var userData: [String: Any] = [
            "username": username,
            "biography": biography
        ]
        
        if let profileImageUrl = profileImageUrl {
            userData["profileImageUrl"] = profileImageUrl
        }
        
        Firestore.firestore()
            .collection("Users")
            .document(userEmail)
            .setData(userData, merge: true) { [weak self] error in
                guard let self = self else { return }
                
                self.toggleLoading(false)
                
                if let error = error {
                    print("Error updating Firestore: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                print("Profile updated successfully.")
                self.showAlert(title: "Success", message: "Profile updated successfully!")
            }
    }
    
    private func toggleLoading(_ isLoading: Bool) {
        loadingSpinner.isHidden = !isLoading
        saveButton.isEnabled = !isLoading
        if isLoading {
            loadingSpinner.startAnimating()
        } else {
            loadingSpinner.stopAnimating()
        }
    }
    
    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

extension ProfileEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            imageView.image = editedImage
        }
        dismiss(animated: true, completion: nil)
    }
}
