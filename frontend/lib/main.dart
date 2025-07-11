import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/transit_provider.dart';
import 'screens/home_screen.dart';

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
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
