import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:busmen_panama/core/services/models/qr_route_model.dart';
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
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isScanning = true;
  String? _lastError;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  Future<void>? _startingFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Diagnostic listener
    controller.addListener(() {
      if (controller.value.isInitialized && _lastError == null) {
        debugPrint('QRScanner: Controller initialized and ready');
        if (mounted) setState(() => _lastError = 'Escáner listo. Enfoca el QR.');
      }
      if (controller.value.error != null) {
        debugPrint('QRScanner: Controller error: ${controller.value.error}');
      }
    });

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    debugPrint('QRScanner: Checking camera permission...');
    try {
      // Add a timeout just in case request() hangs on some devices
      final status = await Permission.camera.request().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('QRScanner: Permission request timed out');
          return PermissionStatus.denied;
        },
      );
      
      debugPrint('QRScanner: Permission status: $status');
      
      if (mounted) {
        setState(() {
          _hasPermission = status.isGranted;
          _isCheckingPermission = false;
          if (!status.isGranted) {
            _lastError = 'Permiso de cámara denegado o expirado (Status: ${status.name})';
          }
        });
        if (status.isGranted) {
          debugPrint('QRScanner: Permission granted, initiating safe start...');
          // Give it a tiny bit of time for the widget to be ready
          Future.delayed(const Duration(milliseconds: 300), () => _safeStart());
        }
      }
    } catch (e) {
      debugPrint('QRScanner: Error checking permission: $e');
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
          _lastError = 'Error al verificar permisos: $e';
        });
      }
    }
  }

  Future<void> _safeStart() async {
    if (_startingFuture != null) {
      debugPrint('QRScanner: Already starting, waiting for previous future...');
      return _startingFuture;
    }

    if (!controller.value.isRunning) {
      debugPrint('QRScanner: Starting controller...');
      _startingFuture = controller.start().then((_) {
        debugPrint('QRScanner: Controller started successfully');
        _startingFuture = null;
      }).catchError((e) {
        debugPrint('QRScanner: Error in safeStart: $e');
        _startingFuture = null;
      });
      return _startingFuture;
    } else {
      debugPrint('QRScanner: Controller is already running.');
    }
  }

  Future<void> _safeStop() async {
    if (_startingFuture != null) {
      await _startingFuture;
    }
    if (controller.value.isRunning) {
      debugPrint('QRScanner: Stopping controller...');
      try {
        await controller.stop();
      } catch (e) {
        debugPrint('QRScanner: Error in safeStop: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _safeStart();
      case AppLifecycleState.inactive:
        _safeStop();
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
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
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
                        onPressed: _checkPermission,
                        child: const Text('Conceder Permiso'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    MobileScanner(
            controller: controller,
            scanWindow: Rect.fromLTWH(0, 0, 320, 320), // Focus on the larger center area
            placeholderBuilder: (context, child) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Iniciando cámara...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ?? 'Asegúrate de conceder permisos de cámara.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              final List<Barcode> barcodes = capture.barcodes;
              debugPrint('QRScanner: onDetect called. Found ${barcodes.length} barcodes');
              
              if (barcodes.isNotEmpty && mounted) {
                setState(() => _lastError = '¡Código detectado! Procesando...');
              }

              if (!_isScanning) return;
              
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                debugPrint('QRScanner: Raw value: $code');
                
                if (code != null) {
                  setState(() => _lastError = 'Detectado: ${code.length > 20 ? code.substring(0, 20) + "..." : code}');
                  
                  try {
                    debugPrint('QRScanner: Attempting to decode JSON...');
                    final Map<String, dynamic> jsonData = jsonDecode(code);
                    
                    debugPrint('QRScanner: Attempting to parse QRRouteResponse...');
                    final qrResponse = QRRouteResponse.fromJson(jsonData);
                    
                    debugPrint('QRScanner: Success! Navigating to HomeView...');
                    setState(() => _isScanning = false);
                    
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => HomeView(qrRoute: qrResponse),
                      ),
                    );
                    break;
                  } catch (e) {
                    debugPrint('QRScanner: Error processing QR: $e');
                    setState(() {
                      _isScanning = true;
                      _lastError = 'Error: QR no válido para ruta';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
          ),
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
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.white);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                      case TorchState.auto:
                        return const Icon(Icons.flash_auto, color: Colors.white);
                      case TorchState.unavailable:
                        return const Icon(Icons.flash_off, color: Colors.grey);
                    }
                  },
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'Posiciona el código QR dentro del recuadro',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_lastError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        _lastError!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () async {
                      await _safeStop();
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _safeStart();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    label: const Text('Reiniciar Cámara', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
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
