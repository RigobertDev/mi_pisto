import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'auth_provider.dart';
import 'home_screen.dart'; // Importa la pantalla HomeScreen
import 'login_screen.dart'; // Importa la pantalla LoginScreen

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Mi Pisto App', // Nombre de la aplicación
      theme: themeProvider.currentTheme, // Usa el tema actual del ThemeProvider
      home: authProvider.isAuthenticated
          ? const HomeScreen() // Si el usuario está autenticado, muestra la HomeScreen
          : const LoginScreen(), // Si no, muestra la LoginScreen
    );
  }
}
