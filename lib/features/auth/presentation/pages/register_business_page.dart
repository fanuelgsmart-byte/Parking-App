import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parkflow_manager/core/constants/app_constants.dart';
import 'package:parkflow_manager/core/theme/app_theme.dart';
import 'package:parkflow_manager/core/utils/validators.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:parkflow_manager/features/auth/presentation/bloc/register_cubit.dart';

class RegisterBusinessPage extends StatefulWidget {
  const RegisterBusinessPage({super.key});

  @override
  State<RegisterBusinessPage> createState() => _RegisterBusinessPageState();
}

class _RegisterBusinessPageState extends State<RegisterBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _businessEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _operationMode = 'manual';
  int _currentStep = 0;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _businessEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          // Trigger auth check so the router navigates to the right dashboard
          context.read<AuthBloc>().add(const AuthCheckRequested());
        } else if (state is RegisterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Column(
          children: [
            _RegisterHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Register Your Business',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set up your parking management account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      // Step indicator
                      _StepIndicator(currentStep: _currentStep),
                      const SizedBox(height: 24),
                      if (_currentStep == 0) _buildBusinessInfoStep(),
                      if (_currentStep == 1) _buildOperationModeStep(),
                      if (_currentStep == 2) _buildAccountStep(),
                      const SizedBox(height: 24),
                      _buildNavigationButtons(),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Business Information',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _businessNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Business Name',
            prefixIcon: Icon(Icons.business),
          ),
          validator: Validators.name,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ownerNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Owner Full Name',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          validator: Validators.name,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _businessEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Business Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Phone (optional)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressCtrl,
          textInputAction: TextInputAction.done,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Address (optional)',
            prefixIcon: Icon(Icons.location_on_outlined),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationModeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How will you operate?',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how vehicles are checked in at your parking lot.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _OperationModeCard(
          title: 'Manual Entry',
          description:
              'Employees manually enter license plates and vehicle details '
              'when cars arrive and leave.',
          icon: Icons.edit_note_rounded,
          isSelected: _operationMode == 'manual',
          onTap: () => setState(() => _operationMode = 'manual'),
        ),
        const SizedBox(height: 16),
        _OperationModeCard(
          title: 'Camera + Gate',
          description:
              'AI cameras automatically detect license plates at entry and '
              'exit. Requires camera hardware setup.',
          icon: Icons.videocam_rounded,
          isSelected: _operationMode == 'camera_gate',
          onTap: () => setState(() => _operationMode = 'camera_gate'),
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Account',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'This will be your manager login for the app.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ownerEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Login Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: Validators.password,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordCtrl,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordCtrl.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final isLoading = state is RegisterLoading;
        return Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: isLoading ? null : _onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 2 ? 'Create Account' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onNext() {
    if (_currentStep == 0) {
      // Validate business info fields
      if (_businessNameCtrl.text.trim().isEmpty ||
          _ownerNameCtrl.text.trim().isEmpty ||
          _businessEmailCtrl.text.trim().isEmpty) {
        if (_formKey.currentState!.validate()) {
          setState(() => _currentStep = 1);
        }
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_formKey.currentState!.validate()) {
        context.read<RegisterCubit>().register(
              businessName: _businessNameCtrl.text.trim(),
              ownerName: _ownerNameCtrl.text.trim(),
              businessEmail: _businessEmailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              operationMode: _operationMode,
              ownerEmail: _ownerEmailCtrl.text.trim(),
              ownerPassword: _passwordCtrl.text,
            );
      }
    }
  }
}

// ────────────────── Header ──────────────────

class _RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 24, 24, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────── Step Indicator ──────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['Business', 'Mode', 'Account'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive
                        ? AppTheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isActive
                        ? AppTheme.primary
                        : Colors.grey.shade300,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive
                          ? AppTheme.primary
                          : Colors.grey.shade500,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ────────────────── Operation Mode Card ──────────────────

class _OperationModeCard extends StatelessWidget {
  const _OperationModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
