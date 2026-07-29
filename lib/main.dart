import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const AriGastosApp());
}

class AriGastosApp extends StatelessWidget {
  const AriGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AriGastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// Modelo de Cuenta / Tarjeta
class MedioPago {
  final String id;
  final String nombre;
  final String entidad;
  final String tipo;
  final String ultimos4;

  MedioPago({
    required this.id,
    required this.nombre,
    required this.entidad,
    required this.tipo,
    this.ultimos4 = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'entidad': entidad,
        'tipo': tipo,
        'ultimos4': ultimos4,
      };

  factory MedioPago.fromMap(Map<String, dynamic> map) => MedioPago(
        id: map['id'],
        nombre: map['nombre'],
        entidad: map['entidad'],
        tipo: map['tipo'],
        ultimos4: map['ultimos4'] ?? '',
      );
}

// Modelo de Gasto
class Gasto {
  final String id;
  final String titulo;
  final double monto;
  final String categoria;
  final String subcategoria;
  final String medioPagoId;
  final DateTime fecha;
  final String ambito; // 'Personal' o 'Negocio'

  Gasto({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.categoria,
    this.subcategoria = '',
    required this.medioPagoId,
    required this.fecha,
    this.ambito = 'Personal',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'monto': monto,
        'categoria': categoria,
        'subcategoria': subcategoria,
        'medioPagoId': medioPagoId,
        'fecha': fecha.toIso8601String(),
        'ambito': ambito,
      };

  factory Gasto.fromMap(Map<String, dynamic> map) => Gasto(
        id: map['id'],
        titulo: map['titulo'],
        monto: map['monto'],
        categoria: map['categoria'],
        subcategoria: map['subcategoria'] ?? '',
        medioPagoId: map['medioPagoId'] ?? 'efectivo_default',
        fecha: DateTime.parse(map['fecha']),
        ambito: map['ambito'] ?? 'Personal',
      );
}

enum FiltroFecha { esteMes, mesAnterior, todos }
enum FiltroAmbito { todos, personal, negocio }
enum ModoReporte { porCategoria, porSubcategoria }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  List<Gasto> _gastos = [];
  List<String> _categorias = [
    'Comida', 'Transporte', 'Servicios', 'Educación', 'Inmuebles', 'Vehículos', 'Ocio', 'Otros'
  ];
  List<String> _subcategoriasFrecuentes = [
    'Sucursal 1',
    'Sucursal 2',
    'Mateo',
    'Mantenimiento',
    'Impuestos'
  ];
  List<String> _conceptosFrecuentes = [
    'Supermercado',
    'Cuota Colegio',
    'Expensas',
    'Combustible',
    'Alquiler',
    'Factura Luz / Gas',
    'Seguro',
    'Farmacia / Medicina',
    'Restaurante / Salidas'
  ];

  List<MedioPago> _mediosPago = [
    MedioPago(id: 'efectivo_default', nombre: 'Efectivo', entidad: 'Caja', tipo: 'Efectivo'),
    MedioPago(id: 'mp_default', nombre: 'Mercado Pago', entidad: 'Mercado Pago', tipo: 'Fintech'),
  ];

  FiltroFecha _filtroActual = FiltroFecha.esteMes;
  FiltroAmbito _filtroAmbitoReporte = FiltroAmbito.todos;
  ModoReporte _modoReporte = ModoReporte.porCategoria;
  final _box = GetStorage();

  final List<Color> _paletaColores = [
    Colors.teal,
    Colors.orange,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.purple,
    Colors.cyan,
    Colors.lightGreen,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    final List<dynamic>? storedGastos = _box.read<List<dynamic>>('arigastos_list');
    if (storedGastos != null) {
      _gastos = storedGastos.map((item) => Gasto.fromMap(Map<String, dynamic>.from(item))).toList();
    }

    final List<dynamic>? storedCats = _box.read<List<dynamic>>('arigastos_cats');
    if (storedCats != null) {
      _categorias = storedCats.cast<String>();
    }

    final List<dynamic>? storedSubCats = _box.read<List<dynamic>>('arigastos_subcats');
    if (storedSubCats != null) {
      _subcategoriasFrecuentes = storedSubCats.cast<String>();
    }

    final List<dynamic>? storedMedios = _box.read<List<dynamic>>('arigastos_medios');
    if (storedMedios != null) {
      _mediosPago = storedMedios.map((item) => MedioPago.fromMap(Map<String, dynamic>.from(item))).toList();
    }

    final List<dynamic>? storedConceptos = _box.read<List<dynamic>>('arigastos_conceptos');
    if (storedConceptos != null) {
      _conceptosFrecuentes = storedConceptos.cast<String>();
    }

    setState(() {});
  }

  void _guardarGastos() {
    _box.write('arigastos_list', _gastos.map((g) => g.toMap()).toList());
  }

  void _guardarMediosPago() {
    _box.write('arigastos_medios', _mediosPago.map((m) => m.toMap()).toList());
  }

  void _guardarConceptos() {
    _box.write('arigastos_conceptos', _conceptosFrecuentes);
  }

  void _guardarSubcategorias() {
    _box.write('arigastos_subcats', _subcategoriasFrecuentes);
  }

  void _aprenderConcepto(String concepto) {
    final limpio = concepto.trim();
    if (limpio.isNotEmpty && !_conceptosFrecuentes.contains(limpio)) {
      setState(() {
        _conceptosFrecuentes.insert(0, limpio);
      });
      _guardarConceptos();
    }
  }

  void _aprenderSubcategoria(String subcat) {
    final limpio = subcat.trim();
    if (limpio.isNotEmpty) {
      // Buscar si ya existe ignorando mayúsculas/minúsculas para no duplicar
      final existe = _subcategoriasFrecuentes.any((s) => s.toLowerCase() == limpio.toLowerCase());
      if (!existe) {
        setState(() {
          _subcategoriasFrecuentes.insert(0, limpio);
        });
        _guardarSubcategorias();
      }
    }
  }

  void _agregarOActualizarGasto({
    String? id,
    required String titulo,
    required double monto,
    required String categoria,
    required String subcategoria,
    required String medioPagoId,
    required DateTime fecha,
    required String ambito,
  }) {
    _aprenderConcepto(titulo);
    _aprenderSubcategoria(subcategoria);

    setState(() {
      if (id != null) {
        final index = _gastos.indexWhere((g) => g.id == id);
        if (index != -1) {
          _gastos[index] = Gasto(
            id: id,
            titulo: titulo,
            monto: monto,
            categoria: categoria,
            subcategoria: subcategoria,
            medioPagoId: medioPagoId,
            fecha: fecha,
            ambito: ambito,
          );
        }
      } else {
        final nuevoGasto = Gasto(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titulo: titulo,
          monto: monto,
          categoria: categoria,
          subcategoria: subcategoria,
          medioPagoId: medioPagoId,
          fecha: fecha,
          ambito: ambito,
        );
        _gastos.add(nuevoGasto);
      }
      _gastos.sort((a, b) => b.fecha.compareTo(a.fecha));
    });
    _guardarGastos();
  }

  void _eliminarGasto(String id) {
    setState(() {
      _gastos.removeWhere((gasto) => gasto.id == id);
    });
    _guardarGastos();
  }

  // ALGORITMO LOCAL DE ANÁLISIS DE VOZ
  void _procesarFraseLocalmente(String frase) {
    if (frase.trim().isEmpty) return;

    final textoMin = frase.toLowerCase();

    // 1. Extraer Monto
    double montoEncontrado = 0.0;
    final regExpMonto = RegExp(r'(\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:[.,]\d+)?)');
    final matches = regExpMonto.allMatches(textoMin);

    for (final match in matches) {
      String strNum = match.group(0)!;
      if (strNum.contains('.') && strNum.contains(',')) {
        strNum = strNum.replaceAll('.', '').replaceAll(',', '.');
      } else if (strNum.contains('.')) {
        final partes = strNum.split('.');
        if (partes.length > 2 || (partes.length == 2 && partes[1].length == 3)) {
          strNum = strNum.replaceAll('.', '');
        }
      } else if (strNum.contains(',')) {
        final partes = strNum.split(',');
        if (partes.length > 2 || (partes.length == 2 && partes[1].length == 3)) {
          strNum = strNum.replaceAll(',', '');
        } else {
          strNum = strNum.replaceAll(',', '.');
        }
      }

      final val = double.tryParse(strNum);
      if (val != null && val > montoEncontrado) {
        montoEncontrado = val;
      }
    }

    // 2. Extraer Ámbito
    String ambitoEncontrado = 'Personal';
    if (textoMin.contains('negocio') ||
        textoMin.contains('empresa') ||
        textoMin.contains('local') ||
        textoMin.contains('cliente') ||
        textoMin.contains('trabajo')) {
      ambitoEncontrado = 'Negocio';
    }

    // 3. Extraer Medio de Pago
    String medioIdEncontrado = _mediosPago.first.id;
    for (var m in _mediosPago) {
      if (textoMin.contains(m.nombre.toLowerCase()) ||
          textoMin.contains(m.entidad.toLowerCase())) {
        medioIdEncontrado = m.id;
        break;
      }
    }

    // 4. Extraer Categoría
    String catEncontrada = _categorias.first;
    if (textoMin.contains('farmacia') || textoMin.contains('remedio') || textoMin.contains('doctor') || textoMin.contains('medicina')) {
      catEncontrada = _categorias.contains('Servicios') ? 'Servicios' : _categorias.first;
    } else if (textoMin.contains('nafta') || textoMin.contains('combustible') || textoMin.contains('ypf') || textoMin.contains('shell')) {
      catEncontrada = _categorias.contains('Vehículos') ? 'Vehículos' : _categorias.first;
    } else if (textoMin.contains('super') || textoMin.contains('comida') || textoMin.contains('carne') || textoMin.contains('verdura') || textoMin.contains('restaurante')) {
      catEncontrada = _categorias.contains('Comida') ? 'Comida' : _categorias.first;
    }

    // 5. FILTRADO INTELIGENTE DE PALABRAS PARA EL TÍTULO
    final hashSetStopWords = {
      'gaste', 'gasto', 'gastos', 'pague', 'pago', 'pagos',
      'compre', 'compra', 'compras', 'abone', 'abono', 'cobro',
      'costo', 'precio', 'pesos', 'peso', 'con', 'para', 'por', 'el',
      'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'en', 'de', 'del', 'al',
      'tarjeta', 'efectivo', 'negocio', 'personal', 'mercado', 'pago', 'debito',
      'credito', 'visa', 'mastercard', 'bbva', 'galicia', 'santander'
    };

    final palabrasOriginales = frase.split(RegExp(r'\s+'));
    final List<String> palabrasUtiles = [];

    for (var palabra in palabrasOriginales) {
      String limpia = palabra.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      limpia = limpia
          .replaceAll('é', 'e')
          .replaceAll('á', 'a')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');

      if (double.tryParse(limpia) == null && !hashSetStopWords.contains(limpia) && limpia.isNotEmpty) {
        palabrasUtiles.add(palabra.replaceAll(RegExp(r'[^\w\s\$\.]'), ''));
      }
    }

    String tituloSugerido = palabrasUtiles.join(' ').trim();

    if (tituloSugerido.isEmpty) {
      tituloSugerido = 'Gasto por Dictado';
    } else {
      tituloSugerido = tituloSugerido[0].toUpperCase() + tituloSugerido.substring(1);
    }

    _mostrarFormularioGasto(
      gastoInicialIA: Gasto(
        id: '',
        titulo: tituloSugerido,
        monto: montoEncontrado,
        categoria: catEncontrada,
        subcategoria: '',
        medioPagoId: medioIdEncontrado,
        fecha: DateTime.now(),
        ambito: ambitoEncontrado,
      ),
    );
  }

  void _abrirModalDictadoVoz() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.teal),
            SizedBox(width: 8),
            Text('Dictar o escribir Gasto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tocá el micrófono del teclado de tu iPhone para dictar.\nEj: "Gasté 18500 en farmacia con Mercado Pago para el negocio"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Hablá o escribí acá...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
            label: const Text('Cargar Gasto', style: TextStyle(color: Colors.white)),
            onPressed: () {
              final texto = textController.text;
              Navigator.of(ctx).pop();
              _procesarFraseLocalmente(texto);
            },
          ),
        ],
      ),
    );
  }

  void _confirmarYBorrarTodosLosGastos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Borrar Todos los Gastos'),
        content: const Text(
          '¿Estás seguro de que querés eliminar TODOS los gastos registrados?\n\n'
          'Tus tarjetas y cuentas NO se borrarán. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _gastos.clear();
              });
              _guardarGastos();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Se han eliminado todos los gastos correctamente.')),
              );
            },
            child: const Text('Sí, Borrar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarYBorrarGasto(String id, String titulo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular / Eliminar Gasto'),
        content: Text('¿Estás seguro de que querés eliminar "$titulo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _eliminarGasto(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<MedioPago?> _agregarNuevoMedioPagoDialog() async {
    final nombreController = TextEditingController();
    final entidadController = TextEditingController();
    final ultimos4Controller = TextEditingController();
    String tipoSeleccionado = 'Crédito';

    return await showDialog<MedioPago>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Tarjeta / Cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre (ej: Visa Platinum)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: entidadController,
                decoration: const InputDecoration(labelText: 'Entidad / Banco (ej: BBVA, Balanz)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Cuenta', border: OutlineInputBorder()),
                items: ['Crédito', 'Débito', 'Fintech', 'Bolsa', 'Efectivo']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => tipoSeleccionado = val!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ultimos4Controller,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Últimos 4 dígitos (opcional)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                if (nombreController.text.isNotEmpty && entidadController.text.isNotEmpty) {
                  final nuevoMedio = MedioPago(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nombre: nombreController.text,
                    entidad: entidadController.text,
                    tipo: tipoSeleccionado,
                    ultimos4: ultimos4Controller.text,
                  );
                  setState(() => _mediosPago.add(nuevoMedio));
                  _guardarMediosPago();
                  Navigator.of(ctx).pop(nuevoMedio);
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<Gasto> get _gastosFiltradosPorFecha {
    final ahora = DateTime.now();
    return _gastos.where((gasto) {
      if (_filtroActual == FiltroFecha.esteMes) {
        return gasto.fecha.year == ahora.year && gasto.fecha.month == ahora.month;
      } else if (_filtroActual == FiltroFecha.mesAnterior) {
        final mesPasado = DateTime(ahora.year, ahora.month - 1);
        return gasto.fecha.year == mesPasado.year && gasto.fecha.month == mesPasado.month;
      }
      return true;
    }).toList();
  }

  List<Gasto> get _gastosFiltradosParaReporte {
    final base = _gastosFiltradosPorFecha;
    if (_filtroAmbitoReporte == FiltroAmbito.personal) {
      return base.where((g) => g.ambito == 'Personal').toList();
    } else if (_filtroAmbitoReporte == FiltroAmbito.negocio) {
      return base.where((g) => g.ambito == 'Negocio').toList();
    }
    return base;
  }

  double get _totalGastosFiltrados => _gastosFiltradosPorFecha.fold(0, (sum, item) => sum + item.monto);
  double get _totalGastosReporte => _gastosFiltradosParaReporte.fold(0, (sum, item) => sum + item.monto);

  Map<String, double> get _gastosPorCategoriaReporte {
    final Map<String, double> resumen = {};
    for (var gasto in _gastosFiltradosParaReporte) {
      resumen[gasto.categoria] = (resumen[gasto.categoria] ?? 0.0) + gasto.monto;
    }
    return resumen;
  }

  Map<String, double> get _gastosPorSubcategoriaReporte {
    final Map<String, double> resumen = {};
    for (var gasto in _gastosFiltradosParaReporte) {
      final key = gasto.subcategoria.isNotEmpty
          ? '${gasto.categoria} (${gasto.subcategoria})'
          : '${gasto.categoria} (Sin asignación)';
      resumen[key] = (resumen[key] ?? 0.0) + gasto.monto;
    }
    return resumen;
  }

  MedioPago _obtenerMedioPago(String id) {
    return _mediosPago.firstWhere(
      (m) => m.id == id,
      orElse: () => MedioPago(id: 'desconocido', nombre: 'Efectivo', entidad: 'Caja', tipo: 'Efectivo'),
    );
  }

  void _mostrarFormularioGasto({Gasto? gastoExistente, Gasto? gastoInicialIA}) {
    final esEdicion = gastoExistente != null;
    final base = gastoExistente ?? gastoInicialIA;

    final tituloController = TextEditingController(text: base != null ? base.titulo : '');
    final montoController = TextEditingController(
      text: (base != null && base.monto > 0) ? base.monto.toString().replaceAll('.', ',') : '',
    );
    final subCatController = TextEditingController(text: base != null ? base.subcategoria : '');

    String categoriaSeleccionada = (base != null && _categorias.contains(base.categoria))
        ? base.categoria
        : _categorias.first;

    String medioSeleccionadoId = (base != null && _mediosPago.any((m) => m.id == base.medioPagoId))
        ? base.medioPagoId
        : _mediosPago.first.id;

    String ambitoSeleccionado = base != null ? base.ambito : 'Personal';
    DateTime fechaSeleccionada = base != null ? base.fecha : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          List<DropdownMenuItem<String>> itemsMedios = _mediosPago.map((medio) {
            final label = medio.ultimos4.isNotEmpty ? '${medio.nombre} (*${medio.ultimos4})' : medio.nombre;
            return DropdownMenuItem(value: medio.id, child: Text(label, overflow: TextOverflow.ellipsis));
          }).toList();

          itemsMedios.add(
            const DropdownMenuItem<String>(
              value: '__CREAR_NUEVO__',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.teal, size: 18),
                  SizedBox(width: 6),
                  Text('+ Agregar nuevo medio...', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );

          return Padding(
            padding: EdgeInsets.only(
              top: 16, left: 16, right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      esEdicion ? 'Editar Gasto' : 'Nuevo Gasto',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (esEdicion)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar / Anular Gasto',
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmarYBorrarGasto(gastoExistente.id, gastoExistente.titulo);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Personal', label: Text('🏠 Personal'), icon: Icon(Icons.home)),
                      ButtonSegment(value: 'Negocio', label: Text('🏢 Negocio'), icon: Icon(Icons.business)),
                    ],
                    selected: {ambitoSeleccionado},
                    onSelectionChanged: (val) => setModalState(() => ambitoSeleccionado = val.first),
                  ),
                ),
                const SizedBox(height: 12),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: tituloController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _conceptosFrecuentes;
                    }
                    return _conceptosFrecuentes.where((option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    tituloController.text = selection;
                  },
                  fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                    fieldTextEditingController.addListener(() {
                      tituloController.text = fieldTextEditingController.text;
                    });
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Concepto / Descripción',
                        hintText: 'Ej: Cuota Colegio, Proveedor, Alquiler...',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (\$)',
                    hintText: '0,00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: categoriaSeleccionada,
                        decoration: const InputDecoration(labelText: 'Rubro Principal', border: OutlineInputBorder()),
                        items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (val) => setModalState(() => categoriaSeleccionada = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AUTOCOMPLETE INTELIGENTE PARA SUBRUBRO / CENTRO COSTOS
                    Expanded(
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: subCatController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _subcategoriasFrecuentes;
                          }
                          return _subcategoriasFrecuentes.where((option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          subCatController.text = selection;
                        },
                        fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                          fieldTextEditingController.addListener(() {
                            subCatController.text = fieldTextEditingController.text;
                          });
                          return TextField(
                            controller: fieldTextEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Subrubro / Centro Costos',
                              hintText: 'Ej: Mateo, Sucursal 1',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: medioSeleccionadoId,
                        decoration: const InputDecoration(labelText: 'Medio de Pago', border: OutlineInputBorder()),
                        items: itemsMedios,
                        onChanged: (val) async {
                          if (val == '__CREAR_NUEVO__') {
                            final nuevoMedio = await _agregarNuevoMedioPagoDialog();
                            if (nuevoMedio != null) {
                              setModalState(() {
                                medioSeleccionadoId = nuevoMedio.id;
                              });
                            }
                          } else if (val != null) {
                            setModalState(() => medioSeleccionadoId = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) setModalState(() => fechaSeleccionada = pickedDate);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatearFecha(fechaSeleccionada)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      final titulo = tituloController.text;
                      final textoMontoLimpio = montoController.text.replaceAll(',', '.');
                      final monto = double.tryParse(textoMontoLimpio) ?? 0.0;

                      if (titulo.isNotEmpty && monto > 0) {
                        _agregarOActualizarGasto(
                          id: esEdicion ? gastoExistente.id : null,
                          titulo: titulo,
                          monto: monto,
                          categoria: categoriaSeleccionada,
                          subcategoria: subCatController.text.trim(),
                          medioPagoId: medioSeleccionadoId,
                          fecha: fechaSeleccionada,
                          ambito: ambitoSeleccionado,
                        );
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: Text(
                      esEdicion ? 'Actualizar Gasto' : 'Guardar Gasto',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AriGastos'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'Agregar Tarjeta / Cuenta',
            onPressed: () => _agregarNuevoMedioPagoDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'borrar_todo') {
                _confirmarYBorrarTodosLosGastos();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'borrar_todo',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Borrar todos los gastos', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal.shade100,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Periodo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<FiltroFecha>(
                  segments: const [
                    ButtonSegment(value: FiltroFecha.esteMes, label: Text('Este Mes')),
                    ButtonSegment(value: FiltroFecha.mesAnterior, label: Text('Mes Anterior')),
                    ButtonSegment(value: FiltroFecha.todos, label: Text('Todos')),
                  ],
                  selected: {_filtroActual},
                  onSelectionChanged: (newSelection) => setState(() => _filtroActual = newSelection.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0 ? _buildVistaGastos() : _buildVistaReportes(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Reportes',
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btn_mic',
            onPressed: () => _abrirModalDictadoVoz(),
            backgroundColor: Colors.amber.shade800,
            tooltip: 'Dictar por voz',
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'btn_add',
            onPressed: () => _mostrarFormularioGasto(),
            backgroundColor: Colors.teal,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Gasto', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaGastos() {
    final listaActual = _gastosFiltradosPorFecha;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          color: Colors.teal.shade50,
          child: Column(
            children: [
              Text(_getTituloPeriodo().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '\$${_totalGastosFiltrados.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: listaActual.isEmpty
              ? Center(
                  child: Text(
                    'No hay gastos registrados en ${_getTituloPeriodo().toLowerCase()}.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: listaActual.length,
                  itemBuilder: (ctx, index) {
                    final gasto = listaActual[index];
                    final medio = _obtenerMedioPago(gasto.medioPagoId);
                    final tieneSubCat = gasto.subcategoria.isNotEmpty;
                    final esNegocio = gasto.ambito == 'Negocio';

                    return Dismissible(
                      key: ValueKey(gasto.id),
                      background: Container(
                        color: Colors.red.shade400,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _eliminarGasto(gasto.id),
                      child: ListTile(
                        onTap: () => _mostrarFormularioGasto(gastoExistente: gasto),
                        leading: CircleAvatar(
                          backgroundColor: esNegocio ? Colors.indigo.shade100 : Colors.teal.shade100,
                          child: Icon(
                            esNegocio ? Icons.business : _getIconoMedioPago(medio.tipo),
                            color: esNegocio ? Colors.indigo.shade800 : Colors.teal.shade800,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(gasto.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: esNegocio ? Colors.indigo.shade50 : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: esNegocio ? Colors.indigo.shade200 : Colors.teal.shade200),
                              ),
                              child: Text(
                                esNegocio ? '🏢 Negocio' : '🏠 Personal',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: esNegocio ? Colors.indigo.shade900 : Colors.teal.shade900,
                                ),
                              ),
                            ),
                            if (tieneSubCat) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  gasto.subcategoria,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${gasto.categoria} • ${medio.nombre} (${medio.entidad}) • ${_formatearFecha(gasto.fecha)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${gasto.monto.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVistaReportes() {
    final total = _totalGastosReporte;

    final resumen = _modoReporte == ModoReporte.porCategoria
        ? _gastosPorCategoriaReporte
        : _gastosPorSubcategoriaReporte;

    final itemsConGasto = resumen.entries.where((e) => e.value > 0).toList();

    final diasEnPeriodo = _filtroActual == FiltroFecha.esteMes
        ? DateTime.now().day
        : (_filtroActual == FiltroFecha.mesAnterior ? 30 : 1);
    final promedioDiario = total / (diasEnPeriodo == 0 ? 1 : diasEnPeriodo);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: SegmentedButton<FiltroAmbito>(
            segments: const [
              ButtonSegment(value: FiltroAmbito.todos, label: Text('Todos')),
              ButtonSegment(value: FiltroAmbito.personal, label: Text('🏠 Personal')),
              ButtonSegment(value: FiltroAmbito.negocio, label: Text('🏢 Negocio')),
            ],
            selected: {_filtroAmbitoReporte},
            onSelectionChanged: (val) => setState(() => _filtroAmbitoReporte = val.first),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.teal.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promedio Diario Estimado', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('\$${promedioDiario.toStringAsFixed(2)} / día', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                  ],
                ),
                Icon(Icons.calendar_month_outlined, color: Colors.teal.shade800, size: 32),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SegmentedButton<ModoReporte>(
            segments: const [
              ButtonSegment(value: ModoReporte.porCategoria, label: Text('Por Rubro')),
              ButtonSegment(value: ModoReporte.porSubcategoria, label: Text('Por Subrubro')),
            ],
            selected: {_modoReporte},
            onSelectionChanged: (val) => setState(() => _modoReporte = val.first),
          ),
        ),
        const SizedBox(height: 20),
        if (total == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Sin datos para generar el gráfico con este filtro.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else ...[
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: DonutChartPainter(
                data: itemsConGasto.map((e) => e.value).toList(),
                colors: List.generate(itemsConGasto.length, (i) => _paletaColores[i % _paletaColores.length]),
                total: total,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total Filtrado', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(itemsConGasto.length, (index) {
            final entry = itemsConGasto[index];
            final color = _paletaColores[index % _paletaColores.length];
            final porcentaje = (entry.value / total) * 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('${porcentaje.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Text('\$${entry.value.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _getTituloPeriodo() {
    switch (_filtroActual) {
      case FiltroFecha.esteMes:
        return 'Gasto de Este Mes';
      case FiltroFecha.mesAnterior:
        return 'Gasto del Mes Anterior';
      case FiltroFecha.todos:
        return 'Gasto Histórico Total';
    }
  }

  String _formatearFecha(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  IconData _getIconoMedioPago(String tipo) {
    switch (tipo) {
      case 'Crédito':
      case 'Débito':
        return Icons.credit_card;
      case 'Fintech':
        return Icons.phone_android;
      case 'Bolsa':
        return Icons.show_chart;
      default:
        return Icons.attach_money;
    }
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final double total;

  DonutChartPainter({required this.data, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 26.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * pi;
      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + 0.03,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}