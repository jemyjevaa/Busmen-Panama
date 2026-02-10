class ResponseChangePwd{
  final String respuesta;
  final String datos;

  ResponseChangePwd({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseChangePwd.fromJson(Map<String, dynamic> json){
    return ResponseChangePwd(
      respuesta: json['respuesta'],
      datos: json['datos'],
    );
  }

}