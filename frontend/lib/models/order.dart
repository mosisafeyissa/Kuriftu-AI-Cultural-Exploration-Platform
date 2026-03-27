class Order {
  final String id;
  final String guestEmail;
  final String artifactId;
  final int quantity;
  final String status;

  Order({
    required this.id,
    required this.guestEmail,
    required this.artifactId,
    required this.quantity,
    this.status = "Pending",
  });
}
