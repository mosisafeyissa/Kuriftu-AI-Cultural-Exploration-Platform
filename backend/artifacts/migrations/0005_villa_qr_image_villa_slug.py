from django.db import migrations, models
from django.utils.text import slugify

def populate_slugs(apps, schema_editor):
    Villa = apps.get_model('artifacts', 'Villa')
    for villa in Villa.objects.all():
        if not villa.slug:
            villa.slug = slugify(villa.name)
            # Ensure unique slug
            base_slug = villa.slug
            counter = 1
            while Villa.objects.filter(slug=villa.slug).exclude(id=villa.id).exists():
                villa.slug = f"{base_slug}-{counter}"
                counter += 1
            villa.save()

class Migration(migrations.Migration):

    dependencies = [
        ('artifacts', '0004_remove_country_image_url_remove_villa_image_url_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='villa',
            name='qr_image',
            field=models.ImageField(blank=True, help_text='Generated QR code image', null=True, upload_to='qr_codes/'),
        ),
        migrations.AddField(
            model_name='villa',
            name='slug',
            field=models.SlugField(blank=True, help_text='User-friendly URL identifier', null=True, unique=True),
        ),
        migrations.RunPython(populate_slugs, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='villa',
            name='slug',
            field=models.SlugField(help_text='User-friendly URL identifier', unique=True),
        ),
    ]
