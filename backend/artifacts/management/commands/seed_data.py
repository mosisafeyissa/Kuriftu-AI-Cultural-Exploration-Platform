"""
Management command to seed the database with sample cultural data.

Usage:
    python manage.py seed_data
    python manage.py seed_data --clear   # wipe existing data first
"""

from django.core.management.base import BaseCommand
from artifacts.models import Country, Villa, Artifact, Story
from orders.models import Order


SEED = {
    "countries": [
        {"name": "Ethiopia", "code": "ET", "image_url": ""},
        {"name": "Morocco", "code": "MA", "image_url": ""},
        {"name": "Nigeria", "code": "NG", "image_url": ""},
    ],
    "villas": [
        {
            "name": "Ethiopian Heritage Villa",
            "country_code": "ET",
            "location": "Inspired by the rock-hewn churches of Lalibela and the majestic Semien Mountains.",
            "image_url": "villas/Afrcan_village_3-1.webp",
        },
        {
            "name": "Moroccan Riad Villa",
            "country_code": "MA",
            "location": "A celebration of Zellige artistry, Riad architecture, and Saharan mystique.",
            "image_url": "villas/moroccan_zellige_table.webp",
        },
        {
            "name": "Nigerian Royal Villa",
            "country_code": "NG",
            "location": "A tribute to Yoruba royalty, vibrant beadwork, and ancestral tradition.",
            "image_url": "villas/beaded_royal_chair.webp",
        },
    ],
    "artifacts": [
        # ── Ethiopia ──
        {
            "name": "Ethiopian Coffee Ceremony Table",
            "country_code": "ET",
            "villa_name": "Ethiopian Heritage Villa",
            "description": "A low hand-carved wooden table central to the Ethiopian coffee ceremony, one of the world's oldest and most sacred rituals of hospitality.",
            "price": 189.99,
            "image_url": "scans/scaled_berber_carpet.webp",
            "image_path": "scans/scaled_berber_carpet.webp",
            "story": {
                "title": "The Heart of Buna",
                "story": "The Ethiopian coffee ceremony is far more than a simple brewing of coffee — it is a sacred ritual of community, respect, and spiritual connection that has been practiced for over a thousand years. At the center of this ritual sits the Rekebot, or coffee ceremony table.",
                "materials": "Hand-carved acacia wood, natural beeswax finish",
                "cultural_significance": "Central to Ethiopian hospitality, the coffee table anchors a thousand-year-old ritual that binds communities and honors guests as family.",
            },
        },
        {
            "name": "Handwoven Mesob Basket",
            "country_code": "ET",
            "villa_name": "Ethiopian Heritage Villa",
            "description": "A traditional tall basket with a conical lid used to serve Injera, the centerpiece of every Ethiopian communal meal.",
            "price": 99.00,
            "image_url": "scans/scaled_yoruba_mask.webp",
            "image_path": "scans/scaled_yoruba_mask.webp",
            "story": {
                "title": "Woven Together",
                "story": "The Mesob is far more than a serving vessel — it is a symbol of unity, communal identity, and the Ethiopian philosophy of 'gursha,' the act of feeding another with your own hand as an expression of love.",
                "materials": "Natural grass, woven reeds, traditional plant-based dyes",
                "cultural_significance": "Embodies the Ethiopian philosophy of shared meals and community bonds, where eating together is an act of trust.",
            },
        },
        {
            "name": "Jimma Traditional Chair",
            "country_code": "ET",
            "villa_name": "Ethiopian Heritage Villa",
            "description": "A three-legged carved throne from the Jimma Kingdom, hand-sculpted from a single piece of Wanza wood by Oromo master craftsmen.",
            "price": 150.00,
            "image_url": "villas/wooden_stool.webp",
            "image_path": "villas/wooden_stool.webp",
            "story": {
                "title": "Throne of the Oromo Kings",
                "story": "In the lush highlands of southwestern Ethiopia, the Jimma Kingdom once flourished as one of the most powerful Oromo monarchies. At the heart of its royal courts stood an iconic three-legged chair.",
                "materials": "Single-piece Wanza (Cordia africana) hardwood, hand-oiled natural finish",
                "cultural_significance": "Embodies the Oromo Gadaa system's philosophy of balanced governance — the three legs representing the unity of elders, warriors, and spiritual leaders.",
            },
        },
        # ── Morocco ──
        {
            "name": "Moroccan Zellige Mosaic Table",
            "country_code": "MA",
            "villa_name": "Moroccan Riad Villa",
            "description": "A stunning hand-cut geometric mosaic table showcasing the Zellige tilework art that has adorned Moroccan palaces for centuries.",
            "price": 349.00,
            "image_url": "villas/moroccan_zellige_table.webp",
            "image_path": "villas/moroccan_zellige_table.webp",
            "story": {
                "title": "Geometry of the Divine",
                "story": "Zellige is an ancient Moroccan mosaic art form dating back to the 10th century, born in the city of Fez. Each tiny tile is hand-cut using a traditional hammer and chisel technique called 'taqshir.'",
                "materials": "Hand-glazed terracotta tiles, wrought iron frame, lime plaster base",
                "cultural_significance": "Represents the intersection of mathematics, spirituality, and art in Islamic tradition.",
            },
        },
        {
            "name": "Brass Hanging Lantern",
            "country_code": "MA",
            "villa_name": "Moroccan Riad Villa",
            "description": "An intricate pierced brass lantern casting mesmerizing light patterns, handcrafted in the copper souks of Marrakech.",
            "price": 120.00,
            "image_url": "villas/berber_carpet.webp",
            "image_path": "villas/berber_carpet.webp",
            "story": {
                "title": "Light of the Medina",
                "story": "In the narrow, bustling souks of Marrakech, master metalworkers known as 'seffarine' hammer, pierce, and shape brass into lanterns that transform ordinary light into something sacred.",
                "materials": "Hand-hammered brass, colored glass insets, copper wire accents",
                "cultural_significance": "Symbolizes divine illumination and protection in Moroccan tradition.",
            },
        },
        {
            "name": "Berber Handwoven Carpet",
            "country_code": "MA",
            "villa_name": "Moroccan Riad Villa",
            "description": "A thick wool carpet handwoven by Berber women of the Atlas Mountains, each pattern telling a personal story.",
            "price": 499.00,
            "image_url": "scans/scaled_berber_carpet.webp",
            "image_path": "scans/scaled_berber_carpet.webp",
            "story": {
                "title": "A Diary in Thread",
                "story": "High in the Atlas Mountains, Berber women have been weaving carpets for over two thousand years. Unlike commercial production, each Berber rug is a deeply personal creation.",
                "materials": "100% hand-spun sheep wool, natural plant-based dyes",
                "cultural_significance": "Each carpet is a personal autobiography woven in thread, preserving Berber women's stories across generations.",
            },
        },
        # ── Nigeria ──
        {
            "name": "Yoruba Tribal Mask",
            "country_code": "NG",
            "villa_name": "Nigerian Royal Villa",
            "description": "A ceremonial wooden mask carved to honor the Orishas, the divine intermediaries of Yoruba spiritual tradition.",
            "price": 250.00,
            "image_url": "scans/scaled_yoruba_mask.webp",
            "image_path": "scans/scaled_yoruba_mask.webp",
            "story": {
                "title": "Face of the Ancestors",
                "story": "Yoruba masks are among the most powerful objects in West African spiritual tradition. They are not art in the Western sense — they are spiritual technology.",
                "materials": "Iroko hardwood, natural earth pigments, palm oil finish",
                "cultural_significance": "Serves as a bridge between the living and ancestral realms in Yoruba spiritual practice.",
            },
        },
        {
            "name": "Carved Wooden Stool",
            "country_code": "NG",
            "villa_name": "Nigerian Royal Villa",
            "description": "A solid wood stool carved from a single piece of iroko, traditionally reserved for village elders and chiefs.",
            "price": 80.00,
            "image_url": "villas/wooden_stool.webp",
            "image_path": "villas/wooden_stool.webp",
            "story": {
                "title": "The Elder's Seat",
                "story": "In Yoruba society, the stool is far more than furniture — it is a symbol of authority, wisdom, and the right to speak.",
                "materials": "Single-piece iroko hardwood, hand-oiled finish",
                "cultural_significance": "Represents authority, wisdom, and the elder's sacred right to counsel the community.",
            },
        },
        {
            "name": "Beaded Royal Chair",
            "country_code": "NG",
            "villa_name": "Nigerian Royal Villa",
            "description": "An intricately beaded throne-chair reserved for Yoruba royalty, taking months of painstaking artistry to complete.",
            "price": 900.00,
            "image_url": "scans/scaled_beaded_royal_chair.webp",
            "image_path": "scans/scaled_beaded_royal_chair.webp",
            "story": {
                "title": "Throne of Glass & Light",
                "story": "The beaded chair is the pinnacle of Yoruba artistic achievement and royal authority. Reserved exclusively for the Oba (king) and high-ranking chiefs.",
                "materials": "Hand-sewn glass beads, carved wood frame, cotton thread base",
                "cultural_significance": "The ultimate seat of power in Yoruba culture, encoding the king's divine authority in beads of light.",
            },
        },
    ],
}

VILLA_GUIDE_DATA = {
    "Ethiopian Heritage Villa": {
        "welcome_story": "Welcome to the Ethiopian Heritage Villa — a living portal to one of Africa's oldest civilizations. As you step through the threshold, you are not merely entering a room; you are crossing into three thousand years of unbroken cultural tradition. Every surface, every artifact, and every scent in this villa tells a story of the Ethiopian highlands — from the ancient Aksumite kingdoms to the vibrant ceremonies still practiced today. Let the warm aroma of freshly roasted coffee and the gentle glow of handwoven textiles guide your journey through the heart of Ethiopia.",
        "cultural_highlights": [
            "Ethiopia is the birthplace of coffee — the Buna ceremony dates back over 1,000 years",
            "Home to 9 UNESCO World Heritage Sites including the rock-hewn churches of Lalibela",
            "The only African nation never colonized, preserving a unique cultural identity",
            "Ge'ez, the ancient Ethiopian script, is one of the oldest alphabets still in use",
            "The Ethiopian calendar has 13 months — 12 months of 30 days and a 13th month of 5-6 days"
        ],
        "design_philosophy": "This villa draws inspiration from the rock-hewn architecture of Lalibela and the traditional Tukul roundhouses of the Ethiopian highlands. Natural materials — acacia wood, handwoven cotton, and volcanic stone — create an authentic atmosphere. The circular motifs echo the communal dining tradition, while the earth tones reflect the Semien Mountains at sunset.",
        "sections": [
            {
                "name": "The Welcome Hall",
                "order": 1,
                "description": "The entrance space adorned with traditional Ethiopian crosses and woven tapestries.",
                "narrative": "As you enter the Welcome Hall, notice the large Ethiopian Orthodox cross hanging above the doorway — a symbol of faith and protection that has guided Ethiopian culture for over 1,600 years. The handwoven Shemma cloth draped along the walls tells the story of Ethiopia's master weavers, who have passed their craft down through generations in the town of Dorze. Each geometric pattern represents a family lineage, making every textile a wearable family tree."
            },
            {
                "name": "The Coffee Ceremony Room",
                "order": 2,
                "description": "A dedicated space for the ancient Ethiopian coffee ritual.",
                "narrative": "This is the soul of the villa. The Coffee Ceremony Room recreates the sacred Buna ritual that has been the heartbeat of Ethiopian social life for over a millennium. Sit on the traditional Medeb (woven seat) and imagine the three rounds of coffee — Abol, Tona, and Bereka — each carrying a deeper spiritual meaning. The frankincense and myrrh burning on the Mebkhar (incense burner) purify the air just as they have in Ethiopian homes for centuries. Here, coffee is not a beverage — it is a prayer, a council, and a celebration of community."
            },
            {
                "name": "The Dining Quarter",
                "order": 3,
                "description": "Traditional communal dining area centered around the Mesob basket.",
                "narrative": "In Ethiopia, meals are never eaten alone. The Dining Quarter embodies the philosophy of 'Gursha' — the tender act of feeding another person by hand as an expression of love and respect. At the center sits the Mesob, a towering handwoven basket that conceals the Injera (sourdough flatbread) and an array of colorful Wot (stews). When the conical lid is lifted, the shared meal beneath connects everyone at the table. As Ethiopians say: 'Those who eat from the same plate do not betray each other.'"
            },
            {
                "name": "The Royal Chamber",
                "order": 4,
                "description": "A resting space inspired by the thrones of the Jimma Kingdom.",
                "narrative": "The Royal Chamber draws its inspiration from the courts of the Jimma Kingdom and the Solomonic dynasty that shaped Ethiopian history. The three-legged Jimma Chair in the corner embodies the Gadaa system's philosophy of balanced governance — each leg representing elders, warriors, and spiritual leaders. The indigo-dyed fabrics and carved wooden panels echo the artistry of Oromo craftsmen who worked in sacred seclusion, transforming raw wood into symbols of power and unity."
            },
        ],
    },
    "Moroccan Riad Villa": {
        "welcome_story": "Welcome to the Moroccan Riad Villa — step into a world where geometry becomes poetry and silence speaks louder than words. This villa is modeled after the traditional Riads of Fez and Marrakech, where every surface is a canvas of Zellige mosaic tilework, carved cedarwood, and flowing Zouak plasterwork. The central courtyard, open to the sky, represents the Moroccan belief that paradise can be found within the walls of a beautiful home. Let the sound of trickling water from the mosaic fountain guide your senses through this Maghreb masterpiece.",
        "cultural_highlights": [
            "Moroccan Zellige mosaic art uses over 40 hours of hand-cutting for a single square meter",
            "The Medina of Fez is the world's largest car-free urban area — a living medieval city",
            "Moroccan hospitality tradition requires offering tea three times to every guest",
            "Berber culture predates Arab arrival by thousands of years and shapes modern Morocco",
            "The star-and-cross pattern in Zellige represents infinite divine geometry in Islamic art"
        ],
        "design_philosophy": "Every element in this villa pays homage to the Riad architecture of Fez — the mother of Moroccan civilization. The geometric Zellige tilework is hand-cut and assembled by Maalem (master artisans) using techniques unchanged since the 10th century. The carved plaster Muqarnas ceiling represents the infinite complexity of the natural world, while the central courtyard fountain symbolizes the four rivers of paradise described in Islamic tradition.",
        "sections": [
            {
                "name": "The Courtyard Entrance",
                "order": 1,
                "description": "The central courtyard with a traditional Zellige mosaic fountain.",
                "narrative": "The heart of every Riad is its courtyard — a private paradise hidden behind unassuming walls. The mosaic fountain at the center is not merely decorative; in Moroccan tradition, flowing water cleanses the spirit and cools the soul. Notice how the Zellige tiles radiate outward in a star pattern — each tiny piece hand-cut from a larger glazed tile by artisans in the pottery district of Fez. No two patterns are exactly alike, reflecting the Islamic belief that only God can create perfection."
            },
            {
                "name": "The Zellige Gallery",
                "order": 2,
                "description": "A showcase of traditional Moroccan mosaic artistry and geometric tilework.",
                "narrative": "Step into the gallery and witness centuries of mathematical precision merged with artistic expression. The Zellige mosaic table before you contains over 10,000 individual tile pieces, each hand-cut with a traditional Menqash (chisel). The geometric patterns are not random — they follow the principles of Islamic sacred geometry, where repeating star motifs symbolize the infinite nature of God. Moroccan Maalem (master craftsmen) train for over a decade before they are trusted to create a Zellige masterpiece."
            },
            {
                "name": "The Berber Lounge",
                "order": 3,
                "description": "A comfortable space celebrating indigenous Berber textile traditions.",
                "narrative": "The Berber Lounge celebrates Morocco's indigenous Amazigh heritage — a culture that has thrived in North Africa for over 4,000 years. The handwoven Beni Ourain rug beneath your feet was created by women of the Atlas Mountain tribes, each knot encoding a symbol of protection, fertility, or guidance. The leather poufs were crafted in the tanneries of Fez — the oldest operational tanneries in the world — using vegetable dyes and methods that have not changed since the 11th century."
            },
        ],
    },
    "Nigerian Royal Villa": {
        "welcome_story": "Welcome to the Nigerian Royal Villa — a tribute to the artistic genius and royal traditions of West Africa's most vibrant civilization. From the ancient Benin bronzes that rivaled Renaissance Europe to the indigo-dipped Adire textiles that map Yoruba cosmology, this villa celebrates the artistic mastery that has defined Nigerian culture for millennia. Every artifact here carries the weight of kingdoms, the rhythm of talking drums, and the brilliance of a people whose creativity has shaped global art and music.",
        "cultural_highlights": [
            "The Benin Bronzes are among the most sophisticated metal castings ever created",
            "Nigeria has over 250 ethnic groups and 500+ languages — the most linguistically diverse nation on Earth",
            "Yoruba Adire textile dyeing uses cassava paste resist patterns passed down for centuries",
            "The Nok civilization produced Africa's oldest known terracotta sculptures over 2,500 years ago",
            "Nigerian drumming traditions directly shaped modern jazz, blues, and hip-hop rhythms"
        ],
        "design_philosophy": "This villa channels the grandeur of the Benin Kingdom's royal court and the creative energy of Yoruba artistic tradition. The bronze-toned accents reference the legendary Benin Bronzes, while the Adire textile patterns adorning the walls map the Yoruba understanding of the cosmos. Bold palm-oil reds and indigo blues create an atmosphere of royal authority and artistic freedom.",
        "sections": [
            {
                "name": "The Oba's Reception",
                "order": 1,
                "description": "An entrance hall inspired by the royal court of the Benin Kingdom.",
                "narrative": "You are standing in a space inspired by the legendary court of the Oba (King) of Benin — one of the most powerful monarchies in African history. The bronze plaques on the walls echo the over 4,000 Benin Bronzes that once adorned the Royal Palace of the Oba, documenting centuries of history in cast metal. These bronzes stunned European scholars when they first encountered them in 1897 — their technical sophistication rivaled anything produced in Renaissance Italy, challenging colonial narratives about African civilization."
            },
            {
                "name": "The Adire Workshop",
                "order": 2,
                "description": "A space showcasing traditional Yoruba textile art and indigo dyeing.",
                "narrative": "The indigo-dipped textiles surrounding you are Adire — a Yoruba art form where patterns are drawn with cassava paste onto cloth before being dyed in deep indigo vats. Each pattern has a name and a story: 'Ibadandun' (life in Ibadan is sweet), 'Olokun' (goddess of the sea), 'Ejo' (the serpent of wisdom). For centuries, Yoruba women controlled the Adire trade, running sophisticated dyeing operations that were among the earliest known female-led industries in Africa."
            },
            {
                "name": "The Talking Drum Hall",
                "order": 3,
                "description": "A musical space celebrating Nigerian drumming and oral traditions.",
                "narrative": "In the Talking Drum Hall, you encounter the heartbeat of West African communication. The Dundun (talking drum) is not merely a musical instrument — it is a language. By squeezing the leather cords that connect the drum's two heads, a skilled drummer can replicate the tonal patterns of the Yoruba language, sending complex messages across vast distances. This drum technology was the original 'wireless communication' — predating the telegraph by centuries. The rhythmic patterns born here traveled across the Atlantic, eventually becoming the foundation of jazz, blues, gospel, and hip-hop."
            },
        ],
    },
}


class Command(BaseCommand):
    help = "Seed the database with sample countries, villas, artifacts, and stories."

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Delete all existing data before seeding.",
        )

    def handle(self, *args, **options):
        from artifacts.models import VillaSection

        if options["clear"]:
            self.stdout.write("Clearing existing data...")
            Order.objects.all().delete()
            Story.objects.all().delete()
            Artifact.objects.all().delete()
            VillaSection.objects.all().delete()
            Villa.objects.all().delete()
            Country.objects.all().delete()

        # Countries
        country_map = {}
        for c in SEED["countries"]:
            defaults = {"name": c["name"]}
            if c.get("image_url"):
                # Strip leading /media/ if present for ImageField
                path = c["image_url"].replace("/media/", "")
                defaults["image"] = path

            obj, created = Country.objects.get_or_create(
                code=c["code"],
                defaults=defaults,
            )
            country_map[c["code"]] = obj
            tag = "Created" if created else "Exists"
            self.stdout.write(f"  {tag} country: {obj.name}")

        # Villas
        villa_map = {}
        for v in SEED["villas"]:
            country = country_map[v["country_code"]]
            defaults = {"location": v["location"]}
            if v.get("image_url"):
                path = v["image_url"].replace("/media/", "")
                defaults["image"] = path

            obj, created = Villa.objects.get_or_create(
                name=v["name"],
                country=country,
                defaults=defaults,
            )
            villa_map[v["name"]] = obj
            tag = "Created" if created else "Exists"
            self.stdout.write(f"  {tag} villa: {obj.name}")

        # Villa Guide Data (welcome_story, cultural_highlights, design_philosophy)
        for villa_name, guide_data in VILLA_GUIDE_DATA.items():
            villa = villa_map.get(villa_name)
            if not villa:
                continue
            villa.welcome_story = guide_data["welcome_story"]
            villa.cultural_highlights = guide_data["cultural_highlights"]
            villa.design_philosophy = guide_data["design_philosophy"]
            villa.save(update_fields=["welcome_story", "cultural_highlights", "design_philosophy"])
            self.stdout.write(f"  Updated guide: {villa.name}")

            # Sections
            for sec_data in guide_data.get("sections", []):
                section, created = VillaSection.objects.get_or_create(
                    villa=villa,
                    order=sec_data["order"],
                    defaults={
                        "name": sec_data["name"],
                        "description": sec_data["description"],
                        "narrative": sec_data["narrative"],
                    },
                )
                tag = "Created" if created else "Exists"
                self.stdout.write(f"    {tag} section: {section.name}")

        # Artifacts + Stories
        section_map = {}
        for villa in villa_map.values():
            sections = VillaSection.objects.filter(villa=villa).order_by("order")
            section_map[villa.name] = list(sections)

        for a in SEED["artifacts"]:
            country = country_map[a["country_code"]]
            villa = villa_map[a["villa_name"]]
            artifact_defaults = {
                "villa": villa,
                "description": a["description"],
                "price": a["price"],
                "image_url": a["image_url"],
            }
            if "image_path" in a:
                artifact_defaults["image"] = a["image_path"]

            # Assign artifact to the first available section in its villa
            villa_sections = section_map.get(a["villa_name"], [])
            if villa_sections:
                # Distribute artifacts across sections round-robin
                artifact_index = SEED["artifacts"].index(a)
                villa_artifacts = [x for x in SEED["artifacts"] if x["villa_name"] == a["villa_name"]]
                local_idx = villa_artifacts.index(a)
                section_idx = local_idx % len(villa_sections)
                artifact_defaults["section"] = villa_sections[section_idx]

            obj, created = Artifact.objects.get_or_create(
                name=a["name"],
                country=country,
                defaults=artifact_defaults,
            )
            tag = "Created" if created else "Exists"
            self.stdout.write(f"  {tag} artifact: {obj.name}")

            if created and "story" in a:
                s = a["story"]
                Story.objects.create(
                    artifact=obj,
                    title=s["title"],
                    story=s["story"],
                    materials=s["materials"],
                    cultural_significance=s["cultural_significance"],
                )
                self.stdout.write(f"    + Story: {s['title']}")

        self.stdout.write(self.style.SUCCESS("\nSeed data loaded successfully!"))
