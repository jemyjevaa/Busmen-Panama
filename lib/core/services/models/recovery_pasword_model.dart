class ResponseRecoveryPwd{
  final String respuesta;
  final String datos;

  ResponseRecoveryPwd({
    required this.respuesta,
    required this.datos,
  });

  factory ResponseRecoveryPwd.fromJson(Map<String, dynamic> json){
    return ResponseRecoveryPwd(
      respuesta: json['respuesta'],
      datos: json['datos'],
    );
  }
}