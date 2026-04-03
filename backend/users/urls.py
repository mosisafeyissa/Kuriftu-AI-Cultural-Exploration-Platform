from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    path("register/", views.register, name="auth-register"),
    path("login/", views.login, name="auth-login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="auth-token-refresh"),
    path("profile/", views.profile, name="auth-profile"),
    path("change-password/", views.change_password, name="auth-change-password"),
    path("password-reset/", views.password_reset_request, name="auth-password-reset"),
    path("password-reset/confirm/", views.password_reset_confirm, name="auth-password-reset-confirm"),
]
