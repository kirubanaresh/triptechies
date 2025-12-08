const translations = {
    en: {
        welcome: "Welcome Passenger",
        scan_qr: "Scan Bus QR",
        live_update: "Live Update for Bus",
        crowding: "Crowding",
        select_lang: "Select Language",
        accessories: "Recommended for you",
        temp: "Temp",
        condition: "Condition"
    },
    hi: {
        welcome: "यात्री का स्वागत है",
        scan_qr: "बस QR स्कैन करें",
        live_update: "बस के लिए लाइव अपडेट",
        crowding: "भीड़",
        select_lang: "भाषा चुनें",
        accessories: "आपके लिए अनुशंसित",
        temp: "तापमान",
        condition: "स्थिति"
    },
    ta: {
        welcome: "பயணி வரவேற்கிறோம்",
        scan_qr: "பேருந்து QR ஐ ஸ்கேன் செய்யவும்",
        live_update: "பேருந்து நேரலை புதுப்பிப்பு",
        crowding: "கூட்டம்",
        select_lang: "மொழியைத் தேர்ந்தெடுக்கவும்",
        accessories: "உங்களுக்காக பரிந்துரைக்கப்படுகிறது",
        temp: "வெப்பநிலை",
        condition: "நிலை"
    },
    de: { // German
        welcome: "Willkommen Fahrgast",
        scan_qr: "Bus QR scannen",
        live_update: "Live-Update für Bus",
        crowding: "Auslastung",
        select_lang: "Sprache wählen",
        accessories: "Für dich empfohlen",
        temp: "Temp",
        condition: "Zustand"
    }
};

export const t = (key, lang = 'en') => {
    return translations[lang]?.[key] || translations['en'][key] || key;
};

export const languages = [
    { code: 'en', label: 'English' },
    { code: 'hi', label: 'Hindi' },
    { code: 'ta', label: 'Tamil' },
    { code: 'de', label: 'German' },
];
