import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/camera_management/presentation/bloc/camera_cubit.dart';

class CameraPairPage extends StatefulWidget {
  const CameraPairPage({super.key});

  @override
  State<CameraPairPage> createState() => _CameraPairPageState();
}

class _CameraPairPageState extends State<CameraPairPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _nameCtrl = TextEditingController(text: 'Camera');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _step = 0; // 0=scan, 1=form, 2=pairing, 3=success
  String? _cameraUid;
  String? _pairingCode;
  String _cameraType = 'entrance';
  String? _returnedApiKey;
  bool _scanProcessed = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_scanProcessed) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    try {
      final data = jsonDecode(barcode.rawValue!) as Map<String, dynamic>;
      final uid = data['camera_uid'] as String?;
      final code = data['pairing_code'] as String?;
      if (uid == null || code == null) {
        _showError('Invalid QR code: missing camera_uid or pairing_code');
        return;
      }
      _scanProcessed = true;
      _scannerController.stop();
      setState(() {
        _cameraUid = uid;
        _pairingCode = code;
        _step = 1;
      });
    } catch (_) {
      _showError('Invalid QR code format. Expected JSON with camera_uid and pairing_code.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _submitPairing() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.context.hasLotAccess) return;

    context.read<CameraCubit>().pairCamera(
          cameraUid: _cameraUid!,
          pairingCode: _pairingCode!,
          lotId: authState.context.requireLotId(),
          cameraType: _cameraType,
          name: _nameCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraCubit, CameraState>(
      listener: (context, state) {
        if (state is CameraPairing) {
          setState(() => _step = 2);
        } else if (state is CameraPairingSuccess) {
          setState(() {
            _step = 3;
            _returnedApiKey = state.result.apiKey;
          });
        } else if (state is CameraError) {
          setState(() => _step = 1);
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          title: Text(_stepTitle),
          leading: _step == 3
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
        ),
        body: switch (_step) {
          0 => _buildScanStep(),
          1 => _buildFormStep(),
          2 => _buildPairingStep(),
          3 => _buildSuccessStep(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'Scan QR Code',
        1 => 'Camera Details',
        2 => 'Pairing...',
        3 => 'Camera Paired!',
        _ => '',
      };

  Widget _buildScanStep() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onQrDetected,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Point your camera at the QR code sticker on the camera device.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.successColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QR Code Scanned',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Camera: $_cameraUid',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Camera Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            const Text('Camera Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'entrance', label: Text('Entrance')),
                ButtonSegment(value: 'exit', label: Text('Exit')),
              ],
              selected: {_cameraType},
              onSelectionChanged: (value) {
                setState(() => _cameraType = value.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _cameraType == 'entrance'
                  ? 'Entrance cameras automatically check in vehicles when they arrive.'
                  : 'Exit cameras notify employees when a vehicle is leaving.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitPairing,
                icon: const Icon(Icons.link),
                label: const Text('Pair Camera'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairingStep() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Pairing camera...'),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: AppTheme.successColor),
            const SizedBox(height: 24),
            Text(
              'Camera Paired Successfully!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'The camera "$_cameraUid" is now paired to your lot as ${_cameraType == "entrance" ? "an entrance" : "an exit"} camera.',
              textAlign: TextAlign.center,
            ),
            if (_returnedApiKey != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'The API key has been sent to the camera. It will connect automatically on next boot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.read<CameraCubit>().reloadCameras();
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
