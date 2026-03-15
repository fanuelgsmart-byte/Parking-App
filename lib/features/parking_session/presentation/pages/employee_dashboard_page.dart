import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:parkflow_manager/core/di/injection.dart';
import 'package:parkflow_manager/core/services/camera_websocket_service.dart';
import 'package:parkflow_manager/core/services/incident_service.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
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
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraWebSocketService();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final lotId = authState.user.assignedLotId ?? 'default';
      context.read<SessionCubit>().loadActiveSessions(lotId);
      _cameraService.connect(lotId, authToken: '');

      _plateSub = _cameraService.plateStream.listen((event) {
        setState(() => _lastDetectedPlate = event.licensePlate);
        _onPlateDetected(event);
      });
      _statusSub = _cameraService.statusStream.listen((status) {
        if (mounted) setState(() => _cameraStatus = status);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Plate detected: ${event.licensePlate}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        action: SnackBarAction(
          label: 'CHECK IN',
          textColor: Colors.white,
          onPressed: () =>
              _showCheckInDialog(context, prefillPlate: event.licensePlate),
        ),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName =
        authState is AuthAuthenticated ? authState.user.name : 'Employee';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _navIndex == 0
          ? _SessionsTab(
              userName: userName,
              cameraStatus: _cameraStatus,
              lastDetectedPlate: _lastDetectedPlate,
              onCheckIn: () =>
                  _showCheckInDialog(context, prefillPlate: _lastDetectedPlate),
              onIncident: () => _showIncidentDialog(context),
              onLotMap: () => context.goNamed('lot-map'),
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            )
          : _ProfileTab(
              userName: userName,
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              onIncident: () => _showIncidentDialog(context),
            ),
      // FAB only on sessions tab
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showCheckInDialog(context, prefillPlate: _lastDetectedPlate),
              icon: const Icon(Icons.add),
              label: const Text('Check In'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
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

  // ──────────────────────────── Check-In Dialog ────────────────────────────

  void _showCheckInDialog(BuildContext ctx, {String? prefillPlate}) {
    final formKey = GlobalKey<FormState>();
    final plateCtrl = TextEditingController(text: prefillPlate ?? '');
    final colorCtrl = TextEditingController();
    String selectedSize = 'medium';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_car_filled,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vehicle Check-In',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  DateFormat('EEE, MMM d · h:mm a')
                                      .format(DateTime.now()),
                                  style: Theme.of(ctx).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // License Plate
                              TextFormField(
                                controller: plateCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  Validators.licensePlateFormatter
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'License Plate *',
                                  prefixIcon:
                                      Icon(Icons.badge_outlined),
                                  hintText: 'e.g. ABC-1234',
                                ),
                                validator: Validators.licensePlate,
                              ),
                              const SizedBox(height: 16),
                              // Vehicle Size
                              DropdownButtonFormField<String>(
                                value: selectedSize,
                                decoration: const InputDecoration(
                                  labelText: 'Vehicle Size *',
                                  prefixIcon:
                                      Icon(Icons.straighten_outlined),
                                ),
                                items: [
                                  _sizeItem('small', 'Small',
                                      Icons.directions_car_outlined),
                                  _sizeItem('medium', 'Medium',
                                      Icons.directions_car),
                                  _sizeItem('large', 'Large',
                                      Icons.local_shipping_outlined),
                                ],
                                onChanged: (val) => setSheetState(
                                  () => selectedSize = val ?? 'medium',
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Vehicle Color
                              TextFormField(
                                controller: colorCtrl,
                                textCapitalization:
                                    TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Vehicle Color *',
                                  prefixIcon:
                                      Icon(Icons.palette_outlined),
                                  hintText: 'e.g. White, Black, Red',
                                ),
                                validator: Validators.vehicleColor,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    Navigator.of(sheetCtx).pop();
                                    final authState =
                                        ctx.read<AuthBloc>().state;
                                    if (authState
                                        is! AuthAuthenticated) return;

                                    ctx.read<SessionCubit>().createSession(
                                          licensePlate: plateCtrl.text
                                              .trim()
                                              .toUpperCase(),
                                          vehicleSize: selectedSize,
                                          vehicleColor:
                                              colorCtrl.text.trim(),
                                          spotId: 1,
                                          lotId: authState.user
                                                  .assignedLotId ??
                                              'default',
                                          employeeId: authState.user.id,
                                        );
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Confirm Check-In'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _sizeItem(
      String val, String label, IconData icon) {
    return DropdownMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  // ──────────────────────────── Incident Dialog ────────────────────────────

  void _showIncidentDialog(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    final descCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    IncidentType selectedType = IncidentType.violation;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.warningColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Log Incident',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<IncidentType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Incident Type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: IncidentType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setDialogState(
                          () => selectedType = val ?? IncidentType.violation,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: plateCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [Validators.licensePlateFormatter],
                        decoration: const InputDecoration(
                          labelText: 'License Plate (optional)',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: Validators.description,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.of(dialogCtx).pop();

                        final authState = ctx.read<AuthBloc>().state;
                        if (authState is! AuthAuthenticated) return;

                        await getIt<IncidentService>().logIncident(
                          lotId: authState.user.assignedLotId ?? 'default',
                          employeeId: authState.user.id,
                          type: selectedType,
                          description: descCtrl.text.trim(),
                          licensePlate:
                              plateCtrl.text.trim().isNotEmpty
                                  ? plateCtrl.text.trim().toUpperCase()
                                  : null,
                        );

                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Incident logged successfully'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Submit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Sessions Tab ───────────────────────────────────

class _SessionsTab extends StatelessWidget {
  final String userName;
  final ConnectionStatus cameraStatus;
  final String? lastDetectedPlate;
  final VoidCallback onCheckIn;
  final VoidCallback onIncident;
  final VoidCallback onLotMap;
  final VoidCallback onLogout;

  const _SessionsTab({
    required this.userName,
    required this.cameraStatus,
    required this.lastDetectedPlate,
    required this.onCheckIn,
    required this.onIncident,
    required this.onLotMap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverAppBar(
          expandedHeight: 130,
          pinned: true,
          elevation: 0,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration:
                  const BoxDecoration(gradient: AppTheme.headerGradient),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${userName.split(' ').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CameraStatusBadge(status: cameraStatus),
                ],
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
            collapseMode: CollapseMode.parallax,
            title: Text(
              'Active Sessions',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              tooltip: 'Lot Map',
              onPressed: onLotMap,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'incident') onIncident();
                if (v == 'logout') onLogout();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'incident',
                  child: Row(children: [
                    Icon(Icons.warning_amber_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Log Incident'),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout,
                        size: 20, color: AppTheme.errorColor),
                    const SizedBox(width: 10),
                    Text('Sign Out',
                        style: TextStyle(color: AppTheme.errorColor)),
                  ]),
                ),
              ],
            ),
          ],
        ),

        // ── Content ──
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: BlocConsumer<SessionCubit, SessionState>(
            listener: (context, state) {
              if (state is SessionCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.session.vehicle.licensePlate} checked in at spot ${state.session.spotNumber}',
                    ),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is SessionLoading) {
                return const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Loading sessions...'),
                );
              }
              if (state is SessionError) {
                return SliverFillRemaining(
                  child: ErrorDisplay(
                    message: state.message,
                    onRetry: () {
                      final auth = context.read<AuthBloc>().state;
                      if (auth is AuthAuthenticated) {
                        context.read<SessionCubit>().loadActiveSessions(
                              auth.user.assignedLotId ?? 'default',
                            );
                      }
                    },
                  ),
                );
              }
              if (state is SessionLoaded) {
                if (state.sessions.isEmpty) {
                  return const SliverFillRemaining(
                    child: _EmptySessionsState(),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(session: state.sessions[i]),
                    ),
                    childCount: state.sessions.length,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Empty State ────────────────────────────────────

class _EmptySessionsState extends StatelessWidget {
  const _EmptySessionsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 40,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No active sessions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF718096),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Check In to register a vehicle',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Session Card ───────────────────────────────────

class _SessionCard extends StatelessWidget {
  final ParkingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isFlagged = session.status == SessionStatus.flaggedForCheckout;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isFlagged
            ? () => context.goNamed(
                  'checkout',
                  pathParameters: {'sessionId': session.id.toString()},
                )
            : null,
        onLongPress: session.status == SessionStatus.active
            ? () => _showFlagDialog(context)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row ──
              Row(
                children: [
                  // Vehicle icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_car_filled,
                      color: _statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.vehicle.licensePlate,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.vehicle.color} · ${session.vehicle.size.displayName}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: session.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // ── Details Row ──
              Row(
                children: [
                  _DetailPill(
                    icon: Icons.local_parking_rounded,
                    label: 'Spot ${session.spotNumber}',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _DetailPill(
                    icon: Icons.timer_outlined,
                    label: session.formattedDuration,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _DetailPill(
                    icon: Icons.schedule_outlined,
                    label: DateFormat('h:mm a').format(session.entryTime),
                    color: const Color(0xFF718096),
                  ),
                ],
              ),
              if (session.status == SessionStatus.active ||
                  session.status == SessionStatus.flaggedForCheckout) ...[
                const SizedBox(height: 12),
                // ── Action Row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (session.status == SessionStatus.active)
                      _ActionButton(
                        label: 'Flag Checkout',
                        icon: Icons.exit_to_app_outlined,
                        onTap: () => _showFlagDialog(context),
                        color: AppTheme.warningColor,
                        filled: false,
                      ),
                    if (session.status == SessionStatus.flaggedForCheckout)
                      _ActionButton(
                        label: 'Process Payment',
                        icon: Icons.payment_outlined,
                        onTap: () => context.goNamed(
                          'checkout',
                          pathParameters: {
                            'sessionId': session.id.toString()
                          },
                        ),
                        color: AppTheme.primary,
                        filled: true,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    return switch (session.status) {
      SessionStatus.active => AppTheme.primary,
      SessionStatus.flaggedForCheckout => AppTheme.warningColor,
      SessionStatus.completed => AppTheme.successColor,
    };
  }

  void _showFlagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flag for Checkout?'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Mark '),
              TextSpan(
                text: session.vehicle.licensePlate,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' as ready to check out?'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SessionCubit>().flagForCheckout(session.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.warningColor),
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SessionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      SessionStatus.active => (
          'Active',
          AppTheme.primary,
          AppTheme.primary.withValues(alpha: 0.1),
        ),
      SessionStatus.flaggedForCheckout => (
          'Ready',
          AppTheme.warningColor,
          AppTheme.warningColor.withValues(alpha: 0.1),
        ),
      SessionStatus.completed => (
          'Done',
          AppTheme.successColor,
          AppTheme.successColor.withValues(alpha: 0.1),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────── Camera Status Badge ─────────────────────────────

class _CameraStatusBadge extends StatelessWidget {
  final ConnectionStatus status;

  const _CameraStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      ConnectionStatus.connected => (
          Icons.videocam_rounded,
          'Live',
          AppTheme.spotAvailable,
        ),
      ConnectionStatus.connecting => (
          Icons.videocam_rounded,
          '...',
          AppTheme.warningColor,
        ),
      ConnectionStatus.disconnected => (
          Icons.videocam_off_rounded,
          'Off',
          Colors.grey,
        ),
      ConnectionStatus.authFailed => (
          Icons.videocam_off_rounded,
          'Error',
          AppTheme.errorColor,
        ),
    };

    return Tooltip(
      message: 'Camera: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Profile Tab ─────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback onIncident;

  const _ProfileTab({
    required this.userName,
    required this.onLogout,
    required this.onIncident,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Avatar
            CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'E',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              userName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Employee',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Quick Actions
            _ProfileMenuItem(
              icon: Icons.warning_amber_outlined,
              label: 'Log Incident',
              color: AppTheme.warningColor,
              onTap: onIncident,
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.info_outline,
              label: 'About ParkFlow',
              color: AppTheme.infoColor,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'ParkFlow Manager',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.local_parking_rounded,
                  color: AppTheme.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppTheme.errorColor,
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color == AppTheme.errorColor ? color : null,
          ),
        ),
        trailing: Icon(Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
