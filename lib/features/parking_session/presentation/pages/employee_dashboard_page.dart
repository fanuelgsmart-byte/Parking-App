import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/di/injection.dart';
import 'package:parkflow_manager/core/services/camera_websocket_service.dart';
import 'package:parkflow_manager/core/services/incident_service.dart';
import 'package:parkflow_manager/core/utils/validators.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/presentation/bloc/session_cubit.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  late final CameraWebSocketService _cameraService;
  StreamSubscription<PlateDetectionEvent>? _plateSub;
  StreamSubscription<ConnectionStatus>? _statusSub;
  ConnectionStatus _cameraStatus = ConnectionStatus.disconnected;

  String? _lastDetectedPlate;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraWebSocketService();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final lotId = authState.user.assignedLotId ?? 'default';
      context.read<SessionCubit>().loadActiveSessions(lotId);

      // Connect camera WebSocket
      // In production, the auth token comes from secure storage
      _cameraService.connect(lotId, authToken: '');

      _plateSub = _cameraService.plateStream.listen((event) {
        setState(() => _lastDetectedPlate = event.licensePlate);
        _showPlateDetectedSnackbar(event);
      });

      _statusSub = _cameraService.statusStream.listen((status) {
        setState(() => _cameraStatus = status);
      });
    }
  }

  @override
  void dispose() {
    _plateSub?.cancel();
    _statusSub?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  void _showPlateDetectedSnackbar(PlateDetectionEvent event) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plate detected: ${event.licensePlate}'),
        action: SnackBarAction(
          label: 'Check In',
          onPressed: () =>
              _showCheckInDialog(context, prefillPlate: event.licensePlate),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        actions: [
          // Camera connection indicator
          _CameraStatusIndicator(status: _cameraStatus),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Lot Map',
            onPressed: () => context.goNamed('lot-map'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'incident':
                  _showIncidentDialog(context);
                case 'logout':
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'incident',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber),
                    SizedBox(width: 8),
                    Text('Log Incident'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCheckInDialog(
          context,
          prefillPlate: _lastDetectedPlate,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Check In'),
      ),
      body: BlocConsumer<SessionCubit, SessionState>(
        listener: (context, state) {
          if (state is SessionCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Vehicle ${state.session.vehicle.licensePlate} checked in at spot ${state.session.spotNumber}',
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SessionLoading) {
            return const LoadingIndicator(message: 'Loading sessions...');
          }
          if (state is SessionError) {
            return ErrorDisplay(
              message: state.message,
              onRetry: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  context.read<SessionCubit>().loadActiveSessions(
                        authState.user.assignedLotId ?? 'default',
                      );
                }
              },
            );
          }
          if (state is SessionLoaded) {
            if (state.sessions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No active sessions',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Tap "Check In" to register a vehicle',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                return _SessionCard(session: state.sessions[index]);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ──────────────────── Check-In Dialog ────────────────────

  void _showCheckInDialog(BuildContext ctx, {String? prefillPlate}) {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(text: prefillPlate ?? '');
    final colorController = TextEditingController();
    String selectedSize = 'medium';

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Vehicle Check-In'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [Validators.licensePlateFormatter],
                  validator: Validators.licensePlate,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Size',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'small', child: Text('Small')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'large', child: Text('Large')),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedSize = val ?? 'medium'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Color',
                    prefixIcon: Icon(Icons.palette_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.vehicleColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogCtx).pop();

                final authState = ctx.read<AuthBloc>().state;
                if (authState is! AuthAuthenticated) return;

                ctx.read<SessionCubit>().createSession(
                      licensePlate: plateController.text.trim().toUpperCase(),
                      vehicleSize: selectedSize,
                      vehicleColor: colorController.text.trim(),
                      spotId: 1, // In production: user selects from lot map
                      lotId: authState.user.assignedLotId ?? 'default',
                      employeeId: authState.user.id,
                    );
              },
              child: const Text('Check In'),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── Incident Dialog ────────────────────

  void _showIncidentDialog(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final plateController = TextEditingController();
    IncidentType selectedType = IncidentType.violation;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Log Incident'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<IncidentType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Incident Type',
                    border: OutlineInputBorder(),
                  ),
                  items: IncidentType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (val) => setDialogState(
                      () => selectedType = val ?? IncidentType.violation),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate (optional)',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [Validators.licensePlateFormatter],
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: Validators.description,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogCtx).pop();

                final authState = ctx.read<AuthBloc>().state;
                if (authState is! AuthAuthenticated) return;

                final incidentService = getIt<IncidentService>();
                await incidentService.logIncident(
                  lotId: authState.user.assignedLotId ?? 'default',
                  employeeId: authState.user.id,
                  type: selectedType,
                  description: descriptionController.text.trim(),
                  licensePlate: plateController.text.trim().isNotEmpty
                      ? plateController.text.trim().toUpperCase()
                      : null,
                );

                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Incident logged')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────── Camera Status Indicator ────────────────────

class _CameraStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;

  const _CameraStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (status) {
      ConnectionStatus.connected => (
          Icons.videocam,
          Colors.green,
          'Camera connected',
        ),
      ConnectionStatus.connecting => (
          Icons.videocam,
          Colors.orange,
          'Camera connecting...',
        ),
      ConnectionStatus.disconnected => (
          Icons.videocam_off,
          Colors.grey,
          'Camera disconnected',
        ),
      ConnectionStatus.authFailed => (
          Icons.videocam_off,
          Colors.red,
          'Camera auth failed',
        ),
    };

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ──────────────────── Session Card ────────────────────

class _SessionCard extends StatelessWidget {
  final ParkingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (session.status == SessionStatus.flaggedForCheckout) {
            context.goNamed(
              'checkout',
              pathParameters: {'sessionId': session.id.toString()},
            );
          }
        },
        onLongPress: () {
          if (session.status == SessionStatus.active) {
            _showFlagDialog(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    session.vehicle.licensePlate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _StatusChip(status: session.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.directions_car,
                    label: session.vehicle.size.displayName,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.palette,
                    label: session.vehicle.color,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.local_parking,
                    label: 'Spot ${session.spotNumber}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration: ${session.formattedDuration}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (session.status == SessionStatus.active)
                    TextButton.icon(
                      onPressed: () => _showFlagDialog(context),
                      icon: const Icon(Icons.exit_to_app, size: 16),
                      label: const Text('Flag Checkout'),
                    ),
                  if (session.status == SessionStatus.flaggedForCheckout)
                    FilledButton.icon(
                      onPressed: () {
                        context.goNamed(
                          'checkout',
                          pathParameters: {
                            'sessionId': session.id.toString()
                          },
                        );
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Process'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFlagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flag for Checkout?'),
        content: Text(
          'Flag vehicle ${session.vehicle.licensePlate} as ready for checkout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SessionCubit>().flagForCheckout(session.id);
            },
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SessionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      SessionStatus.active => (
          Colors.blue,
          Colors.blue.shade50,
        ),
      SessionStatus.flaggedForCheckout => (
          Colors.orange,
          Colors.orange.shade50,
        ),
      SessionStatus.completed => (
          Colors.green,
          Colors.green.shade50,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
