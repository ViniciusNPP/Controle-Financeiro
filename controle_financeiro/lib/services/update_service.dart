// A implementação certa é escolhida na compilação:
//  - Windows/Android (dart:io disponível) -> update_service_io.dart
//  - Web                                  -> update_service_web.dart
export 'update_info.dart';
export 'update_service_web.dart'
    if (dart.library.io) 'update_service_io.dart';
