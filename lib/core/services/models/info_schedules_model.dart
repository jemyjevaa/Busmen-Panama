class ResponseInfoRoutes {
  final String respuesta;
  final List<RouteData> datos;

  ResponseInfoRoutes({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseInfoRoutes.fromJson(Map<String, dynamic> json) {
    return ResponseInfoRoutes(
      respuesta: json['respuesta'] ?? 'error',
      datos: (json['datos'] is List)
          ? (json['datos'] as List)
              .map((item) => RouteData.fromJson(item))
              .toList()
          : [],
    );
  }
}

class RouteData {
  final String claveruta;
  final String nombre;
  final String tipo_ruta;
  final String tramo;
  final String? hora_inicio; // Added
  final String? hora_fin;    // Added
  final String? dia_ruta;    // Day of operation (LUN-VIE, SAB, DOM, etc.)

  RouteData({
    required this.claveruta,
    required this.nombre,
    required this.tipo_ruta,
    required this.tramo,
    this.hora_inicio,
    this.hora_fin,
    this.dia_ruta,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      claveruta: json['clave'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo_ruta: json['turno'] ?? '',
      tramo: json['tramo'] ?? '',
      hora_inicio: json['hora_inicio'],
      hora_fin: json['hora_fin'],
      dia_ruta: json['dia'], // API returns 'dia', not 'dia_ruta'
    );
  }
}

class ResponseInfoStops {
  final String respuesta;
  final List<StopData> datos;

  ResponseInfoStops({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseInfoStops.fromJson(Map<String, dynamic> json) {
    return ResponseInfoStops(
      respuesta: json['respuesta'] ?? 'error',
      datos: (json['datos'] is List)
          ? (json['datos'] as List)
              .map((item) => StopData.fromJson(item))
              .toList()
          : [],
    );
  }
}

class StopData {
  final String claveruta;
  final String nombre_parada;
  final String horario;
  final String estatus;
  final String hora_parada;
  final double latitud;
  final double longitud;
  final int numero_parada; // Added for ordering & tracking
  final String? url_imagen; // Added for stop photo

  StopData({
    required this.claveruta,
    required this.nombre_parada,
    required this.horario,
    required this.estatus,
    required this.hora_parada,
    required this.latitud,
    required this.longitud,
    required this.numero_parada,
    this.url_imagen,
  });

  factory StopData.fromJson(Map<String, dynamic> json) {
    return StopData(
      claveruta: json['clave_ruta'] ?? '',
      nombre_parada: json['nombre_parada'] ?? '',
      horario: json['turno_ruta'] ?? '',
      estatus: json['estatus'] ?? 'A tiempo',
      hora_parada: json['hora_parada'] ?? '',
      latitud: double.tryParse(json['latitud']?.toString() ?? '0') ?? 0.0,
      longitud: double.tryParse(json['longitud']?.toString() ?? '0') ?? 0.0,
      numero_parada: int.tryParse(json['numero_parada']?.toString() ?? '0') ?? 0,
      url_imagen: json['url_imagen'] ?? json['foto'] ?? json['imagen'] ?? json['url_foto'] ?? json['url'],
    );
  }
}

class ResponseInfoUnit {
  final String respuesta;
  final List<UnitData> datos;

  ResponseInfoUnit({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseInfoUnit.fromJson(Map<String, dynamic> json) {
    return ResponseInfoUnit(
      respuesta: json['respuesta'] ?? 'error',
      datos: (json['datos'] is List)
          ? (json['datos'] as List)
              .map((item) => UnitData.fromJson(item))
              .toList()
          : [],
    );
  }
}

class UnitData {
  final String claveruta;
  final String economico;
  final String lat;
  final String lon;
  final String? idplataformagps; // Device ID for WebSocket filtering

  UnitData({
    required this.claveruta,
    required this.economico,
    required this.lat,
    required this.lon,
    this.idplataformagps,
  });

  factory UnitData.fromJson(Map<String, dynamic> json) {
    return UnitData(
      claveruta: json['claveruta'] ?? '',
      economico: json['economico'] ?? '',
      lat: json['lat'] ?? '0.0',
      lon: json['lon'] ?? '0.0',
      idplataformagps: json['idplataformagps']?.toString(),
    );
  }
}

class ResponseFlyers {
  final String respuesta;
  final List<FlyerData> datos;

  ResponseFlyers({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseFlyers.fromJson(Map<String, dynamic> json) {
    return ResponseFlyers(
      respuesta: json['respuesta'] ?? 'error',
      datos: (json['datos'] is List)
          ? (json['datos'] as List)
              .map((item) => FlyerData.fromJson(item))
              .toList()
          : [],
    );
  }
}

class FlyerData {
  final String nombre;
  final String url;
  final String fecha_alta;
  final bool estatus;

  FlyerData({
    required this.nombre,
    required this.url,
    required this.fecha_alta,
    required this.estatus,
  });

  factory FlyerData.fromJson(Map<String, dynamic> json) {
    return FlyerData(
      nombre: json['nombre'] ?? '',
      url: json['url'] ?? '',
      fecha_alta: json['fecha_alta'] ?? '',
      estatus: json['estatus'] == true || json['estatus'] == 1,
    );
  }
}
