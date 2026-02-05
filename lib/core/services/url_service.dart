import 'package:busmen_panama/core/services/cache_user_session.dart';

class UrlService {

  List<String> nombres = [ 'copaair', 'grainger' ];

  final String _urlBasegGeovoy = "https://geovoy.com/app/api/";
  final String _urlBaseLectorasPan = "https://lectorasbusmenpa.geovoy.com/api/";

  final String _urlBaseGeovoyAdmin = "https://geovoy.com/appadmin/api/";
  final String _urlBaseLectorasPanAdmin = "https://lectorasadminbusmenpa.geovoy.com/api/";

  final String _validateDominio  = "validarDominio";
  final String _validateCompany  = "validarempresa";
  final String _validateUser  = "validarusuario";

  late bool isExisted = nombres.contains(CacheUserSession().isCopaair);

  String getUrlDomineValidate(){
    return CacheUserSession().isCopaair? "$_urlBaseGeovoyAdmin$_validateDominio" : "$_urlBaseLectorasPanAdmin$_validateDominio";
  }

  String getUrlCompanyValidate(){
    return CacheUserSession().isCopaair? "$_urlBaseGeovoyAdmin$_validateCompany":"$_urlBaseLectorasPanAdmin$_validateCompany";
  }

  String getUrlUserValidate(){
    return CacheUserSession().isCopaair? "$_urlBasegGeovoy$_validateUser":"$_urlBaseLectorasPan$_validateUser";
  }

}