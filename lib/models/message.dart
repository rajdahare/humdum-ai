enum Sender { user, ai }

class Message {
  final String id;
  final String text;
  final DateTime createdAt;
  final Sender sender;

  Message({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.sender,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'sender': sender.name,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sender: (json['sender'] as String) == 'user' ? Sender.user : Sender.ai,
      );
}


