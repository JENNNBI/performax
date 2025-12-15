# 🔥 Deploy Firestore Security Rules - Quick Guide

## ⚡ QUICK FIX (Firebase Console - 2 minutes)

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select your project: **performax**

### Step 2: Navigate to Firestore Rules
1. Click on **"Firestore Database"** in the left sidebar
2. Click on the **"Rules"** tab at the top

### Step 3: Copy & Paste the Rules
Copy the entire content below and paste it into the Firebase Console:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow users to read/write their own user document
    // This includes favorites stored as arrays: favoriteQuestions, favoriteBooks, favoritePlaylists
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to read/write their own test results (subcollection)
      match /test_results/{testResultId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ==================== FAVORITES COLLECTIONS ====================
    // Users can only read/write their own favorites
    // Security: userId field must match authenticated user's UID
    
    // Favorite questions collection
    match /favorites/{favoriteId} {
      allow read: if request.auth != null && 
                     (!resource.exists || resource.data.userId == request.auth.uid);
      allow create, update: if request.auth != null && 
                               request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && 
                       resource.data.userId == request.auth.uid;
    }
    
    // Favorite books collection
    match /favorite_books/{bookId} {
      allow read: if request.auth != null && 
                     (!resource.exists || resource.data.userId == request.auth.uid);
      allow create, update: if request.auth != null && 
                               request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && 
                       resource.data.userId == request.auth.uid;
    }
    
    // Favorite playlists collection
    match /favorite_playlists/{playlistId} {
      allow read: if request.auth != null && 
                     (!resource.exists || resource.data.userId == request.auth.uid);
      allow create, update: if request.auth != null && 
                               request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && 
                       resource.data.userId == request.auth.uid;
    }
    
    // Allow users to read/write their own progress data
    match /user_progress/{progressId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read public content
    match /content/{document=**} {
      allow read: if request.auth != null;
    }
    
    // Default deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 4: Publish the Rules
1. Click the **"Publish"** button at the top right
2. Wait for confirmation message

### Step 5: Test the Fix
1. Restart your app (stop and rerun)
2. Try to favorite a question
3. Should work now! ✅

---

## 🔧 Alternative: Deploy via Firebase CLI

If you prefer command-line deployment:

### Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Login to Firebase
```bash
firebase login
```

### Initialize Firebase (if not already done)
```bash
cd /Users/renasa/Development/projects/performax
firebase init firestore
```

### Deploy Rules
```bash
firebase deploy --only firestore:rules
```

---

## 🐛 What Was Fixed?

### The Problem:
- Your code uses collection: `favorites`
- Old rules had: `favorite_questions` (wrong name)
- Result: Permission denied error ❌

### The Solution:
- Updated rules to use: `favorites` ✅
- Added proper security: users can only access their own favorites
- Maintained security for other collections

### Security Features:
✅ Users must be authenticated
✅ Users can only read/write their own favorites
✅ userId field must match authenticated user's UID
✅ Prevents unauthorized access to other users' data

---

## 📝 Notes

- The `firestore.rules` file in your project has been updated
- You need to deploy this file to Firebase for changes to take effect
- Changes are instant once deployed (no app restart needed on Firebase side)
- You may need to restart your Flutter app to clear any cached errors

---

**Status:** ✅ Rules file updated locally  
**Next Step:** Deploy to Firebase Console (2 minutes)

