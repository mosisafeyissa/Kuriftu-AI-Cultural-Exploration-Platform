class Artifact {
  final String id;
  final String name;
  final String countryId;
  final String countryName;
  final String villaId;
  final double price;
  final String image;
  final String description;
  final String storyTitle;
  final String fullStory;
  final String materials;
  final String culturalSignificance;
  final bool isAiGenerated;
  final double? confidence;

  const Artifact({
    required this.id,
    required this.name,
    required this.countryId,
    this.countryName = '',
    this.villaId = '',
    required this.price,
    required this.image,
    required this.description,
    this.storyTitle = '',
    this.fullStory = 'A carefully preserved artifact reflecting centuries of history.',
    this.materials = 'Traditional materials',
    this.culturalSignificance = 'Holds deep local significance.',
    this.isAiGenerated = false,
    this.confidence,
  });

  factory Artifact.fromScanJson(Map<String, dynamic> json) {
    final story = json['story'] as Map<String, dynamic>?;
    return Artifact(
      id: json['artifact_id']?.toString() ?? '0',
      name: json['name'] ?? json['artifact_name'] ?? 'Unknown Artifact',
      countryId: '',
      countryName: json['country'] ?? 'Unknown',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      image: json['image_url'] ?? '',
      description: story?['story'] ?? '',
      storyTitle: story?['title'] ?? 'The Story of ${json['name'] ?? json['artifact_name']}',
      fullStory: story?['story'] ?? '',
      materials: json['materials'] ?? story?['materials'] ?? 'Traditional materials',
      culturalSignificance: json['cultural_significance'] ?? story?['cultural_significance'] ?? '',
      isAiGenerated: story?['ai_generated'] ?? false,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  factory Artifact.fromApiJson(Map<String, dynamic> json) {
    final story = json['story'] as Map<String, dynamic>?;
    final country = json['country'] as Map<String, dynamic>?;
    final villa = json['villa'] as Map<String, dynamic>?;
    return Artifact(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? '',
      countryId: country?['id']?.toString() ?? '',
      countryName: country?['name'] ?? '',
      villaId: villa?['id']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      image: json['image_url'] ?? '',
      description: json['description'] ?? '',
      storyTitle: story?['title'] ?? '',
      fullStory: story?['story'] ?? '',
      materials: story?['materials'] ?? '',
      culturalSignificance: story?['cultural_significance'] ?? '',
      isAiGenerated: story?['ai_generated'] ?? false,
    );
  }
}
