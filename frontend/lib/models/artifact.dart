class Artifact {
  final String id;
  final String name;
  final String countryId;
  final String countryName;
  final String villaId;
  final String villaName;
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
    this.villaName = '',
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

  /// Parse from the AI scan endpoint response.
  /// Response format: { "status": "success", "data": { ... }, "similarity": 0.82 }
  factory Artifact.fromScanJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final story = data['story'] as Map<String, dynamic>?;
    final similarity = (json['similarity'] as num?)?.toDouble();

    return Artifact(
      id: data['id']?.toString() ?? data['artifact_id']?.toString() ?? '0',
      name: data['name'] ?? data['artifact_name'] ?? 'Unknown Artifact',
      countryId: '',
      countryName: data['country'] ?? 'Unknown',
      price: double.tryParse(data['price']?.toString() ?? '') ?? 0.0,
      image: data['image'] ?? data['image_url'] ?? '',
      description: data['description'] ?? story?['story'] ?? '',
      storyTitle: story?['title'] ?? 'The Story of ${data['name'] ?? data['artifact_name']}',
      fullStory: story?['story'] ?? '',
      materials: story?['materials'] ?? 'Traditional materials',
      culturalSignificance: story?['cultural_significance'] ?? '',
      isAiGenerated: story?['ai_generated'] ?? false,
      confidence: similarity ?? (json['confidence'] as num?)?.toDouble(),
    );
  }

  /// Parse from the REST API list/detail endpoints.
  /// Response format: { "id": 1, "name": "...", "country": {...}, "villa": {...}, "story": {...} }
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
      villaName: villa?['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      image: json['image'] ?? json['image_url'] ?? '',
      description: json['description'] ?? '',
      storyTitle: story?['title'] ?? '',
      fullStory: story?['story'] ?? '',
      materials: story?['materials'] ?? '',
      culturalSignificance: story?['cultural_significance'] ?? '',
      isAiGenerated: story?['ai_generated'] ?? false,
    );
  }
}
