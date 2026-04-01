import 'villa_section.dart';

class VillaGuide {
  final String id;
  final String name;
  final String countryId;
  final String countryName;
  final String countryCode;
  final String location;
  final String imageUrl;
  final String qrCode;
  final String welcomeStory;
  final List<String> culturalHighlights;
  final String designPhilosophy;
  final List<VillaSection> sections;
  final String language;

  const VillaGuide({
    required this.id,
    required this.name,
    this.countryId = '',
    this.countryName = '',
    this.countryCode = '',
    this.location = '',
    this.imageUrl = '',
    this.qrCode = '',
    this.welcomeStory = '',
    this.culturalHighlights = const [],
    this.designPhilosophy = '',
    this.sections = const [],
    this.language = 'en',
  });

  factory VillaGuide.fromJson(Map<String, dynamic> json) {
    final country = json['country'] as Map<String, dynamic>?;
    final sectionsList = (json['sections'] as List<dynamic>?)
        ?.map((s) => VillaSection.fromJson(s as Map<String, dynamic>))
        .toList() ?? [];

    final highlights = (json['cultural_highlights'] as List<dynamic>?)
        ?.map((h) => h.toString())
        .toList() ?? [];

    return VillaGuide(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? '',
      countryId: country?['id']?.toString() ?? '',
      countryName: country?['name'] ?? '',
      countryCode: country?['code'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['image'] ?? json['image_url'] ?? '',
      qrCode: json['qr_code'] ?? '',
      welcomeStory: json['welcome_story'] ?? '',
      culturalHighlights: highlights,
      designPhilosophy: json['design_philosophy'] ?? '',
      sections: sectionsList,
      language: json['language'] ?? 'en',
    );
  }
}
