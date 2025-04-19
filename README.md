# NutriSense

A Flutter **Mobile Application** designed to help users track their nutrition, set health goals, and make better dietary choices. **(Code files in master branch)**

---

##  Features

- **User Authentication**: Sign up, login, and password recovery  ✅
- **Personalized Nutrition Tracking**: Customized calorie and macronutrient targets based on your profile   ✅
- **Weight Tracking**: Monitor your weight journey with visual graphs  ✅
- **Food Logging**: Multiple ways to log meals (barcode scanning, search, manual entry, and image recognition)  ✅
- **Meal Planning**: Plan your meals in advance to meet your nutritional goals
- **Barcode Scanner**: Get nutritional information by scanning barcode **(In Progess)**
- **Database**: OpenFoodFacts/USDA database
- **Manual Entry**: User inputs nutritinal values themselves **(In Progess)**
- **Image Recognition**: Food Image Recognition - users take a photo of their meal and instantly get nutritional info based on image detection

---


### ✅ Prerequisites

- Flutter SDK (3.7.0 or higher)  
- Dart SDK  
- Firebase account for authentication and storage  

---

###  Installation

```bash
# Clone the repository
git clone https://github.com/mahrukhyousuf/NutriSense-SE-Project.git

# Navigate to the project directory
cd nutrisense

# Install dependencies
flutter pub get

---
### Configure Firebase
1. Create a Firebase project
2. Add your Android/iOS apps
3. Download the configuration files:
```bash
google-services.json for Android

GoogleService-Info.plist for iOS
```

4. Place them in the appropriate directories:
Android: android/app/
iOS: ios/Runner/

---
### Run The App
```bash
flutter run
```

### Project Structure
```arduino
lib/
├── config/
│   └── theme.dart
├── core/
│   ├── models/
│   │   └── user_profile.dart
│   ├── services/
│   │   └── user_service.dart
│   └── utils/
│       └── date_formatter.dart
├── ui/
│   ├── dashboard_screen.dart
│   ├── food_logging_screen.dart
│   ├── forgot_password_screen.dart
│   ├── goals_preference_screen.dart
│   ├── health_info_screen.dart
│   ├── login_screen.dart
│   ├── personal_details_screen.dart
│   ├── signup_screen.dart
│   └── welcome_screen.dart
└── main.dart
```
---
### Tech Stack:
Flutter – Cross-platform UI development
Firebase Authentication – User management
Cloud Firestore – Data storage
fl_chart – Data visualization

