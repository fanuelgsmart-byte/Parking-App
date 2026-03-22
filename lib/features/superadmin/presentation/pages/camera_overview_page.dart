import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/features/superadmin/domain/entities/lot_detail.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_cubit.dart';
import 'package:parkflow_manager/features/superadmin/presentation/bloc/superadmin_state.dart';

class CameraOverviewPage extends StatelessWidget {
  const CameraOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Camera Overview'),
              background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
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
                  return const Padding(padding: EdgeInsets.only(top: 100), child: LoadingIndicator(message: 'Loading cameras...'));
                }
                if (state is SuperadminError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: ErrorDisplay(message: state.message, onRetry: () => context.read<SuperadminCubit>().loadCameras()),
                  );
                }
                if (state is SuperadminCamerasLoaded) {
                  return _CameraList(cameras: state.cameras);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPreRegisterSheet(context),
        tooltip: 'Pre-register Camera',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPreRegisterSheet(BuildContext context) {
    final cubit = context.read<SuperadminCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreRegisterSheet(
        onSave: (uid, code) => cubit.preRegisterCamera(cameraUid: uid, pairingCode: code),
      ),
    );
  }
}

class _CameraList extends StatelessWidget {
  const _CameraList({required this.cameras});
  final List<CameraOverviewItem> cameras;

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(child: Text('No cameras registered.')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: cameras.length,
      itemBuilder: (context, i) {
        final cam = cameras[i];
        final statusColor = cam.isActive && cam.isPaired ? AppTheme.successColor : Colors.grey;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(
                cam.cameraType == 'entrance' ? Icons.login_rounded : Icons.logout_rounded,
                color: statusColor,
              ),
            ),
            title: Text(cam.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UID: ${cam.cameraUid}'),
                Row(
                  children: [
                    if (cam.lotName != null) Text('${cam.lotName} • '),
                    Text(cam.cameraType),
                    const Text(' • '),
                    Text(cam.isPaired ? 'Paired' : 'Unpaired',
                        style: TextStyle(color: cam.isPaired ? AppTheme.successColor : AppTheme.warningColor)),
                  ],
                ),
                if (cam.lastSeenAt != null)
                  Text('Last seen: ${_formatTime(cam.lastSeenAt!)}',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            isThreeLine: true,
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PreRegisterSheet extends StatefulWidget {
  const _PreRegisterSheet({required this.onSave});
  final void Function(String uid, String code) onSave;

  @override
  State<_PreRegisterSheet> createState() => _PreRegisterSheetState();
}

class _PreRegisterSheetState extends State<_PreRegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _uidCtrl.dispose();
    _codeCtrl.dispose();
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
              Text('Pre-register Camera', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uidCtrl,
                decoration: const InputDecoration(labelText: 'Camera UID'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: 'Pairing Code'),
                validator: (v) => v == null || v.length < 4 ? 'Min 4 chars' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    widget.onSave(_uidCtrl.text.trim(), _codeCtrl.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
