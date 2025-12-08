import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, Alert, TouchableOpacity } from 'react-native';
import api, { setAuthToken } from '../services/api';

export default function LoginScreen({ navigation }) {
    const [isDriver, setIsDriver] = useState(false);
    const [phone, setPhone] = useState('');
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');

    const handleLogin = async () => {
        try {
            let response;
            if (isDriver) {
                if (!username || !password) return Alert.alert('Error', 'Fill all fields');
                response = await api.post('/auth/login', { username, password });
            } else {
                if (!phone) return Alert.alert('Error', 'Enter phone number');
                response = await api.post('/customer/login', { phone });
            }

            const { token, role } = response.data;
            setAuthToken(token);

            // Navigate based on role
            if (role === 'customer') {
                navigation.replace('PassengerHome');
            } else {
                navigation.replace('DriverHome');
            }
        } catch (error) {
            console.error(error);
            Alert.alert('Login Failed', error.response?.data?.error || 'Server error');
        }
    };

    return (
        <View style={styles.container}>
            <Text style={styles.title}>Smart Bus System</Text>

            <View style={styles.toggleContainer}>
                <TouchableOpacity onPress={() => setIsDriver(false)} style={[styles.toggleBtn, !isDriver && styles.activeBtn]}>
                    <Text style={!isDriver ? styles.activeText : styles.text}>Passenger</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={() => setIsDriver(true)} style={[styles.toggleBtn, isDriver && styles.activeBtn]}>
                    <Text style={isDriver ? styles.activeText : styles.text}>Driver/Staff</Text>
                </TouchableOpacity>
            </View>

            {isDriver ? (
                <>
                    <TextInput placeholder="Username" style={styles.input} value={username} onChangeText={setUsername} autoCapitalize="none" />
                    <TextInput placeholder="Password" style={styles.input} value={password} onChangeText={setPassword} secureTextEntry />
                </>
            ) : (
                <TextInput placeholder="Phone Number" style={styles.input} value={phone} onChangeText={setPhone} keyboardType="phone-pad" />
            )}

            <Button title="Login" onPress={handleLogin} />
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, justifyContent: 'center', padding: 20 },
    title: { fontSize: 24, fontWeight: 'bold', mb: 20, textAlign: 'center' },
    input: { borderWidth: 1, borderColor: '#ccc', padding: 10, marginBottom: 15, borderRadius: 5 },
    toggleContainer: { flexDirection: 'row', marginBottom: 20, justifyContent: 'center' },
    toggleBtn: { padding: 10, borderWidth: 1, borderColor: '#007AFF', width: '40%', alignItems: 'center' },
    activeBtn: { backgroundColor: '#007AFF' },
    text: { color: '#007AFF' },
    activeText: { color: 'white' }
});
