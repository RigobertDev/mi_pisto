import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

// Nombre de la base de datos
const String _databaseName = "mi_pisto_db_new.db";
// Versión de la base de datos
const int _databaseVersion = 1;
// Nombre de las tablas
const String _tableUsuarios = "usuarios";
const String _tableTransacciones = "transacciones";
const String _tablePresupuestos = "presupuestos";
const String _tableCategorias = "categorias";

// Clase para manejar la base de datos
class DatabaseHelper {
  // Singleton para asegurar que solo haya una instancia de la base de datos
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database; // <-- приватная переменная

  // Getter para obtener la instancia de la base de datos
  Future<Database> get database async {
    // Solo inicializa la base de datos si aún no se ha hecho.
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Función para inicializar la base de datos
  Future<Database> _initDatabase() async {
    // Obtiene la ruta donde se almacenará la base de datos
    String path = join(await getDatabasesPath(), _databaseName);
    print('DatabaseHelper: Inicializando base de datos en $path'); // Log

    // Abre la base de datos, creando la si no existe
    try {
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate, // Función que se ejecuta al crear la base de datos
        onUpgrade: _onUpgrade, // Función para manejar actualizaciones de la base de datos
      );
      print('DatabaseHelper: Base de datos abierta exitosamente');
      return db;
    } catch (e) {
      print('DatabaseHelper: Error al inicializar la base de datos: $e');
      throw e; // Importante: relanzar la excepción
    }
  }

  // Función para crear las tablas de la base de datos
  Future<void> _onCreate(Database db, int version) async {
    print('DatabaseHelper: _onCreate llamado con versión: $version'); // Log
    // Ejecuta el código SQL para crear las tablas
    try {
      await db.execute('''
        CREATE TABLE $_tableUsuarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          correo TEXT NOT NULL UNIQUE,
          contrasena TEXT NOT NULL
        )
      ''');
      print('DatabaseHelper: Tabla $_tableUsuarios creada');

      await db.execute('''
        CREATE TABLE $_tableTransacciones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id INTEGER NOT NULL,
          descripcion TEXT NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL,
          tipo TEXT NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
          categoria TEXT,
          FOREIGN KEY (usuario_id) REFERENCES $_tableUsuarios(id)
        )
      ''');
      print('DatabaseHelper: Tabla $_tableTransacciones creada');

      await db.execute('''
        CREATE TABLE $_tablePresupuestos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id INTEGER NOT NULL,
          monto REAL NOT NULL,
          tipo TEXT NOT NULL CHECK (tipo IN ('semanal', 'mensual', 'anual')),
          fecha_inicio TEXT NOT NULL,
          fecha_fin TEXT NOT NULL,
          FOREIGN KEY (usuario_id) REFERENCES $_tableUsuarios(id)
        )
      ''');
      print('DatabaseHelper: Tabla $_tablePresupuestos creada');

      await db.execute('''
        CREATE TABLE $_tableCategorias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE
        )
      ''');
      print('DatabaseHelper: Tabla $_tableCategorias creada');

      // Insertar las categorías iniciales
      await _insertInitialCategories(db);
    } catch (e) {
      print("DatabaseHelper: Error al crear las tablas: $e");
      rethrow; // Relanza la excepción para que se maneje en un nivel superior
    }
  }

  Future<void> _insertInitialCategories(Database db) async {
    print('DatabaseHelper: Insertando categorías iniciales');
    try {
      await db.execute('''
        INSERT INTO $_tableCategorias (nombre) VALUES
          ( 'Comida'),
          ( 'Facturas'),
          ( 'Transporte'),
          ( 'Ocio'),
          ( 'Otros'),
          ( 'Salud'),
          ( 'Educación'),
          ( 'Ropa'),
          ( 'Entretenimiento'),
          ( 'Regalos'),
          ( 'Ejercicio')
        ''');
      print('DatabaseHelper: Datos iniciales de $_tableCategorias insertados');
    } catch (e) {
      print('DatabaseHelper: Error al insertar categorías iniciales: $e');
      rethrow;
    }
  }

  // Función para manejar las actualizaciones de la base de datos
  void _onUpgrade(Database db, int oldVersion, int newVersion) {
    print('DatabaseHelper: _onUpgrade llamado de la versión $oldVersion a $newVersion');
    // Aquí puedes implementar la lógica para migrar los datos a la nueva versión
    // Por ejemplo, puedes usar sentencias ALTER TABLE para modificar las tablas
    if (oldVersion < newVersion) {
      try {
        // Ejemplo de migración: agregar una nueva columna
        db.execute('ALTER TABLE $_tableTransacciones ADD COLUMN categoria_id INTEGER');
        print('DatabaseHelper: Columna categoria_id añadida a $_tableTransacciones');
        // Ejemplo de migración: crear una nueva tabla
        // db.execute('CREATE TABLE nueva_tabla (...)');
        // print('DatabaseHelper: Nueva tabla creada: nueva_tabla');
      } catch (e) {
        print("DatabaseHelper: Error en onUpgrade: $e");
        rethrow;
      }
    }
  }

  // Funciones para interactuar con la base de datos (CRUD)

  // Insertar un nuevo usuario
  Future<int> insertarUsuario(Map<String, dynamic> usuario) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final id = await dbClient.insert(_tableUsuarios, usuario);
      print('DatabaseHelper: Usuario insertado con ID: $id');
      return id;
    } catch (e) {
      print('DatabaseHelper: Error al insertar usuario: $e');
      throw e; // Propaga el error para que quien llame a la función lo maneje
    }
  }

  // Obtener un usuario por su correo
  Future<Map<String, dynamic>?> obtenerUsuarioPorCorreo(String correo) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      List<Map<String, dynamic>> result = await dbClient.query(
        _tableUsuarios,
        where: 'correo = ?',
        whereArgs: [correo],
      );
      print('DatabaseHelper: Resultado de obtenerUsuarioPorCorreo: $result');
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('DatabaseHelper: Error al obtener usuario por correo: $e');
      throw e;
    }
  }

  // Añadido: Obtener un usuario por su ID
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(int id) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      List<Map<String, dynamic>> result = await dbClient.query(
        _tableUsuarios,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Resultado de obtenerUsuarioPorId: $result');
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('DatabaseHelper: Error al obtener usuario por ID: $e');
      throw e;
    }
  }

  // Actualizar la información de un usuario
  Future<int> actualizarUsuario(Map<String, dynamic> usuario) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final result = await dbClient.update(
        _tableUsuarios,
        usuario,
        where: 'id = ?',
        whereArgs: [usuario['id']], // Asegúrate de incluir el ID del usuario en el mapa
      );
      print('DatabaseHelper: Usuario actualizado. Resultado: $result');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al actualizar usuario: $e');
      throw e;
    }
  }

  // Insertar una nueva transacción
  Future<int> insertarTransaccion(Map<String, dynamic> transaccion) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      // Si el tipo es gasto, asegúrate de que el monto sea negativo
      if (transaccion['tipo'] == 'gasto') {
        transaccion['monto'] = (transaccion['monto'] as double).abs() * -1;
      }
      final id = await dbClient.insert(_tableTransacciones, transaccion);
      print('DatabaseHelper: Transacción insertada con ID: $id');
      return id;
    } catch (e) {
      print('DatabaseHelper: Error al insertar transacción: $e');
      throw e;
    }
  }

  // Obtener todas las transacciones de un usuario en un rango de fechas
  Future<List<Map<String, dynamic>>> obtenerTransaccionesPorUsuario(
      int usuarioId, DateTime fechaInicio, DateTime fechaFin) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final String inicio = DateFormat('yyyy-MM-dd').format(fechaInicio);
      final String fin = DateFormat('yyyy-MM-dd').format(fechaFin);
      print(
          'DatabaseHelper: Obteniendo transacciones para usuarioId: $usuarioId, inicio: $inicio, fin: $fin'); //log
      List<Map<String, dynamic>> result = await dbClient.query(
        _tableTransacciones,
        where: 'usuario_id = ? AND fecha >= ? AND fecha <= ?',
        whereArgs: [usuarioId, inicio, fin],
        orderBy: 'fecha DESC',
      );
      print('DatabaseHelper: Transacciones obtenidas: ${result.length}');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al obtener transacciones: $e');
      throw e;
    }
  }

  // Obtener una transacción por su ID
  Future<Map<String, dynamic>?> obtenerTransaccionPorId(int id) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      List<Map<String, dynamic>> result = await dbClient.query(
        _tableTransacciones,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Transacción obtenida por ID $id: $result');
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('DatabaseHelper: Error al obtener transacción por ID: $e');
      throw e;
    }
  }

  // Actualizar una transacción
  Future<int> actualizarTransaccion(int id, Map<String, dynamic> transaccion) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final result = await dbClient.update(
        _tableTransacciones,
        transaccion,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Transacción actualizada con ID $id. Resultado: $result');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al actualizar transacción: $e');
      throw e;
    }
  }

  // Eliminar una transacción
  Future<int> eliminarTransaccion(int id) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final result = await dbClient.delete(
        _tableTransacciones,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Transacción eliminada con ID $id. Resultado: $result');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al eliminar transacción: $e');
      throw e;
    }
  }

  // Insertar un nuevo presupuesto
  Future<int> insertarPresupuesto(Map<String, dynamic> presupuesto) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final id = await dbClient.insert(_tablePresupuestos, presupuesto);
      print('DatabaseHelper: Presupuesto insertado con ID: $id');
      return id;
    } catch (e) {
      print('DatabaseHelper: Error al insertar presupuesto: $e');
      throw e;
    }
  }

  // Obtener presupuesto por usuario y tipo
  Future<Map<String, dynamic>?> obtenerPresupuestoPorUsuarioYTipo(
      int usuarioId, String tipo) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      List<Map<String, dynamic>> result = await dbClient.query(
        _tablePresupuestos,
        where: 'usuario_id = ? AND tipo = ?',
        whereArgs: [usuarioId, tipo],
      );
      print(
          'DatabaseHelper: Presupuesto obtenido para usuario $usuarioId y tipo $tipo: $result');
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('DatabaseHelper: Error al obtener presupuesto: $e');
      throw e;
    }
  }

  // Actualizar un presupuesto
  Future<int> actualizarPresupuesto(int id, Map<String, dynamic> presupuesto) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final result = await dbClient.update(
        _tablePresupuestos,
        presupuesto,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Presupuesto actualizado con ID $id. Resultado: $result');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al actualizar presupuesto: $e');
      throw e;
    }
  }

  // Eliminar un presupuesto
  Future<int> eliminarPresupuesto(int id) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final result = await dbClient.delete(
        _tablePresupuestos,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Presupuesto eliminado con ID $id. Resultado: $result');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al eliminar presupuesto: $e');
      throw e;
    }
  }

  // Obtener todas las categorías
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final dbClient = await database; // Usa el getter `database`
    try {
      List<Map<String, dynamic>> result = await dbClient.query(_tableCategorias);
      print('DatabaseHelper: Categorías obtenidas: ${result.length}');
      return result;
    } catch (e) {
      print('DatabaseHelper: Error al obtener categorías: $e');
      throw e;
    }
  }

  // Método para obtener el total de gastos de un usuario en un rango de fechas
  Future<double> getTotalExpensesForUser(
      int userId, DateTime startDate, DateTime endDate) async {
    final dbClient = await database; // Usa el getter `database`
    try {
      final String inicio = DateFormat('yyyy-MM-dd').format(startDate);
      final String fin = DateFormat('yyyy-MM-dd').format(endDate);
      print(
          'DatabaseHelper: Obteniendo total de gastos para usuario $userId, inicio: $inicio, fin: $fin');
      final result = await dbClient.rawQuery(
        'SELECT SUM(monto) as total FROM $_tableTransacciones WHERE usuario_id = ? AND fecha >= ? AND fecha <= ? AND tipo = ?',
        [userId, inicio, fin, 'gasto'],
      );
      print('DatabaseHelper: Resultado del total de gastos: $result');
      return result.isNotEmpty && result.first['total'] != null
          ? (result.first['total'] as num).toDouble()
          : 0.0;
    } catch (e) {
      print('DatabaseHelper: Error al obtener el total de gastos: $e');
      throw e;
    }
  }
}

