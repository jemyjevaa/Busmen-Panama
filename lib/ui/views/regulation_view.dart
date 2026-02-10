import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/language_service.dart';
import '../../core/viewmodels/regulation_viewmodel.dart';

class RegulationView extends StatefulWidget {
  const RegulationView({super.key});

  @override
  State<RegulationView> createState() => _RegulationViewState();

}

class _RegulationViewState extends State<RegulationView> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
    });
  }

  @override
  Widget build(BuildContext context) {

    final language = context.watch<LanguageService>();
    final viewModel = context.watch<RegulationViewmodel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text( language.getString("regulations") ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: (){
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        )
      ),
    );
  }

}