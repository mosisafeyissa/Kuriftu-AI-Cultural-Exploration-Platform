import '../models/country.dart';
import '../models/villa.dart';
import '../models/artifact.dart';

class ApiService {
  static final List<Country> mockCountries = [
    Country(id: '1', name: 'Ethiopia', description: 'Land of Origins', flagImage: '🇪🇹'),
    Country(id: '2', name: 'Morocco', description: 'Kingdom of Light', flagImage: '🇲🇦'),
    Country(id: '3', name: 'Nigeria', description: 'Giant of Africa', flagImage: '🇳🇬'),
    Country(id: '4', name: 'Kenya', description: 'Pride of Africa', flagImage: '🇰🇪'),
  ];

  static final List<Villa> mockVillas = [
    Villa(id: '1', name: 'Ethiopian Villa', countryId: '1', description: 'Urban retreat', image: 'assets/images/villa_1.jpg'),
    Villa(id: '2', name: 'Moroccan Villa', countryId: '2', description: 'Historic center', image: 'assets/images/villa_2.jpg'),
    Villa(id: '3', name: 'Nigerian Villa', countryId: '3', description: 'Modern fusion', image: 'assets/images/villa_3.jpg'),
    Villa(id: '4', name: 'Kenyan Villa', countryId: '4', description: 'Savanna getaway', image: 'assets/images/villa_4.jpg'),
  ];

  static final List<Artifact> mockArtifacts = [
    Artifact(
      id: '1',
      name: 'Ethiopian Coffee Table',
      countryId: '1',
      villaId: '1',
      price: 189.99,
      image: 'assets/images/ethiopian_coffee_table.jpg',
      description: 'A low hand-carved wooden table central to the Ethiopian coffee ceremony.',
      fullStory: 'The coffee ceremony table anchors one of the world\'s oldest coffee rituals...',
      materials: 'Hand-carved acacia wood, beeswax',
      culturalMeaning: 'Central to Ethiopian hospitality, reflecting strong community bonds.',
    ),
    Artifact(
      id: '2',
      name: 'Handwoven Mesob Basket',
      countryId: '1',
      villaId: '1',
      price: 99.00,
      image: 'assets/images/mesob_basket.jpg',
      description: 'A traditional basket used to serve Injera.',
      fullStory: 'Woven with skill, passed down through generations...',
      materials: 'Natural grass, traditional dyes',
      culturalMeaning: 'A symbol of community feasts.',
    ),
    Artifact(
      id: '3',
      name: 'Traditional Harari Chair',
      countryId: '1',
      villaId: '1',
      price: 150.00,
      image: 'assets/images/harari_chair.avif',
      description: 'Handcrafted chair from Harar.',
      fullStory: 'Used in traditional Harari households.',
      materials: 'Wood, woven seating',
      culturalMeaning: 'A staple of Harari domestic life.',
    ),
    Artifact(
      id: '4',
      name: 'Moroccan Zellige Table',
      countryId: '2',
      villaId: '2',
      price: 349.00,
      image: 'assets/images/moroccan_zellige_table.webp',
      description: 'A hand-cut geometric mosaic table.',
      fullStory: 'Zellige is an ancient Moroccan tilework art...',
      materials: 'Glazed terracotta, iron frame',
      culturalMeaning: 'Represents Islamic geometric philosophy made physical.',
    ),
    Artifact(
      id: '5',
      name: 'Brass Hanging Lantern',
      countryId: '2',
      villaId: '2',
      price: 120.00,
      image: 'assets/images/brass_lantern.png',
      description: 'Intricate brass lantern for soft lighting.',
      fullStory: 'Crafted in the souks of Marrakech...',
      materials: 'Brass, stained glass',
      culturalMeaning: 'Symbolizes illuminating peace.',
    ),
    Artifact(
      id: '6',
      name: 'Berber Handwoven Carpet',
      countryId: '2',
      villaId: '2',
      price: 499.00,
      image: 'assets/images/berber_carpet.webp',
      description: 'A thick wool carpet woven by Berber artisans.',
      fullStory: 'Each rug tells the story of the weaver...',
      materials: '100% sheep wool, natural dyes',
      culturalMeaning: 'A diary woven in thread.',
    ),
    Artifact(
      id: '7',
      name: 'Yoruba Tribal Mask',
      countryId: '3',
      villaId: '3',
      price: 250.00,
      image: 'assets/images/yoruba_mask.webp',
      description: 'A traditional ceremonial mask.',
      fullStory: 'Carved to honor ancestral spirits...',
      materials: 'Carved wood, local pigments',
      culturalMeaning: 'Connects the living with their ancestors.',
    ),
    Artifact(
      id: '8',
      name: 'Carved Wooden Stool',
      countryId: '3',
      villaId: '3',
      price: 80.00,
      image: 'assets/images/wooden_stool.webp',
      description: 'Solid wood stool.',
      fullStory: 'Designed for chiefs and elders...',
      materials: 'Iroko wood',
      culturalMeaning: 'Authority and stability.',
    ),
    Artifact(
      id: '9',
      name: 'Beaded Royal Chair',
      countryId: '3',
      villaId: '3',
      price: 900.00,
      image: 'assets/images/beaded_royal_chair.webp',
      description: 'Intricately beaded chair for royalty.',
      fullStory: 'Takes months to complete the beadwork...',
      materials: 'Glass beads, wood frame',
      culturalMeaning: 'A seat of ultimate power in Yoruba culture.',
    ),
  ];

  static Future<List<Country>> getCountries() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockCountries;
  }

  static Future<List<Villa>> getVillas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockVillas;
  }

  static Future<List<Artifact>> getArtifacts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockArtifacts;
  }
}
