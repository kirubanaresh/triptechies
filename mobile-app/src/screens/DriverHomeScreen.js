import React, { useState } from 'react';
import { View, Text, StyleSheet, Button, TextInput, Alert } from 'react-native';
import api from '../services/api';
// import { Camera } from 'expo-camera'; // Uncomment when installed

export default function DriverHomeScreen() {
    const [location, setLocation] = useState({ lat: '', lng: '' });
    const [crowding, setCrowding] = useState('');

    const updateStatus = async () => {
        try {
            // Mock data for demo
            await api.post('/driver/update_location', {
                busRegistration: 'BUS-123',
                route: 'Route 1',
                destination: 'Downtown',
                latitude: parseFloat(location.lat || '12.9716'),
                longitude: parseFloat(location.lng || '77.5946'),
                crowding: parseInt(crowding || '50')
            });
            Alert.alert('Success', 'Status Updated');
        } catch (error) {
            Alert.alert('Error', 'Failed to update status');
        }
    };

    return (
        <View style={styles.container}>
            <Text style={styles.title}>Driver Dashboard</Text>
            <TextInput placeholder="Latitude (Mock)" style={styles.input} onChangeText={t => setLocation({ ...location, lat: t })} />
            <TextInput placeholder="Longitude (Mock)" style={styles.input} onChangeText={t => setLocation({ ...location, lng: t })} />
            <TextInput placeholder="Crowding %" style={styles.input} onChangeText={setCrowding} keyboardType="numeric" />
            <Button title="Update Live Status" onPress={updateStatus} />
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, padding: 20 },
    title: { fontSize: 22, fontWeight: 'bold', marginBottom: 20 },
    input: { borderWidth: 1, borderColor: '#ccc', padding: 10, marginBottom: 15, borderRadius: 5 }
});
