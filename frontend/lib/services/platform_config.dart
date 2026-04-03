// Platform-aware base URL configuration.
// Uses conditional imports to avoid dart:io on web.
//
// Production: https://kuriftu-ai-cultural-exploration-platform-b7jj.onrender.com/api

export 'platform_config_stub.dart'
    if (dart.library.io) 'platform_config_io.dart'
    if (dart.library.html) 'platform_config_web.dart';
