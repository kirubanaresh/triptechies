class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'customer_login': 'Customer Login',
      'worker_login': 'Worker Login',
      'choose_login': 'Choose Login',
      'username': 'Phone or Email',
      'worker_username': 'Username',
      'password': 'Password',
      'login': 'Login',
      'sign_in_subtitle': 'Sign in to track your buses',
      'register_prompt': "Don't have an account? Register",
      'cancel': 'Cancel',
      'scan_qr': 'Scan QR Code',
    },
    'ta': {
      'customer_login': 'பயனர் உள்நுழைவு',
      'worker_login': 'பணியாளர் உள்நுழைவு',
      'choose_login': 'உள்நுழைவைத் தேர்ந்தெடுக்கவும்',
      'username': 'தொலைபேசி எண்',
      'worker_username': 'பயனர் பெயர்',
      'password': 'கடவுச்சொல்',
      'login': 'உள்நுழைக',
      'sign_in_subtitle': 'பேருந்துகளைக் கண்காணிக்க உள்நுழையவும்',
      'register_prompt': "கணக்கு இல்லையா? பதிவு செய்யவும்",
      'cancel': 'ரத்துசெய்',
      'scan_qr': 'QR குறியீட்டை ஸ்கேன்',
    },
    'kn': {
      'customer_login': 'ಗ್ರಾಹಕ ಲಾಗಿನ್',
      'worker_login': 'ನೌಕರರ ಲಾಗಿನ್',
      'choose_login': 'ಲಾಗಿನ್ ಆಯ್ಕೆಮಾಡಿ',
      'username': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ',
      'worker_username': 'ಬಳಕೆದಾರ ಹೆಸರು',
      'password': 'ಪಾಸ್‌ವರ್ಡ್',
      'login': 'ಲಾಗಿನ್',
      'sign_in_subtitle': 'ಬಸ್‌ಗಳನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಲು ಲಾಗಿನ್ ಮಾಡಿ',
      'register_prompt': "ಖಾತೆ ಇಲ್ಲವೇ? ನೋಂದಾಯಿಸಿ",
      'cancel': 'ರದ್ದುಮಾಡಿ',
      'scan_qr': 'ಕ್ಯೂಆರ್ ಕೋಡ್ ಸ್ಕ್ಯಾನ್',
    },
    'hi': {
      'customer_login': 'ग्राहक लॉगिन',
      'worker_login': 'कर्मचारी लॉगिन',
      'choose_login': 'लॉगिन चुनें',
      'username': 'फ़ोन नंबर',
      'worker_username': 'उपयोगकर्ता नाम',
      'password': 'पासवर्ड',
      'login': 'लॉगिन',
      'sign_in_subtitle': 'बसों को ट्रैक करने के लिए साइन इन करें',
      'register_prompt': "खाता नहीं है? रजिस्टर करें",
      'cancel': 'रद्द करें',
      'scan_qr': 'QR कोड स्कैन करें',
    },
  };

  static String get(String code, String key) {
    return _localizedValues[code]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
