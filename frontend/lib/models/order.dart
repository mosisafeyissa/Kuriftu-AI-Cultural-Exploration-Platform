class Order {
  final String id;
  final String artifactId;
  final String artifactName;
  final String userEmail;
  final int quantity;
  final String status;
  final double totalAmount;
  final String paymentStatus;
  final String? txRef;
  final String? checkoutUrl;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.artifactId,
    this.artifactName = '',
    required this.userEmail,
    this.quantity = 1,
    this.status = 'Pending',
    this.totalAmount = 0,
    this.paymentStatus = 'unpaid',
    this.txRef,
    this.checkoutUrl,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? '0',
        artifactId: json['artifact']?.toString() ?? '',
        artifactName: json['artifact_name'] ?? '',
        userEmail: json['user_email'] ?? '',
        quantity: json['quantity'] ?? 1,
        status: json['status'] ?? 'Pending',
        totalAmount:
            double.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
        paymentStatus: json['payment_status'] ?? 'unpaid',
        txRef: json['tx_ref'],
        checkoutUrl: json['checkout_url'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'artifact': int.tryParse(artifactId) ?? 0,
        'user_email': userEmail,
        'quantity': quantity,
      };

  bool get isPaid => paymentStatus == 'paid';
  bool get hasCheckoutUrl => checkoutUrl != null && checkoutUrl!.isNotEmpty;
}
