import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation layer does not import data infrastructure directly', () {
    final projectRoot = Directory.current.path;
    final presentationRoot = Directory('$projectRoot/lib/features');

    final forbiddenPatterns = <RegExp>[
      RegExp(r'package:parkflow_manager/core/database/'),
      RegExp(r'package:parkflow_manager/core/network/api_client\\.dart'),
      RegExp(r'package:parkflow_manager/core/di/injection\\.dart'),
      RegExp(r'package:get_it/get_it\\.dart'),
      RegExp(r'package:parkflow_manager/.*/data/datasources/'),
    ];

    final violations = <String>[];

    for (final file
        in presentationRoot.listSync(recursive: true).whereType<File>()) {
      if (!file.path.contains('${Platform.pathSeparator}presentation${Platform.pathSeparator}')) {
        continue;
      }
      if (!file.path.endsWith('.dart')) {
        continue;
      }

      final source = file.readAsStringSync();
      final imports = RegExp(r"^import\s+'([^']+)';", multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toList();

      for (final importPath in imports) {
        if (forbiddenPatterns.any((pattern) => pattern.hasMatch(importPath))) {
          violations.add('${file.path} -> $importPath');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Presentation layer imported forbidden infrastructure:\n${violations.join('\n')}',
    );
  });
}

