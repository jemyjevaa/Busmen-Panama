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
  final String _infoRoutesTramos = "inforutastramo";
  final String _infoStopsRoute = "infoparadasruta";
  final String _infoUnit = "infounidad";
  final String _infoFlyers = "infotipoflyers";
  final String _infoNotifications = "infonotificaciones";
  final String _positions = "positions";
  final String _changePassword = "cambiopassword";
  final String _lostObjects = "envioobjetos";

  final String _urlBaseTracking = "https://rastreobusmenpa.geovoy.com/api/";
  final String _urlSocket = "wss://rastreobusmenpa.geovoy.com/api/socket";
  final String _urlDirections = "https://maps.googleapis.com/maps/api/directions/json";
  final String _newUser  = "registrarusuarioinvitadotodos";
  final String _recoveryPwd  = "recuperarpassword";
  final String _changePwd  = "cambiopassword";
  final String _flyer  = "infotipoflyers";


  late bool isExisted = nombres.contains(CacheUserSession().isCopaair);


  String getUrlSocket() => _urlSocket;
  String getUrlDirections() => _urlDirections;
  String getUrlInfoPositions() => "$_urlBaseTracking$_positions";
  String getUrlInfoFlyers() => "$_urlBaseLectorasPan$_infoFlyers";
  String getUrlInfoNotifications() => "$_urlBaseLectorasPan$_infoNotifications";
  String getUrlLostObjects() => "$_urlBasegGeovoy$_lostObjects";

  
  bool get isSpecialCompany {
    final company = CacheUserSession().companyClave?.toLowerCase() ?? '';
    return company == 'transportepp' || company == 'london';
  }

  String getUrlDomineValidate(){
    return CacheUserSession().isCopaair? "$_urlBaseGeovoyAdmin$_validateDominio" : "$_urlBaseLectorasPanAdmin$_validateDominio";
  }

  String getUrlCompanyValidate(){
    return CacheUserSession().isCopaair? "$_urlBaseGeovoyAdmin$_validateCompany":"$_urlBaseLectorasPanAdmin$_validateCompany";
  }

  String getUrlUserValidate(){
    return CacheUserSession().isCopaair? "$_urlBasegGeovoy$_validateUser":"$_urlBaseLectorasPan$_validateUser";
  }

  String getUrlInfoRoutes(){
    return CacheUserSession().isCopaair 
      ? "$_urlBasegGeovoy$_infoRoutesTramos" 
      : "$_urlBaseLectorasPan$_infoRoutesTramos";
  }

  String getUrlInfoStops(){
    return CacheUserSession().isCopaair 
      ? "$_urlBasegGeovoy$_infoStopsRoute" 
      : "$_urlBaseLectorasPan$_infoStopsRoute";
  }

  String getUrlInfoUnit(){
    return CacheUserSession().isCopaair 
      ? "$_urlBasegGeovoy$_infoUnit" 
      : "$_urlBaseLectorasPan$_infoUnit";
  }

  // region INFORMATION
  String getUrlAnnouncements(){
    return CacheUserSession().isCopaair? "$_urlBasegGeovoy$_flyer":"$_urlBaseLectorasPan$_flyer";
  }
  // endregion INFORMATION


  String getUrlChangePassword() {
    return CacheUserSession().isCopaair 
      ? "$_urlBasegGeovoy$_changePassword" 
      : "$_urlBaseLectorasPan$_changePassword";
  }

  String getUrlNewUser(){
    return "$_urlBasegGeovoy$_newUser";
  }

  String getUrlRecoveryPwd(){
    return "$_urlBasegGeovoy$_recoveryPwd";
  }

  String getUrlChangePwd(){
    return "$_urlBaseLectorasPan$_changePwd";
  }


}