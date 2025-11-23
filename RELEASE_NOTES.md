# Face Recognition App - APK Release

## 📱 Download

Download the latest APK from the [Releases](https://github.com/alpharibbin/facerecognition/releases) page.

## 📸 Screenshots

| Home Page                  | Face Detaction                 | View All Registered            |
|----------------------------|--------------------------------|--------------------------------|
| ![Home Page](assets/images/homepage.jpeg) | ![Before](assets/images/multifaces.jpeg) | ![After](assets/images/viewalllist.jpeg) |

## ✨ Features

- 📸 **Face Registration**: Register faces with email and name
- 🔍 **Real-time Detection**: Detect and recognize faces in real-time using camera
- 📋 **View All Registered**: Browse all registered faces with search functionality
- 💾 **Offline Support**: Store embeddings locally using Hive for offline recognition
- ☁️ **Cloud Sync**: Sync embeddings with Firebase Firestore
- 🎯 **High Accuracy**: Uses FaceNet model for face embeddings

## 🚀 Quick Start

1. **Install the APK** on your Android device
2. **Grant Camera Permission** when prompted
3. **Setup Firebase** (see [SETUP_FIREBASE.md](SETUP_FIREBASE.md))
4. **Start Using**: Register faces and detect them in real-time!

## 📋 Requirements

- **Android**: Minimum SDK 21 (Android 5.0+)
- **Camera**: Required for face capture and detection
- **Internet**: Required for Firebase sync (offline mode available)

## 🎯 Use Cases

This app can be extended for:
- 🎓 Class Attendance Systems
- 🏢 Office Access Control
- 📅 Event Management
- 🔒 Security & Surveillance
- 🛍️ Customer Recognition
- 🏥 Healthcare Applications
- 🚗 Transportation Systems

## 📖 Documentation

For detailed setup instructions, architecture, and API documentation, see:
- [README.md](README.md) - Project overview
- [SETUP_FIREBASE.md](SETUP_FIREBASE.md) - Firebase setup guide
- [docs/SETUP.md](docs/SETUP.md) - Complete setup guide
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architecture documentation
- [docs/API.md](docs/API.md) - API reference

## 🔧 Technical Details

**Tech Stack:**
- Flutter (Cross-platform)
- TensorFlow Lite (FaceNet model)
- Google ML Kit (Face detection)
- Firebase Firestore (Cloud database)
- Hive (Local storage)

## ⚠️ Important Notes

- This app requires **Firebase configuration** to work properly
- You need to set up your own Firebase project (see [SETUP_FIREBASE.md](SETUP_FIREBASE.md))
- The APK does NOT include Firebase credentials for security reasons
- Camera permission is required for face recognition features

## 🐛 Known Issues

- None at this time

## 📝 Changelog

### Version 1.0.0
- Initial release
- Face registration and detection
- Real-time face recognition
- Offline support with local storage
- Firebase cloud sync
- Search and manage registered faces

## 🤝 Contributing

Contributions are welcome! Please read [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

## 📄 License

This project is private and not licensed for public use.

## 🔗 Links

- **Repository**: [https://github.com/alpharibbin/facerecognition](https://github.com/alpharibbin/facerecognition)
- **Issues**: [Report a bug](https://github.com/alpharibbin/facerecognition/issues)

---

**Note**: Make sure to grant camera permissions and set up Firebase before using the app.

