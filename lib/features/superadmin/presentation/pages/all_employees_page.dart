import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class AllEmployeesPage extends StatefulWidget {
  const AllEmployeesPage({super.key});

  @override
  State<AllEmployeesPage> createState() => _AllEmployeesPageState();
}

class _AllEmployeesPageState extends State<AllEmployeesPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('All Employees'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocConsumer<SuperadminCubit, SuperadminState>(
              listener: (context, state) {
                if (state is SuperadminActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is SuperadminLoading) {
                  return const Padding(padding: EdgeInsets.only(top: 80), child: LoadingIndicator(message: 'Loading employees...'));
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: ErrorDisplay(message: state.message, onRetry: () => context.read<SuperadminCubit>().loadEmployees()),
                  );
                }
                if (state is SuperadminEmployeesLoaded) {
                  final filtered = state.employees.where((e) =>
                      e.name.toLowerCase().contains(_search) || e.email.toLowerCase().contains(_search)).toList();
                  return _EmployeeList(employees: filtered, lots: state.lots);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final cubit = context.read<SuperadminCubit>();
    // Need lots list for assignment dropdown
    final state = cubit.state;
    final lots = state is SuperadminEmployeesLoaded ? state.lots : <LotDetail>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(
        lots: lots,
        onSave: (name, email, password, role, lotId) =>
            cubit.createEmployee(name: name, email: email, password: password, role: role, assignedLotId: lotId),
      ),
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees, required this.lots});
  final List<EmployeeDetail> employees;
  final List<LotDetail> lots;

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text('No employees found.')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: employees.length,
      itemBuilder: (context, i) {
        final emp = employees[i];
        final roleColor = emp.role == 'manager' ? AppTheme.warningColor : AppTheme.primary;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: emp.isActive ? roleColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: emp.isActive ? roleColor : Colors.grey),
            ),
            title: Row(
              children: [
                Flexible(child: Text(emp.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(emp.role, style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w600)),
                ),
                if (!emp.isActive) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ],
              ],
            ),
            subtitle: Text('${emp.email}${emp.assignedLotName != null ? ' • ${emp.assignedLotName}' : ''}'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                final cubit = context.read<SuperadminCubit>();
                if (action == 'edit') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _EditEmployeeSheet(
                      employee: emp,
                      lots: lots,
                      onSave: (name, email, role, lotId, isActive) =>
                          cubit.updateEmployee(emp.id, name: name, email: email, role: role, assignedLotId: lotId, isActive: isActive),
                    ),
                  );
                }
                if (action == 'deactivate') cubit.deactivateEmployee(emp.id);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (emp.isActive) const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmployeeFormSheet extends StatefulWidget {
  const _EmployeeFormSheet({required this.lots, required this.onSave});
  final List<LotDetail> lots;
  final void Function(String name, String email, String password, String role, String? lotId) onSave;

  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'employee';
  String? _lotId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Add Employee', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _lotId,
                decoration: const InputDecoration(labelText: 'Assigned Lot (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.lots.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                ],
                onChanged: (v) => setState(() => _lotId = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    widget.onSave(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text, _role, _lotId);
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditEmployeeSheet extends StatefulWidget {
  const _EditEmployeeSheet({required this.employee, required this.lots, required this.onSave});
  final EmployeeDetail employee;
  final List<LotDetail> lots;
  final void Function(String? name, String? email, String? role, String? lotId, bool? isActive) onSave;

  @override
  State<_EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends State<_EditEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late String _role;
  late String? _lotId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee.name);
    _emailCtrl = TextEditingController(text: widget.employee.email);
    _role = widget.employee.role;
    _lotId = widget.employee.assignedLotId;
    _isActive = widget.employee.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Edit Employee', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _lotId,
                decoration: const InputDecoration(labelText: 'Assigned Lot'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.lots.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                ],
                onChanged: (v) => setState(() => _lotId = v),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onSave(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _role, _lotId, _isActive);
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
