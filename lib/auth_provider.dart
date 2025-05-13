// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart'; // Asegúrate de tener esta importación

class AuthProvider with ChangeNotifier {
  int? _currentUserId;
  Map<String, dynamic>? _currentUserData;
  String? _errorMessage;
  bool _isAuthenticated = false; // Inicializa en false

  int? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Función para registrar un nuevo usuario
  Future<bool> registerUser(String nombre, String correo, String contrasena) async {
    _errorMessage = null;
    try {
      final id = await _dbHelper.insertarUsuario({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      });
      _currentUserId = id;
      await _saveUserId(id);
      await fetchCurrentUser();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar el usuario: $e';
      notifyListeners();
      return false;
    }
  }

  // Función para iniciar sesión
  Future<bool> loginUser(String correo, String contrasena) async {
    _errorMessage = null;
    try {
      final user = await _dbHelper.obtenerUsuarioPorCorreo(correo);
      if (user == null) {
        _errorMessage = 'Usuario no encontrado.';
        notifyListeners();
        return false;
      }
      if (user['contrasena'] == contrasena) {
        _currentUserId = user['id'];
        await _saveUserId(_currentUserId!);
        await fetchCurrentUser();
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Contraseña incorrecta.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      notifyListeners();
      return false;
    }
  }

  // Función para cerrar sesión
  Future<void> logoutUser() async {
    _currentUserId = null;
    _currentUserData = null;
    _isAuthenticated = false; // Asegúrate de resetear el estado de autenticación
    await _clearUserId();
    notifyListeners();
  }

  // Función para obtener la información del usuario actual
  Future<void> fetchCurrentUser() async {
    print('AuthProvider: fetchCurrentUser llamado'); // <--- PRINT STATEMENT

    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
    print('AuthProvider: UserId cargado de SharedPreferences: $_currentUserId'); // <--- PRINT STATEMENT

    if (_currentUserId != null) {
      _currentUserData = await _dbHelper.obtenerUsuarioPorId(_currentUserId!);
      _isAuthenticated = true;
      print('AuthProvider: Usuario encontrado, isAuthenticated = $_isAuthenticated'); // <--- PRINT STATEMENT
      notifyListeners();
    } else {
      _isAuthenticated = false;
      print('AuthProvider: No se encontró usuario, isAuthenticated = $_isAuthenticated'); // <--- PRINT STATEMENT
      notifyListeners();
    }
  }

  // Función para cambiar la contraseña
  Future<bool> changePassword(String newPassword) async {
    _errorMessage = null;
    if (_currentUserId == null) {
      _errorMessage = 'No hay usuario autenticado.';
      notifyListeners();
      return false;
    }
    try {
      final rowsAffected = await _dbHelper.actualizarUsuario({
        'id': _currentUserId,
        'contrasena': newPassword,
      });
      if (rowsAffected > 0) {
        // Opcional: podrías recargar los datos del usuario si es necesario
        // await fetchCurrentUser();
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Error al actualizar la contraseña.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al cambiar la contraseña: $e';
      notifyListeners();
      return false;
    }
  }

  // Funciones para persistir el ID del usuario (usando SharedPreferences como ejemplo)
  Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  Future<void> _clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Llama a _loadUserId al inicializar el AuthProvider si es necesario
  AuthProvider() {
    // No llamar a _loadUserId() aquí
  }
}