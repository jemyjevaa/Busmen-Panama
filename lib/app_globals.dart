import 'package:busmen_panama/core/services/cache_user_session.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

/// FUNCTION GLOBAL TO HIDE KEYBOAR
void hideKeyboard(BuildContext context) {
  final currentFocus = FocusScope.of(context);

  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    currentFocus.unfocus();
  }
}
Color hexColor(String hex) {
  final hex_new = hex.isEmpty? CacheUserSession().colorOne:hex;
  print("COLOR => $hex | $hex_new | ${CacheUserSession().colorOne}");
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}
