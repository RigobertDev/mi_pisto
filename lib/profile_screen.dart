import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _changePasswordError;
  bool _isChangingPassword = false;
  bool _showPassword = false; // Nuevo estado para mostrar/ocultar contraseña
  String _encryptedPassword = ''; // Variable para almacenar la contraseña encriptada

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchCurrentUser();
    // Obtener la contraseña encriptada al cargar el perfil
    if (authProvider.currentUserData != null && authProvider.currentUserData!['contrasena'] != null) {
      setState(() {
        _encryptedPassword = authProvider.currentUserData!['contrasena'];
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logoutUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _changePasswordError = 'Por favor, introduce la nueva contraseña y su confirmación.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _changePasswordError = 'Las contraseñas no coinciden.';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _changePasswordError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.changePassword(
      _passwordController.text,
    );

    setState(() {
      _isChangingPassword = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada exitosamente.')),
      );
      _passwordController.clear();
      _confirmPasswordController.clear();
      // Recargar los datos del perfil para obtener la nueva contraseña encriptada
      _loadProfileData();
    } else {
      setState(() {
        _changePasswordError = authProvider.errorMessage ?? 'Error al cambiar la contraseña.';
      });
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Mi Pisto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Saldo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ajustes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.currentUserData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(userData?['correo'] ?? 'No disponible'),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [
                  Text(_showPassword
                      ? (userData?['contrasena'] ?? 'No disponible')
                      : _encryptedPassword.replaceAll(RegExp(r'.'), '*')),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                    child: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'CAMBIO DE CONTRASEÑA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2.0),
                ),
                errorText: _changePasswordError,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Nueva Contraseña',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isChangingPassword ? null : () => _changePassword(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isChangingPassword
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('CAMBIAR CONTRASEÑA', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => _logout(context),
                child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}