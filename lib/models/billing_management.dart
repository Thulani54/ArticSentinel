class BillingManagement {
  int id; // Assuming you want an identifier for the transaction
  String type;
  DateTime sentDate;
  String description;
  double amount;
  String recipients;
  DateTime dueDate;
  String status;

  BillingManagement({
    required this.id,
    required this.type,
    required this.sentDate,
    required this.description,
    required this.amount,
    required this.recipients,
    required this.dueDate,
    required this.status,
  });

  // Method to convert the model to a Map (for JSON serialization)
  factory BillingManagement.fromMap(Map<String, dynamic> map) {
    return BillingManagement(
      id: map['id'] ?? 0,
      type: map['type'] ?? "",
      sentDate: DateTime.parse(map['sentDate']),
      description: map['description'] ?? "",
      amount: map['amount'] ?? 0.0,
      recipients: map['recipients'] ?? "",
      dueDate: DateTime.parse(map['dueDate']),
      status: map['status'] ?? "",
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sentDate': sentDate.toIso8601String(),
      'description': description,
      'amount': amount,
      'recipients': recipients,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
    };
  }

  // Method to create a Transaction from a Map
}
