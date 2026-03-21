import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _api = KutootApi();
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _processing = false;
  String? _message;
  bool _showManualEntry = false;
  final _codeController = TextEditingController();
  Map<String, dynamic>? _lastScanData;

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _extractToken(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return '';

    if (input.startsWith('http://') || input.startsWith('https://')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
        final qrIdx = segments.indexOf('qr');
        if (qrIdx >= 0 && qrIdx + 1 < segments.length) {
          return segments[qrIdx + 1];
        }
        if (segments.isNotEmpty) return segments.last;
      }
    }

    return input;
  }

  String _readErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg != null) return msg.toString();
      }
      return 'Unable to validate QR right now';
    }
    return 'Unable to validate QR right now';
  }

  Future<void> _submitCode(String code) async {
    if (_processing) return;
    final token = _extractToken(code);
    if (token.isEmpty) return;
    setState(() {
      _processing = true;
      _message = null;
      _lastScanData = null;
    });
    try {
      final res = await _api.scanQr(token);
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      final payload = data['data'] is Map ? Map<String, dynamic>.from(data['data'] as Map) : data;
      final merchantLocation = payload['merchant_location'];
      final branchName = merchantLocation is Map ? (merchantLocation['branch_name']?.toString() ?? 'merchant') : 'merchant';
      final msg = payload['message']?.toString() ?? 'Connected to $branchName';

      if (mounted) {
        setState(() {
          _processing = false;
          _message = msg;
          _lastScanData = payload;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = _readErrorMessage(e);
          _processing = false;
        });
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue ?? barcodes.first.displayValue;
    if (code == null || code.isEmpty) return;

    await _submitCode(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_showManualEntry ? 'Enter Code' : 'Scan QR Code'),
        actions: _showManualEntry
            ? [
                TextButton(
                  onPressed: () => setState(() => _showManualEntry = false),
                  child: const Text('Scan', style: TextStyle(color: Colors.white)),
                ),
              ]
            : null,
      ),
      body: _showManualEntry
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter QR code / token',
                      hintText: 'Paste or type the code',
                    ),
                    onSubmitted: _submitCode,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processing ? null : () => _submitCode(_codeController.text),
                      child: _processing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit'),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(_message!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            )
          : Stack(
        children: [
          MobileScanner(onDetect: _onDetect, controller: _controller),
          if (_message != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lastScanData != null ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              ),
            ),
          if (_lastScanData != null)
            Positioned(
              bottom: 92,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _lastScanData),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Continue'),
              ),
            ),
          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: TextButton.icon(
              onPressed: () => setState(() => _showManualEntry = true),
              icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white),
              label: const Text('Enter code manually', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
