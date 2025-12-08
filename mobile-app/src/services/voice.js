import * as Speech from 'expo-speech';

export const speak = (text, lang = 'en') => {
    Speech.speak(text, {
        language: lang,
        pitch: 1.0,
        rate: 0.9,
    });
};

export const stopSpeaking = () => {
    Speech.stop();
};
