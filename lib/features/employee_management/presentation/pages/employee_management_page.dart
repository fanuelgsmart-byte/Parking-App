import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/utils/validators.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/employee_management/domain/entities/employee.dart';
import 'package:parkflow_manager/features/employee_management/presentation/bloc/employee_cubit.dart';

class EmployeeManagementPage extends StatefulWidget {
  final String lotId;

  const EmployeeManagementPage({super.key, required this.lotId});

  @override
  State<EmployeeManagementPage> createState() =>
      _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<EmployeeCubit>().loadEmployees(widget.lotId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmployeeDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: BlocConsumer<EmployeeCubit, EmployeeState>(
        listener: (context, state) {
          if (state is EmployeeActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is EmployeeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EmployeeLoading) {
            return const LoadingIndicator(message: 'Loading employees...');
          }
          if (state is EmployeeListLoaded) {
            return _EmployeeListView(
              employees: state.employees,
              onDeactivate: (id) =>
                  context.read<EmployeeCubit>().deactivateEmployee(id),
              onViewShift: (id) {
                context.read<EmployeeCubit>().loadShiftSummary(
                      id,
                      DateTime.now(),
                    );
                _showShiftSummarySheet(context, id);
              },
            );
          }
          if (state is EmployeeError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'employee';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Employee'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text('Employee'),
                    ),
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text('Manager'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedRole = val ?? 'employee'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();
                final employee = Employee(
                  id: '',
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  role: selectedRole,
                  assignedLotId: widget.lotId,
                  isActive: true,
                  createdAt: DateTime.now(),
                );
                context.read<EmployeeCubit>().addEmployee(employee);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftSummarySheet(BuildContext context, String employeeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocBuilder<EmployeeCubit, EmployeeState>(
        bloc: context.read<EmployeeCubit>(),
        builder: (ctx, state) {
          if (state is EmployeeLoading) {
            return const SizedBox(
              height: 200,
              child: LoadingIndicator(message: 'Loading shift data...'),
            );
          }
          if (state is ShiftSummaryLoaded) {
            final s = state.summary;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shift Summary',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    label: 'Date',
                    value:
                        '${s.shiftStart.year}-${s.shiftStart.month.toString().padLeft(2, '0')}-${s.shiftStart.day.toString().padLeft(2, '0')}',
                  ),
                  _SummaryRow(
                    label: 'Vehicles Processed',
                    value: s.vehiclesProcessed.toString(),
                  ),
                  _SummaryRow(
                    label: 'Cash Collected',
                    value: '\$${s.cashCollected.toStringAsFixed(2)}',
                  ),
                  _SummaryRow(
                    label: 'Digital Collected',
                    value: '\$${s.digitalCollected.toStringAsFixed(2)}',
                  ),
                  _SummaryRow(
                    label: 'Total Collected',
                    value:
                        '\$${(s.cashCollected + s.digitalCollected).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return const SizedBox(height: 100);
        },
      ),
    );
  }
}

class _EmployeeListView extends StatelessWidget {
  final List<Employee> employees;
  final void Function(String id) onDeactivate;
  final void Function(String id) onViewShift;

  const _EmployeeListView({
    required this.employees,
    required this.onDeactivate,
    required this.onViewShift,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No employees found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: employee.role == 'manager'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              child: Text(employee.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(employee.name),
            subtitle: Text('${employee.role} • ${employee.email}'),
            trailing: PopupMenuButton(
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'shift',
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 8),
                      Text("Today's Shift"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.person_off, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Deactivate',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'shift') onViewShift(employee.id);
                if (value == 'deactivate') {
                  _confirmDeactivate(context, employee);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDeactivate(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Employee'),
        content:
            Text('Are you sure you want to deactivate ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.grey,
              )),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
