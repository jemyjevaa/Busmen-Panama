import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:busmen_panama/core/services/models/qr_route_model.dart';
import 'package:busmen_panama/core/services/request_service.dart';
import 'package:busmen_panama/core/services/url_service.dart';
import 'package:busmen_panama/ui/views/home_view.dart';

class QRScannerView extends StatefulWidget {
  const QRScannerView({super.key});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    autoStart: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isScanning = true;
  String? _statusMessage;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isLoading = false;

  final _urlService = UrlService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller.addListener(() {
      if (controller.value.isInitialized && _statusMessage == null) {
        if (mounted) setState(() => _statusMessage = 'Escáner listo. Enfoca el QR.');
      }
      if (controller.value.error != null) {
        final error = controller.value.error!;
        if (error.errorCode == MobileScannerErrorCode.genericError &&
            (error.errorDetails?.message?.contains('already started') ?? false)) {
          return; // harmless Android race condition
        }
        debugPrint('QRScanner: Controller error: ${error.errorCode}');
      }
    });

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.request().timeout(
        const Duration(seconds: 5),
        onTimeout: () => PermissionStatus.denied,
      );

      if (mounted) {
        setState(() {
          _hasPermission = status.isGranted;
          _isCheckingPermission = false;
          if (status.isPermanentlyDenied) {
            _statusMessage = 'El permiso fue denegado permanentemente. Por favor, habilítalo en los ajustes.';
          } else if (!status.isGranted) {
            _statusMessage = 'Permiso de cámara denegado';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
          _statusMessage = 'Error al verificar permisos: $e';
        });
      }
    }
  }

  Future<void> _safeStart() async {
    try {
      if (!controller.value.isRunning) await controller.start();
    } catch (e) {
      debugPrint('QRScanner: safeStart error: $e');
    }
  }

  Future<void> _safeStop() async {
    try {
      if (controller.value.isRunning) await controller.stop();
    } catch (e) {
      debugPrint('QRScanner: safeStop error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) _safeStart();
    if (state == AppLifecycleState.inactive) _safeStop();
  }

  /// Extracts id_frecuencia from a URL like:
  /// https://lectorasbusmenpa.geovoy.com/...?id_frecuencia=73
  int? _extractIdFrecuencia(String raw) {
    try {
      final uri = Uri.tryParse(raw);
      if (uri == null) return null;

      // 1. New format: https://lectorasbusmenpa.geovoy.com/v2/q/71
      // pathSegments would be ['v2', 'q', '71']
      if (uri.pathSegments.length >= 3 &&
          uri.pathSegments[0] == 'v2' &&
          uri.pathSegments[1] == 'q') {
        return int.tryParse(uri.pathSegments[2]);
      }

      // 2. Legacy format: https://lectorasbusmenpa.geovoy.com/...?id_frecuencia=73
      if (uri.queryParameters.containsKey('id_frecuencia')) {
        return int.tryParse(uri.queryParameters['id_frecuencia']!);
      }
    } catch (_) {}
    return null;
  }

  /// Calls the frequency API and navigates to HomeView with the result.
  Future<void> _fetchAndNavigate(int idFrecuencia) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Consultando ruta... (ID: $idFrecuencia)';
    });

    try {
      final url = _urlService.getUrlQRFrecuencia(idFrecuencia);
      debugPrint('QRScanner: Calling API: $url');

      // Use RequestService so the JSESSIONID cookie is sent automatically
      final qrResponse = await RequestService.instance.handlingRequestParsed<QRRouteResponse>(
        urlParam: url,
        method: 'GET',
        fromJson: (json) => QRRouteResponse.fromJson(json as Map<String, dynamic>),
      );

      if (qrResponse != null) {
        debugPrint('QRScanner: Success! Route: ${qrResponse.frecuencia.nombre}');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeView(qrRoute: qrResponse)),
        );
      } else {
        debugPrint('QRScanner: API returned null — check credentials or endpoint');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isScanning = true;
            _statusMessage = 'No se pudo obtener la ruta. Intenta de nuevo.';
          });
        }
      }
    } catch (e) {
      debugPrint('QRScanner: Fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanning = true;
          _statusMessage = 'Error de conexión. Verifica tu internet.';
        });
      }
    }
  }

  /// Processes a detected barcode value.
  void _onCodeDetected(String code) async {
    if (!_isScanning || _isLoading) return;
    setState(() => _isScanning = false);

    debugPrint('QRScanner: Raw value: $code');
    setState(() => _statusMessage = 'Código detectado. Procesando...');

    // 1. Try to extract id_frecuencia from URL
    final idFromUrl = _extractIdFrecuencia(code);
    if (idFromUrl != null) {
      await _safeStop();
      await _fetchAndNavigate(idFromUrl);
      return;
    }

    // 2. Try plain integer — QR contains just the id_frecuencia number
    final idFromPlain = int.tryParse(code.trim());
    if (idFromPlain != null) {
      await _safeStop();
      await _fetchAndNavigate(idFromPlain);
      return;
    }

    // 3. Fallback: try to parse raw JSON Map (legacy support)
    try {
      final decoded = jsonDecode(code);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
      }
      final qrResponse = QRRouteResponse.fromJson(decoded);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeView(qrRoute: qrResponse)),
      );
    } catch (e) {
      debugPrint('QRScanner: Not a valid QR: $e');
      if (mounted) {
        setState(() {
          _isScanning = true;
          _statusMessage = 'QR no válido para ruta. Intenta con otro código.';
        });
        await _safeStart();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de Ruta'),
        backgroundColor: const Color(0xFF064DC3),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isCheckingPermission
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : !_hasPermission
              ? _buildPermissionError()
              : Stack(
                  children: [
                    // Camera
                    MobileScanner(
                      controller: controller,
                      placeholderBuilder: (context, child) => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text('Iniciando cámara...', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      errorBuilder: (context, error, child) {
                        if (error.errorCode == MobileScannerErrorCode.genericError &&
                            (error.errorDetails?.message?.contains('already started') ?? false)) {
                          return const SizedBox.shrink();
                        }
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al iniciar cámara: ${error.errorCode}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => controller.start(),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          final code = barcode.rawValue;
                          if (code != null) {
                            _onCodeDetected(code);
                            break;
                          }
                        }
                      },
                    ),

                    // Torch button
                    Positioned(
                      top: 20,
                      right: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          onPressed: () => controller.toggleTorch(),
                          icon: ValueListenableBuilder(
                            valueListenable: controller,
                            builder: (context, state, child) {
                              switch (state.torchState) {
                                case TorchState.on:
                                  return const Icon(Icons.flash_on, color: Colors.yellow);
                                default:
                                  return const Icon(Icons.flash_off, color: Colors.white);
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    // Scan frame
                    Center(
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isLoading ? Colors.orangeAccent : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : null,
                      ),
                    ),

                    // Bottom status
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              _isLoading
                                  ? 'Cargando ruta...'
                                  : 'Posiciona el QR dentro del recuadro',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_statusMessage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Text(
                                  _statusMessage!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (!_isLoading)
                              TextButton.icon(
                                onPressed: () async {
                                  await _safeStop();
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  setState(() {
                                    _isScanning = true;
                                    _statusMessage = 'Reiniciando...';
                                  });
                                  await _safeStart();
                                },
                                icon: const Icon(Icons.refresh, color: Colors.white70),
                                label: const Text('Reiniciar', style: TextStyle(color: Colors.white70)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Se requiere permiso de cámara\npara escanear el QR',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final status = await Permission.camera.status;
              if (status.isPermanentlyDenied) {
                await openAppSettings();
              } else {
                _checkPermission();
              }
            },
            child: Text(
              (_statusMessage?.contains('ajustes') ?? false)
                  ? 'Abrir Ajustes'
                  : 'Conceder Permiso',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}
