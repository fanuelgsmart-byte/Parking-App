import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:parkflow_manager/core/services/camera_websocket_service.dart';
import 'package:parkflow_manager/core/services/incident_cubit.dart';
import 'package:parkflow_manager/core/services/incident_service.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/utils/validators.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/parking_session.dart';
import 'package:parkflow_manager/features/parking_session/domain/entities/vehicle.dart';
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
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraWebSocketService();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.context.hasLotAccess) {
      final lotId = authState.context.requireLotId();
      context.read<SessionCubit>().loadOpenSessions(lotId);
      context.read<SessionCubit>().watchSessions(lotId);
      _cameraService.connect(lotId, authToken: authState.session.accessToken);
      _plateSub = _cameraService.plateStream.listen(_onPlateDetected);
      _statusSub = _cameraService.statusStream.listen((status) {
        if (mounted) {
          setState(() => _cameraStatus = status);
        }
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

  void _onPlateDetected(PlateDetectionEvent event) {
    if (!mounted) return;
    setState(() => _lastDetectedPlate = event.licensePlate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plate detected: ${event.licensePlate}'),
        action: SnackBarAction(
          label: 'Check In',
          onPressed: () =>
              _showCheckInDialog(context, prefillPlate: event.licensePlate),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }
    if (!authState.context.hasLotAccess) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This account has no assigned lot. Contact a manager to continue.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(_navIndex == 0 ? 'Employee Dashboard' : 'Profile'),
        actions: [
          if (_navIndex == 0)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => context.goNamed('lot-map'),
            ),
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () => _showIncidentDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: _navIndex == 0
          ? _SessionsView(
              userName: authState.user.name,
              cameraStatus: _cameraStatus,
              lastDetectedPlate: _lastDetectedPlate,
              onCheckIn: () => _showCheckInDialog(
                context,
                prefillPlate: _lastDetectedPlate,
              ),
            )
          : _ProfileView(userName: authState.user.name),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCheckInDialog(
                context,
                prefillPlate: _lastDetectedPlate,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Check In'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showCheckInDialog(BuildContext context, {String? prefillPlate}) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.context.hasLotAccess) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final plateCtrl = TextEditingController(text: prefillPlate ?? '');
    final colorCtrl = TextEditingController();
    VehicleSize selectedSize = VehicleSize.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vehicle Check-In',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: plateCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [Validators.licensePlateFormatter],
                decoration: const InputDecoration(labelText: 'License Plate'),
                validator: Validators.licensePlate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VehicleSize>(
                initialValue: selectedSize,
                items: VehicleSize.values
                    .map(
                      (size) => DropdownMenuItem(
                        value: size,
                        child: Text(size.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedSize = value;
                  }
                },
                decoration: const InputDecoration(labelText: 'Vehicle Size'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Vehicle Color'),
                validator: Validators.vehicleColor,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(sheetContext).pop();
                    context.read<SessionCubit>().createSession(
                          CheckInRequest(
                            licensePlate: plateCtrl.text.trim().toUpperCase(),
                            vehicleSize: selectedSize,
                            vehicleColor: colorCtrl.text.trim(),
                            lotId: authState.context.requireLotId(),
                            employeeId: authState.context.userId,
                          ),
                        );
                  },
                  child: const Text('Confirm Check-In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showIncidentDialog(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.context.hasLotAccess) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final descCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    IncidentType selectedType = IncidentType.violation;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Incident'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<IncidentType>(
                initialValue: selectedType,
                items: IncidentType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: plateCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [Validators.licensePlateFormatter],
                decoration: const InputDecoration(
                  labelText: 'License Plate (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: Validators.description,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await context.read<IncidentCubit>().logIncident(
                    lotId: authState.context.requireLotId(),
                    employeeId: authState.context.userId,
                    type: selectedType,
                    description: descCtrl.text.trim(),
                    licensePlate: plateCtrl.text.trim().isEmpty
                        ? null
                        : plateCtrl.text.trim().toUpperCase(),
                  );
              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Incident logged successfully'
                        : 'Failed to log incident',
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SessionsView extends StatelessWidget {
  const _SessionsView({
    required this.userName,
    required this.cameraStatus,
    required this.lastDetectedPlate,
    required this.onCheckIn,
  });

  final String userName;
  final ConnectionStatus cameraStatus;
  final String? lastDetectedPlate;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $userName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatusChip(
                          label: 'Camera ${cameraStatus.name}',
                          color: cameraStatus == ConnectionStatus.connected
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(width: 8),
                        if (lastDetectedPlate != null)
                          _StatusChip(
                            label: 'Last plate: $lastDetectedPlate',
                            color: AppTheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onCheckIn,
                      icon: const Icon(Icons.add),
                      label: const Text('New Check-In'),
                    ),
                  ],
                ),
              ),
            ),
            if (state is SessionLoading)
              const SliverFillRemaining(
                child: LoadingIndicator(message: 'Loading sessions...'),
              )
            else if (state is SessionError)
              SliverFillRemaining(child: ErrorDisplay(message: state.message))
            else if (state is SessionLoaded && state.sessions.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SessionCard(session: state.sessions[index]),
                  ),
                  itemCount: state.sessions.length,
                ),
              )
            else
              const SliverFillRemaining(
                child: Center(child: Text('No open sessions yet.')),
              ),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ParkingSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
          child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary),
        ),
        title: Text(
          session.vehicle.licensePlate,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${session.vehicle.color} • ${session.vehicle.size.displayName} • ${session.formattedDuration} • Spot ${session.spotNumber}',
          ),
        ),
        trailing: session.status == SessionStatus.active
            ? FilledButton(
                onPressed: () =>
                    context.read<SessionCubit>().flagForCheckout(session.id),
                child: const Text('Flag Checkout'),
              )
            : FilledButton(
                onPressed: () => context.goNamed(
                  'checkout',
                  pathParameters: {'sessionId': session.id.toString()},
                ),
                child: Text(
                  session.status == SessionStatus.paymentPending
                      ? 'Resume Payment'
                      : 'Checkout',
                ),
              ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEE, MMM d • h:mm a').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
