import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/transit_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AccraTransitApp());
}

class AccraTransitApp extends StatelessWidget {
  const AccraTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransitProvider()),
      ],
      child: MaterialApp(
        title: 'Accra Transit Optimizer',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.light,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
