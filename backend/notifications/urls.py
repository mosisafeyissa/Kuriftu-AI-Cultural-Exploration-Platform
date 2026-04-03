from django.urls import path
from . import views

urlpatterns = [
    path("notifications/", views.notification_list, name="notification-list"),
    path("notifications/mark-read/", views.mark_read, name="notification-mark-read"),
    path("notifications/unread-count/", views.unread_count, name="notification-unread-count"),
]
