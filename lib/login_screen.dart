import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'auth_provider.dart'; // Importa tu AuthProvider
import 'theme_provider.dart'; // Importa ThemeProvider

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _usernameController.text = prefs.getString('username') ?? '';
        _rememberMe = prefs.getBool('rememberMe') ?? false;
      });
    } catch (e) {
      print('Error al cargar las credenciales guardadas: $e');
      // Considera mostrar un mensaje de error al usuario si es crítico
    }
  }

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;
    print('Intentando iniciar sesión con: $username, $password');

    if (username.isNotEmpty && password.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginUser(
        username.trim(), // Usamos el correo electrónico como nombre de usuario
        password.trim(),
      );
      if (success) {
        // ¡Carga los datos del usuario inmediatamente después del inicio de sesión!
        await authProvider.fetchCurrentUser();
        // Navega a la pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()), // Cambia a tu pantalla principal
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Correo o contraseña incorrectos';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Por favor, introduce correo y contraseña';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce correo y contraseña')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtén el ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Usa el modo de tema para determinar si es modo oscuro
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100], // Aplica el color de fondo según el tema
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/mi pisto.png',
                height: 150,
              ),
              const SizedBox(height: 30),
              Text(
                'Bienvenido a Mi Pisto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color.fromARGB(255, 97, 97, 97), // Aplica el color del texto según el tema
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.green[400]!),
                    ),
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.grey[600]), // Color de la etiqueta
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), // Color del texto ingresado
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.green[400]!),
                    ),
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.grey[600]),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (bool? value) {
                      setState(() {
                        _rememberMe = value!;
                      });
                    },
                    activeColor: isDarkMode ? Colors.blue[200] : null, // Color del checkbox
                  ),
                  Text(
                    'Recordar correo',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.blue[800] : Colors.pink[100], // Color del botón según el tema
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Ingresar',
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87), // Color del texto del botón
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  _showForgotPasswordDialog(context);
                },
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '¿No tienes una cuenta?',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Aquí irá la lógica para "Ingresa con huella o reconocimiento facial"
                },
                child: const Text(
                  'Ingresa con huella o reconocimiento facial',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo Electrónico'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Enviar Correo'),
              onPressed: () {
                String email = _emailController.text;
                print('Solicitud de recuperación de contraseña para: $email');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Se ha enviado un correo electrónico para restablecer tu contraseña')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

