//
//  LoginSignUpViewController.swift
//  BaseInstagramCloneApp
//
//  Created by Medya Han on 5.12.2024.
//

import UIKit
import FirebaseAuth
import Firebase

class LoginSignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameOrEmailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginButtonClicked(_ sender: Any) {
        if !areFieldsValid(){
            return
        }
        checkUser()
    }
    
    @IBAction func signUpButtonClicked(_ sender: Any) {
        
        if !areFieldsValid(){
            return
        }
        
        registerUser()
    }
    
    private func registerUser() {
        guard let email = usernameOrEmailTextField.text,
              let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { authData, error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            // Kullanıcıyı Firestore'a kaydet
            self.saveUserToFirestore(email: email)
        }
    }
    
    private func saveUserToFirestore(email: String) {
        let firestoreDatabase = Firestore.firestore()
        
        let username = extractUsername(from: email)
        let userData: [String: Any] = [
            "email": email,
            "username": username,
            "profileImageUrl": "",
            "biography": ""
        ]
        
        firestoreDatabase.collection("Users").document(email).setData(userData) { error in
            if let error = error {
                self.showAlert(title: "Error", message: "User created, but additional info couldn't be saved: \(error.localizedDescription)")
                return
            }
            
            self.performSegue(withIdentifier: "toHomeVC", sender: nil)
        }
    }
    
    private func extractUsername(from email: String) -> String {
        if let username = email.split(separator: "@").first {
            return String(username)
        }
        return "User"
    }
    
    private func checkUser(){
        Auth.auth().signIn(withEmail: usernameOrEmailTextField.text!, password: passwordTextField.text!) { (authData, error )in
            
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            self.performSegue(withIdentifier: "toHomeVC", sender: nil)
            self.showAlert(title: "Success", message: "Logged in successfully!")
        }
    }
    
    private func areFieldsValid() -> Bool {
        guard let usernameOrEmail = usernameOrEmailTextField.text, !usernameOrEmail.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill all fields.")
            return false
        }
        return true
    }
    
    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    
}

