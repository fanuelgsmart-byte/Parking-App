import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/features/auth/domain/entities/user.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/utils/validators.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';
import 'package:parkflow_manager/features/employee_management/presentation/bloc/employee_cubit.dart';

class EmployeeManagementPage extends StatefulWidget {

  const EmployeeManagementPage({super.key, required this.lotId});
  final String lotId;

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<EmployeeCubit>().loadEmployees(widget.lotId);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: const Text(
                'Employee Management',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.headerGradient),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white),
                  onPressed: () => _showAddEmployeeSheet(context),
                  tooltip: 'Add Employee',
                ),
              ),
            ],
          ),

          // ── Search bar ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          BlocConsumer<EmployeeCubit, EmployeeState>(
            listener: (context, state) {
              if (state is EmployeeActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(state.message),
                      ],
                    ),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state is EmployeeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is EmployeeLoading) {
                return const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Loading employees...'),
                );
              }
              if (state is EmployeeListLoaded) {
                final filtered = _query.isEmpty
                    ? state.employees
                    : state.employees
                        .where((e) =>
                            e.name
                                .toLowerCase()
                                .contains(_query.toLowerCase()) ||
                            e.email
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(hasQuery: _query.isNotEmpty),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _EmployeeCard(
                        employee: filtered[index],
                        onDeactivate: (id) =>
                            context.read<EmployeeCubit>().deactivateEmployee(id),
                        onViewShift: (id) {
                          context.read<EmployeeCubit>().loadShiftSummary(
                                id,
                                DateTime.now(),
                              );
                          _showShiftSummarySheet(context, id);
                        },
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                );
              }
              if (state is EmployeeError) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                );
              }
              return const SliverFillRemaining(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEmployeeSheet(
        lotId: widget.lotId,
        onAdd: (employee) =>
            context.read<EmployeeCubit>().addEmployee(employee),
      ),
    );
  }

  void _showShiftSummarySheet(BuildContext context, String employeeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocBuilder<EmployeeCubit, EmployeeState>(
        bloc: context.read<EmployeeCubit>(),
        builder: (ctx, state) {
          if (state is EmployeeLoading) {
            return const _Sheet(
              child: SizedBox(
                height: 100,
                child: LoadingIndicator(message: 'Loading shift...'),
              ),
            );
          }
          if (state is ShiftSummaryLoaded) {
            return _ShiftSummarySheet(summary: state.summary);
          }
          return const _Sheet(child: SizedBox(height: 80));
        },
      ),
    );
  }
}

// ──────────────────────────── Employee Card ───────────────────────────────────

class _EmployeeCard extends StatelessWidget {

  const _EmployeeCard({
    required this.employee,
    required this.onDeactivate,
    required this.onViewShift,
  });
  final Employee employee;
  final void Function(String id) onDeactivate;
  final void Function(String id) onViewShift;

  Color get _roleColor =>
      employee.role == UserRole.manager ? AppTheme.warningColor : AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _roleColor.withValues(alpha: 0.12),
            child: Text(
              employee.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        employee.role.label,
                        style: TextStyle(
                          color: _roleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  employee.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!employee.isActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Deactivated',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'shift',
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18),
                    SizedBox(width: 8),
                    Text("Today's Shift"),
                  ],
                ),
              ),
              if (employee.isActive)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.person_off_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Deactivate',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'shift') onViewShift(employee.id);
              if (value == 'deactivate') _confirmDeactivate(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_rounded,
            color: AppTheme.warningColor, size: 36),
        title: const Text('Deactivate Employee'),
        content: Text(
            'Are you sure you want to deactivate ${employee.name}? They will lose access to the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDeactivate(employee.id);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Add Employee Sheet ─────────────────────────────

class _AddEmployeeSheet extends StatefulWidget {

  const _AddEmployeeSheet({required this.lotId, required this.onAdd});
  final String lotId;
  final void Function(Employee) onAdd;

  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'employee';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return _Sheet(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Employee',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(
                      value: 'manager', child: Text('Manager')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedRole = val ?? 'employee'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Add Employee',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop();
    widget.onAdd(
      Employee(
        id: '',
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _selectedRole == 'manager' ? UserRole.manager : UserRole.employee,
        assignedLotId: widget.lotId,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
  }
}

// ──────────────────────────── Shift Summary Sheet ────────────────────────────

class _ShiftSummarySheet extends StatelessWidget {

  const _ShiftSummarySheet({required this.summary});
  final ShiftSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.cashCollected + summary.digitalCollected;
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Shift Summary",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.shiftStart.year}-${summary.shiftStart.month.toString().padLeft(2, '0')}-${summary.shiftStart.day.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ShiftStat(
                label: 'Vehicles',
                value: summary.vehiclesProcessed.toString(),
                icon: Icons.directions_car_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              _ShiftStat(
                label: 'Total',
                value: '\$${total.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.successColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Cash Collected', value: '\$${summary.cashCollected.toStringAsFixed(2)}'),
          const Divider(height: 1),
          _SummaryRow(label: 'Digital Collected', value: '\$${summary.digitalCollected.toStringAsFixed(2)}'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ShiftStat extends StatelessWidget {

  const _ShiftStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {

  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Empty State ────────────────────────────────────

class _EmptyState extends StatelessWidget {

  const _EmptyState({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'No results found' : 'No employees yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Sheet Container ────────────────────────────────

class _Sheet extends StatelessWidget {

  const _Sheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}


