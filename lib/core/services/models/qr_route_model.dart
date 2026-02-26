class QRRouteResponse {
  final QRMetadata metadata;
  final QRFrecuencia frecuencia;
  final List<QRParada> paradas;

  QRRouteResponse({
    required this.metadata,
    required this.frecuencia,
    required this.paradas,
  });

  factory QRRouteResponse.fromJson(Map<String, dynamic> json) {
    return QRRouteResponse(
      metadata: QRMetadata.fromJson(json['metadata'] ?? {}),
      frecuencia: QRFrecuencia.fromJson(json['frecuencia'] ?? {}),
      paradas: (json['paradas'] as List? ?? [])
          .map((i) => QRParada.fromJson(i))
          .toList(),
    );
  }
}

class QRMetadata {
  final String version;
  final String fechaGeneracion;
  final String formato;
  final int idFrecuencia;

  QRMetadata({
    required this.version,
    required this.fechaGeneracion,
    required this.formato,
    required this.idFrecuencia,
  });

  factory QRMetadata.fromJson(Map<String, dynamic> json) {
    return QRMetadata(
      version: json['version'] ?? '',
      fechaGeneracion: json['fecha_generacion'] ?? '',
      formato: json['formato'] ?? '',
      idFrecuencia: json['id_frecuencia'] ?? 0,
    );
  }
}

class QRFrecuencia {
  final int id;
  final String nombre;
  final String horaInicio;
  final QRRuta ruta;

  QRFrecuencia({
    required this.id,
    required this.nombre,
    required this.horaInicio,
    required this.ruta,
  });

  factory QRFrecuencia.fromJson(Map<String, dynamic> json) {
    return QRFrecuencia(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      ruta: QRRuta.fromJson(json['ruta'] ?? {}),
    );
  }
}

class QRRuta {
  final String nombre;

  QRRuta({required this.nombre});

  factory QRRuta.fromJson(Map<String, dynamic> json) {
    return QRRuta(nombre: json['nombre'] ?? '');
  }
}

class QRParada {
  final int numero;
  final String nombre;
  final int tiempoMinutos;
  final double latitud;
  final double longitud;
  final String tipo;
  final String horaLlegada;
  final String horaSalida;

  QRParada({
    required this.numero,
    required this.nombre,
    required this.tiempoMinutos,
    required this.latitud,
    required this.longitud,
    required this.tipo,
    required this.horaLlegada,
    required this.horaSalida,
  });

  factory QRParada.fromJson(Map<String, dynamic> json) {
    return QRParada(
      numero: json['numero'] ?? 0,
      nombre: json['nombre'] ?? '',
      tiempoMinutos: json['tiempo_minutos'] ?? 0,
      latitud: (json['latitud'] as num? ?? 0.0).toDouble(),
      longitud: (json['longitud'] as num? ?? 0.0).toDouble(),
      tipo: json['tipo'] ?? '',
      horaLlegada: json['horaLlegada'] ?? '',
      horaSalida: json['horaSalida'] ?? '',
    );
  }
}
