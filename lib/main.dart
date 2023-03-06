import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatAppState createState() => _ChatAppState();
}

// Write a [Message] class that has author, timestamp, nad content fields.
class Message {
  final String author;
  final String content;
  final DateTime timestamp;

  Message(this.author, this.content, this.timestamp);
}

// Write a [MessageParmas] class that has role, content
class MessageParams {
  final String role;
  final String content;
  toJson() => {'role': role, 'content': content};

  MessageParams(this.role, this.content);
}

class _ChatAppState extends State<ChatApp> {
  final List<Message> _messages = [];
  // q: 下面有一个错误，Error: Converting object to an encodable object failed: Instance of 'MessageParams'
  // a: 因为MessageParams不是一个基本类型，所以需要在MessageParams类中添加toJson方法

  final List<MessageParams> _messageParams = [];
  final TextEditingController _textController = TextEditingController();

  Future<String> getBotResponse(String message) async {
    var url = Uri.parse('https://api.openai.com/v1/chat/completions');
    _messageParams.add(MessageParams('user', message));
    var response = await http.post(url,
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
          'Authorization': 'Bearer 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',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': _messageParams,
        }));

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes));
      var result = data['choices'][0]['message']['content'].toString();
      _messageParams.add(MessageParams('assistant', result));
      return result;
    } else {
      return 'Error getting bot response';
    }
  }

  void _handleSubmitted(Message text) async {
    _textController.clear();

    setState(() {
      _messages.insert(0, text);
    });

    String response = await getBotResponse(text.content);
    setState(() {
      _messages.insert(0, Message('Bot', response.trim(), DateTime.now()));
    });
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (String text) =>
                      _handleSubmitted(Message('User', text, DateTime.now())),
                  decoration:
                      const InputDecoration.collapsed(hintText: 'Send a message'),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _handleSubmitted(Message('User', _textController.text, DateTime.now())),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT App',
      home: Scaffold(
        appBar: AppBar(title: const Text('ChatGPT App')),
        body: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) =>
                    _buildListItem(_messages[index]),
                itemCount: _messages.length,
              ),
            ),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Message message) {
    // show an avatar for the user and the bot, use Icons.person and Icons.android
    // for the user and the bot respectively
    return ListTile(
      title: Text(message.content),
      subtitle: Text(_formatTimestamp(message.timestamp)),
      leading: CircleAvatar(
        backgroundColor: message.author == 'User' ? Colors.blue : Colors.green,
        child: Icon(
          message.author == 'User' ? Icons.person : Icons.android,
          color: Colors.white,
        ),
      ),
    );
  }

  // convert the timestamp to a human readable format, e.g. "2 minutes ago"
  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
