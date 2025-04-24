import 'package:booking_app/screens/home_screen.dart';
import 'package:booking_app/providers/date_provider.dart';
import 'package:booking_app/providers/storage_provider.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:booking_app/utils/database_helper.dart';
import 'package:booking_app/screens/edit_appointment_screen.dart';
import 'package:booking_app/screens/search_screen.dart';
import 'package:booking_app/screens/appointment_day_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';



final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper().database;
  // Fullscreen view
  await windowManager.ensureInitialized();
  WindowOptions windowsOptions = const WindowOptions(
    fullScreen: false,
    title: 'Booking App'
  );
  windowManager.waitUntilReadyToShow(windowsOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => DateProvider()),
      ChangeNotifierProvider(create: (context) => StorageNotifier()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF18BBB9), brightness: Brightness.light),
        useMaterial3: true,
        tooltipTheme: const TooltipThemeData(preferBelow: false),
      ),
      routes: {
        '/': (context) => const HomeScreen(),
        '/edit-appointment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return EditAppointmentScreen(
            date: args['date'],
            time: args['time'],
            location: args['location'],
          );
        },
        '/search': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return SearchScreen(
            name: args['name'],
          );
        },
        '/appointment-day': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>;
          return AppointmentDayScreen(
            date: args['date'],
            location: args['location'],
          );
        },
      },
    );
  }
}
