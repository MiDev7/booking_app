import 'package:booking_app/screens/home_screen.dart';
import 'package:booking_app/providers/date_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:booking_app/screens/edit_appointment_screen.dart';
import 'package:booking_app/screens/search_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => DateProvider(),
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
            seedColor: Colors.green, brightness: Brightness.light),
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
      },
    );
  }
}
