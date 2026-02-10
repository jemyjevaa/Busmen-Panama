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

  int get userSide => _prefs?.getInt('userSide') ?? 1;
  set userSide(int value) => _prefs?.setInt('userSide', value);

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

  String? get companyPhone => _prefs?.getString('companyPhone');
  set companyPhone(String? value) => _prefs?.setString('companyPhone', value ?? '');
  // endregion COMPANY DATA

  // region USER DATA
  String? get userIdCli => _prefs?.getString('userIdCli');
  set userIdCli(String? value) => _prefs?.setString('userIdCli', value ?? '');

  String? get userName => _prefs?.getString('userName');
  set userName(String? value) => _prefs?.setString('userName', value ?? '');

  String? get userEmail => _prefs?.getString('userEmail');
  set userEmail(String? value) => _prefs?.setString('userEmail', value ?? '');

  String? get loginUser => _prefs?.getString('loginUser');
  set loginUser(String? value) => _prefs?.setString('loginUser', value ?? '');

  String? get userRuta1 => _prefs?.getString('userRuta1');
  set userRuta1(String? value) => _prefs?.setString('userRuta1', value ?? '');

  String? get userRuta2 => _prefs?.getString('userRuta2');
  set userRuta2(String? value) => _prefs?.setString('userRuta2', value ?? '');

  String? get userRuta3 => _prefs?.getString('userRuta3');
  set userRuta3(String? value) => _prefs?.setString('userRuta3', value ?? '');

  String? get userRuta4 => _prefs?.getString('userRuta4');
  set userRuta4(String? value) => _prefs?.setString('userRuta4', value ?? '');

  String? get userPassword => _prefs?.getString('userPassword');
  set userPassword(String? value) => _prefs?.setString('userPassword', value ?? '');

  int get notificationsCount => _prefs?.getInt('notificationsCount') ?? 0;
  set notificationsCount(int value) => _prefs?.setInt('notificationsCount', value);
  // endregion USER DATA

}