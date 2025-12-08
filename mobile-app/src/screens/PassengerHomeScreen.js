import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Button, ScrollView, TouchableOpacity, Modal, TextInput, Alert, ActivityIndicator } from 'react-native';
import * as Location from 'expo-location';
import socket from '../services/socket';
import api from '../services/api';
import { t, languages } from '../services/i18n';
import { speak } from '../services/voice';
import WeatherCard from '../components/WeatherCard';

export default function PassengerHomeScreen({ navigation }) {
    const [busUpdate, setBusUpdate] = useState(null);
    const [weather, setWeather] = useState(null);
    const [lang, setLang] = useState('en');
    const [modalVisible, setModalVisible] = useState(false);
    const [rating, setRating] = useState('');
    const [sendingSOS, setSendingSOS] = useState(false);

    useEffect(() => {
        socket.on('bus_update', (data) => {
            console.log('Live Bus Update:', data);
            setBusUpdate(data);
            // Voice announcement
            const message = lang === 'en'
                ? `Bus ${data.busRegistration} is now at ${data.latitude}, ${data.longitude}`
                : `Bus update received`;
            speak(message, lang);
        });

        fetchWeather('Chennai');

        return () => {
            socket.off('bus_update');
        };
    }, [lang]);

    const fetchWeather = async (location) => {
        try {
            const res = await api.get(`/weather?location=${location}`);
            setWeather(res.data);
        } catch (err) {
            console.error('Weather fetch error', err);
        }
    };

    const handleSOS = async () => {
        setSendingSOS(true);
        try {
            let { status } = await Location.requestForegroundPermissionsAsync();
            if (status !== 'granted') {
                Alert.alert('Permission to access location was denied');
                setSendingSOS(false);
                return;
            }

            let location = await Location.getCurrentPositionAsync({});
            await api.post('/sos', {
                busRegistration: busUpdate?.busRegistration || 'UNKNOWN',
                location: location.coords,
                userId: '12345' // Replace with real ID
            });
            Alert.alert('SOS SENT', 'Emergency alert has been broadcasted!');
        } catch (error) {
            Alert.alert('Error', 'Failed to send SOS');
            console.error(error);
        } finally {
            setSendingSOS(false);
        }
    };

    const submitFeedback = async () => {
        try {
            await api.post('/feedback', {
                busRegistration: busUpdate?.busRegistration || 'UNKNOWN',
                rating,
                comments: 'Cleanliness rating'
            });
            setModalVisible(false);
            Alert.alert('Thank you', 'Feedback submitted');
        } catch (error) {
            console.error(error);
        }
    };

    return (
        <ScrollView contentContainerStyle={styles.container}>
            <Text style={styles.title}>Smart Bus System</Text>

            <View style={styles.langContainer}>
                {languages.map(l => (
                    <TouchableOpacity
                        key={l.code}
                        onPress={() => setLang(l.code)}
                        style={[styles.langBtn, lang === l.code && styles.activeLang]}
                    >
                        <Text style={[styles.langText, lang === l.code && styles.activeLangText]}>{l.code.toUpperCase()}</Text>
                    </TouchableOpacity>
                ))}
            </View>

            {/* SOS Button */}
            <TouchableOpacity
                style={styles.sosBtn}
                onPress={handleSOS}
                disabled={sendingSOS}
            >
                {sendingSOS ? <ActivityIndicator color="#fff" /> : <Text style={styles.sosText}>🚨 SOS EMERGENCY 🚨</Text>}
            </TouchableOpacity>

            <View style={styles.card}>
                <Text style={styles.subtitle}>{t('welcome', lang)}</Text>
                <Button title={t('scan_qr', lang)} onPress={() => navigation.navigate('QRScanner')} />
                <Button title="Rate Cleanliness" onPress={() => setModalVisible(true)} color="#4CAF50" />
            </View>

            {busUpdate && (
                <View style={styles.card}>
                    <Text style={styles.liveText}>🔴 {t('live_update', lang)}: {busUpdate.busRegistration}</Text>
                    <Text>{t('crowding', lang)}: {busUpdate.crowding}%</Text>
                </View>
            )}

            <WeatherCard weather={weather} t={t} lang={lang} />

            {/* Feedback Modal */}
            <Modal
                animationType="slide"
                transparent={true}
                visible={modalVisible}
                onRequestClose={() => setModalVisible(!modalVisible)}
            >
                <View style={styles.centeredView}>
                    <View style={styles.modalView}>
                        <Text style={styles.modalText}>Rate Bus Cleanliness (1-5)</Text>
                        <TextInput
                            style={styles.input}
                            keyboardType="numeric"
                            onChangeText={setRating}
                            value={rating}
                        />
                        <Button title="Submit" onPress={submitFeedback} />
                    </View>
                </View>
            </Modal>

        </ScrollView>
    );
}

const styles = StyleSheet.create({
    container: { padding: 20, paddingBottom: 50 },
    title: { fontSize: 22, fontWeight: 'bold', marginBottom: 20, textAlign: 'center' },
    card: { padding: 20, backgroundColor: '#f0f0f0', borderRadius: 10, marginBottom: 15 },
    subtitle: { fontSize: 18, marginBottom: 10, fontWeight: '600' },
    liveText: { color: 'red', fontWeight: 'bold', marginBottom: 5 },
    langContainer: { flexDirection: 'row', justifyContent: 'center', marginBottom: 10 },
    langBtn: { padding: 8, marginHorizontal: 5, borderWidth: 1, borderColor: '#ccc', borderRadius: 5 },
    activeLang: { backgroundColor: '#007AFF', borderColor: '#007AFF' },
    langText: { fontSize: 12, color: '#333' },
    activeLangText: { color: 'white' },
    sosBtn: { backgroundColor: 'red', padding: 15, borderRadius: 10, marginBottom: 20, alignItems: 'center' },
    sosText: { color: 'white', fontWeight: 'bold', fontSize: 18 },
    centeredView: { flex: 1, justifyContent: "center", alignItems: "center", marginTop: 22 },
    modalView: { margin: 20, backgroundColor: "white", borderRadius: 20, padding: 35, alignItems: "center", shadowColor: "#000", shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.25, shadowRadius: 4, elevation: 5 },
    modalText: { marginBottom: 15, textAlign: "center", fontWeight: 'bold' },
    input: { borderWidth: 1, borderColor: '#ccc', width: 200, padding: 10, marginBottom: 15, borderRadius: 5 }
});
