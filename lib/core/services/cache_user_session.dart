import 'package:shared_preferences/shared_preferences.dart';

class CacheUserSession {

  static final CacheUserSession _instance = CacheUserSession._internal();
  SharedPreferences? _prefs;

  factory CacheUserSession() {
    return _instance;
  }

  CacheUserSession._internal();

  // Inicializar SharedPreferences una sola vez (ejecutar al iniciar la app)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get isLogin => _prefs?.getBool('isLogin') ?? false;
  set isLogin(bool value) => _prefs?.setBool('isLogin', value);

  bool get isCopaair => _prefs?.getBool('isCopaair') ?? false;
  set isCopaair(bool value) => _prefs?.setBool('isCopaair', value);

  bool get isPerduration => _prefs?.getBool('isPerduration') ?? false;
  set isPerduration(bool value) => _prefs?.setBool('isPerduration', value);

  String get perdureEmail => _prefs?.getString('perdurantEmail') ?? '';
  set perdureEmail(String value) => _prefs?.setString('perdurantEmail', value);

  String get perdurePass => _prefs?.getString('perdurantPass') ?? '';
  set perdurePass(String value) => _prefs?.setString('perdurantPass', value);


  // region COMPANY DATA
  String? get companyLatLog => _prefs?.getString('companyLatLog');
  set companyLatLog(String? value) => _prefs?.setString('companyLatLog', value ?? '');

  String? get companyClave => _prefs?.getString('companyClave');
  set companyClave(String? value) => _prefs?.setString('companyClave', value ?? '');

  String? get companyImg => _prefs?.getString('companyImg');
  set companyImg(String? value) => _prefs?.setString('companyImg', value ?? '');

  String? get companyName => _prefs?.getString('companyName');
  set companyName(String? value) => _prefs?.setString('companyName', value ?? '');

  String? get companyEmail => _prefs?.getString('companyEmail');
  set companyEmail(String? value) => _prefs?.setString('companyEmail', value ?? '');
  // endregion COMPANY DATA

  // region USER DATA
  String? get userIdCli => _prefs?.getString('userIdCli');
  set userIdCli(String? value) => _prefs?.setString('userIdCli', value ?? '');
  // endregion USER DATA

  Future<void> clear() async {
    isLogin = false;
    isCopaair = false;
    companyLatLog = null;
    companyClave = null;
    companyImg = null;
    companyName = null;
    companyEmail = null;
    userIdCli = null;
  }

}