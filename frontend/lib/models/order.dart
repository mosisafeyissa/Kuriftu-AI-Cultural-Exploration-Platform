class Order {
  final String id;
  final String artifactId;
  final String userEmail;
  final int quantity;
  final String status;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.artifactId,
    required this.userEmail,
    this.quantity = 1,
    this.status = 'Pending',
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? '0',
        artifactId: json['artifact']?.toString() ?? '',
        userEmail: json['user_email'] ?? '',
        quantity: json['quantity'] ?? 1,
        status: json['status'] ?? 'Pending',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'artifact': int.tryParse(artifactId) ?? 0,
        'user_email': userEmail,
        'quantity': quantity,
      };
}
