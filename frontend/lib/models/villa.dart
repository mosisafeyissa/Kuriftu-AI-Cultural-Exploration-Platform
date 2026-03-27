class Villa {
  final String id;
  final String name;
  final String countryId;
  final String description;
  final String image;

  Villa({
    required this.id,
    required this.name,
    required this.countryId,
    required this.description,
    this.image = 'assets/images/villa_1.jpg',
  });
}
