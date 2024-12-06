# Base Instagram Clone App

This repository contains a simple Instagram clone application built using Swift and Firebase. The project demonstrates foundational iOS development concepts, including user authentication, database integration, and basic UI/UX design inspired by Instagram's core functionalities.

---

## Features

### User Authentication
- Users can register an account with an email and password.
- Login functionality for existing users.
- Secure authentication using Firebase Authentication.

### Profile Management
- Users can update their profile information, including username and profile picture.

### Post Creation
- Users can upload photos.
- Posts are displayed on the main feed in chronological order.

### Feed
- Basic feed implementation showcasing posts from all users.

### Database
- Real-time data management using Firebase Firestore.
- Efficient storage and retrieval of user data and posts.

---

## Technologies Used

- **Swift**: Core programming language for the app.
- **UIKit**: Building and managing the app's user interface.
- **Firebase Authentication**: User login and registration.
- **Firebase Firestore**: Backend database for storing user data and posts.
- **Firebase Storage**: Hosting and retrieving uploaded images.
- **Cocoapods**: Managing dependencies and third-party libraries.

---

## Setup Instructions

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/medyahan/BaseInstagramCloneApp.git
   cd BaseInstagramCloneApp
   ```

2. **Install Dependencies:**
   Ensure you have [Cocoapods](https://cocoapods.org/) installed and run:
   ```bash
   pod install
   ```

3. **Configure Firebase:**
   - Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
   - Download the `GoogleService-Info.plist` file and add it to the project directory.
   - Enable Firebase Authentication, Firestore, and Storage in the Firebase Console.

4. **Open the Project in Xcode:**
   Open the `.xcworkspace` file in Xcode.

5. **Run the Application:**
   Select a simulator or connected device and click the **Run** button in Xcode.

---
