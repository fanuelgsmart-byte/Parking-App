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
  StreamSubscription<SessionCreatedEvent>? _sessionCreatedSub;
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
      _sessionCreatedSub = _cameraService.sessionStream.listen(_onSessionCreated);
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
    _sessionCreatedSub?.cancel();
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

  void _onSessionCreated(SessionCreatedEvent event) {
    if (!mounted) return;
    setState(() => _lastDetectedPlate = event.licensePlate);
    // Refresh session list — the backend session will appear once the sync runs
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.context.hasLotAccess) {
      context.read<SessionCubit>().loadOpenSessions(authState.context.requireLotId());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.successColor,
        content: Text(
          '🚗 ${event.licensePlate} checked in automatically '
          '— ${event.vehicleColor} ${event.vehicleSize}, spot ${event.spotNumber}',
        ),
        duration: const Duration(seconds: 4),
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

  Color get _statusColor {
    switch (session.status) {
      case SessionStatus.active:
        return AppTheme.successColor;
      case SessionStatus.flaggedForCheckout:
        return AppTheme.warningColor;
      case SessionStatus.paymentPending:
        return AppTheme.secondary;
      case SessionStatus.completed:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.flaggedForCheckout:
        return 'Checkout';
      case SessionStatus.paymentPending:
        return 'Payment';
      case SessionStatus.completed:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSessionDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: plate + status badge
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    session.vehicle.licensePlate,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Colour + size badges
              Wrap(
                spacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.palette_outlined,
                    label: session.vehicle.color,
                  ),
                  _InfoChip(
                    icon: Icons.straighten_outlined,
                    label: session.vehicle.size.displayName,
                  ),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: 'Spot ${session.spotNumber}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Entry time + duration row
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'In: ${DateFormat('h:mm a').format(session.entryTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    session.formattedDuration,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: session.status == SessionStatus.active
                    ? OutlinedButton.icon(
                        onPressed: () => context
                            .read<SessionCubit>()
                            .flagForCheckout(session.id),
                        icon: const Icon(Icons.flag_outlined, size: 16),
                        label: const Text('Flag for Checkout'),
                      )
                    : FilledButton.icon(
                        onPressed: () => context.goNamed(
                          'checkout',
                          pathParameters: {
                            'sessionId': session.id.toString()
                          },
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 16),
                        label: Text(
                          session.status == SessionStatus.paymentPending
                              ? 'Resume Payment'
                              : 'Checkout',
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SessionDetailSheet(session: session),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailSheet extends StatelessWidget {
  const _SessionDetailSheet({required this.session});

  final ParkingSession session;

  @override
  Widget build(BuildContext context) {
    final imageUrl = session.vehicle.imageUrl;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Captured image (if available)
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 48, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.directions_car_rounded,
                    size: 56, color: AppTheme.primary),
              ),
            ),
          const SizedBox(height: 20),
          // Plate + status
          Row(
            children: [
              Text(
                session.vehicle.licensePlate,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 22),
              ),
              const Spacer(),
              Chip(
                label: Text(session.status.name),
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
              icon: Icons.palette_outlined,
              label: 'Colour',
              value: session.vehicle.color),
          _DetailRow(
              icon: Icons.straighten_outlined,
              label: 'Size',
              value: session.vehicle.size.displayName),
          _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Spot',
              value: session.spotNumber),
          _DetailRow(
              icon: Icons.login_rounded,
              label: 'Entry time',
              value: DateFormat('EEE, MMM d • h:mm a')
                  .format(session.entryTime)),
          _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: session.formattedDuration),
          if (session.totalFee != null)
            _DetailRow(
                icon: Icons.attach_money_rounded,
                label: 'Fee',
                value: '\$${session.totalFee!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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
