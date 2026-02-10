class ResponseNewUser{
  final String respuesta;
  final String datos;

  ResponseNewUser({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseNewUser.fromJson(Map<String, dynamic> json){
    return ResponseNewUser(
      respuesta: json['respuesta'],
      datos: json['datos'],
    );
  }

}
