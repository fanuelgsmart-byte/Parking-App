import 'package:flutter/material.dart';

class WebPreviewApp extends StatelessWidget {
  const WebPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkFlow Manager Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _WebPreviewHome(),
    );
  }
}

class _WebPreviewHome extends StatelessWidget {
  const _WebPreviewHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 960;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isWide ? const _WideLayout() : const _NarrowLayout(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(flex: 6, child: _HeroPanel()),
        SizedBox(width: 24),
        Expanded(flex: 4, child: _InfoPanel()),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPanel(),
        SizedBox(height: 24),
        _InfoPanel(),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: const Color(0xFF0F172A),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F172A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_parking_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Text(
                'ParkFlow Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Browser preview mode',
            style: TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The full operations app uses native plugins for local storage, database encryption, and device integrations. This browser build gives you a polished preview shell so the product is viewable immediately in a web browser.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 18,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _StatChip(label: 'Realtime parking ops', value: '24/7'),
              _StatChip(label: 'Sync queue', value: 'Queued'),
              _StatChip(label: 'Reports', value: 'Ready'),
            ],
          ),
          const SizedBox(height: 32),
          const _ModuleCard(
            title: 'What you can see',
            body:
                'A browser-safe overview of the parking system layout, enterprise hardening direction, and key operational modules.',
          ),
          const SizedBox(height: 16),
          const _ModuleCard(
            title: 'What remains native-only',
            body:
                'Encrypted local storage, offline Drift database, biometric unlock, and device camera integrations stay in the desktop/mobile app.',
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SmallCard(
          title: 'Enterprise architecture',
          body:
              'Modular monolith with clear boundaries for auth, sessions, payments, reports, and platform services.',
        ),
        SizedBox(height: 16),
        _SmallCard(
          title: 'Operational focus',
          body:
              'Supports checkout, lot management, reporting, sync, and audit flows with typed domain rules.',
        ),
        SizedBox(height: 16),
        _SmallCard(
          title: 'Browser note',
          body:
              'This browser view is intentionally limited to avoid native-only plugins that do not run on the web.',
        ),
      ],
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141E293B),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
