class ResponseAnnouncements{
  final String respuesta;
  final List<ResponseAnnouncementsData> datos;

  ResponseAnnouncements({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseAnnouncements.fromJson(Map<String, dynamic> json) {
    return ResponseAnnouncements(
      respuesta: json['respuesta'],
      datos:json['respuesta'] != "correcto"? []:(json['datos'] as List?)
              ?.map((item) => ResponseAnnouncementsData.fromJson(item))
              .toList() ?? []
    );
  }

}

class ResponseAnnouncementsData{
  final String nombre;
  final String url;
  final String fecha_alta;
  final bool status;

  ResponseAnnouncementsData({
    required this.nombre,
    required this.url,
    required this.fecha_alta,
    required this.status
  });

  factory ResponseAnnouncementsData.fromJson(Map<String, dynamic> json) {
    return ResponseAnnouncementsData(
        nombre: json["nombre"],
        url: json["url"],
        fecha_alta: json["fecha_alta"],
        status: json["estatus"]
    );
  }

}