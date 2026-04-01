import 'artifact.dart';

class VillaSection {
  final String id;
  final String name;
  final int order;
  final String description;
  final String narrative;
  final String? imageUrl;
  final List<Artifact> artifacts;

  const VillaSection({
    required this.id,
    required this.name,
    this.order = 0,
    this.description = '',
    this.narrative = '',
    this.imageUrl,
    this.artifacts = const [],
  });

  factory VillaSection.fromJson(Map<String, dynamic> json) {
    final artifactsList = (json['artifacts'] as List<dynamic>?)
        ?.map((a) => Artifact.fromApiJson(a as Map<String, dynamic>))
        .toList() ?? [];

    return VillaSection(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      description: json['description'] ?? '',
      narrative: json['narrative'] ?? '',
      imageUrl: json['image'] ?? json['image_url'],
      artifacts: artifactsList,
    );
  }
}
