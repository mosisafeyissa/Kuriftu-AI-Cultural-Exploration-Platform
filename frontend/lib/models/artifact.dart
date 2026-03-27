class Artifact {
  final String id;
  final String name;
  final String countryId;
  final String villaId;
  final double price;
  final String image;
  final String description;
  
  // Extra fields for scan result feature requirements
  final String fullStory;
  final String materials;
  final String culturalMeaning;

  Artifact({
    required this.id,
    required this.name,
    required this.countryId,
    required this.villaId,
    required this.price,
    required this.image,
    required this.description,
    this.fullStory = "A carefully preserved artifact reflecting centuries of history.",
    this.materials = "Traditional materials",
    this.culturalMeaning = "Holds deep local significance.",
  });
}
