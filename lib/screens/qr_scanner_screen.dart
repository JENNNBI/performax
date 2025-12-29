import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/bloc_exports.dart';

class QRScannerScreen extends StatefulWidget {
  static const String id = 'qr_scanner_screen';
  
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!isScanning) return;
    
    setState(() {
      isScanning = false;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.displayValue;
      if (qrData != null) {
        _handleScannedData(qrData);
      } else {
        _showErrorDialog('Geçersiz QR kod. Lütfen tekrar deneyin.');
      }
    }
  }

  void _handleScannedData(String qrData) async {
    // Universal URL resolution - support all link types
    final trimmedData = qrData.trim();
    
    // Check if it's a valid URL
    final Uri? uri = Uri.tryParse(trimmedData);
    
    if (uri != null && (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
      // Valid URL - open it
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          // Resume scanning after opening URL
          setState(() {
            isScanning = true;
          });
        } else {
          _showErrorDialog('Cannot open URL: $trimmedData');
        }
      } catch (e) {
        _showErrorDialog('Error opening URL: $e');
      }
    } else if (trimmedData.isNotEmpty) {
      // Try to treat as URL without scheme
      final urlWithScheme = 'https://$trimmedData';
      final uriWithScheme = Uri.tryParse(urlWithScheme);
      
      if (uriWithScheme != null && uriWithScheme.host.contains('.')) {
        try {
          if (await canLaunchUrl(uriWithScheme)) {
            await launchUrl(
              uriWithScheme,
              mode: LaunchMode.externalApplication,
            );
            setState(() {
              isScanning = true;
            });
          } else {
            _showErrorDialog('Cannot open URL: $urlWithScheme');
          }
        } catch (e) {
          _showErrorDialog('Error opening URL: $e');
        }
      } else {
        // Not a valid URL
        _showErrorDialog('Invalid QR code. Please scan a valid URL.');
      }
    } else {
      _showErrorDialog('Empty QR code data.');
    }
  }

  void _showErrorDialog(String message) {
    final languageBloc = context.read<LanguageBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageBloc.translate('scanning_error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
              });
            },
            child: Text(languageBloc.translate('try_again')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(languageBloc.translate('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(languageBloc.translate('qr_scanner')),
            centerTitle: true,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on_outlined),
                onPressed: () => controller.toggleTorch(),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                flex: 4,
                child: MobileScanner(
                  controller: controller,
                  onDetect: _handleBarcode,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_2_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageBloc.currentLanguage == 'tr'
                          ? 'QR kodunu kameranın görüş alanına getirin'
                          : 'Position the QR code within the camera view',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageBloc.currentLanguage == 'tr'
                          ? 'Tüm URL türleri desteklenir'
                          : 'Supports all URL types',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isScanning
                          ? (languageBloc.currentLanguage == 'tr'
                              ? 'Tarama devam ediyor...'
                              : 'Scanning...')
                          : (languageBloc.currentLanguage == 'tr'
                              ? 'İşleniyor...'
                              : 'Processing...'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 