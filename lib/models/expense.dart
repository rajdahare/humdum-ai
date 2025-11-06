class Expense {
  final String id;
  final double amount;
  final String category; // personal | company
  final String? note;
  final String? photoPath;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
      };
}


