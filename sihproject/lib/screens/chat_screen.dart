import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/language_provider.dart';
import '../config.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'User');
  final ChatUser _botUser = ChatUser(id: '2', firstName: 'TripBot', profileImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712038.png');
  
  List<ChatMessage> _messages = [];
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isListening = false;
  bool _voiceMode = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  void _onSend(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });
    _getBotResponse(message.text);
  }

  Future<void> _getBotResponse(String text) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = langProvider.appLocale.languageCode;

    // Use Config.baseUrl
    final url = Uri.parse('${Config.baseUrl}/api/chat'); 
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": text,
          "language": langCode
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'];
        final extraData = data['data']; // Route data if any

        final botMessage = ChatMessage(
          user: _botUser,
          createdAt: DateTime.now(),
          text: reply,
          customProperties: extraData, // Pass data to render custom widget
        );

        setState(() {
          _messages.insert(0, botMessage);
        });

        if (_voiceMode) {
          _speak(reply, langCode);
        }
      }
    } catch (e) {
      print("Chat Error: $e");
      setState(() {
        _messages.insert(0, ChatMessage(
            user: _botUser, 
            createdAt: DateTime.now(), 
            text: "Connection Error. check Config IP."
        ));
      });
    }
  }

  Future<void> _speak(String text, String langCode) async {
    if (langCode == 'ta') await _flutterTts.setLanguage("ta-IN");
    else if (langCode == 'hi') await _flutterTts.setLanguage("hi-IN");
    else if (langCode == 'fr') await _flutterTts.setLanguage("fr-FR");
    else if (langCode == 'de') await _flutterTts.setLanguage("de-DE");
    else await _flutterTts.setLanguage("en-US");

    await _flutterTts.speak(text);
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    await _speechToText.listen(onResult: (result) {
      if (result.finalResult) {
        final message = ChatMessage(
          user: _currentUser,
          createdAt: DateTime.now(),
          text: result.recognizedWords,
        );
        _onSend(message);
      }
    });
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  // Render Custom Widgets (Route Cards)
  Widget _messageBuilder(ChatMessage message) {
    
    // Default chat bubble
    Widget bubble = Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: message.user.id == '1' ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message.text,
        style: TextStyle(color: message.user.id == '1' ? Colors.white : Colors.black),
      ),
    );

    // If message involves route data
    if (message.customProperties != null && (message.customProperties?['type'] == 'route_list' || message.customProperties?['type'] == 'route_indirect')) {
       List routes = message.customProperties?['routes'] ?? [];
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           bubble,
           SizedBox(height: 5),
           ...routes.map((route) {
             return Card(
               margin: EdgeInsets.only(top: 5, bottom: 5, right: 20),
               color: Colors.white,
               elevation: 2,
               child: ListTile(
                 leading: Icon(Icons.directions_bus, color: Colors.blue),
                 title: Text(route['bus1'] ?? route['bus_registration'] ?? 'Bus'),
                 subtitle: Text(
                   message.customProperties?['type'] == 'route_indirect' 
                   ? "Via ${route['transfer']} \n${route['dep1']} -> ${route['arr2']}" 
                   : "${route['departure_time']} - ${route['arrival_time']}"
                 ),
                 trailing: Icon(Icons.arrow_forward_ios, size: 16),
               ),
             );
           }).toList()
         ],
       );
    }
    
    return bubble;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Assistant"),
        actions: [
          IconButton(
            icon: Icon(_voiceMode ? Icons.mic : Icons.keyboard),
            onPressed: () {
              setState(() {
                _voiceMode = !_voiceMode;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
           // Quick Actions
           Container(
             height: 50,
             padding: EdgeInsets.symmetric(horizontal: 10),
             child: ListView(
               scrollDirection: Axis.horizontal,
               children: [
                 ActionChip(label: Text("Weather"), onPressed: () => _onSend(ChatMessage(user: _currentUser, createdAt: DateTime.now(), text: "Weather"))),
                 SizedBox(width: 8),
                 ActionChip(label: Text("Help/SOS"), backgroundColor: Colors.red[100], onPressed: () => _onSend(ChatMessage(user: _currentUser, createdAt: DateTime.now(), text: "SOS"))),
               ],
             ),
           ),
           Expanded(
             child: DashChat(
                currentUser: _currentUser,
                onSend: _onSend,
                messages: _messages,
                messageOptions: MessageOptions(
                  messageTextBuilder: (message, previousMessage, nextMessage) => _messageBuilder(message), // Custom builder hack or use standard builder if DashChat supports it
                  // Actually DashChat2 simplifies this, let's just use messageTextBuilder or custom property rendering if available.
                  // Since _messageBuilder returns a Widget (Column), messageTextBuilder expects Widget.
                ),
                inputOptions: InputOptions(
                  alwaysShowSend: true,
                  trailing: _voiceMode ? [
                     IconButton(
                       icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.blue),
                       onPressed: _isListening ? _stopListening : _startListening,
                     )
                  ] : null,
                ),
              ),
           ),
        ],
      ),
    );
  }
}
