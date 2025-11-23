# Before Pushing to GitHub - Security Checklist

⚠️ **IMPORTANT**: Before making this repository public, ensure you've completed these steps to protect your Firebase credentials.

## ✅ Checklist

### 1. Verify .gitignore is Updated
- [x] `.gitignore` includes Firebase files (already done)
- [x] `lib/firebase_options.dart` is in `.gitignore`
- [x] `**/google-services.json` is in `.gitignore`
- [x] `**/GoogleService-Info.plist` is in `.gitignore`

### 2. Remove Sensitive Files from Git History (if already committed)

If you've already committed Firebase files, remove them from Git:

```bash
# Remove firebase_options.dart from Git tracking (but keep local file)
git rm --cached lib/firebase_options.dart

# Remove google-services.json from Git tracking (but keep local file)
git rm --cached android/app/google-services.json

# If you have iOS files
git rm --cached ios/Runner/GoogleService-Info.plist

# Commit the removal
git add .gitignore
git commit -m "Remove Firebase configuration files from repository"
```

### 3. Verify Files Are Not Tracked

Check what files Git is tracking:

```bash
# Check if firebase_options.dart is tracked
git ls-files | grep firebase_options.dart

# Check if google-services.json is tracked
git ls-files | grep google-services.json

# If these commands return nothing, you're good!
```

### 4. Verify Example Files Are Included

Make sure these template files are committed:
- [x] `lib/firebase_options.dart.example`
- [x] `android/app/google-services.json.example`
- [x] `SETUP_FIREBASE.md`

### 5. Test Clone (Optional but Recommended)

Test that a fresh clone works:

```bash
# In a different directory
cd /tmp
git clone <your-repo-url> test-clone
cd test-clone

# Verify Firebase files are NOT present
ls lib/firebase_options.dart  # Should fail (file not found)
ls android/app/google-services.json  # Should fail (file not found)

# Verify example files ARE present
ls lib/firebase_options.dart.example  # Should succeed
ls android/app/google-services.json.example  # Should succeed
```

### 6. Update README

- [x] README mentions Firebase setup is required
- [x] Links to SETUP_FIREBASE.md

## 🔒 Security Best Practices

1. **Never commit**:
   - Real API keys
   - Real project IDs
   - Real app IDs
   - Any Firebase credentials

2. **Always use**:
   - Example/template files
   - `.gitignore` to exclude sensitive files
   - Environment variables for CI/CD (if needed)

3. **If you accidentally committed sensitive data**:
   - Remove it immediately
   - Consider rotating your Firebase API keys
   - Use `git filter-branch` or BFG Repo-Cleaner to remove from history

## 📝 After Pushing

Once the repository is public:

1. Update Firebase Console → Project Settings → Authorized domains
2. Review Firestore security rules
3. Monitor Firebase usage for unexpected activity
4. Consider setting up Firebase App Check for additional security

## ✅ Ready to Push?

If all checklist items are complete, you're ready to make the repository public!

```bash
git add .
git commit -m "Prepare repository for public release - remove sensitive Firebase files"
git push origin main
```

---

**Remember**: Your local Firebase configuration files will remain on your machine and won't be pushed to GitHub. Each developer needs to run `flutterfire configure` to generate their own configuration files.

