import os, sys, django
sys.path.append('c:/Users/rebir/OneDrive/Desktop/Kuriftu-AI-Cultural-Exploration-Platform/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from ai_services.services import generate_story

res = generate_story('Yoruba Beaded Royal Chair', 'Nigeria')
print('DICT OUTPUT:')
print(res)
