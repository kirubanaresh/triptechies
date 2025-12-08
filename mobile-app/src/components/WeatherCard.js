import React from 'react';
import { View, Text, StyleSheet, FlatList } from 'react-native';

export default function WeatherCard({ weather, t, lang }) {
    if (!weather) return null;

    return (
        <View style={styles.card}>
            <Text style={styles.header}>{t('condition', lang)}: {weather.condition} ({weather.temperature}°C)</Text>
            {weather.warning && <Text style={styles.warning}>⚠️ {weather.warning}</Text>}

            <Text style={styles.subHeader}>{t('accessories', lang)}:</Text>
            <View style={styles.tagContainer}>
                {weather.accessories.map((item, index) => (
                    <View key={index} style={styles.tag}>
                        <Text style={styles.tagText}>{item}</Text>
                    </View>
                ))}
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    card: {
        backgroundColor: '#fff',
        padding: 15,
        borderRadius: 10,
        marginTop: 20,
        elevation: 3,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
    },
    header: { fontSize: 18, fontWeight: 'bold', color: '#333' },
    warning: { color: 'red', marginTop: 5, fontWeight: 'bold' },
    subHeader: { marginTop: 10, fontSize: 14, color: '#666', marginBottom: 5 },
    tagContainer: { flexDirection: 'row', flexWrap: 'wrap' },
    tag: { backgroundColor: '#e0f7fa', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 15, marginRight: 8, marginTop: 5 },
    tagText: { color: '#006064', fontSize: 12 }
});
