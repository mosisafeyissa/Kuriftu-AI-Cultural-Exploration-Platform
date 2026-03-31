import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artifact.dart';
import '../models/villa.dart';
import '../models/country.dart';
import '../models/order.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static bool useMockData = true;

  // ── Mock Data ──────────────────────────────────────────────────────────────

  static final List<Country> _mockCountries = [
    const Country(id: '1', name: 'Ethiopia', code: 'ET', flagEmoji: '\u{1F1EA}\u{1F1F9}'),
    const Country(id: '2', name: 'Morocco', code: 'MA', flagEmoji: '\u{1F1F2}\u{1F1E6}'),
    const Country(id: '3', name: 'Nigeria', code: 'NG', flagEmoji: '\u{1F1F3}\u{1F1EC}'),
  ];

  static final List<Villa> _mockVillas = [
    const Villa(id: '1', name: 'Ethiopian Heritage Villa', countryId: '1', countryName: 'Ethiopia', description: 'Inspired by the rock-hewn churches of Lalibela and the majestic Semien Mountains.', image: 'assets/images/villa_1.jpg'),
    const Villa(id: '2', name: 'Moroccan Riad Villa', countryId: '2', countryName: 'Morocco', description: 'A celebration of Zellige artistry, Riad architecture, and Saharan mystique.', image: 'assets/images/villa_2.jpg'),
    const Villa(id: '3', name: 'Nigerian Royal Villa', countryId: '3', countryName: 'Nigeria', description: 'A tribute to Yoruba royalty, vibrant beadwork, and ancestral tradition.', image: 'assets/images/villa_3.jpg'),
  ];

  static final List<Artifact> _mockArtifacts = [
    const Artifact(
      id: '1', name: 'Ethiopian Coffee Ceremony Table', countryId: '1', countryName: 'Ethiopia', villaId: '1',
      price: 189.99, image: 'assets/images/ethiopian_coffee_table.jpg',
      description: 'A low hand-carved wooden table central to the Ethiopian coffee ceremony, one of the world\'s oldest and most sacred rituals of hospitality.',
      storyTitle: 'The Heart of Buna',
      fullStory: 'The Ethiopian coffee ceremony is far more than a simple brewing of coffee \u2014 it is a sacred ritual of community, respect, and spiritual connection that has been practiced for over a thousand years. At the center of this ritual sits the Rekebot, or coffee ceremony table. Hand-carved from a single piece of acacia wood by master woodworkers in the highlands of Jimma, each table carries the fingerprint of its maker and the spirit of the forests from which it was born.\n\nThe ceremony itself unfolds in three rounds \u2014 Abol, Tona, and Bereka \u2014 each serving a deeper purpose: the first for pleasure, the second for contemplation, and the third for blessing. The table holds the Jebena (clay coffee pot), tiny handleless cups, and burning frankincense, transforming any room into a sanctuary of togetherness.\n\nIn Ethiopian culture, refusing an invitation to a coffee ceremony is considered deeply disrespectful, as it represents the highest form of friendship and hospitality.',
      materials: 'Hand-carved acacia wood, natural beeswax finish',
      culturalSignificance: 'Central to Ethiopian hospitality, the coffee table anchors a thousand-year-old ritual that binds communities and honors guests as family.',
    ),
    const Artifact(
      id: '2', name: 'Handwoven Mesob Basket', countryId: '1', countryName: 'Ethiopia', villaId: '1',
      price: 99.00, image: 'assets/images/mesob_basket.jpg',
      description: 'A traditional tall basket with a conical lid used to serve Injera, the centerpiece of every Ethiopian communal meal.',
      storyTitle: 'Woven Together',
      fullStory: 'The Mesob is far more than a serving vessel \u2014 it is a symbol of unity, communal identity, and the Ethiopian philosophy of "gursha," the act of feeding another with your own hand as an expression of love. Woven by women from the Gurage and Amhara communities using locally harvested grass and reeds, each Mesob takes weeks to complete.\n\nThe tight weave keeps the Injera warm and the stews beneath it fragrant. When the conical lid is lifted, it reveals a shared meal meant to be eaten together from a single platter \u2014 a practice that embodies the Ethiopian saying, "Those who eat from the same plate do not betray each other."',
      materials: 'Natural grass, woven reeds, traditional plant-based dyes',
      culturalSignificance: 'Embodies the Ethiopian philosophy of shared meals and community bonds, where eating together is an act of trust.',
    ),
    const Artifact(
      id: '3', name: 'Jimma Traditional Chair', countryId: '1', countryName: 'Ethiopia', villaId: '1',
      price: 150.00, image: 'assets/images/JimmaChair.jpg',
      description: 'A three-legged carved throne from the Jimma Kingdom, hand-sculpted from a single piece of Wanza wood by Oromo master craftsmen.',
      storyTitle: 'Throne of the Oromo Kings',
      fullStory: 'In the lush highlands of southwestern Ethiopia, the Jimma Kingdom once flourished as one of the most powerful Oromo monarchies. At the heart of its royal courts stood an iconic three-legged chair \u2014 carved from a single trunk of the sacred Wanza tree (Cordia africana) by master craftsmen whose skills were passed down through family lineages spanning centuries.\n\nThe three legs of this throne are far from arbitrary. They embody the Gadaa system\u2019s philosophy of balanced governance: the unity of elders, warriors, and spiritual leaders. No single leg can stand alone, just as no single pillar of society can govern without the others. Kings and clan elders sat upon these chairs during council gatherings, dispute resolutions, and the blessing ceremonies that marked the transition of power every eight years under the Gadaa cycle.\n\nThe Wanza wood was chosen for both its spiritual significance and remarkable durability. Oromo tradition holds that the Cordia africana tree is a living bridge between the earth and the sky, its deep roots grounding wisdom while its broad canopy shelters the community. The craftsmen who carved these thrones worked in sacred seclusion, shaping the raw trunk with hand-forged adzes and finishing it with natural oils pressed from local seeds.\n\nToday, the Jimma Traditional Chair stands as one of Ethiopia\u2019s most recognized cultural symbols \u2014 a testament to the Oromo people\u2019s sophisticated political philosophy and their mastery of form carved from nature.',
      materials: 'Single-piece Wanza (Cordia africana) hardwood, hand-oiled natural finish',
      culturalSignificance: 'Embodies the Oromo Gadaa system\u2019s philosophy of balanced governance \u2014 the three legs representing the unity of elders, warriors, and spiritual leaders.',
    ),
    const Artifact(
      id: '4', name: 'Moroccan Zellige Mosaic Table', countryId: '2', countryName: 'Morocco', villaId: '2',
      price: 349.00, image: 'assets/images/moroccan_zellige_table.webp',
      description: 'A stunning hand-cut geometric mosaic table showcasing the Zellige tilework art that has adorned Moroccan palaces for centuries.',
      storyTitle: 'Geometry of the Divine',
      fullStory: 'Zellige is an ancient Moroccan mosaic art form dating back to the 10th century, born in the city of Fez. Each tiny tile is hand-cut from larger glazed terracotta pieces using a traditional hammer and chisel technique called "taqshir." A single table can contain thousands of individual pieces, assembled face-down on a flat surface before being set with plaster.\n\nThe geometric patterns are not merely decorative \u2014 they are mathematical representations of infinity and divine order in Islamic philosophy. Because Islamic art avoids figurative representation, artisans channeled their creativity into increasingly complex geometric patterns, creating what scholars call "the most sophisticated mathematical art in human history."',
      materials: 'Hand-glazed terracotta tiles, wrought iron frame, lime plaster base',
      culturalSignificance: 'Represents the intersection of mathematics, spirituality, and art in Islamic tradition.',
    ),
    const Artifact(
      id: '5', name: 'Brass Hanging Lantern', countryId: '2', countryName: 'Morocco', villaId: '2',
      price: 120.00, image: 'assets/images/brass_lantern.png',
      description: 'An intricate pierced brass lantern casting mesmerizing light patterns, handcrafted in the copper souks of Marrakech.',
      storyTitle: 'Light of the Medina',
      fullStory: 'In the narrow, bustling souks of Marrakech, master metalworkers known as "seffarine" hammer, pierce, and shape brass into lanterns that transform ordinary light into something sacred. The pierced patterns allow candlelight to escape in geometric constellations that dance across the walls of riads and mosques alike.\n\nThese lanterns are not simply light sources \u2014 they are symbols of guidance and divine illumination in Moroccan culture. Hung in doorways, they are believed to welcome good spirits and ward off the evil eye.',
      materials: 'Hand-hammered brass, colored glass insets, copper wire accents',
      culturalSignificance: 'Symbolizes divine illumination and protection in Moroccan tradition.',
    ),
    const Artifact(
      id: '6', name: 'Berber Handwoven Carpet', countryId: '2', countryName: 'Morocco', villaId: '2',
      price: 499.00, image: 'assets/images/berber_carpet.webp',
      description: 'A thick wool carpet handwoven by Berber women of the Atlas Mountains, each pattern telling a personal story.',
      storyTitle: 'A Diary in Thread',
      fullStory: 'High in the Atlas Mountains, Berber women have been weaving carpets for over two thousand years. Unlike commercial production, each Berber rug is a deeply personal creation \u2014 the weaver encodes her life story, hopes, and prayers into the patterns. Diamond shapes represent femininity and protection, zigzag lines represent water and life, and the "evil eye" motif wards off misfortune.\n\nA single carpet can take three to six months to complete, with the wool hand-spun and dyed using natural pigments from saffron, indigo, henna, and pomegranate. No two Berber carpets are ever identical.',
      materials: '100% hand-spun sheep wool, natural plant-based dyes',
      culturalSignificance: 'Each carpet is a personal autobiography woven in thread, preserving Berber women\'s stories across generations.',
    ),
    const Artifact(
      id: '7', name: 'Yoruba Tribal Mask', countryId: '3', countryName: 'Nigeria', villaId: '3',
      price: 250.00, image: 'assets/images/yoruba_mask.webp',
      description: 'A ceremonial wooden mask carved to honor the Orishas, the divine intermediaries of Yoruba spiritual tradition.',
      storyTitle: 'Face of the Ancestors',
      fullStory: 'Yoruba masks are among the most powerful objects in West African spiritual tradition. They are not art in the Western sense \u2014 they are spiritual technology. When a dancer wears a consecrated mask during the Egungun festival, they cease to be human; they become a vessel for the ancestors.\n\nMaster carvers work in sacred seclusion, often guided by dreams sent by the Orishas. The exaggerated features \u2014 large eyes for spiritual sight, elongated forms for dignity \u2014 are intentional. Each line and curve serves a metaphysical purpose, acting as a bridge between the world of the living and the realm of the ancestors.',
      materials: 'Iroko hardwood, natural earth pigments, palm oil finish',
      culturalSignificance: 'Serves as a bridge between the living and ancestral realms in Yoruba spiritual practice.',
    ),
    const Artifact(
      id: '8', name: 'Carved Wooden Stool', countryId: '3', countryName: 'Nigeria', villaId: '3',
      price: 80.00, image: 'assets/images/wooden_stool.webp',
      description: 'A solid wood stool carved from a single piece of iroko, traditionally reserved for village elders and chiefs.',
      storyTitle: 'The Elder\'s Seat',
      fullStory: 'In Yoruba society, the stool is far more than furniture \u2014 it is a symbol of authority, wisdom, and the right to speak. Only elders and titled chiefs sit on carved stools during community gatherings; younger members sit on the ground or on mats as a sign of respect.\n\nCarved from a single block of iroko wood (considered sacred due to its longevity), each stool features motifs that indicate the owner\'s rank and lineage. The act of "giving someone a stool" is a metaphor for bestowing authority.',
      materials: 'Single-piece iroko hardwood, hand-oiled finish',
      culturalSignificance: 'Represents authority, wisdom, and the elder\'s sacred right to counsel the community.',
    ),
    const Artifact(
      id: '9', name: 'Beaded Royal Chair', countryId: '3', countryName: 'Nigeria', villaId: '3',
      price: 900.00, image: 'assets/images/beaded_royal_chair.webp',
      description: 'An intricately beaded throne-chair reserved for Yoruba royalty, taking months of painstaking artistry to complete.',
      storyTitle: 'Throne of Glass & Light',
      fullStory: 'The beaded chair is the pinnacle of Yoruba artistic achievement and royal authority. Reserved exclusively for the Oba (king) and high-ranking chiefs, these chairs are covered in thousands of tiny glass beads imported along ancient trans-Saharan trade routes, then hand-sewn in patterns that encode the ruler\'s lineage, achievements, and divine mandate.\n\nThe beadwork tradition dates back centuries. Each color carries meaning: white for Obatala (purity and creation), blue for Yemoja (the ocean mother), red for Shango (thunder and justice). Creating a single chair can take three to six months of continuous work by the kingdom\'s most skilled artisans.',
      materials: 'Hand-sewn glass beads, carved wood frame, cotton thread base',
      culturalSignificance: 'The ultimate seat of power in Yoruba culture, encoding the king\'s divine authority in beads of light.',
    ),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<List<Country>> getCountries() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockCountries;
    }
    final response = await http.get(Uri.parse('$_baseUrl/countries/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Country.fromJson(e)).toList();
    }
    throw Exception('Failed to load countries');
  }

  static Future<List<Villa>> getVillas() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockVillas;
    }
    final response = await http.get(Uri.parse('$_baseUrl/villas/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Villa.fromJson(e)).toList();
    }
    throw Exception('Failed to load villas');
  }

  static Future<List<Artifact>> getArtifacts({String? countryId, String? villaId}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var list = _mockArtifacts;
      if (countryId != null) list = list.where((a) => a.countryId == countryId).toList();
      if (villaId != null) list = list.where((a) => a.villaId == villaId).toList();
      return list;
    }
    final params = <String, String>{};
    if (countryId != null) params['country'] = countryId;
    if (villaId != null) params['villa'] = villaId;
    final uri = Uri.parse('$_baseUrl/artifacts/').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = (data['results'] as List?) ?? (data as List);
      return results.map((e) => Artifact.fromApiJson(e)).toList();
    }
    throw Exception('Failed to load artifacts');
  }

  static Future<Artifact> getArtifactById(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockArtifacts.firstWhere((a) => a.id == id);
    }
    final response = await http.get(Uri.parse('$_baseUrl/artifacts/$id/'));
    if (response.statusCode == 200) {
      return Artifact.fromApiJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load artifact');
  }

  static Future<Order> createOrder({
    required String artifactId,
    required String email,
    required int quantity,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 2));
      return Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        artifactId: artifactId,
        userEmail: email,
        quantity: quantity,
        status: 'Pending',
        createdAt: DateTime.now(),
      );
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/order/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'artifact': int.tryParse(artifactId) ?? 0,
        'user_email': email,
        'quantity': quantity,
      }),
    );
    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create order: ${response.body}');
  }

  static Future<List<Order>> getOrders({required String email}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return [];
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/').replace(queryParameters: {'email': email}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = (data is List) ? data : (data['results'] as List? ?? []);
      return results.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception('Failed to load orders');
  }

  static List<Artifact> get mockArtifacts => _mockArtifacts;
  static List<Villa> get mockVillas => _mockVillas;
  static List<Country> get mockCountries => _mockCountries;
}
