# 🔥 Firestore Security Rules - Deployment Guide

## ⚠️ CRITICAL: Permission Denied Error Fix

This guide will help you deploy the updated Firestore security rules to fix the permission denied error when favoriting questions.

---

## 🎯 What Was Fixed

### Problem:
- Error: `[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation`
- Users couldn't favorite questions due to missing security rules

### Solution:
- ✅ Added proper security rules for `favorites` collection
- ✅ Preserved existing `favorite_questions` collection rules (as required)
- ✅ Added helper functions for cleaner rule management
- ✅ Ensured rules work for both document reads and list queries

---

## 📋 Step-by-Step Deployment

### Option 1: Firebase Console (RECOMMENDED - 2 minutes)

#### Step 1: Open Firebase Console
1. Go to: **https://console.firebase.google.com/**
2. Select your project: **performax**

#### Step 2: Navigate to Firestore Rules
1. Click **"Firestore Database"** in the left sidebar
2. Click the **"Rules"** tab at the top

#### Step 3: Copy & Paste Rules
Copy the **ENTIRE** content from `firestore.rules` file and paste it into the Firebase Console editor.

**OR** copy this complete rules file:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function: check if user owns the document
    function isOwner() {
      return request.auth != null && 
             (!resource.exists || resource.data.userId == request.auth.uid);
    }
    
    // Helper function: check if creating/updating with own userId
    function isCreatingOwn() {
      return request.auth != null && 
             request.resource.data.userId == request.auth.uid;
    }
    
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
    
    // Current favorites collection (used by FavoritesService)
    // Allows authenticated users to read/write their own favorites
    match /favorites/{favoriteId} {
      allow read: if isOwner();
      allow create, update: if isCreatingOwn();
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Legacy favorite_questions collection (PRESERVED - must not be removed)
    match /favorite_questions/{questionId} {
      allow read: if isOwner();
      allow create, update: if isCreatingOwn();
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Favorite books collection
    match /favorite_books/{bookId} {
      allow read: if isOwner();
      allow create, update: if isCreatingOwn();
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Favorite playlists collection
    match /favorite_playlists/{playlistId} {
      allow read: if isOwner();
      allow create, update: if isCreatingOwn();
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
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

#### Step 4: Validate Rules
1. Click **"Validate"** button (if available) to check for syntax errors
2. Review any warnings (should be none)

#### Step 5: Publish Rules
1. Click **"Publish"** button at the top right
2. Wait for confirmation: "Rules published successfully"

#### Step 6: Test the Fix
1. **Restart your Flutter app** (hot reload might not pick up rule changes)
2. Try to favorite a question
3. Should work now! ✅

---

### Option 2: Firebase CLI (Alternative)

If you prefer command-line deployment:

#### Install Firebase CLI (if not installed)
```bash
npm install -g firebase-tools
```

#### Login to Firebase
```bash
firebase login
```

#### Deploy Rules
```bash
cd /Users/renasa/Development/projects/performax
firebase deploy --only firestore:rules
```

---

## 🔍 Verification Checklist

After deploying, verify:

- [ ] Rules published successfully in Firebase Console
- [ ] No syntax errors shown
- [ ] Flutter app restarted
- [ ] User is logged in
- [ ] Can favorite a question ✅
- [ ] Can unfavorite a question ✅
- [ ] Can view favorites in "Favorites" section ✅
- [ ] Favorites grouped by book title ✅

---

## 🛡️ Security Features

The rules ensure:

✅ **Authentication Required**: Only logged-in users can access favorites
✅ **User Isolation**: Users can only read/write their own favorites
✅ **Data Validation**: userId field must match authenticated user's UID
✅ **Document Existence**: Can check if document exists (for favorite status)
✅ **List Queries**: Can query all favorites for a user
✅ **Legacy Support**: `favorite_questions` collection preserved

---

## 🐛 Troubleshooting

### Still Getting Permission Denied?

1. **Check Authentication**
   - Ensure user is logged in
   - Verify `FirebaseAuth.instance.currentUser` is not null

2. **Verify Rules Deployed**
   - Check Firebase Console → Firestore → Rules
   - Ensure latest rules are published

3. **Check Collection Name**
   - Code uses: `favorites` (not `favorite_questions`)
   - Verify document ID format: `{userId}_{testName}_Q{questionNumber}`

4. **Restart App**
   - Rules changes require app restart (not just hot reload)

5. **Check Firebase Project**
   - Ensure correct Firebase project is connected
   - Verify `google-services.json` / `GoogleService-Info.plist` matches

### Common Errors

**Error: "Missing or insufficient permissions"**
- Rules not deployed yet → Deploy rules
- User not authenticated → Check login status
- Wrong collection name → Verify `favorites` collection exists

**Error: "userId does not match"**
- Document created with wrong userId → Delete and recreate
- Authentication issue → Re-login user

---

## 📝 Notes

- **Rules are instant**: Once published, changes take effect immediately
- **No app update needed**: Only Firebase rules need updating
- **Backward compatible**: Old `favorite_questions` collection still works
- **Secure by default**: Default deny prevents unauthorized access

---

## ✅ Status

- [x] Rules file updated locally
- [ ] Rules deployed to Firebase (YOU NEED TO DO THIS)
- [ ] Tested and verified working

**Next Step:** Deploy rules to Firebase Console (2 minutes)

---

**Last Updated:** December 15, 2025  
**File:** `firestore.rules`  
**Commit:** Ready for manual commit (not pushed per user request)

