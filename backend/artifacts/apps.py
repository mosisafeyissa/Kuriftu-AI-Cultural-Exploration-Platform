from django.apps import AppConfig


class ArtifactsConfig(AppConfig):
    name = "artifacts"

    def ready(self):
        import artifacts.signals  # noqa: F401 — register signals
