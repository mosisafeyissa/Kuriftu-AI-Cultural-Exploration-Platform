"""
Management command to seed the database with sample cultural data.

Usage:
    python manage.py seed_data
    python manage.py seed_data --clear   # wipe existing data first
"""

from django.core.management.base import BaseCommand
from artifacts.models import Country, Villa, Artifact, Story


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
            "image_url": "https://placehold.co/400x300/png?text=Ethiopian+Villa",
        },
        {
            "name": "Moroccan Riad Villa",
            "country_code": "MA",
            "location": "A celebration of Zellige artistry, Riad architecture, and Saharan mystique.",
            "image_url": "https://placehold.co/400x300/png?text=Moroccan+Villa",
        },
        {
            "name": "Nigerian Royal Villa",
            "country_code": "NG",
            "location": "A tribute to Yoruba royalty, vibrant beadwork, and ancestral tradition.",
            "image_url": "https://placehold.co/400x300/png?text=Nigerian+Villa",
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
            "image_url": "https://placehold.co/400x300/png?text=Coffee+Table",
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
            "image_url": "https://placehold.co/400x300/png?text=Mesob+Basket",
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
            "image_url": "https://placehold.co/400x300/png?text=Jimma+Chair",
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
            "image_url": "https://placehold.co/400x300/png?text=Zellige+Table",
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
            "image_url": "https://placehold.co/400x300/png?text=Brass+Lantern",
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
            "image_url": "https://placehold.co/400x300/png?text=Berber+Carpet",
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
            "image_url": "https://placehold.co/400x300/png?text=Yoruba+Mask",
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
            "image_url": "https://placehold.co/400x300/png?text=Wooden+Stool",
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
            "image_url": "https://placehold.co/400x300/png?text=Beaded+Chair",
            "story": {
                "title": "Throne of Glass & Light",
                "story": "The beaded chair is the pinnacle of Yoruba artistic achievement and royal authority. Reserved exclusively for the Oba (king) and high-ranking chiefs.",
                "materials": "Hand-sewn glass beads, carved wood frame, cotton thread base",
                "cultural_significance": "The ultimate seat of power in Yoruba culture, encoding the king's divine authority in beads of light.",
            },
        },
    ],
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
        if options["clear"]:
            self.stdout.write("Clearing existing data...")
            Story.objects.all().delete()
            Artifact.objects.all().delete()
            Villa.objects.all().delete()
            Country.objects.all().delete()

        asset_map = {
            "Ethiopian Heritage Villa": "assets/images/villa_1.jpg",
            "Moroccan Riad Villa": "assets/images/villa_2.jpg",
            "Nigerian Royal Villa": "assets/images/villa_3.jpg",
            "Handwoven Mesob Basket": "assets/images/mesob_basket.jpg",
            "Jimma Traditional Chair": "assets/images/JimmaChair.jpg",
            "Ethiopian Coffee Ceremony Table": "assets/images/ethiopian_coffee_table.jpg",
            "Ethiopian Coffee Table": "assets/images/ethiopian_coffee_table.jpg",
            "Beaded Royal Chair": "assets/images/beaded_royal_chair.webp",
            "Berber Handwoven Carpet": "assets/images/berber_carpet.webp",
            "Brass Hanging Lantern": "assets/images/brass_lantern.png",
            "Moroccan Zellige Mosaic Table": "assets/images/moroccan_zellige_table.webp",
            "Moroccan Zellige Table": "assets/images/moroccan_zellige_table.webp",
            "Carved Wooden Stool": "assets/images/wooden_stool.webp",
            "Yoruba Tribal Mask": "assets/images/yoruba_mask.webp",
        }

        # Countries
        country_map = {}
        for c in SEED["countries"]:
            obj, created = Country.objects.update_or_create(
                code=c["code"],
                defaults={"name": c["name"], "image_url": c["image_url"]},
            )
            country_map[c["code"]] = obj
            tag = "Created" if created else "Updated"
            self.stdout.write(f"  {tag} country: {obj.name}")

        # Villas
        villa_map = {}
        for v in SEED["villas"]:
            country = country_map[v["country_code"]]
            mapped_image = asset_map.get(v["name"], v["image_url"])
            obj, created = Villa.objects.update_or_create(
                name=v["name"],
                country=country,
                defaults={"location": v["location"], "image_url": mapped_image},
            )
            villa_map[v["name"]] = obj
            tag = "Created" if created else "Updated"
            self.stdout.write(f"  {tag} villa: {obj.name}")

        # Artifacts + Stories
        for a in SEED["artifacts"]:
            country = country_map[a["country_code"]]
            villa = villa_map[a["villa_name"]]
            mapped_image = asset_map.get(a["name"], a["image_url"])
            obj, created = Artifact.objects.update_or_create(
                name=a["name"],
                country=country,
                defaults={
                    "villa": villa,
                    "description": a["description"],
                    "price": a["price"],
                    "image_url": mapped_image,
                },
            )
            tag = "Created" if created else "Updated"
            self.stdout.write(f"  {tag} artifact: {obj.name}")

            if "story" in a:
                s = a["story"]
                Story.objects.update_or_create(
                    artifact=obj,
                    defaults={
                        "title": s["title"],
                        "story": s["story"],
                        "materials": s["materials"],
                        "cultural_significance": s["cultural_significance"],
                    }
                )
                self.stdout.write(f"    + Story: {s['title']}")

        self.stdout.write(self.style.SUCCESS("\n✅ Seed data loaded successfully!"))
