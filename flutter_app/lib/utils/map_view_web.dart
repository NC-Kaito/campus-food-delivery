import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

void registerMapView(String viewId, double lat, double lng) {
  ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
    return html.IFrameElement()
      ..src = 'https://www.google.com/maps?q=$lat,$lng&z=17&output=embed'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;
  });
}

Widget buildMapView(String viewId) {
  return HtmlElementView(viewType: viewId);
}
