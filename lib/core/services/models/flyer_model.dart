class ResponseFlyer{
  final String respuesta;
  final List<ResponseFlyerData> datos;

  ResponseFlyer({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseFlyer.fromJson(Map<String, dynamic> json) {
    return ResponseFlyer(
      respuesta: json['respuesta'],
      datos:json['respuesta'] != "correcto"? []:(json['datos'] as List?)
              ?.map((item) => ResponseFlyerData.fromJson(item))
              .toList() ?? []
    );
  }

}

class ResponseFlyerData{
  final String nombre;
  final String url;
  final String fecha_alta;
  final bool status;

  ResponseFlyerData({
    required this.nombre,
    required this.url,
    required this.fecha_alta,
    required this.status
  });

  factory ResponseFlyerData.fromJson(Map<String, dynamic> json) {
    return ResponseFlyerData(
        nombre: json["nombre"],
        url: json["url"],
        fecha_alta: json["fecha_alta"],
        status: json["estatus"]
    );
  }

}