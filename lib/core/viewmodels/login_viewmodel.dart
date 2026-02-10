import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/models/company_validate_model.dart';
import 'package:busmen_panama/core/services/models/user_validate_model.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:flutter/material.dart';

import '../../app_globals.dart';
import '../../ui/views/home_view.dart';
import '../services/language_service.dart';
import '../services/models/create_new_user_model.dart';
import '../services/models/domine_validate_model.dart';
import '../services/models/recovery_pasword_model.dart';
import '../services/url_service.dart';
import '../services/socket_service.dart';

class LoginViewModel extends ChangeNotifier {

  final language = LanguageService();

  final formKeyLogin = GlobalKey<FormState>();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  UrlService urlService = UrlService();
  RequestService callApi = RequestService.instance;


  final int _identifiedCompany = 0; // 0: None, 1: Empresa 1, 2: Empresa 2
  int get identifiedCompany => _identifiedCompany;

  bool isOtherDomine = false;
  bool loadingLogIn = false;
  bool loadingCreateUser = false;
  bool loadingRecoveryPwd = false;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  LoginViewModel() {
    // Keep listener as backup, but we'll use direct calls for better reliability
    userController.addListener(_onUserChanged);
  }

  void identifyCompany(String val) {
    final trimmed = val.trim();
    final regex = RegExp(r'@([^\.]+)\.');
    final match = regex.firstMatch(trimmed);

    if (match != null) {
      String resultado = match.group(1)!;

      CacheUserSession().isCopaair = urlService.nombres.contains(resultado);

    }
    else{
      CacheUserSession().isCopaair = false;
    }

    notifyListeners();

  }

  void _onUserChanged() => identifyCompany(userController.text);

  bool _rememberMe = CacheUserSession().isPerduration;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe(bool? value) {
    _rememberMe = value ?? false;
    CacheUserSession().isPerduration = _rememberMe;
    // print("isPerduration => ${CacheUserSession().isPerduration}");
    perdureSession();
    notifyListeners();
  }

  void perdureSession(){
    CacheUserSession().perdureEmail = CacheUserSession().isPerduration? userController.text:"";
    CacheUserSession().perdurePass = CacheUserSession().isPerduration?  passwordController.text:"";
  }

  Future<void> login(BuildContext context) async {

    loadingLogIn = !loadingLogIn;
    notifyListeners();

    if (!formKeyLogin.currentState!.validate()) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(language.getString('fill_all_fields')),
          backgroundColor: Colors.red,
        ),
      );
      loadingLogIn = !loadingLogIn;
      notifyListeners();
      return;
    }

    try{
      // region VALIDATE DOMINE
      ResponseValidateDomine? respDomine = await callApi.handlingRequestParsed<ResponseValidateDomine>(
          urlParam: urlService.getUrlDomineValidate(),
          method: "POST",
          params: {'correo': userController.text},
          fromJson: (json) {
            print("respDomine-json => $json");
            return ResponseValidateDomine.fromJson(json);
          },
      );

      print("respDomine => ${respDomine}");

      if( respDomine == null || respDomine.respuesta != "correcto" ){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('error_domine')),
            backgroundColor: Colors.red,
          ),
        );
        loadingLogIn = !loadingLogIn;
        notifyListeners();
        return;
      }
      // endregion VALIDATE DOMINE

      // region VALIDATE COMPANY
      ResponseValidateCompany? respCompany = await callApi.handlingRequestParsed(
          urlParam: urlService.getUrlCompanyValidate(),
          params: {"idempresa": respDomine.datos.first.id},
          method: 'POST',
          fromJson: (json){
            print("respCompany-json => $json");
            return ResponseValidateCompany.fromJson(json);
          }
      );

      print("respCompany => $respCompany");

      if( respCompany == null || respCompany.respuesta != "existe" ){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('error_domine')),
            backgroundColor: Colors.red,
          ),
        );
        loadingLogIn = !loadingLogIn;
        notifyListeners();
        return;
      }
      // endregion VALIDATE COMPANY

      // region VALIDATE USER
      ResponseValidateUser? respUser = await callApi.handlingRequestParsed<ResponseValidateUser>(
        urlParam: urlService.getUrlUserValidate(),
        method: "POST",
        params: {
          "usuario": userController.text,
          "clave": passwordController.text,
          "empresa": respCompany.datos.first.clave
        },
        fromJson: (json) {
          print("respUser-json => $json");
          return ResponseValidateUser.fromJson(json);
        }
      );
      print("respUser => ${respUser?.respuesta}");
      
      if( respUser == null || respUser.respuesta != "existe" ){
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('error_user')),
            backgroundColor: Colors.red,
          ),
        );
        loadingLogIn = !loadingLogIn;
        notifyListeners();
        return;
      }

      CacheUserSession().companyLatLog = respCompany.datos.first.latitud_longitud;
      CacheUserSession().companyClave = respCompany.datos.first.clave;
      CacheUserSession().companyImg = respCompany.datos.first.url;
      CacheUserSession().companyName = respCompany.datos.first.nombre;
      CacheUserSession().companyEmail = respCompany.datos.first.correos;
      CacheUserSession().companyPhone = respCompany.datos.first.telefonos;
      
      print("DEBUG - COMPANY DATA: ${respCompany.datos.first.nombre}, Phone: '${respCompany.datos.first.telefonos}', Emails: '${respCompany.datos.first.correos}'");
      print("DEBUG - FULL COMPANY API RESPONSE READY");
      
      print("DEBUG - COMPANY CLAVE FROM API: '${respCompany.datos.first.clave}'");

      // Determine userSide based on company (Case insensitive)
      final claveUpper = respCompany.datos.first.clave.toUpperCase();
      if (claveUpper == "COPAAIR" || claveUpper == "GRAINGER") {
        CacheUserSession().userSide = 2;
        CacheUserSession().isCopaair = true;
      } else {
        CacheUserSession().userSide = 1;
        CacheUserSession().isCopaair = false;
      }
      
      print("DEBUG - SETTING USER SIDE TO: ${CacheUserSession().userSide}");

      CacheUserSession().userName = respUser.datos.first.nombre;
      CacheUserSession().userEmail = respUser.datos.first.email;
      CacheUserSession().loginUser = userController.text;
      CacheUserSession().userIdCli = respUser.datos.first.id_cli;
      print("Sesión guardada - Usuario: ${CacheUserSession().userName}, Email: ${CacheUserSession().userEmail}");
      CacheUserSession().userRuta1 = respUser.datos.first.ruta1;
      CacheUserSession().userRuta2 = respUser.datos.first.ruta2;
      CacheUserSession().userRuta3 = respUser.datos.first.ruta3;
      CacheUserSession().userRuta4 = respUser.datos.first.ruta4;
      CacheUserSession().userPassword = passwordController.text;
      CacheUserSession().isLogin = true;

      // Initialize GPS session cookie for WebSocket tracking (in background)
      print("DEBUG - Initializing GPS session cookie after successful login...");
      SocketService().initSessionCookie().then((success) {
        if (success) {
          print("DEBUG - GPS session cookie ready for tracking");
        } else {
          print("WARNING - GPS session cookie initialization failed, tracking may not work");
        }
      });

      // OneSignal Tagging
      SocketService().setOneSignalTags(CacheUserSession().companyClave ?? "", CacheUserSession().userIdCli ?? "");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
      CacheUserSession().userEmail = userController.text;
      CacheUserSession().isLogin = true;
      perdureSession();
      // userController.text = "";
      // passwordController.text = "";

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('welcome')),
            backgroundColor: Colors.green,
          ),
        );
        loadingLogIn = !loadingLogIn;
        notifyListeners();
      }
      // endregion VALIDATE USER

    }catch( e ){
      loadingLogIn = !loadingLogIn;
      notifyListeners();
      print("Login error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.getString('error_user')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  }

  // region CREATE NEW USER
  final formKeyNewUser = GlobalKey<FormState>();
  final TextEditingController registerNewCompanyController = TextEditingController();
  final TextEditingController registerNewUserNameController = TextEditingController();
  final TextEditingController registerNewEmailController = TextEditingController();
  final TextEditingController registerNewUserController = TextEditingController();

  void registerUser(BuildContext context) async {
    hideKeyboard(context);
    if (!formKeyNewUser.currentState!.validate()) {
      return;
    }

    try{
      ResponseNewUser? respNewUser = await callApi.handlingRequestParsed<ResponseNewUser>(
          urlParam: urlService.getUrlNewUser(),
          method: "POST",
          params: {
            "empresa": registerNewCompanyController.text,
            "nombre_usuario": registerNewUserNameController.text,
            "correo": registerNewEmailController.text,
            "usuario": registerNewUserController.text
          },
          fromJson: (json) => ResponseNewUser.fromJson(json)
      );

      print("respNewUser => $respNewUser");

      if( respNewUser == null || respNewUser.respuesta != "registro correcto" ){
        print("error al crear");
        Navigator.pop(context);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('register_error')),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      registerNewCompanyController.clear();
      registerNewUserNameController.clear();
      registerNewEmailController.clear();
      registerNewUserController.clear();

      Navigator.pop(context);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(language.getString('register_success')),
          backgroundColor: Colors.green,
        ),
      );


    }catch(e){
      print("Register error: $e");
    }
  }

  // endregion CREATE NEW USER

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // region RECOVERY PWD
  final formKeyRecoveryPwd = GlobalKey<FormState>();
  final TextEditingController recoveryUserController = TextEditingController();
  final TextEditingController recoveryEmailController = TextEditingController();

  void recoverPassword(BuildContext context) async {
    hideKeyboard(context);
    if( !formKeyRecoveryPwd.currentState!.validate() ) return;

    _isProcessing = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isProcessing = false;
    notifyListeners();

    try{

      ResponseRecoveryPwd? respRecoveryPwd = await callApi.handlingRequestParsed<ResponseRecoveryPwd>(
        urlParam: urlService.getUrlRecoveryPwd(),
        params: {
          "usuario": recoveryUserController.text,
          "empresa": recoveryEmailController.text
        },
        method: 'POST',
        fromJson: (json){
          print("respRecoveryPwd-json => $json");
          return ResponseRecoveryPwd.fromJson(json);
        }
      );

      print("respRecoveryPwd => $respRecoveryPwd");

      if( respRecoveryPwd == null || respRecoveryPwd.respuesta == "error" ){
        print("Error al recuperar");
        Navigator.pop(context);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(language.getString('recovery_sent_error')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.pop(context);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(language.getString('recovery_sent')),
          backgroundColor: Colors.green,
        ),
      );


    }catch(e){
      print("Recovery error: $e");
    }
  }

  // endregion RECOVERY PWD

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    recoveryUserController.dispose();
    recoveryEmailController.dispose();
    registerNewCompanyController.dispose();
    registerNewUserNameController.dispose();
    registerNewEmailController.dispose();
    registerNewUserController.dispose();
    super.dispose();
  }
}
