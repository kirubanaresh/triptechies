import io from 'socket.io-client';

const SOCKET_URL = 'http://10.0.2.2:3000'; // Match backend URL

const socket = io(SOCKET_URL, {
    transports: ['websocket'],
    autoConnect: true,
});

export default socket;
