class Country {
  final String id;
  final String name;
  final String code;
  final String flagEmoji;
  final String imageUrl;

  const Country({
    required this.id,
    required this.name,
    this.code = '',
    this.flagEmoji = '',
    this.imageUrl = '',
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id']?.toString() ?? '0',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        imageUrl: json['image_url'] ?? '',
      );
}
