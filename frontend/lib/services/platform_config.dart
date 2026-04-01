// Platform-aware base URL configuration.
// Uses conditional imports to avoid dart:io on web.
//
// On Web:     http://127.0.0.1:8000/api
// On Android: http://10.0.2.2:8000/api
// On iOS:     http://localhost:8000/api

export 'platform_config_stub.dart'
    if (dart.library.io) 'platform_config_io.dart'
    if (dart.library.html) 'platform_config_web.dart';
