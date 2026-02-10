import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/language_service.dart';
import '../../core/viewmodels/announcements_viewmodel.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AnnouncementsViewModel>().loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageService>();
    final viewModel = context.watch<AnnouncementsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(language.getString("announcements")),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.announcements.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(viewModel.announcements[index].nombre),
                  Center(
                    child: Text(viewModel.announcements[index].fecha_alta) ,
                  ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                              backgroundColor: Colors.white,
                              leading: IconButton(
                              icon: const Icon(Icons.home),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 6.0,
                              child: Image.network(
                                viewModel.announcements[index].url,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    viewModel.announcements[index].url,
                    fit: BoxFit.cover,
                  ),
                )

                ]
              ),
            ),
          );
        },
      ),
    );
  }
}
