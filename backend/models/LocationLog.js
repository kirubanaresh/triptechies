const mongoose = require('mongoose');

const LocationLogSchema = new mongoose.Schema({
    busId: { type: String, required: true, index: true },
    routeId: { type: String, required: true },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    occupancy: { type: Number }, // 0-100% or count
    timestamp: { type: Date, default: Date.now },
    meta: { type: Object } // Speed, etc.
});

module.exports = mongoose.model('LocationLog', LocationLogSchema);
