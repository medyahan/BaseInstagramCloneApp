//
//  ProfileViewController.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import UIKit
import FirebaseAuth
class ProfileViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func logOutButtonClicked(_ sender: Any) {
        
        logOut()
    }
    
    private func logOut() {
        do {
            print("Attempting to sign out...")
            try Auth.auth().signOut()
            print("Sign out successful!")
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = windowScene.delegate as? SceneDelegate {
                    print("Navigating to login screen...")
                    sceneDelegate.navigateToLogin()
                } else {
                    print("SceneDelegate or UIWindowScene is nil.")
                }
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
            showAlert(title: "Error", message: signOutError.localizedDescription)
        }
    }
    
    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
