import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import LoginScreen from './src/screens/LoginScreen';
import PassengerHomeScreen from './src/screens/PassengerHomeScreen';
import DriverHomeScreen from './src/screens/DriverHomeScreen';
import QRScannerScreen from './src/screens/QRScannerScreen';

const Stack = createStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login">
        <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
        <Stack.Screen name="PassengerHome" component={PassengerHomeScreen} options={{ title: 'Passenger' }} />
        <Stack.Screen name="DriverHome" component={DriverHomeScreen} options={{ title: 'Driver' }} />
        <Stack.Screen name="QRScanner" component={QRScannerScreen} options={{ title: 'Scan Bus QR' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
