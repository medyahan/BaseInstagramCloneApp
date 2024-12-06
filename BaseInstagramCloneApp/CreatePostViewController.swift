//
//  CreatePostViewController.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseDatabase

class CreatePostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    let defaultImage = UIImage(systemName: "photo.badge.plus")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if loadingSpinner.isAnimating { return }
        showImagePicker()
    }
    
    private func setupRecognizer()
    {
        imageView.isUserInteractionEnabled = true
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(showImagePicker))
        imageView.addGestureRecognizer(imageTapGesture)
    }
    
    @objc private func showImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.editedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButton(_ sender: Any) {
        
        // Spinner'ı başlat ve butonu devre dışı bırak
        loadingSpinner.startAnimating()
        (sender as? UIButton)?.isEnabled = false
        
        if imageView.image?.pngData() == defaultImage?.pngData() {
            showAlert(title: "Error", message: "Please select an image")
            loadingSpinner.stopAnimating()
            (sender as? UIButton)?.isEnabled = true
            return
        }
        print("Image is valid")
        
        let storage = Storage.storage()
        let storageReference = storage.reference()
        let mediaFolder = storageReference.child("media")
        
        if let data = imageView.image?.jpegData(compressionQuality: 0.1) {
            print("Image data prepared")
            
            let uuid = UUID().uuidString
            let imageReference = mediaFolder.child("\(uuid).jpeg")
            
            imageReference.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    self.loadingSpinner.stopAnimating()
                    (sender as? UIButton)?.isEnabled = true
                    return
                }
                print("Image uploaded successfully")
                
                imageReference.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        self.showAlert(title: "Error", message: error.localizedDescription)
                        self.loadingSpinner.stopAnimating()
                        (sender as? UIButton)?.isEnabled = true
                        return
                    }
                    print("Download URL retrieved")
                    let imageUrl = url?.absoluteString
                    let post: [String: Any] = [
                        "imageUrl": imageUrl ?? "",
                        "postedBy": Auth.auth().currentUser?.email ?? "Unknown User",
                        "postDescription": self.descriptionTextField.text ?? "",
                        "creationDate": FieldValue.serverTimestamp(),
                        "likeCount": 0,
                        "id" : uuid
                    ]
                    
                    let firestoreDatabase = Firestore.firestore()
                    
                    firestoreDatabase.collection("Posts").addDocument(data: post, completion: { error in
                        if let error = error {
                            print("Error saving post to Firestore: \(error.localizedDescription)")
                            self.showAlert(title: "Error", message: error.localizedDescription)
                            self.loadingSpinner.stopAnimating()
                            (sender as? UIButton)?.isEnabled = true
                            return
                        }
                        print("Post saved to Firestore")
                        self.handleSharingSuccess()
                        
                        // Spinner'ı durdur ve butonu aktif hale getir
                        self.loadingSpinner.stopAnimating()
                        (sender as? UIButton)?.isEnabled = true
                    })
                }
            }
        } else {
            print("Error converting image to data")
            showAlert(title: "Error", message: "Failed to process the image")
            loadingSpinner.stopAnimating()
            (sender as? UIButton)?.isEnabled = true
        }
    }
    
    private func handleSharingSuccess()
    {
        resetView()
        tabBarController?.selectedIndex = 0
    }
    
    private func resetView()
    {
        imageView.image = defaultImage
        descriptionTextField.text = ""
    }
    
    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
