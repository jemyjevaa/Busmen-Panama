import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/viewmodels/operator_viewmodel.dart';
import '../../core/services/language_service.dart';
import '../../core/services/cache_user_session.dart';
import 'login_view.dart';

class OperatorHomeView extends StatefulWidget {
  const OperatorHomeView({super.key});

  @override
  State<OperatorHomeView> createState() => _OperatorHomeViewState();
}

class _OperatorHomeViewState extends State<OperatorHomeView> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperatorViewModel>().fetchRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<OperatorViewModel>();
    final localization = context.watch<LanguageService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localization.getString('operator_mode'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF064DC3),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await CacheUserSession().clear();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: model.isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF064DC3)))
          : model.selectedRoute == null 
              ? _buildRouteSelection(model, localization, isDark)
              : _buildOperatorConsole(model, localization, isDark),
    );
  }

  Widget _buildRouteSelection(OperatorViewModel model, LanguageService localization, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF064DC3),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.getString('select_route_operator'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Selecciona una unidad para iniciar simulación",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: model.availableRoutes.length,
            itemBuilder: (context, index) {
              final route = model.availableRoutes[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF064DC3).withOpacity(0.1),
                    child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF064DC3)),
                  ),
                  title: Text(
                    route.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    route.tramo,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF064DC3)),
                  onTap: () => model.selectRoute(route),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorConsole(OperatorViewModel model, LanguageService localization, bool isDark) {
    final currentStop = model.currentStopIndex >= 0 ? model.stops[model.currentStopIndex] : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoHeader(model, localization, isDark),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!model.isRouteStarted)
                  _buildStartAction(model, localization)
                else ...[
                  _buildTimerSection(model, localization, currentStop, isDark),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          onTap: model.toggleBusFull,
                          icon: Icons.people_rounded,
                          label: localization.getString('bus_full'),
                          isActive: model.isBusFull,
                          activeColor: Colors.orange,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // MARK ARRIVAL (Only active in transit)
                      Expanded(
                        child: _buildActionButton(
                          onTap: model.isInTransit ? model.arriveAtNextStop : null,
                          icon: Icons.check_circle_rounded,
                          label: localization.getString('mark_arrival'),
                          isActive: false,
                          activeColor: const Color(0xFF064DC3),
                          disabled: !model.isInTransit,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // LEAVE STOP (SIG. PARADA) - Active at stop
                      Expanded(
                        child: _buildActionButton(
                          onTap: !model.isInTransit ? model.nextStop : null,
                          icon: Icons.skip_next_rounded,
                          label: "SIG. PARADA",
                          isActive: false,
                          activeColor: Colors.blueGrey,
                          disabled: model.isInTransit,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildTimeline(model, isDark),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: model.endRoute,
                    child: Text(
                      localization.getString('end_route'),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader(OperatorViewModel model, LanguageService localization, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF064DC3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "OPERADOR ACTIVADO",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: model.isRouteStarted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: model.isRouteStarted ? Colors.green : Colors.orange),
                ),
                child: Text(
                  model.isRouteStarted ? "EN RUTA" : "PENDIENTE",
                  style: TextStyle(
                    color: model.isRouteStarted ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            model.selectedRoute!.nombre,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            model.selectedRoute!.tramo,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStartAction(OperatorViewModel model, LanguageService localization) {
    return ElevatedButton(
      onPressed: model.startRoute,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF064DC3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      child: Text(
        localization.getString('start_route'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimerSection(OperatorViewModel model, LanguageService localization, dynamic currentStop, bool isDark) {
    bool isWaiting = model.secondsAtStop < OperatorViewModel.minWaitSeconds;
    double progress = (model.secondsAtStop / OperatorViewModel.minWaitSeconds).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isWaiting ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              currentStop?.nombre_parada ?? '---',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(isWaiting ? Colors.orange : Colors.green),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      localization.getString('waiting_time'),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    Text(
                      model.formattedWaitTime,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isWaiting)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    localization.getString('stop_timer_warning'),
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              )
            else
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "¡TIEMPO MÍNIMO CUMPLIDO!",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    bool disabled = false,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isActive ? activeColor : (disabled ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
        ),
      ),
      color: isActive ? activeColor.withOpacity(0.1) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : (disabled ? Colors.grey[400] : const Color(0xFF064DC3)),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: isActive ? activeColor : (disabled ? Colors.grey[400] : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(OperatorViewModel model, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "LISTA DE PARADAS",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: model.stops.length,
          itemBuilder: (context, index) {
            final stop = model.stops[index];
            bool isPast = index < model.currentStopIndex;
            bool isCurrent = index == model.currentStopIndex;
            final waitTime = model.stopWaitTimes[index];

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF064DC3) : (isPast ? const Color(0xFF064DC3).withOpacity(0.4) : Colors.grey.withOpacity(0.3)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index < model.stops.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isPast ? const Color(0xFF064DC3).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stop.nombre_parada,
                              style: TextStyle(
                                color: isCurrent ? Colors.black : (isPast ? Colors.black.withOpacity(0.5) : Colors.grey),
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                decoration: isPast ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (isPast && waitTime != null)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                               decoration: BoxDecoration(
                                 color: Colors.grey.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Text(
                                 "$waitTime min",
                                 style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                               ),
                             ),
                        ],
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const Icon(Icons.location_on_rounded, color: Color(0xFF064DC3), size: 16),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
