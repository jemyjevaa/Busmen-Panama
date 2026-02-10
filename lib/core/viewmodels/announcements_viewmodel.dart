import 'package:flutter/material.dart';

import '../../app_globals.dart';
import '../services/cache_user_session.dart';
import '../services/language_service.dart';
import '../services/models/flyer_model.dart';
import '../services/request_service.dart';
import '../services/url_service.dart';

class AnnouncementsViewModel extends ChangeNotifier {

  UrlService urlService = UrlService();
  RequestService callApi = RequestService.instance;
  final language = LanguageService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ResponseFlyerData> _announcements = [];
  List<ResponseFlyerData> get announcements => _announcements;

  Future<void> loadAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try{
      ResponseFlyer? respAnnouncements = await callApi.handlingRequestParsed<ResponseFlyer>(
        urlParam: urlService.getUrlAnnouncements(),
        params: {
          "tipo_flyer": "2",
          "empresa": CacheUserSession().companyClave,
          "claveruta":""
        },
        method: 'POST',
        fromJson: (json){
          // print("respAnnouncements-json => $json");
          return ResponseFlyer.fromJson(json);
        }
      );

      print(respAnnouncements?.respuesta);
      if( respAnnouncements!.respuesta != "correcto" ){
        _announcements = [];
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('announcements_found')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      respAnnouncements.datos.forEach((element) {
        _announcements.add(element);
      });

      _announcements.sort((a, b) => b.fecha_alta.compareTo(a.fecha_alta));

    }catch(_){}

    /*_announcements = [
      "Aviso importante",
      "Cambio de horario",
      "Nueva actualización disponible",
    ];

     */

    _isLoading = false;
    notifyListeners();
  }
}
