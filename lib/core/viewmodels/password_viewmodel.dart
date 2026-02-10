import 'package:flutter/material.dart';

import '../services/cache_user_session.dart';
import '../services/language_service.dart';
import '../services/models/change_password_model.dart';
import '../services/request_service.dart';
import '../services/url_service.dart';

class PasswordViewModel extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();

  final language = LanguageService();

  UrlService urlService = UrlService();
  RequestService callApi = RequestService.instance;
  
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _obscureText = true;
  bool get obscureText => _obscureText;

  void toggleVisibility() {
    _obscureText = !_obscureText;
    notifyListeners();
  }

  Future<void> changePassword(BuildContext context) async {
    if (newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language.getString('new_password_hint'))),
      );
      return;
    }

    _isSubmitting = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    try{
      ResponseChangePwd? respChangePwd = await callApi.handlingRequestParsed<ResponseChangePwd>(
        urlParam: urlService.getUrlChangePwd(),
        params: {
          "usuario":CacheUserSession().userEmail,
          "passwordnuevo":newPasswordController.text,
          "empresa":CacheUserSession().companyClave
        },
        method: 'POST',
        fromJson: (json) => ResponseChangePwd.fromJson(json)
      );
      print("respChangePwd => $respChangePwd");
      if( respChangePwd?.respuesta == null || respChangePwd?.respuesta != "correcto" ){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(language.getString('new_password_hint'))),
        );
        _isSubmitting = false;
        notifyListeners();
        return;
      }

    }catch(_){

    }


    _isSubmitting = false;
    newPasswordController.clear();
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(language.getString('password_updated'))),
    );

    // Navigator.pop(context);
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    super.dispose();
  }
}
