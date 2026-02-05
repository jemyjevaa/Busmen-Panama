class ResponseValidateCompany{
  final String respuesta;
  final List<ResponseValidateCompanyData> datos;

  ResponseValidateCompany({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseValidateCompany.fromJson(Map<String, dynamic> json){
    return ResponseValidateCompany(
      respuesta: json['respuesta'],
      datos:json['respuesta'] != "existe"? []:(json['datos'] as List?)
          ?.map((item) => ResponseValidateCompanyData.fromJson(item))
          .toList() ??
          [],
    );
  }

}

class ResponseValidateCompanyData{
  final String nombre;
  final String clave;
  final String correos;
  final String telefonos;
  final String latitud_longitud;
  final String estatus;
  final String color1;
  final String color2;
  final String url;
  final String geocerca;
  final String webapi;
  final String proyecto;

  ResponseValidateCompanyData({
    required this.nombre,
    required this.clave,
    required this.correos,
    required this.telefonos,
    required this.latitud_longitud,
    required this.estatus,
    required this.color1,
    required this.color2,
    required this.url,
    required this.geocerca,
    required this.webapi,
    required this.proyecto
  });

  factory ResponseValidateCompanyData.fromJson(Map<String, dynamic> json){
    return ResponseValidateCompanyData(
      nombre: json['nombre'],
      clave: json['clave'],
      correos: json['correos'],
      telefonos: json['telefonos'],
      latitud_longitud: json['latitud_longitud'],
      estatus: json['estatus'],
      color1: json['color1'],
      color2: json['color2'],
      url: json['url'],
      geocerca: json['geocerca'],
      webapi: json['webapi'],
      proyecto: json['proyecto']
    );
  }

}