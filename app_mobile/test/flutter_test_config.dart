import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

// Tela de teste do tamanho de um celular em pé. O padrão do Flutter (800x600)
// é mais baixo que o login atual, e os toques cairiam fora da área visível.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final view = binding.platformDispatcher.views.first;
    view.physicalSize = const Size(2400, 4800);
    addTearDown(view.resetPhysicalSize);
  });
  await testMain();
}
