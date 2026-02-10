import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/notifications_viewmodel.dart';
import 'package:busmen_panama/core/services/models/notification_model.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:intl/intl.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();
    final localization = context.watch<LanguageService>();
    final primaryColor = const Color(0xFF064DC3);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              primaryColor.withOpacity(0.05),
              primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildCustomHeader(context, localization, primaryColor, viewModel.notifications.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => viewModel.loadNotifications(),
                color: primaryColor,
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF064DC3)))
                    : viewModel.notifications.isEmpty
                        ? Stack(
                            children: [
                              ListView(), // To enable pull-to-refresh
                              _buildEmptyState(viewModel, localization),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: viewModel.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = viewModel.notifications[index];
                              return _buildNotificationCard(notification, localization);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, LanguageService localization, Color primaryColor, int count) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withBlue(primaryColor.blue + 20),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    localization.getString('notification'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance for the back button
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 15),
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$count",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization.getString('notification'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(NotificationsViewModel viewModel, LanguageService localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF064DC3).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_rounded, size: 64, color: const Color(0xFF064DC3).withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text(
            localization.getString('no_notifications'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            localization.getString('notify_msg'),
            style: TextStyle(fontSize: 14, color: Colors.blueGrey[300]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => viewModel.loadNotifications(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(localization.getString('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064DC3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, LanguageService localization) {
    final style = _getNotificationStyle(notification.tipo, localization);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification, localization),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        style.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: style.color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        _formatDate(notification.fecha),
                        style: TextStyle(fontSize: 10, color: Colors.blueGrey[200], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.blueGrey[100], size: 20),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification, LanguageService localization) {
    final tipo = notification.tipo ?? "1";
    
    if (tipo == "1") {
      _showSimpleAlert(notification, localization);
    } else {
      _showDetailSheet(notification, localization);
    }
  }

  void _showSimpleAlert(AppNotification notification, LanguageService localization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(notification.titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(notification.mensaje, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.getString('close_btn'), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF064DC3))),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(AppNotification notification, LanguageService localization) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blueGrey[100],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getNotificationStyle(notification.tipo, localization).label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: _getNotificationStyle(notification.tipo, localization).color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.titulo,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatDate(notification.fecha),
                      style: TextStyle(color: Colors.blueGrey[300], fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 40),
                    Text(
                      notification.mensaje,
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getNotificationStyle(notification.tipo, localization).color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(localization.getString('understood'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotificationStyle _getNotificationStyle(String? tipo, LanguageService localization) {
    switch (tipo) {
      case "2":
        return _NotificationStyle(
          label: localization.getString('comunicado'),
          icon: Icons.campaign_rounded,
          color: const Color(0xFF10B981),
        );
      case "3":
        return _NotificationStyle(
          label: localization.getString('reglamento'),
          icon: Icons.description_rounded,
          color: const Color(0xFFF59E0B),
        );
      case "4":
        return _NotificationStyle(
          label: localization.getString('manual'),
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF8B5CF6),
        );
      case "5":
        return _NotificationStyle(
          label: localization.getString('reporte'),
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFFEF4444),
        );
      default:
        return _NotificationStyle(
          label: localization.getString('notificacion'),
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF064DC3),
        );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class _NotificationStyle {
  final String label;
  final IconData icon;
  final Color color;

  _NotificationStyle({required this.label, required this.icon, required this.color});
}
