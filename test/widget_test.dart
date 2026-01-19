import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecosistema_fiware/main.dart';

void main() {
  testWidgets('App loads with correct title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EcosistemaFiwareApp());

    // Verify that the app title is displayed.
    expect(find.text('Ecosistema FIWARE'), findsOneWidget);
    
    // Verify that the welcome message is displayed.
    expect(find.text('Bienvenido al Ecosistema FIWARE'), findsOneWidget);
    
    // Verify that the explore button is present.
    expect(find.text('Explorar'), findsOneWidget);
  });
}
