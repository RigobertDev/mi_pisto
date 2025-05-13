import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'auth_provider.dart';
import 'theme_provider.dart';
import 'my_app.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Asegúrate de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de la base de datos
  if (!Platform.isAndroid) {
    print('Ejecutando en una plataforma NO Android');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    print('Ejecutando en Android');
    // No es necesario inicializar de nuevo, solo obtener el path
  }

  final dbHelper = DatabaseHelper.instance;
  // Asegúrate de que la base de datos esté inicializada antes de continuar
 // Obtén la instancia de la base de datos

  // Inicialización del AuthProvider
  final authProvider = AuthProvider();
  await authProvider.fetchCurrentUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider<DatabaseHelper>(
          create: (context) => dbHelper,
        ),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
}
