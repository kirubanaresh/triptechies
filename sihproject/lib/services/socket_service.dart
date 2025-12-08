import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  // Replace with your actual backend URL. 
  // For Android Emulator use 10.0.2.2, for iOS use localhost or IP.
  // Using 10.0.2.2 for Android Emulator by default.
  final String _url = 'http://10.0.2.2:3000'; 

  void initSocket() {
    socket = IO.io(_url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connection established');
    });

    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
  }

  void dispose() {
    socket.dispose();
  }
}
