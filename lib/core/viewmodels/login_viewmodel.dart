import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:busmen_panama/core/services/models/company_validate_model.dart';
import 'package:busmen_panama/core/services/models/user_validate_model.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:flutter/material.dart';

import '../../ui/views/home_view.dart';
import '../services/language_service.dart';
import '../services/models/create_new_user_model.dart';
import '../services/models/domine_validate_model.dart';
import '../services/models/recovery_pasword_model.dart';
import '../services/url_service.dart';

class LoginViewModel extends ChangeNotifier {

  final language = LanguageService();

  final formKeyLogin = GlobalKey<FormState>();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  UrlService urlService = UrlService();
  RequestService callApi = RequestService.instance;
  
  int _identifiedCompany = 0; // 0: None, 1: Empresa 1, 2: Empresa 2
  int get identifiedCompany => _identifiedCompany;

  bool isOtherDomine = false;

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

    /*int newCompany = 0;

    if (trimmed == '1') {
      newCompany = 1;
    } else if (trimmed == '2') {
      newCompany = 2;
    } else if (trimmed.contains('@')) {
      newCompany = 2;
    }

    if (newCompany != _identifiedCompany) {
      _identifiedCompany = newCompany;
      notifyListeners();
      debugPrint('Compañía identificada: $_identifiedCompany');
    }*/
  }

  void _onUserChanged() => identifyCompany(userController.text);

  bool _rememberMe = CacheUserSession().isPerduration;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe(bool? value) {
    _rememberMe = value ?? false;
    CacheUserSession().isPerduration = _rememberMe;
    print("isPerduration => ${CacheUserSession().isPerduration}");
    perdureSession();
    notifyListeners();
  }

  void perdureSession(){
    CacheUserSession().perdureEmail = CacheUserSession().isPerduration? userController.text:"";
    CacheUserSession().perdurePass = CacheUserSession().isPerduration?  passwordController.text:"";
  }

  Future<void> login(BuildContext context) async {

    if (!formKeyLogin.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language.getString('fill_all_fields')),
          backgroundColor: Colors.red,
        ),
      );
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

      if( respDomine!.respuesta != "correcto" ){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.getString('error_domine')),
            backgroundColor: Colors.red,
          ),
        );
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

      if( respCompany!.respuesta != "existe" ){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.getString('error_domine')),
            backgroundColor: Colors.red,
          ),
        );
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
      if( respUser!.respuesta != "existe" ){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.getString('error_user')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      CacheUserSession().companyLatLog = respCompany.datos.first.latitud_longitud;
      CacheUserSession().companyClave = respCompany.datos.first.clave;
      CacheUserSession().companyImg = respCompany.datos.first.url;
      CacheUserSession().companyName = respCompany.datos.first.nombre;
      CacheUserSession().companyEmail = respCompany.datos.first.correos;
      CacheUserSession().userIdCli = respUser.datos.first.id_cli;
      CacheUserSession().isLogin = true;
      perdureSession();
      userController.text = "";
      passwordController.text = "";
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
      // endregion VALIDATE USER

    }catch( _ ){

    }

  }

  // region CREATE NEW USER
  final formKeyNewUser = GlobalKey<FormState>();
  final TextEditingController registerNewCompanyController = TextEditingController();
  final TextEditingController registerNewUserNameController = TextEditingController();
  final TextEditingController registerNewEmailController = TextEditingController();
  final TextEditingController registerNewUserController = TextEditingController();

  void registerUser(BuildContext context) async {

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

      if( respNewUser!.respuesta != "registro correcto" ){
        print("error al crear");
        return;
      }

      registerNewCompanyController.clear();
      registerNewUserNameController.clear();
      registerNewEmailController.clear();
      registerNewUserController.clear();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(language.getString('register_success')) ));


    }catch(_){}

    /*if (registerNameController.text.isEmpty || registerEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos')));
      return;
    }

    _isProcessing = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isProcessing = false;
    notifyListeners();

    if (context.mounted) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario registrado correctamente')));
      registerNameController.clear();
      registerEmailController.clear();
    }
     */
  }

  // endregion CREATE NEW USER

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;


  // region RECOVERY PWD
  final formKeyRecoveryPwd = GlobalKey<FormState>();
  final TextEditingController recoveryUserController = TextEditingController();
  final TextEditingController recoveryEmailController = TextEditingController();

  void recoverPassword(BuildContext context) async {

    if( !formKeyRecoveryPwd.currentState!.validate() ) return;

    /*if (recoveryUserController.text.isEmpty || recoveryEmailController.text.isEmpty) {
      return;
    }*/

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
      print("respRecoveryPwd => ${respRecoveryPwd?.respuesta == null }");

      if( respRecoveryPwd?.respuesta == null || respRecoveryPwd?.respuesta == "error" ){
        print("Error al recuperar");
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(language.getString('recovery_sent')) ));


    }catch(_){

    }

    /*if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo de recuperación enviado')));
      recoveryUserController.clear();
      recoveryEmailController.clear();
    }*/
  }

  // region RECOVERY PWD
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
