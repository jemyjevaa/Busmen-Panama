class ResponseValidateDomine {
  final String respuesta;
  final List<ResponseValidateDomineData> datos;

  ResponseValidateDomine({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseValidateDomine.fromJson(Map<String, dynamic> json) {
    return ResponseValidateDomine(
      respuesta: json['respuesta'],
      datos:json['respuesta'] != "correcto"? []:(json['datos'] as List?)
              ?.map((item) => ResponseValidateDomineData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ResponseValidateDomineData {
  final String id;
  final String clave;

  ResponseValidateDomineData({
    required this.id,
    required this.clave,
  });

  factory ResponseValidateDomineData.fromJson(Map<String, dynamic> json) {
    return ResponseValidateDomineData(
      id: json['id'],
      clave: json['clave'],
    );
  }
}
