import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/widgets/error_display.dart';
import 'package:parkflow_manager/core/widgets/loading_indicator.dart';
import 'package:parkflow_manager/features/camera_management/domain/entities/camera_device.dart';
import 'package:parkflow_manager/features/camera_management/presentation/bloc/camera_cubit.dart';

class CameraManagementPage extends StatefulWidget {
  const CameraManagementPage({required this.lotId, super.key});

  final String lotId;

  @override
  State<CameraManagementPage> createState() => _CameraManagementPageState();
}

class _CameraManagementPageState extends State<CameraManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<CameraCubit>().loadCameras(widget.lotId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Cameras')),
      body: BlocBuilder<CameraCubit, CameraState>(
        builder: (context, state) {
          if (state is CameraLoading) {
            return const LoadingIndicator(message: 'Loading cameras...');
          }
          if (state is CameraError) {
            return ErrorDisplay(message: state.message);
          }
          if (state is CameraListLoaded) {
            if (state.cameras.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No cameras paired yet.\nTap + to add your first camera.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.cameras.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CameraCard(camera: state.cameras[index]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed('camera-pair'),
        icon: const Icon(Icons.add),
        label: const Text('Add Camera'),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.camera});

  final CameraDevice camera;

  @override
  Widget build(BuildContext context) {
    final isEntrance = camera.cameraType == 'entrance';
    final typeColor = isEntrance ? AppTheme.successColor : AppTheme.secondary;
    final typeLabel = isEntrance ? 'Entrance' : 'Exit';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEntrance ? Icons.login_rounded : Icons.logout_rounded,
                  color: typeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    camera.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.qr_code_2, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  camera.cameraUid,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: camera.isActive ? AppTheme.successColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  camera.isActive ? 'Active' : 'Inactive',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (camera.lastSeenAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen: ${DateFormat('MMM d, h:mm a').format(camera.lastSeenAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
