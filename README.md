# 🐞 Insect Identifier

**Insect Identifier** is an intelligent mobile application designed to identify insect species in real time using machine learning. Built with **Flutter** and **TensorFlow Lite**, the app delivers instant classification results, detailed confidence scores, and cloud-based history tracking while remaining fully functional offline.

---

## ✨ Key Features

- **Real-time Classification**  
  Instantly identify insect species using the device’s camera.

- **Offline Capability**  
  Utilizes an on-device **TensorFlow Lite (MobileNet)** model, allowing insect detection without an internet connection.

- **Cloud-Based History**  
  Automatically stores classification results — including species name, confidence score, and timestamp — in **Firebase Realtime Database**.

- **Detailed Insights**  
  Displays confidence scores for every prediction to ensure transparency and reliability.

- **User Profile & History Tracking**  
  Maintains a personal identification history, enabling users to track their insect discoveries over time.

---

## 🔄 How It Works

1. **Capture**  
   The application accesses the device camera to capture image frames in real time.

2. **Analyze**  
   Captured frames are processed locally using a quantized **MobileNet TensorFlow Lite** model through `tflite_flutter`.

3. **Classify**  
   The model generates probability scores for each insect class, and the highest-confidence result is displayed to the user.

4. **Record**  
   When the confidence threshold is met, the classification result is securely saved to the **Firebase Realtime Database** for future reference.

---
![Beetle](https://github.com/user-attachments/assets/9cabe9c9-d670-4f7a-b980-c1f87dbde61c)

## 🧰 Tech Stack

- **Frontend**: Flutter (Dart)  
- **Machine Learning Engine**: TensorFlow Lite (MobileNet)  
- **Backend / Database**: Firebase Realtime Database  
- **Authentication**: Firebase Auth (Anonymous)  
- **State Management**: Native `setState` & `ValueNotifier`

---

⭐ *Insect Identifier demonstrates the practical application of mobile development, on-device machine learning, and cloud-based data storage in a real-world scenario.*
