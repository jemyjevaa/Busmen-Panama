class AppNotification {
  final String id;
  final String titulo;
  final String mensaje;
  final String fecha;
  final String? tipoFlyer;
  final String? tipo;

  AppNotification({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    this.tipoFlyer,
    this.tipo,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      titulo: json['notificacion'] ?? json['titulo'] ?? '',
      mensaje: json['informacion'] ?? json['mensaje'] ?? '',
      fecha: json['fecha_alta'] ?? '',
      tipoFlyer: json['tipo_flyer']?.toString(),
      tipo: json['tipo']?.toString(),
    );
  }
}

class ResponseNotifications {
  final String respuesta;
  final List<AppNotification> datos;

  ResponseNotifications({required this.respuesta, required this.datos});

  factory ResponseNotifications.fromJson(Map<String, dynamic> json) {
    return ResponseNotifications(
      respuesta: json['respuesta'] ?? '',
      datos: (json['datos'] as List?)
              ?.map((item) => AppNotification.fromJson(item))
              .toList() ??
          [],
    );
  }
}
