import 'package:flutter/material.dart';

bool sidebarVisivel(BuildContext context) {

  MediaQuery.sizeOf(context);
  return Scaffold.maybeOf(context)?.hasDrawer != true;
}