class Villa {
  final String id;
  final String name;
  final String countryId;
  final String countryName;
  final String description;
  final String image;

  const Villa({
    required this.id,
    required this.name,
    this.countryId = '',
    this.countryName = '',
    this.description = '',
    required this.image,
  });

  factory Villa.fromJson(Map<String, dynamic> json) {
    final country = json['country'] as Map<String, dynamic>?;
    return Villa(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? '',
      countryId: country?['id']?.toString() ?? '',
      countryName: country?['name'] ?? '',
      description: json['location'] ?? '',
      image: json['image'] ?? json['image_url'] ?? '',
    );
  }
}
