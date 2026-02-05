class ResponseValidateUser{
  final String respuesta;
  final List<ResponseValidateUserData> datos;

  ResponseValidateUser({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseValidateUser.fromJson(Map<String, dynamic> json){
    return ResponseValidateUser(
      respuesta: json['respuesta'],
      datos:json['respuesta'] != "existe"? []:(json['datos'] as List?)
          ?.map((item) => ResponseValidateUserData.fromJson(item))
          .toList() ??
          [],
    );
  }

}

class ResponseValidateUserData{
  final String id;
  final String id_cli;
  final String nombre;
  final String ruta1;
  final String ruta2;
  final String ruta3;
  final String ruta4;
  final String horario;
  final String clave_parada;
  final String parada_ascenso;
  final String email;
  final String tipo_usuario;
  final String estatus;
  final String sesion;
  final String proyecto;

  ResponseValidateUserData({
    required this.id,
    required this.id_cli,
    required this.nombre,
    required this.ruta1,
    required this.ruta2,
    required this.ruta3,
    required this.ruta4,
    required this.horario,
    required this.clave_parada,
    required this.parada_ascenso,
    required this.email,
    required this.tipo_usuario,
    required this.estatus,
    required this.sesion,
    required this.proyecto
  });

  factory ResponseValidateUserData.fromJson(Map<String, dynamic> json){
    return ResponseValidateUserData(
      id: json['id'],
      id_cli: json['id_cli'],
      nombre: json['nombre'],
      ruta1: json['ruta1'],
      ruta2: json['ruta2'],
      ruta3: json['ruta3'],
      ruta4: json['ruta4'],
      horario: json['horario'],
      clave_parada: json['clave_parada'],
      parada_ascenso: json['parada_ascenso'],
      email: json['email'],
      tipo_usuario: json['tipo_usuario'],
      estatus: json['estatus'],
      sesion: json['sesion'],
      proyecto: json['proyecto']
    );
  }

}