import 'package:flutter/material.dart';

import 'app/bus_eta_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const BusEtaApp();
  }
}
