import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/food_item.dart';
import 'screens/home_screen.dart';
import 'services/food_service.dart';

void main() async {
  await Hive.initFlutter();
  FoodService.initHive();
  await Hive.openBox<FoodItem>('foodBox');
  runApp(FoodTrackerApp());
}

class FoodTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Tracker',
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ThemeData().colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
              background: Colors.white,
              onBackground: Colors.green,
            ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: HomeScreen(),
    );
  }
}
