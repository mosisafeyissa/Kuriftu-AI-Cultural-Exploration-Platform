class Country {
  final String id;
  final String name;
  final String code;
  final String flagEmoji;
  final String image;

  const Country({
    required this.id,
    required this.name,
    this.code = '',
    this.flagEmoji = '',
    this.image = '',
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id']?.toString() ?? '0',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        image: json['image'] ?? json['image_url'] ?? '',
      );
}
