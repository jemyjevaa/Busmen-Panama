import 'dart:convert';

class GeneralOptionsResponse {
  final String respuesta;

  GeneralOptionsResponse({
    required this.respuesta,
  });

  factory GeneralOptionsResponse.fromJson(Map<String, dynamic> json) => GeneralOptionsResponse(
    respuesta: json["respuesta"] ?? "fallo",
  );

  Map<String, dynamic> toJson() => {
    "respuesta": respuesta,
  };
}

GeneralOptionsResponse generalOptionsResponseFromJson(String str) => GeneralOptionsResponse.fromJson(json.decode(str));

String generalOptionsResponseToJson(GeneralOptionsResponse data) => json.encode(data.toJson());
